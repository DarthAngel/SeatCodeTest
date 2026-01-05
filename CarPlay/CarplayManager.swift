//
//  CarPlayManager.swift
//  SeatCodeTest
//
//  Created by Angel Docampo on 04/01/2026.
//

internal import CarPlay
import UIKit
import MapKit
import Combine
import CoreLocation

@MainActor
class CarPlayManager: NSObject {
    
    var interfaceController: CPInterfaceController?
    private let tripViewModel = TripManagerViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        setupBindings()
    }
    
    private func setupBindings() {
        // Observe changes in trips and update templates accordingly
        // Note: Since TripManagerViewModel uses @Observable, we'd need to adapt this
        // For now, we'll manually refresh when needed
    }
    
    func createRootTabBarTemplate() -> CPTabBarTemplate {
        let tripsTab = createTripsTab()
        let mapTab = createMapTab()
        let statusTab = createStatusTab()
        
        let tabBarTemplate = CPTabBarTemplate(templates: [tripsTab, mapTab, statusTab])
        return tabBarTemplate
    }
    
    // MARK: - Trips Tab
    
    private func createTripsTab() -> CPListTemplate {
        let tripsTemplate = CPListTemplate(title: "Trips", sections: [])
        tripsTemplate.tabSystemItem = .recents
        
        Task {
            await updateTripsTemplate(tripsTemplate)
        }
        
        return tripsTemplate
    }
    
    private func updateTripsTemplate(_ template: CPListTemplate) async {
        await tripViewModel.refreshTrips()
        
        let activeTripsSection = createActiveTripsSection()
        let completedTripsSection = createCompletedTripsSection()
        
        var sections: [CPListSection] = []
        
        if !activeTripsSection.items.isEmpty {
            sections.append(activeTripsSection)
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
        
        template.updateSections(sections)
    }
    
    private func createActiveTripsSection() -> CPListSection {
        let activeTrips = tripViewModel.trips.filter { $0.status == .ongoing || $0.status == .scheduled }
        
        let items = activeTrips.map { trip in
            // Format start time inline
            let startTimeFormatted: String = {
                let formatter = ISO8601DateFormatter()
                guard let date = formatter.date(from: trip.startTime) else { return trip.startTime }
                let displayFormatter = DateFormatter()
                displayFormatter.timeStyle = .short
                return displayFormatter.string(from: date)
            }()
            
            // Format status inline
            let statusText: String = {
                switch trip.status {
                case .ongoing: return "In Progress"
                case .scheduled: return "Scheduled"
                case .finalized: return "Completed"
                case .cancelled: return "Cancelled"
                }
            }()
            
            let item = CPListItem(
                text: trip.description,
                detailText: "\(trip.driverName) • \(startTimeFormatted) • \(statusText)",
                image: UIImage(systemName: "car.fill") ?? UIImage()
            )
            
            item.handler = { [weak self] _, completion in
                self?.showTripDetail(trip: trip)
                completion()
            }
            
            return item
        }
        
        return CPListSection(items: items, header: "Active Trips", sectionIndexTitle: nil)
    }
    
    private func createCompletedTripsSection() -> CPListSection {
        let completedTrips = tripViewModel.trips.filter { $0.status == .finalized }
        
        let items = completedTrips.map { trip in
            // Format start time inline  
            let startTimeFormatted: String = {
                let formatter = ISO8601DateFormatter()
                guard let date = formatter.date(from: trip.startTime) else { return trip.startTime }
                let displayFormatter = DateFormatter()
                displayFormatter.timeStyle = .short
                return displayFormatter.string(from: date)
            }()
            
            // Format duration inline
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
                detailText: "\(trip.driverName) • \(startTimeFormatted) • \(durationFormatted)",
                image: UIImage(systemName: "checkmark.circle.fill") ?? UIImage()
            )
            
            item.handler = { [weak self] _, completion in
                self?.showTripDetail(trip: trip)
                completion()
            }
            
            return item
        }
        
        return CPListSection(items: items, header: "Completed Trips", sectionIndexTitle: nil)
    }
    
    private func showTripDetail(trip: Trip) {
        let detailTemplate = CarPlayTripDetailTemplate(trip: trip, viewModel: tripViewModel, interfaceController: interfaceController)
        interfaceController?.pushTemplate(detailTemplate.template, animated: true) { _, _ in }
    }
    
    // MARK: - Map Tab
    
    private func createMapTab() -> CPListTemplate {
        let mapTemplate = CPListTemplate(title: "Map", sections: [])
        mapTemplate.tabSystemItem = .more
        
        Task {
            await updateMapTabWithOptions(mapTemplate)
        }
        
        return mapTemplate
    }
    
    private func updateMapTabWithOptions(_ listTemplate: CPListTemplate) async {
        await tripViewModel.refreshTrips()
        
        let items = [
            CPListItem(
                text: "Active Trips on Map",
                detailText: "View ongoing and scheduled trips",
                image: UIImage(systemName: "car.fill") ?? UIImage()
            ),
            CPListItem(
                text: "Trip Destinations", 
                detailText: "View all trip destinations",
                image: UIImage(systemName: "flag.fill") ?? UIImage()
            ),
            CPListItem(
                text: "Navigate to Full Map",
                detailText: "Open detailed map view",
                image: UIImage(systemName: "map.fill") ?? UIImage()
            )
        ]
        
        // Set up handlers
        items[0].handler = { [weak self] _, completion in
            Task { @MainActor in
                await self?.showActiveTripsOnMap()
            }
            completion()
        }
        
        items[1].handler = { [weak self] _, completion in
            Task { @MainActor in
                await self?.showTripDestinations()
            }
            completion()
        }
        
        items[2].handler = { [weak self] _, completion in
            self?.showFullMapView()
            completion()
        }
        
        let section = CPListSection(items: items, header: "Map Options", sectionIndexTitle: nil)
        listTemplate.updateSections([section])
    }
    
    private func showFullMapView() {
        // Create a full map template for detailed map interaction
        let mapTemplate = CPMapTemplate()
        
        // Configure map buttons for trip navigation
        var mapButtons: [CPMapButton] = []
        
        // Add a button to show active trips
        let activeTripsButton = CPMapButton { [weak self] _ in
            Task { @MainActor in
                await self?.showActiveTripsOnMap()
            }
        }
        activeTripsButton.image = UIImage(systemName: "car.fill") ?? UIImage()
        mapButtons.append(activeTripsButton)
        
        // Add a button to show trip destinations  
        let destinationsButton = CPMapButton { [weak self] _ in
            Task { @MainActor in
                await self?.showTripDestinations()
            }
        }
        destinationsButton.image = UIImage(systemName: "flag.fill") ?? UIImage()
        mapButtons.append(destinationsButton)
        
        mapTemplate.mapButtons = mapButtons
        
        // Push the full map template
        interfaceController?.pushTemplate(mapTemplate, animated: true) { _, _ in }
    }
    
    private func refreshMapData() async {
        if let mapTemplate = interfaceController?.rootTemplate as? CPTabBarTemplate {
            if let mapTab = mapTemplate.templates.first(where: { $0.isKind(of: CPListTemplate.self) && ($0 as? CPListTemplate)?.title == "Map" }) as? CPListTemplate {
                await updateMapTabWithOptions(mapTab)
            }
        }
    }
    
    // Helper methods for map functionality
    private func showActiveTripsOnMap() async {
        // Get active trips and create a list template to show them
        await tripViewModel.refreshTrips()
        let activeTrips = tripViewModel.trips.filter { $0.status == .ongoing || $0.status == .scheduled }
        
        let items = activeTrips.map { trip in
            let item = CPListItem(
                text: trip.description,
                detailText: "Driver: \(trip.driverName)",
                image: UIImage(systemName: "car.fill") ?? UIImage()
            )
            
            item.handler = { [weak self] _, completion in
                Task { @MainActor in
                    await self?.navigateToTrip(trip)
                }
                completion()
            }
            
            return item
        }
        
        if !items.isEmpty {
            let listTemplate = CPListTemplate(title: "Active Trips", sections: [CPListSection(items: items)])
            interfaceController?.pushTemplate(listTemplate, animated: true) { _, _ in }
        }
    }
    
    private func showTripDestinations() async {
        // Show a list of trip destinations
        await tripViewModel.refreshTrips()
        
        let items = tripViewModel.trips.map { trip in
            let item = CPListItem(
                text: trip.destination.address,
                detailText: trip.description,
                image: UIImage(systemName: "flag.fill") ?? UIImage()
            )
            
            item.handler = { [weak self] _, completion in
                Task { @MainActor in
                    await self?.navigateToTrip(trip)
                }
                completion()
            }
            
            return item
        }
        
        if !items.isEmpty {
            let listTemplate = CPListTemplate(title: "Trip Destinations", sections: [CPListSection(items: items)])
            interfaceController?.pushTemplate(listTemplate, animated: true) { _, _ in }
        }
    }
    
    private func navigateToTrip(_ trip: Trip) async {
        // For a real CarPlay app, you would typically start navigation to the trip destination
        // This could involve creating a CPRouteChoice and starting a CPNavigationSession
        
        // For now, we'll show the trip details
        showTripDetail(trip: trip)
    }
    
    // MARK: - Status Tab
    
    private func createStatusTab() -> CPInformationTemplate {
        let statusTemplate = CPInformationTemplate(title: "Trip Status", layout: .leading, items: [], actions: [])
        statusTemplate.tabSystemItem = .search
        
        Task {
            await updateStatusTemplate(statusTemplate)
        }
        
        return statusTemplate
    }
    
    private func updateStatusTemplate(_ template: CPInformationTemplate) async {
        await tripViewModel.refreshTrips()
        
        let totalTrips = tripViewModel.trips.count
        let activeTrips = tripViewModel.trips.filter { $0.status == .ongoing }.count
        let completedTrips = tripViewModel.trips.filter { $0.status == .finalized }.count
        let scheduledTrips = tripViewModel.trips.filter { $0.status == .scheduled }.count
        
        let items = [
            CPInformationItem(title: "Total Trips", detail: "\(totalTrips)"),
            CPInformationItem(title: "Active", detail: "\(activeTrips)"),
            CPInformationItem(title: "Completed", detail: "\(completedTrips)"),
            CPInformationItem(title: "Scheduled", detail: "\(scheduledTrips)")
        ]
        
        let refreshAction = CPTextButton(title: "Refresh", textStyle: .normal) { [weak self] _ in
            Task {
                await self?.updateStatusTemplate(template)
            }
        }
        
        // Update the template by recreating it with new data
        // Note: CPInformationTemplate doesn't have an updateTitle method
        // We need to update through the interface controller
        if let interfaceController = self.interfaceController,
           let tabBarTemplate = interfaceController.rootTemplate as? CPTabBarTemplate,
           let statusTabIndex = tabBarTemplate.templates.firstIndex(where: { $0 === template }) {
            
            let newStatusTemplate = CPInformationTemplate(
                title: "Trip Status",
                layout: .leading,
                items: items,
                actions: [refreshAction]
            )
            newStatusTemplate.tabSystemItem = .search
            
            var updatedTemplates = tabBarTemplate.templates
            updatedTemplates[statusTabIndex] = newStatusTemplate
            
            let newTabBarTemplate = CPTabBarTemplate(templates: updatedTemplates)
            interfaceController.setRootTemplate(newTabBarTemplate, animated: false) { _, _ in }
        }
    }
}
