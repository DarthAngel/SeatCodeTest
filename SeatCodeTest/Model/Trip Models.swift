//
//  Trip Models.swift
//  SeatCode
//
//  Created by Angel Docampo on 17/12/25.
//

import Foundation
import CoreLocation

// ID Generator for Trip objects
class TripIdGenerator {
    private var currentId = 0
    
    func nextId() -> Int {
        currentId += 1
        return currentId
    }
    
    func reset() {
        currentId = 0
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
        
        // Get the next available ID from the decoder's userInfo
        if let idGenerator = decoder.userInfo[.tripIdGenerator] as? TripIdGenerator {
            self.id = idGenerator.nextId()
        } else {
            // Fallback if no generator is provided
            self.id = 1
        }
        
        self.description = try container.decode(String.self, forKey: .description)
        self.driverName = try container.decode(String.self, forKey: .driverName)
        self.route = try container.decode(String.self, forKey: .route)
        self.status = try container.decode(TripStatus.self, forKey: .status)
        self.origin = try container.decode(Location.self, forKey: .origin)
        self.stops = try container.decode([Stop].self, forKey: .stops)
        self.destination = try container.decode(Location.self, forKey: .destination)
        self.endTime = try container.decode(String.self, forKey: .endTime)
        self.startTime = try container.decode(String.self, forKey: .startTime)
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

// MARK: - Usage Example
/*
// Example of how to decode trips with auto-generated IDs:
let jsonData = // your JSON data
let decoder = JSONDecoder()
let idGenerator = TripIdGenerator()
decoder.userInfo[.tripIdGenerator] = idGenerator

do {
    let trips = try decoder.decode([Trip].self, from: jsonData)
    // trips will now have IDs: 1, 2, 3, etc.
} catch {
    print("Decoding error: \(error)")
}
*/
