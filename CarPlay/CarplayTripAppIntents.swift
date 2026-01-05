//
//  TripAppIntents.swift
//  SeatCodeTest
//
//   Created by Angel Docampo on 04/01/2026.
//

import AppIntents
import Foundation

// MARK: - Trip Entity
struct TripEntity: AppEntity {
    let id: Int
    let description: String
    let driverName: String
    let status: String
    
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Trip"
    static let defaultQuery = TripEntityQuery()
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(description)", subtitle: "Driver: \(driverName)")
    }
}

// MARK: - Trip Entity Query
struct TripEntityQuery: EntityQuery {
    func entities(for identifiers: [TripEntity.ID]) async throws -> [TripEntity] {
        // In a real app, you'd fetch from your data source
        return []
    }
    
    func suggestedEntities() async throws -> [TripEntity] {
        // Provide suggested trips
        return []
    }
}

// MARK: - Show Trips Intent
struct ShowTripsIntent: AppIntent {
    static let title: LocalizedStringResource = "Show Trips"
    static let description = IntentDescription("Show all available trips")
    
    func perform() async throws -> some IntentResult {
        // This intent can be triggered from Siri
        return .result()
    }
}

// MARK: - Show Trip Details Intent
struct ShowTripDetailsIntent: AppIntent {
    static let title: LocalizedStringResource = "Show Trip Details"
    static let description = IntentDescription("Show details for a specific trip")
    
    @Parameter(title: "Trip")
    var trip: TripEntity
    
    func perform() async throws -> some IntentResult {
        // Show specific trip details
        return .result()
    }
}

// MARK: - Get Trip Status Intent
struct GetTripStatusIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Trip Status"
    static let description = IntentDescription("Get the current status of trips")
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // In a real app, you'd fetch real data
        let statusMessage = "You have 3 active trips and 5 completed trips."
        return .result(dialog: IntentDialog(stringLiteral: statusMessage))
    }
}

// MARK: - App Shortcuts Provider
struct TripAppShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ShowTripsIntent(),
            phrases: [
                "Show my trips in \(.applicationName)",
                "Open trips in \(.applicationName)",
                "Show trip list in \(.applicationName)"
            ],
            shortTitle: "Show Trips",
            systemImageName: "car.fill"
        )
        
        AppShortcut(
            intent: GetTripStatusIntent(),
            phrases: [
                "What's my trip status in \(.applicationName)",
                "Show trip status in \(.applicationName)",
                "How many trips do I have in \(.applicationName)"
            ],
            shortTitle: "Trip Status",
            systemImageName: "chart.bar.fill"
        )
    }
}
