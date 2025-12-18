//
//  Stop Models.swift
//  SeatCodeTest
//
//  Created by Angel Docampo on 17/12/25.
//

import Foundation
import CoreLocation

struct Stop: Codable, Identifiable {
    let stopId: Int?
    let point: Point?
    
    // Identifiable conformance - required id property
    var id: String {
        if let stopId = stopId {
            return "\(stopId)"
        } else if let point = point {
            // Create a stable ID from coordinates when stopId is nil
            return "\(point.latitude)_\(point.longitude)"
        } else {
            // Fallback to a UUID string if neither stopId nor point are available
            return UUID().uuidString
        }
    }
    
    var coordinate: CLLocationCoordinate2D? {
        point?.coordinate
    }
    
    enum CodingKeys: String, CodingKey {
        case stopId = "id"
        case point
    }
}

struct StopDetail: Codable, Identifiable {
    let stopId: Int?
    let stopTime: String
    let paid: Bool
    let address: String
    let tripId: Int
    let userName: String
    let point: Point
    let price: Double
    
    // Use stopId if available, otherwise fall back to tripId for Identifiable
    var id: Int {
        stopId ?? tripId
    }
    
    var coordinate: CLLocationCoordinate2D {
        point.coordinate
    }
    
    // Regular initializer for manual creation
    init(stopId: Int?, stopTime: String, paid: Bool, address: String, tripId: Int, userName: String, point: Point, price: Double) {
        self.stopId = stopId
        self.stopTime = stopTime
        self.paid = paid
        self.address = address
        self.tripId = tripId
        self.userName = userName
        self.point = point
        self.price = price
    }
    
    
    enum CodingKeys: String, CodingKey {
        case stopId = "id"
        case stopTime, paid, address, tripId, userName, point, price
    }
    
    var formattedTime: String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: stopTime) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .none
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        return stopTime
    }
    
    var formattedPrice: String {
        String(format: "%.2f€", price)
    }
}
