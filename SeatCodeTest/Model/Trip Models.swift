//
//  Trip Models.swift
//  SeatCode
//
//  Created by Angel Docampo on 17/12/25.
//

import Foundation
import CoreLocation

// ID Generator for Trip objects - Using a class with modern concurrency principles
class TripIdGenerator: @unchecked Sendable {
    private var currentId = 0
    private let lock = NSLock()
    
    func nextId() -> Int {
        lock.withLock {
            currentId += 1
            return currentId
        }
    }
    
    func reset() {
        lock.withLock {
            currentId = 0
        }
    }
}

// Extension to add custom userInfo key
extension CodingUserInfoKey {
    static let tripIdGenerator = CodingUserInfoKey(rawValue: "tripIdGenerator")!
}

struct Trip: Codable, Identifiable {
    let id: Int
    let description: String
    let driverName: String
    let route: String // Google encoded polyline
    let status: TripStatus
    let origin: Location
    let stops: [Stop]
    let destination: Location
    let endTime: String
    let startTime: String
    
    // Custom coding keys to exclude id from decoding
    private enum CodingKeys: String, CodingKey {
        case description, driverName, route, status, origin, stops, destination, endTime, startTime
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        print("Starting decoding ======>")
        // Decode all other properties first
        self.description = try container.decode(String.self, forKey: .description)
        self.driverName = try container.decode(String.self, forKey: .driverName)
        self.route = try container.decode(String.self, forKey: .route)
        self.status = try container.decode(TripStatus.self, forKey: .status)
        self.origin = try container.decode(Location.self, forKey: .origin)
        // Handle optional stops - decode as empty array if key is missing, empty, or contains invalid objects
        if let stopsContainer = try? container.nestedUnkeyedContainer(forKey: .stops) {
            var tempStops: [Stop] = []
            var mutableContainer = stopsContainer
            
            while !mutableContainer.isAtEnd {
                do {
                    let stop = try mutableContainer.decode(Stop.self)
                    tempStops.append(stop)
                } catch {
                    // Skip invalid stop objects (like empty objects {})
                    print("Skipping invalid stop object: \(error)")
                    _ = try? mutableContainer.decode([String: String].self) // Consume the invalid object
                }
            }
            self.stops = tempStops
        } else {
            self.stops = []
        }
        self.destination = try container.decode(Location.self, forKey: .destination)
        self.endTime = try container.decode(String.self, forKey: .endTime)
        self.startTime = try container.decode(String.self, forKey: .startTime)
        
        // Get the next available ID from the decoder's userInfo
        // This should be called last to ensure each Trip gets a unique ID
        print("Generating id for trip: \(self.description)")
        if let idGenerator = decoder.userInfo[.tripIdGenerator] as? TripIdGenerator {
            self.id = idGenerator.nextId()
            print("Generated ID: \(self.id) for trip: \(self.description)")
        } else {
            // Fallback if no generator is provided
            self.id = 1
            print("No TripIdGenerator provided, using default ID for trip: \(self.description)")
        }
    }
    
    // Custom initializer for manual creation
    init(id: Int, description: String, driverName: String, route: String, status: TripStatus, origin: Location, stops: [Stop], destination: Location, endTime: String, startTime: String) {
        self.id = id
        self.description = description
        self.driverName = driverName
        self.route = route
        self.status = status
        self.origin = origin
        self.stops = stops
        self.destination = destination
        self.endTime = endTime
        self.startTime = startTime
    }
}

enum TripStatus: String, Codable, CaseIterable {
    case ongoing = "ongoing"
    case scheduled = "scheduled"
    case finalized = "finalized"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .ongoing:
            return "Ongoing"
        case .scheduled:
            return "Scheduled"
        case .finalized:
            return "Finalized"
        case .cancelled:
            return "Cancelled"
        }
    }
    
    var color: String {
        switch self {
        case .ongoing:
            return "green"
        case .scheduled:
            return "blue"
        case .finalized:
            return "gray"
        case .cancelled:
            return "red"
        }
    }
}


