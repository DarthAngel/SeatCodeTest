//
//  Stop Models.swift
//  SeatCodeTest
//
//  Created by Angel Docampo on 17/12/25.
//

import Foundation
import CoreLocation

// ID Generator for Stop objects
class StopIdGenerator {
    private var currentId = 0
    
    func nextId() -> Int {
        currentId += 1
        return currentId
    }
    
    func reset() {
        currentId = 0
    }
}

// ID Generator for StopDetail objects
class StopDetailIdGenerator {
    private var currentId = 0
    
    func nextId() -> Int {
        currentId += 1
        return currentId
    }
    
    func reset() {
        currentId = 0
    }
}

// Extension to add custom userInfo keys
extension CodingUserInfoKey {
    static let stopIdGenerator = CodingUserInfoKey(rawValue: "stopIdGenerator")!
    static let stopDetailIdGenerator = CodingUserInfoKey(rawValue: "stopDetailIdGenerator")!
}

struct Stop: Codable, Identifiable {
    let id: Int
    let point: Point?
    
    var coordinate: CLLocationCoordinate2D? {
        point?.coordinate
    }
    
    // Custom coding keys to exclude id from decoding
    private enum CodingKeys: String, CodingKey {
        case point
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Get the next available ID from the decoder's userInfo
        if let idGenerator = decoder.userInfo[.stopIdGenerator] as? StopIdGenerator {
            self.id = idGenerator.nextId()
        } else {
            // Fallback if no generator is provided
            self.id = 1
        }
        
        self.point = try container.decodeIfPresent(Point.self, forKey: .point)
    }
    
    // Custom initializer for manual creation
    init(id: Int, point: Point?) {
        self.id = id
        self.point = point
    }
}

struct StopDetail: Codable, Identifiable {
    let id: Int
    let stopTime: String
    let paid: Bool
    let address: String
    let tripId: Int
    let userName: String
    let point: Point
    let price: Double
    
    var coordinate: CLLocationCoordinate2D {
        point.coordinate
    }
    
    // Custom coding keys to exclude id from decoding
    private enum CodingKeys: String, CodingKey {
        case stopTime, paid, address, tripId, userName, point, price
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Get the next available ID from the decoder's userInfo
        if let idGenerator = decoder.userInfo[.stopDetailIdGenerator] as? StopDetailIdGenerator {
            self.id = idGenerator.nextId()
        } else {
            // Fallback if no generator is provided
            self.id = 1
        }
        
        self.stopTime = try container.decode(String.self, forKey: .stopTime)
        self.paid = try container.decode(Bool.self, forKey: .paid)
        self.address = try container.decode(String.self, forKey: .address)
        self.tripId = try container.decode(Int.self, forKey: .tripId)
        self.userName = try container.decode(String.self, forKey: .userName)
        self.point = try container.decode(Point.self, forKey: .point)
        self.price = try container.decode(Double.self, forKey: .price)
    }
    
    // Custom initializer for manual creation
    init(id: Int, stopTime: String, paid: Bool, address: String, tripId: Int, userName: String, point: Point, price: Double) {
        self.id = id
        self.stopTime = stopTime
        self.paid = paid
        self.address = address
        self.tripId = tripId
        self.userName = userName
        self.point = point
        self.price = price
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

// MARK: - Usage Example
/*
// Example of how to decode stops with auto-generated IDs:
let jsonData = // your JSON data
let decoder = JSONDecoder()
let stopIdGenerator = StopIdGenerator()
let stopDetailIdGenerator = StopDetailIdGenerator()
decoder.userInfo[.stopIdGenerator] = stopIdGenerator
decoder.userInfo[.stopDetailIdGenerator] = stopDetailIdGenerator

do {
    let stops = try decoder.decode([Stop].self, from: jsonData)
    let stopDetails = try decoder.decode([StopDetail].self, from: jsonData)
    // stops and stopDetails will now have auto-incremented IDs: 1, 2, 3, etc.
} catch {
    print("Decoding error: \(error)")
}
*/
