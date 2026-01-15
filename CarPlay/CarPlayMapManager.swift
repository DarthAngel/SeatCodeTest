//
//  CarPlayMapManager.swift
//  SeatCodeTest
//
//  Created by Angel Docampo on 07/01/2026.
//

import Foundation
internal import CarPlay
import MapKit
import CoreLocation

@MainActor
class CarPlayMapManager: NSObject {
    
    private weak var mapTemplate: CPMapTemplate?
    private var currentTrip: Trip?
    private var mapView: MKMapView?
    
    init(mapTemplate: CPMapTemplate) {
        self.mapTemplate = mapTemplate
        super.init()
        setupMapView()
    }
    
    private func setupMapView() {
        // Note: In actual CarPlay implementation, the mapView is typically
        // managed by the system. This is a conceptual implementation.
        mapView = MKMapView()
        mapView?.delegate = self
    }
    
    // MARK: - Public Methods
    
    func displayTrip(_ trip: Trip) {
        currentTrip = trip
        clearMap()
        
        // Validate coordinates first
        let originCoord = trip.origin.point.coordinate
        let destinationCoord = trip.destination.point.coordinate
        
        guard CLLocationCoordinate2DIsValid(originCoord) && 
              CLLocationCoordinate2DIsValid(destinationCoord) else {
            print("⚠️ Invalid coordinates for trip: \(trip.description)")
            displayFallbackInfo(for: trip)
            return
        }
        
        // Add annotations to map view
        addAnnotations(for: trip)
        
        // Calculate and display route
        calculateRoute(for: trip)
    }
    
    func clearMap() {
        mapView?.removeAnnotations(mapView?.annotations ?? [])
        mapView?.removeOverlays(mapView?.overlays ?? [])
    }
    
    func centerOnCurrentTrip() {
        guard let trip = currentTrip else { return }
        displayTrip(trip)
    }
    
    func showAllTrips(_ trips: [Trip]) {
        clearMap()
        
        var allCoordinates: [CLLocationCoordinate2D] = []
        
        for trip in trips where trip.status == .ongoing || trip.status == .scheduled {
            // Add annotations for origin and destination
            let originCoord = trip.origin.point.coordinate
            let destinationCoord = trip.destination.point.coordinate
            
            addAnnotation(
                coordinate: originCoord,
                title: "\(trip.description) - Start",
                subtitle: trip.origin.address
            )
            
            addAnnotation(
                coordinate: destinationCoord,
                title: "\(trip.description) - End", 
                subtitle: trip.destination.address
            )
            
            allCoordinates.append(originCoord)
            allCoordinates.append(destinationCoord)
        }
        
        if !allCoordinates.isEmpty {
            let region = regionForCoordinates(allCoordinates)
            mapView?.setRegion(region, animated: true)
        }
    }
    
    // MARK: - Private Methods
    
    private func addAnnotations(for trip: Trip) {
        // Origin annotation
        let originAnnotation = MKPointAnnotation()
        originAnnotation.coordinate = trip.origin.point.coordinate
        originAnnotation.title = "Origin"
        originAnnotation.subtitle = trip.origin.address
        mapView?.addAnnotation(originAnnotation)
        
        // Destination annotation
        let destinationAnnotation = MKPointAnnotation()
        destinationAnnotation.coordinate = trip.destination.point.coordinate
        destinationAnnotation.title = "Destination"
        destinationAnnotation.subtitle = trip.destination.address
        mapView?.addAnnotation(destinationAnnotation)
        
        // Stop annotations
        for (index, stop) in trip.stops.enumerated() {
            if let stopCoordinate = stop.coordinate {
                let stopAnnotation = MKPointAnnotation()
                stopAnnotation.coordinate = stopCoordinate
                stopAnnotation.title = "Stop \(index + 1)"
                stopAnnotation.subtitle = "Intermediate stop"
                mapView?.addAnnotation(stopAnnotation)
            }
        }
    }
    
    private func addAnnotation(coordinate: CLLocationCoordinate2D, title: String, subtitle: String) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = title
        annotation.subtitle = subtitle
        mapView?.addAnnotation(annotation)
    }
    
    private func calculateRoute(for trip: Trip) {
        Task {
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: trip.origin.point.coordinate))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: trip.destination.point.coordinate))
            request.requestsAlternateRoutes = false
            request.transportType = .automobile
            
            let directions = MKDirections(request: request)
            
            do {
                let response = try await directions.calculate()
                if let route = response.routes.first {
                    await displayRoute(with: route.polyline, for: trip)
                } else {
                    await displayAnnotationsOnly(for: trip)
                }
            } catch {
                print("Failed to calculate route: \(error.localizedDescription)")
                await displayAnnotationsOnly(for: trip)
            }
        }
    }
    
    private func displayRoute(with polyline: MKPolyline, for trip: Trip) async {
        // Add the route overlay to the map
        mapView?.addOverlay(polyline)
        
        // Set the region to show the entire route
        let coordinates = [trip.origin.point.coordinate, trip.destination.point.coordinate] + trip.stops.compactMap { $0.coordinate }
        let region = regionForCoordinates(coordinates)
        mapView?.setRegion(region, animated: true)
        
        print("✅ Successfully displayed route for trip: \(trip.description)")
    }
    
    private func displayAnnotationsOnly(for trip: Trip) async {
        let coordinates = [trip.origin.point.coordinate, trip.destination.point.coordinate] + trip.stops.compactMap { $0.coordinate }
        let region = regionForCoordinates(coordinates)
        mapView?.setRegion(region, animated: true)
    }
    
    private func displayFallbackInfo(for trip: Trip) {
        // For trips with invalid coordinates, show a default region
        let region = defaultRegion()
        mapView?.setRegion(region, animated: true)
    }
    
    private func regionForCoordinates(_ coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        guard !coordinates.isEmpty else {
            return defaultRegion()
        }
        
        let validCoordinates = coordinates.filter { CLLocationCoordinate2DIsValid($0) }
        guard !validCoordinates.isEmpty else {
            return defaultRegion()
        }
        
        let minLat = validCoordinates.map { $0.latitude }.min()!
        let maxLat = validCoordinates.map { $0.latitude }.max()!
        let minLon = validCoordinates.map { $0.longitude }.min()!
        let maxLon = validCoordinates.map { $0.longitude }.max()!
        
        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        let center = CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon)
        
        let latDelta = max(maxLat - minLat, 0.01) * 1.3 // Add 30% padding
        let lonDelta = max(maxLon - minLon, 0.01) * 1.3 // Add 30% padding
        
        return MKCoordinateRegion(center: center, 
                                span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta))
    }
    
    private func defaultRegion() -> MKCoordinateRegion {
        // Default to San Francisco area - you can change this to your app's default location
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            latitudinalMeters: 10000,
            longitudinalMeters: 10000
        )
    }
}

// MARK: - MKMapViewDelegate
extension CarPlayMapManager: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = .systemBlue
            renderer.lineWidth = 3.0
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation { return nil }
        
        let identifier = "TripAnnotation"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        
        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
        } else {
            annotationView?.annotation = annotation
        }
        
        // Customize based on annotation title
        if let markerView = annotationView as? MKMarkerAnnotationView {
            if annotation.title == "Origin" {
                markerView.markerTintColor = .systemGreen
                markerView.glyphImage = UIImage(systemName: "car.fill")
            } else if annotation.title == "Destination" {
                markerView.markerTintColor = .systemRed
                markerView.glyphImage = UIImage(systemName: "flag.fill")
            } else {
                markerView.markerTintColor = .systemBlue
                markerView.glyphImage = UIImage(systemName: "mappin.circle.fill")
            }
        }
        
        return annotationView
    }
}
