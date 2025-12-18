//
//  Trip Models.swift
//  SeatCode
//
//  Created by Angel Docampo on 17/12/25.
//

import Foundation
import CoreLocation

struct Trip: Codable, Identifiable {
    let id = UUID()
    let tripId: Int? // Numeric ID from JSON that matches StopDetail.tripId
    let description: String
    let driverName: String
    let route: String // Google encoded polyline
    let status: TripStatus
    let origin: Location
    let stops: [Stop]
    let destination: Location
    let endTime: String
    let startTime: String
    
    enum CodingKeys: String, CodingKey {
        case tripId = "id"
        case description, driverName, route, status, origin, stops, destination, endTime, startTime
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
