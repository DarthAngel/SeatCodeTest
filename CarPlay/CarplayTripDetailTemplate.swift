//
//  CarPlayTripDetailTemplate.swift
//  SeatCodeTest
//
//  Created by Angel Docampo on 04/01/2026.
//

internal import CarPlay
import UIKit
import MapKit
import CoreLocation

@MainActor
class CarPlayTripDetailTemplate: NSObject, CPMapTemplateDelegate {
    
    let trip: Trip
    let viewModel: TripManagerViewModel
    weak var interfaceController: CPInterfaceController?
    
    init(trip: Trip, viewModel: TripManagerViewModel, interfaceController: CPInterfaceController?) {
        self.trip = trip
        self.viewModel = viewModel
        self.interfaceController = interfaceController
    }
    
    var template: CPListTemplate {
        createDetailTemplate()
    }
    
    private func createDetailTemplate() -> CPListTemplate {
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
        let showOnMapButton = CPBarButton(title: "Show on Map") { [weak self] _ in
            print("Show on Map button tapped")
            self?.showTripOnMap()
        }
        
        detailTemplate.trailingNavigationBarButtons = [showOnMapButton]
        
        return detailTemplate
    }
    
    private func createTripInfoSection() -> CPListSection {
        // Format values inline
        let startTimeFormatted: String = {
            let formatter = ISO8601DateFormatter()
            guard let date = formatter.date(from: trip.startTime) else { return trip.startTime }
            let displayFormatter = DateFormatter()
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }()
        
        let durationFormatted: String = {
            let formatter = ISO8601DateFormatter()
            guard let start = formatter.date(from: trip.startTime),
                  let end = formatter.date(from: trip.endTime) else { return "Unknown" }
            let interval = end.timeIntervalSince(start)
            let hours = Int(interval) / 3600
            let minutes = Int(interval) % 3600 / 60
            return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
        }()
        
        let statusText: String = {
            switch trip.status {
            case .ongoing: return "In Progress"
            case .scheduled: return "Scheduled"
            case .finalized: return "Completed"
            case .cancelled: return "Cancelled"
            }
        }()
        
        let items = [
            CPListItem(text: "Driver", detailText: trip.driverName),
            CPListItem(text: "Status", detailText: statusText),
            CPListItem(text: "Start Time", detailText: startTimeFormatted),
            CPListItem(text: "Duration", detailText: durationFormatted),
            CPListItem(text: "Origin", detailText: trip.origin.address),
            CPListItem(text: "Destination", detailText: trip.destination.address)
        ]
        
        return CPListSection(items: items, header: "Trip Information", sectionIndexTitle: nil as String?)
    }
    
    private func createRouteSection() -> CPListSection {
        let routeItem = CPListItem(
            text: "View Route",
            detailText: "Show complete trip route on map",
            image: UIImage(systemName: "map.fill")
        )
        
        routeItem.handler = { [weak self] _, completion in
            print("View Route item tapped")
            self?.showRouteOnMap()
            completion()
        }
        
        return CPListSection(items: [routeItem], header: "Route", sectionIndexTitle: nil as String?)
    }
    
    private func createStopsSection() -> CPListSection {
        let stopItems = trip.stops.enumerated().map { index, stop in
            let item = CPListItem(
                text: "Stop \(index + 1)",
                detailText: "Tap for details",
                image: UIImage(systemName: "mappin.circle.fill")
            )
            
            item.handler = { [weak self] _, completion in
                print("Stop \(index + 1) tapped")
                self?.showStopDetail(stopId: index + 1)
                completion()
            }
            
            return item
        }
        
        return CPListSection(items: stopItems, header: "Stops (\(trip.stops.count))", sectionIndexTitle: nil as String?)
    }
    
    private func showTripOnMap() {
        print("showTripOnMap called")
        
        guard let interfaceController = interfaceController else {
            print("Error: interfaceController is nil")
            return
        }
        
        print("Interface controller available, creating map template")
        
        // Create a map template focused on this trip
        let mapTemplate = CPMapTemplate()
        
        // Set up the map delegate
        mapTemplate.mapDelegate = self
        
        // Add navigation and route buttons
        var trailingButtons: [CPBarButton] = []
        
        // Route button
        let routeButton = CPBarButton(title: "Route") { [weak self] _ in
            self?.showRouteOptions()
        }
        trailingButtons.append(routeButton)
        
        // Navigate button
        let navigateButton = CPBarButton(title: "Navigate") { [weak self] _ in
            self?.startNavigation()
        }
        trailingButtons.append(navigateButton)
        
        mapTemplate.trailingNavigationBarButtons = trailingButtons
        
        // Add map buttons for quick actions
        let centerButton = CPMapButton { [weak self] _ in
            // Center on trip route
            print("Center button tapped")
        }
        if let centerImage = UIImage(systemName: "scope") {
            centerButton.image = centerImage
        }
        
        let zoomButton = CPMapButton { [weak self] _ in
            // Zoom to fit trip
            print("Zoom button tapped")
        }
        if let zoomImage = UIImage(systemName: "plus.magnifyingglass") {
            zoomButton.image = zoomImage
        }
        
        mapTemplate.mapButtons = [centerButton, zoomButton]
        
        // Push the map template
        print("Pushing map template")
        interfaceController.pushTemplate(mapTemplate, animated: true) { (success, error) in
            if let error = error {
                print("Error pushing map template: \(error)")
            } else if success {
                print("Successfully presented trip map")
            } else {
                print("Failed to push map template without specific error")
            }
        }
    }
    
    private func showRouteOptions() {
        guard let interfaceController = interfaceController else {
            print("Error: interfaceController is nil")
            return
        }
        
        // Create route options for the entire trip
        let routeAction = CPAlertAction(title: "Get Directions", style: .default) { [weak self] _ in
            self?.startNavigation()
        }
        
        let showOverviewAction = CPAlertAction(title: "Show Route Overview", style: .default) { [weak self] _ in
            self?.showRouteOverview()
        }
        
        let cancelAction = CPAlertAction(title: "Cancel", style: .cancel) { _ in
            // Do nothing
        }
        
        let alert = CPActionSheetTemplate(
            title: "Route Options", 
            message: "Choose an option for this trip route", 
            actions: [routeAction, showOverviewAction, cancelAction]
        )
        
        interfaceController.presentTemplate(alert, animated: true) { (success, error) in
            if let error = error {
                print("Error showing route options: \(error)")
            }
        }
    }
    
    private func startNavigation() {
        // Open in Maps app for navigation to destination
        let destinationMapItem = MKMapItem(placemark: MKPlacemark(coordinate: trip.destination.point.coordinate))
        destinationMapItem.name = trip.destination.address
        
        let originMapItem = MKMapItem(placemark: MKPlacemark(coordinate: trip.origin.point.coordinate))
        originMapItem.name = trip.origin.address
        
        MKMapItem.openMaps(with: [originMapItem, destinationMapItem], launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving,
            MKLaunchOptionsShowsTrafficKey: true
        ])
    }
    
    private func showRouteOverview() {
        guard let interfaceController = interfaceController else {
            print("Error: interfaceController is nil")
            return
        }
        
        // Create a list template showing the route breakdown
        let routeTemplate = CPListTemplate(title: "Route Overview", sections: [])
        
        var routeItems: [CPListItem] = []
        
        // Origin
        let originItem = CPListItem(
            text: "Start: \(trip.origin.address)",
            detailText: "Trip origin",
            image: UIImage(systemName: "location.circle.fill")
        )
        routeItems.append(originItem)
        
        // Stops
        for (index, stop) in trip.stops.enumerated() {
            let stopItem = CPListItem(
                text: "Stop \(index + 1)",
                detailText: "Intermediate stop",
                image: UIImage(systemName: "mappin.circle.fill")
            )
            
            stopItem.handler = { [weak self] _, completion in
                self?.showStopDetail(stopId: index + 1)
                completion()
            }
            
            routeItems.append(stopItem)
        }
        
        // Destination
        let destinationItem = CPListItem(
            text: "End: \(trip.destination.address)",
            detailText: "Trip destination",
            image: UIImage(systemName: "flag.fill")
        )
        routeItems.append(destinationItem)
        
        let routeSection = CPListSection(items: routeItems, header: "Route Sequence", sectionIndexTitle: nil)
        routeTemplate.updateSections([routeSection])
        
        interfaceController.pushTemplate(routeTemplate, animated: true) { (success, error) in
            if let error = error {
                print("Error pushing route overview: \(error)")
            }
        }
    }
    

    
    private func showRouteOnMap() {
        showTripOnMap()
    }
    
    private func showStopDetail(stopId: Int) {
        print("showStopDetail called for stop \(stopId)")
        
        guard let interfaceController = interfaceController else {
            print("Error: interfaceController is nil")
            return
        }
        
        // Ensure we have a valid stop index
        guard stopId > 0 && stopId <= trip.stops.count else {
            print("Error: Invalid stop ID \(stopId), trip has \(trip.stops.count) stops")
            showInvalidStopError()
            return
        }
        
        print("Valid stop ID, refreshing stop details")
        
        // Get stop details and show them
        Task {
            await viewModel.refreshStops()
            
            let tripStopDetails = viewModel.stopDetails.filter { $0.tripId == trip.id }
            print("Found \(tripStopDetails.count) stop details for trip \(trip.id)")
            
            let stopDetailTemplate: CPListTemplate
            
            // Find the specific stop detail by matching the stop order
            if tripStopDetails.count >= stopId,
               let stopDetail = tripStopDetails[safe: stopId - 1] {
                print("Creating stop detail template with data")
                stopDetailTemplate = createStopDetailTemplate(stopDetail: stopDetail, stopNumber: stopId)
            } else {
                print("Creating empty stop detail template")
                stopDetailTemplate = createEmptyStopDetailTemplate(stopNumber: stopId)
            }
            
            interfaceController.pushTemplate(stopDetailTemplate, animated: true) { (success, error) in
                if let error = error {
                    print("Error pushing stop detail template: \(error)")
                } else if success {
                    print("Successfully showed stop \(stopId) details")
                } else {
                    print("Failed to push stop detail template without specific error")
                }
            }
        }
    }
    
    private func showInvalidStopError() {
        guard let interfaceController = interfaceController else {
            print("Error: interfaceController is nil when showing invalid stop error")
            return
        }
        
        let errorTemplate = CPAlertTemplate(
            titleVariants: ["Invalid Stop"],
            actions: [
                CPAlertAction(title: "OK", style: .default) { _ in
                    // Do nothing, just dismiss
                }
            ]
        )
        
        interfaceController.presentTemplate(errorTemplate, animated: true) { (success, error) in
            if let error = error {
                print("Error showing invalid stop error: \(error)")
            }
        }
    }
    
    private func createStopDetailTemplate(stopDetail: StopDetail, stopNumber: Int) -> CPListTemplate {
        let template = CPListTemplate(title: "Stop \(stopNumber)", sections: [])
        
        // Format values inline
        let timeFormatted: String = {
            let formatter = ISO8601DateFormatter()
            guard let date = formatter.date(from: stopDetail.stopTime) else { return stopDetail.stopTime }
            let displayFormatter = DateFormatter()
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }()
        
        let priceFormatted = String(format: "%.2f€", stopDetail.price)
        let paymentStatus = stopDetail.paid ? "Paid" : "Pending"
        
        let items = [
            CPListItem(text: "Passenger", detailText: stopDetail.userName),
            CPListItem(text: "Address", detailText: stopDetail.address),
            CPListItem(text: "Stop Time", detailText: timeFormatted),
            CPListItem(text: "Price", detailText: priceFormatted),
            CPListItem(text: "Payment Status", detailText: paymentStatus)
        ]
        
        let section = CPListSection(items: items, header: "Stop Details", sectionIndexTitle: nil as String?)
        template.updateSections([section])
        
        return template
    }
    
    private func createEmptyStopDetailTemplate(stopNumber: Int) -> CPListTemplate {
        let template = CPListTemplate(title: "Stop \(stopNumber)", sections: [])
        
        let emptyItem = CPListItem(
            text: "No details available",
            detailText: "Stop information is not available at this time"
        )
        
        let section = CPListSection(items: [emptyItem], header: nil as String?, sectionIndexTitle: nil as String?)
        template.updateSections([section])
        
        return template
    }
    
    private func regionToFit(coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        guard !coordinates.isEmpty else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 41.3851, longitude: 2.1734),
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
        }
        
        let minLat = coordinates.map { $0.latitude }.min() ?? 0
        let maxLat = coordinates.map { $0.latitude }.max() ?? 0
        let minLng = coordinates.map { $0.longitude }.min() ?? 0
        let maxLng = coordinates.map { $0.longitude }.max() ?? 0
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLng + maxLng) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.3, 0.01),
            longitudeDelta: max((maxLng - minLng) * 1.3, 0.01)
        )
        
        return MKCoordinateRegion(center: center, span: span)
    }
    
    // MARK: - Map Configuration
    
    private func configureMapTemplate(_ mapTemplate: CPMapTemplate, with mapItems: [MKMapItem], region: MKCoordinateRegion) {
        // The map view will be available after the template is presented
        // We need to use CPMapTemplate delegate methods to configure it
    }
    
    // MARK: - CPMapTemplateDelegate
    
    func mapTemplate(_ mapTemplate: CPMapTemplate, selectedPreviewFor trip: CPTrip, using routeChoice: CPRouteChoice) {
        // Handle route preview selection
    }
    
    func mapTemplate(_ mapTemplate: CPMapTemplate, startedTrip trip: CPTrip, using routeChoice: CPRouteChoice) {
        // Handle trip start if needed
    }
    
    func mapTemplate(_ mapTemplate: CPMapTemplate, displayStyleFor maneuver: CPManeuver) -> CPManeuverDisplayStyle {
        return .leadingSymbol
    }
    
    func mapTemplate(_ mapTemplate: CPMapTemplate, shouldUpdateNotificationFor maneuver: CPManeuver, with travelEstimates: CPTravelEstimates) -> Bool {
        return true
    }
    
    func mapTemplateDidEndNavigation(_ mapTemplate: CPMapTemplate) {
        // Handle navigation end
    }
    
    func mapTemplate(_ mapTemplate: CPMapTemplate, willShow panDirection: CPMapTemplate.PanDirection, for maneuver: CPManeuver) {
        // Handle pan direction display
    }
    
    func mapTemplate(_ mapTemplate: CPMapTemplate, panWith direction: CPMapTemplate.PanDirection) {
        // Handle map panning
    }
    
    func mapTemplate(_ mapTemplate: CPMapTemplate, didSelectPointOfInterest pointOfInterest: CPPointOfInterest) {
        // Handle POI selection - this would be called if POIs were set up
        print("POI selected: \(pointOfInterest.title ?? "Unknown")")
    }

}

// MARK: - Array Extension for Safe Access
private extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
