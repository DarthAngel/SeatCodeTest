//
//  TripManagerViewModel.swift
//  SeatCode
//
//  Created by Angel Docampo on 19/12/25.
//

import Foundation
import SwiftUI
import MapKit
import Polyline

@Observable
@MainActor
class TripManagerViewModel {
    var trips: [Trip] = []
    var selectedTrip: Trip?
    var selectedTripCoordinates = [CLLocationCoordinate2D]()
    var stopDetails: [StopDetail] = []
    var selectedStopDetail: StopDetail?
    var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 41.3851, longitude: 2.1734), // Barcelona center
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    var errorMessage: String? = nil
    var isLoading: Bool = false
    var showingContactForm = false
    var showingStopPopup = false
    
    let networkService = NetworkService()
 //   let contactService = ContactService()
    
    init() {
        // Load data when view model is created
        Task {
            await refreshTrips()
            await refreshStops()
        }
   
    }
    
    func refreshTrips() async {
        
            isLoading = true
            errorMessage = nil
            do {
                trips = try await networkService.loadTrips()
            } catch {
                errorMessage = "Failed to load trips: \(error.localizedDescription)"
            }
            
            isLoading = false
    }
    
    func refreshStops() async {
        
            isLoading = true
            errorMessage = nil
            do {
                stopDetails = try await networkService.loadStops()
            } catch {
                errorMessage = "Failed to load stops: \(error.localizedDescription)"
            }
            
            isLoading = false
    }
    
    func selectTrip(_ trip: Trip) {
        selectedTrip = trip
        
        // Center map on trip route
        let polyline = Polyline(encodedPolyline: trip.route)
        
        // Safely unwrap the optional locations array
        guard let locations = polyline.locations, !locations.isEmpty else {
            return
        }
        
        
        let minLat = locations.map { $0.coordinate.latitude }.min() ?? 0
        let maxLat = locations.map { $0.coordinate.latitude }.max() ?? 0
        let minLng = locations.map { $0.coordinate.longitude }.min() ?? 0
        let maxLng = locations.map { $0.coordinate.longitude }.max() ?? 0
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLng + maxLng) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.2, // Add some padding
            longitudeDelta: (maxLng - minLng) * 1.2
        )
        
        withAnimation(.easeInOut(duration: 1.0)) {
            mapRegion = MKCoordinateRegion(center: center, span: span)
        }
        
        selectedTripCoordinates = locations.map { $0.coordinate }
    }
    
    func selectStop(stopId: Int, from trip: Trip) {
        // Get stop details if available using the trip's numeric ID
        let tripStopDetails = stopDetails.filter( { $0.tripId == trip.id } )
        if tripStopDetails.count >= stopId { selectedStopDetail =  tripStopDetails[stopId-1]}
        else { selectedStopDetail = nil }
        showingStopPopup = true
    }
    
  
}


