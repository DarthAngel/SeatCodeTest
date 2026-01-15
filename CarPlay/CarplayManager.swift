//
//  CarPlayManager.swift
//  SeatCodeTest
//
//  Created by Angel Docampo on 04/01/2026.
//

internal import CarPlay
import UIKit
import MapKit
import CoreLocation

@MainActor
class CarPlayManager: NSObject {
    
    var interfaceController: CPInterfaceController?
    private let tripViewModel = TripManagerViewModel()
    private var currentSelectedTrip: Trip?
    private var tabBarTemplate: CPTabBarTemplate?
    private var mapManager: CarPlayMapManager?
    
    func createRootTabBarTemplate() -> CPTabBarTemplate {
        let tripsListTemplate = createTripsListTemplate()
        let mapListTemplate = createMapListTemplate()
        
        let tabTemplate = CPTabBarTemplate(templates: [tripsListTemplate, mapListTemplate])
        self.tabBarTemplate = tabTemplate
        
        Task {
            await refreshTripsData()
        }
        
        return tabTemplate
    }
    
    // MARK: - Tab Bar Templates
    
    private func createTripsListTemplate() -> CPListTemplate {
        let tripsTemplate = CPListTemplate(title: "Available Trips", sections: [])
        tripsTemplate.tabTitle = "Trips"
        tripsTemplate.tabImage = UIImage(systemName: "car.fill")
        
        // Add refresh button
        let refreshButton = CPBarButton(title: "Refresh") { [weak self] _ in
            Task {
                await self?.refreshTripsData()
            }
        }
        tripsTemplate.trailingNavigationBarButtons = [refreshButton]
        
        return tripsTemplate
    }
    
    private func createMapListTemplate() -> CPListTemplate {
        let mapListTemplate = CPListTemplate(title: "Map", sections: [])
        mapListTemplate.tabTitle = "Map"
        mapListTemplate.tabImage = UIImage(systemName: "map.fill")
        
        // Create map access items
        let currentTripMapItem = CPListItem(
            text: "View Current Trip",
            detailText: "See selected trip on map",
            image: UIImage(systemName: "location.fill")
        )
        currentTripMapItem.handler = { [weak self] _, completion in
            self?.showMapTemplate()
            completion()
        }
        
        let allTripsMapItem = CPListItem(
            text: "View All Trips",
            detailText: "See all active and scheduled trips",
            image: UIImage(systemName: "map.circle.fill")
        )
        allTripsMapItem.handler = { [weak self] _, completion in
            self?.showMapTemplateWithAllTrips()
            completion()
        }
        
        let mapSection = CPListSection(items: [currentTripMapItem, allTripsMapItem])
        mapListTemplate.updateSections([mapSection])
        
        return mapListTemplate
    }
    private func createMapTemplate() -> CPMapTemplate {
        let mapTemplate = CPMapTemplate()
        
        // Initialize map manager
        mapManager = CarPlayMapManager(mapTemplate: mapTemplate)
        
        // Add map controls
        setupMapControls(for: mapTemplate)
        
        return mapTemplate
    }
    
    private func showMapTemplate() {
        let mapTemplate = createMapTemplate()
        
        // Show current selected trip if available
        if let selectedTrip = currentSelectedTrip {
            mapManager?.displayTrip(selectedTrip)
        }
        
        interfaceController?.pushTemplate(mapTemplate, animated: true) { success, error in
            if let error = error {
                print("Error showing map: \(error)")
            }
        }
    }
    
    private func showMapTemplateWithAllTrips() {
        let mapTemplate = createMapTemplate()
        
        // Show all relevant trips
        let relevantTrips = tripViewModel.trips.filter { $0.status == .ongoing || $0.status == .scheduled }
        mapManager?.showAllTrips(relevantTrips)
        
        interfaceController?.pushTemplate(mapTemplate, animated: true) { success, error in
            if let error = error {
                print("Error showing map: \(error)")
            }
        }
    }
    
    private func setupMapControls(for mapTemplate: CPMapTemplate) {
        var mapButtons: [CPMapButton] = []
        
        // Navigation button - shows when a trip is selected
        let navigationButton = CPMapButton { [weak self] _ in
            self?.startNavigationToSelectedTrip()
        }
        navigationButton.image = UIImage(systemName: "location.fill") ?? UIImage()
        mapButtons.append(navigationButton)
        
        // Center on trip button
        let centerButton = CPMapButton { [weak self] _ in
            self?.centerMapOnSelectedTrip()
        }
        centerButton.image = UIImage(systemName: "scope") ?? UIImage()
        mapButtons.append(centerButton)
        
        // Toggle traffic button
        let trafficButton = CPMapButton { [weak self] _ in
            self?.toggleTrafficOnMap(mapTemplate)
        }
        trafficButton.image = UIImage(systemName: "car.2.fill") ?? UIImage()
        mapButtons.append(trafficButton)
        
        mapTemplate.mapButtons = mapButtons
        
        // Add toolbar buttons
        let tripInfoButton = CPBarButton(title: "Trip Info") { [weak self] _ in
            self?.showSelectedTripInfo()
        }
        
        let allTripsButton = CPBarButton(title: "Show All") { [weak self] _ in
            self?.showAllTripsOnMap()
        }
        
        mapTemplate.leadingNavigationBarButtons = [tripInfoButton]
        mapTemplate.trailingNavigationBarButtons = [allTripsButton]
    }
    
    private func refreshTripsData() async {
        await tripViewModel.refreshTrips()
        updateTripsListTemplate()
        
        // If there's no selected trip, select the first available trip
        if currentSelectedTrip == nil,
           let firstTrip = tripViewModel.trips.first(where: { $0.status == .ongoing || $0.status == .scheduled }) {
            currentSelectedTrip = firstTrip
        }
    }
    
    private func updateTripsListTemplate() {
        guard let tabTemplate = tabBarTemplate,
              let listTemplate = tabTemplate.templates.first as? CPListTemplate else {
            return
        }
        
        let activeTripsSection = createActiveTripsSection()
        let scheduledTripsSection = createScheduledTripsSection()
        let completedTripsSection = createCompletedTripsSection()
        
        var sections: [CPListSection] = []
        
        if !activeTripsSection.items.isEmpty {
            sections.append(activeTripsSection)
        }
        
        if !scheduledTripsSection.items.isEmpty {
            sections.append(scheduledTripsSection)
        }
        
        if !completedTripsSection.items.isEmpty {
            sections.append(completedTripsSection)
        }
        
        if sections.isEmpty {
            let emptySection = CPListSection(items: [
                CPListItem(text: "No trips available", detailText: "Check back later for new trips")
            ])
            sections.append(emptySection)
        }
        
        listTemplate.updateSections(sections)
    }
    
    private func createActiveTripsSection() -> CPListSection {
        let activeTrips = tripViewModel.trips.filter { $0.status == .ongoing }
        
        let items = activeTrips.map { trip in
            let startTimeFormatted: String = {
                let formatter = ISO8601DateFormatter()
                guard let date = formatter.date(from: trip.startTime) else { return trip.startTime }
                let displayFormatter = DateFormatter()
                displayFormatter.timeStyle = .short
                return displayFormatter.string(from: date)
            }()
            
            let item = CPListItem(
                text: trip.description,
                detailText: "\(trip.driverName) • \(startTimeFormatted) • In Progress",
                image: UIImage(systemName: "car.fill") ?? UIImage()
            )
            
            // Add selection indicator if this is the currently selected trip
            if let currentTrip = currentSelectedTrip, currentTrip.id == trip.id {
                item.accessoryType = .disclosureIndicator
            }
            
            item.handler = { [weak self] _, completion in
                self?.selectTrip(trip)
                completion()
            }
            
            return item
        }
        
        return CPListSection(items: items, header: "Active Trips", sectionIndexTitle: nil)
    }
    
    private func createScheduledTripsSection() -> CPListSection {
        let scheduledTrips = tripViewModel.trips.filter { $0.status == .scheduled }
        
        let items = scheduledTrips.map { trip in
            let startTimeFormatted: String = {
                let formatter = ISO8601DateFormatter()
                guard let date = formatter.date(from: trip.startTime) else { return trip.startTime }
                let displayFormatter = DateFormatter()
                displayFormatter.timeStyle = .short
                return displayFormatter.string(from: date)
            }()
            
            let item = CPListItem(
                text: trip.description,
                detailText: "\(trip.driverName) • \(startTimeFormatted) • Scheduled",
                image: UIImage(systemName: "clock.fill") ?? UIImage()
            )
            
            // Add selection indicator if this is the currently selected trip
            if let currentTrip = currentSelectedTrip, currentTrip.id == trip.id {
                item.accessoryType = .disclosureIndicator
            }
            
            item.handler = { [weak self] _, completion in
                self?.selectTrip(trip)
                completion()
            }
            
            return item
        }
        
        return CPListSection(items: items, header: "Scheduled Trips", sectionIndexTitle: nil)
    }
    
    private func createCompletedTripsSection() -> CPListSection {
        let completedTrips = tripViewModel.trips.filter { $0.status == .finalized }.prefix(5) // Show only last 5 completed trips
        
        let items = completedTrips.map { trip in
            let startTimeFormatted: String = {
                let formatter = ISO8601DateFormatter()
                guard let date = formatter.date(from: trip.startTime) else { return trip.startTime }
                let displayFormatter = DateFormatter()
                displayFormatter.dateStyle = .short
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
            
            let item = CPListItem(
                text: trip.description,
                detailText: "\(startTimeFormatted) • \(durationFormatted)",
                image: UIImage(systemName: "checkmark.circle.fill") ?? UIImage()
            )
            
            // Add selection indicator if this is the currently selected trip
            if let currentTrip = currentSelectedTrip, currentTrip.id == trip.id {
                item.accessoryType = .disclosureIndicator
            }
            
            item.handler = { [weak self] _, completion in
                self?.selectTrip(trip)
                completion()
            }
            
            return item
        }
        
        return CPListSection(items: items, header: "Recent Completed", sectionIndexTitle: nil)
    }
    
    private func selectTrip(_ trip: Trip) {
        print("Selected trip: \(trip.description)")
        
        // Update the currently selected trip
        currentSelectedTrip = trip
        
        // Refresh the list to show selection indicators
        updateTripsListTemplate()
        
        // Note: Map will be updated when user navigates to map template
    }
    
    // MARK: - Map Actions
    
    private func startNavigationToSelectedTrip() {
        guard let selectedTrip = currentSelectedTrip else {
            print("No trip selected for navigation")
            return
        }
        
        let destinationItem = MKMapItem(placemark: MKPlacemark(coordinate: selectedTrip.destination.point.coordinate))
        destinationItem.name = selectedTrip.destination.address
        
        destinationItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving,
            MKLaunchOptionsShowsTrafficKey: true
        ])
    }
    
    private func centerMapOnSelectedTrip() {
        mapManager?.centerOnCurrentTrip()
    }
    
    private func toggleTrafficOnMap(_ mapTemplate: CPMapTemplate) {
        // CarPlay automatically handles traffic display - this is just a placeholder
        // In a real implementation, you might want to show different information
        print("Traffic toggle requested")
    }
    
    private func showSelectedTripInfo() {
        guard let selectedTrip = currentSelectedTrip else {
            print("No trip selected")
            return
        }
        
        // Check if we're already at or near the template hierarchy limit
        // CarPlay typically allows 5 levels in the navigation stack
        if let templates = interfaceController?.templates, templates.count >= 4 {
            print("Template hierarchy limit approaching, showing alert instead")
            showTripInfoAlert(for: selectedTrip)
            return
        }
        
        let detailManager = CarPlayTripDetailManager(trip: selectedTrip, viewModel: tripViewModel, interfaceController: interfaceController)
        let detailTemplate = detailManager.createDetailTemplate()
        
        interfaceController?.pushTemplate(detailTemplate, animated: true) { success, error in
            if let error = error {
                print("Error showing trip details: \(error)")
                // Fallback to alert if template push fails
                DispatchQueue.main.async { [weak self] in
                    self?.showTripInfoAlert(for: selectedTrip)
                }
            } else if success {
                print("Successfully showed trip details")
            }
        }
    }
    
    private func showTripInfoAlert(for trip: Trip) {
        let alert = CPAlertTemplate(titleVariants: ["Trip Details"], actions: [
            CPAlertAction(title: trip.description, style: .default) { _ in },
            CPAlertAction(title: "Driver: \(trip.driverName)", style: .default) { _ in },
            CPAlertAction(title: "From: \(trip.origin.address)", style: .default) { _ in },
            CPAlertAction(title: "To: \(trip.destination.address)", style: .default) { _ in },
            CPAlertAction(title: "Navigate", style: .default) { [weak self] _ in
                self?.startNavigationToSelectedTrip()
            },
            CPAlertAction(title: "Close", style: .cancel) { _ in }
        ])
        
        interfaceController?.presentTemplate(alert, animated: true, completion: nil)
    }
    
    private func showAllTripsOnMap() {
        let relevantTrips = tripViewModel.trips.filter { $0.status == .ongoing || $0.status == .scheduled }
        mapManager?.showAllTrips(relevantTrips)
    }
}
