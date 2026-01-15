//
//  CarPlayTripDetailManager.swift
//  SeatCodeTest
//
//   Created by Angel Docampo on 04/01/2026.
//

internal import CarPlay
import UIKit
import MapKit
import CoreLocation

@MainActor
class CarPlayTripDetailManager {
    
    let trip: Trip
    let viewModel: TripManagerViewModel
    weak var interfaceController: CPInterfaceController?
    
    init(trip: Trip, viewModel: TripManagerViewModel, interfaceController: CPInterfaceController?) {
        self.trip = trip
        self.viewModel = viewModel
        self.interfaceController = interfaceController
    }
    
    func createDetailTemplate() -> CPListTemplate {
        let detailTemplate = CPListTemplate(title: trip.description, sections: [])
        
        let tripInfoSection = createTripInfoSection()
        let routeSection = createRouteSection()
        let stopsSection = createStopsSection()
        
        var sections = [tripInfoSection, routeSection]
        
        if !stopsSection.items.isEmpty {
            sections.append(stopsSection)
        }
        
        detailTemplate.updateSections(sections)
        
        // Add action buttons
//        let showOnMapButton = CPBarButton(title: "Show on Map") { [weak self] _ in
//            self?.showTripOnMap()
//        }
        
//        detailTemplate.trailingNavigationBarButtons = [showOnMapButton]
        
        return detailTemplate
    }
    
    private func createTripInfoSection() -> CPListSection {
        let items = [
            CPListItem(text: "Driver", detailText: trip.driverName),
            CPListItem(text: "Status", detailText: trip.statusDisplayTextForCarPlay),
            CPListItem(text: "Start Time", detailText: trip.formattedStartTimeForCarPlay),
            CPListItem(text: "Duration", detailText: trip.formattedDurationForCarPlay),
            CPListItem(text: "Origin", detailText: trip.origin.address),
            CPListItem(text: "Destination", detailText: trip.destination.address)
        ]
        
        return CPListSection(items: items, header: "Trip Information", sectionIndexTitle: nil)
    }
    
    private func createRouteSection() -> CPListSection {
        let routeItem = CPListItem(
            text: "View Route",
            detailText: "Show complete trip route on map",
            image: UIImage(systemName: "map.fill")
        )
        
        routeItem.handler = { [weak self] _, completion in
            self?.showRouteOnMap()
            completion()
        }
        
        return CPListSection(items: [routeItem], header: "Route", sectionIndexTitle: nil)
    }
    
    private func createStopsSection() -> CPListSection {
        let stopItems = trip.stops.enumerated().map { index, stop in
            let item = CPListItem(
                text: "Stop \(index + 1)",
                detailText: "Tap for details",
                image: UIImage(systemName: "mappin.circle.fill")
            )
            
            item.handler = { [weak self] _, completion in
                self?.showStopDetail(stopId: index + 1)
                completion()
            }
            
            return item
        }
        
        return CPListSection(items: stopItems, header: "Stops (\(trip.stops.count))", sectionIndexTitle: nil)
    }
    
    private func showTripOnMap() {
        print("🗺️ showTripOnMap called")
        
        // Check template hierarchy depth before proceeding
        if let templates = interfaceController?.templates, templates.count >= 4 {
            print("Template hierarchy limit approaching, showing map fallback")
            showMapFallback()
            return
        }
        
        // Debug: Print trip coordinates to verify they exist
        let originCoord = trip.origin.point.coordinate
        let destCoord = trip.destination.point.coordinate
        print("Origin: \(originCoord.latitude), \(originCoord.longitude)")
        print("Destination: \(destCoord.latitude), \(destCoord.longitude)")
        
        // Check if coordinates are valid
        guard CLLocationCoordinate2DIsValid(originCoord) && CLLocationCoordinate2DIsValid(destCoord) else {
            print("❌ Invalid coordinates, showing fallback information")
            showMapFallback()
            return
        }
        
        let mapTemplate = CPMapTemplate()
        
        // Create navigation button
        let destinationMapItem = MKMapItem(placemark: MKPlacemark(coordinate: destCoord))
        destinationMapItem.name = trip.destination.address
        
        let navigationButton = CPMapButton { [weak destinationMapItem] _ in
            print("🧭 Navigation button tapped")
            destinationMapItem?.openInMaps(launchOptions: [
                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving,
                MKLaunchOptionsShowsTrafficKey: true
            ])
        }
        
        if let navImage = UIImage(systemName: "location.fill") {
            navigationButton.image = navImage
        }
        
        mapTemplate.mapButtons = [navigationButton]
        
        // Add back button
        let backButton = CPBarButton(title: "Back") { [weak self] _ in
            print("⬅️ Map back button tapped")
            self?.interfaceController?.popTemplate(animated: true, completion: nil)
        }
        mapTemplate.leadingNavigationBarButtons = [backButton]
        
        // Add info button for trip details (now uses alert instead of pushing template)
        let infoButton = CPBarButton(title: "Info") { [weak self] _ in
            print("ℹ️ Map info button tapped")
            self?.showTripInfoFromMap()
        }
        mapTemplate.trailingNavigationBarButtons = [infoButton]
        
        print("📱 Pushing map template...")
        interfaceController?.pushTemplate(mapTemplate, animated: true) { success, error in
            if success {
                print("✅ Map template pushed successfully")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    print("🖐️ Enabling map panning")
                    mapTemplate.showPanningInterface(animated: true)
                }
            } else {
                print("❌ Failed to push map template: \(String(describing: error))")
                // Show fallback if map template fails
                DispatchQueue.main.async { [weak self] in
                    self?.showMapFallback()
                }
            }
        }
    }
    
    private func showTripInfoFromMap() {
        // Instead of pushing another template, show a CarPlay-friendly alert
        // CarPlay has strict hierarchy limits, so we avoid pushing more templates
        let alert = CPAlertTemplate(titleVariants: ["Trip Info"], actions: [
            CPAlertAction(title: "From: \(trip.origin.address)", style: .default) { _ in },
            CPAlertAction(title: "To: \(trip.destination.address)", style: .default) { _ in },
            CPAlertAction(title: "Driver: \(trip.driverName)", style: .default) { _ in },
            CPAlertAction(title: "Navigate", style: .default) { [weak self] _ in
                self?.startNavigation()
            },
            CPAlertAction(title: "Close", style: .cancel) { _ in }
        ])
        
        interfaceController?.presentTemplate(alert, animated: true, completion: nil)
    }
    
    private func showMapFallback() {
        print("📋 Showing map fallback information template")
        let fallbackTemplate = CPInformationTemplate(
            title: "Trip Route",
            layout: .leading,
            items: [
                CPInformationItem(title: "From", detail: trip.origin.address),
                CPInformationItem(title: "To", detail: trip.destination.address),
                CPInformationItem(title: "Driver", detail: trip.driverName),
                CPInformationItem(title: "Status", detail: trip.statusDisplayTextForCarPlay),
                CPInformationItem(title: "Stops", detail: "\(trip.stops.count) intermediate stops")
            ],
            actions: [
                CPTextButton(title: "Navigate", textStyle: .confirm) { [weak self] _ in
                    self?.startNavigation()
                },
                CPTextButton(title: "Back", textStyle: .normal) { [weak self] _ in
                    self?.interfaceController?.popTemplate(animated: true, completion: nil)
                }
            ]
        )
        
        interfaceController?.pushTemplate(fallbackTemplate, animated: true, completion: nil)
    }
    
    private func startNavigation() {
        print("🧭 Starting navigation to destination")
        let destinationItem = MKMapItem(placemark: MKPlacemark(coordinate: trip.destination.point.coordinate))
        destinationItem.name = trip.destination.address
        
        destinationItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving,
            MKLaunchOptionsShowsTrafficKey: true
        ])
    }
    
    private func showRouteOnMap() {
        showTripOnMap()
    }
    
    private func showStopDetail(stopId: Int) {
        // Check template hierarchy depth before proceeding
        if let templates = interfaceController?.templates, templates.count >= 4 {
            print("Template hierarchy limit approaching, showing stop info via alert")
            showStopInfoAlert(stopId: stopId)
            return
        }
        
        Task {
            await viewModel.refreshStops()
            
            let tripStopDetails = viewModel.stopDetails.filter { $0.tripId == trip.id }
            
            let stopDetailTemplate: CPListTemplate
            
            if let stopDetail = tripStopDetails.first(where: { _ in tripStopDetails.count >= stopId }) {
                stopDetailTemplate = createStopDetailTemplate(stopDetail: stopDetail, stopNumber: stopId)
            } else {
                stopDetailTemplate = createEmptyStopDetailTemplate(stopNumber: stopId)
            }
            
            interfaceController?.pushTemplate(stopDetailTemplate, animated: true, completion: nil)
        }
    }
    
    private func showStopInfoAlert(stopId: Int) {
        Task {
            await viewModel.refreshStops()
            
            let tripStopDetails = viewModel.stopDetails.filter { $0.tripId == trip.id }
            
            var actions: [CPAlertAction] = []
            
            if let stopDetail = tripStopDetails.first(where: { _ in tripStopDetails.count >= stopId }) {
                actions = [
                    CPAlertAction(title: "Stop \(stopId)", style: .default) { _ in },
                    CPAlertAction(title: "Passenger: \(stopDetail.userName)", style: .default) { _ in },
                    CPAlertAction(title: "Address: \(stopDetail.address)", style: .default) { _ in },
                    CPAlertAction(title: "Close", style: .cancel) { _ in }
                ]
            } else {
                actions = [
                    CPAlertAction(title: "Stop \(stopId)", style: .default) { _ in },
                    CPAlertAction(title: "No details available", style: .default) { _ in },
                    CPAlertAction(title: "Close", style: .cancel) { _ in }
                ]
            }
            
            let alert = CPAlertTemplate(titleVariants: ["Stop Details"], actions: actions)
            interfaceController?.presentTemplate(alert, animated: true, completion: nil)
        }
    }
    
    internal func createStopDetailTemplate(stopDetail: StopDetail, stopNumber: Int) -> CPListTemplate {
        let template = CPListTemplate(title: "Stop \(stopNumber)", sections: [])
        
        let items = [
            CPListItem(text: "Passenger", detailText: stopDetail.userName),
            CPListItem(text: "Address", detailText: stopDetail.address),
            CPListItem(text: "Stop Time", detailText: stopDetail.formattedTimeForCarPlay),
            CPListItem(text: "Price", detailText: stopDetail.formattedPriceForCarPlay),
            CPListItem(text: "Payment Status", detailText: stopDetail.paymentStatusForCarPlay)
        ]
        
        let section = CPListSection(items: items, header: "Stop Details", sectionIndexTitle: nil)
        template.updateSections([section])
        
        return template
    }
    
    internal func createEmptyStopDetailTemplate(stopNumber: Int) -> CPListTemplate {
        let template = CPListTemplate(title: "Stop \(stopNumber)", sections: [])
        
        let emptyItem = CPListItem(
            text: "No details available",
            detailText: "Stop information is not available at this time"
        )
        
        let section = CPListSection(items: [emptyItem], header: nil, sectionIndexTitle: nil)
        template.updateSections([section])
        
        return template
    }
}
