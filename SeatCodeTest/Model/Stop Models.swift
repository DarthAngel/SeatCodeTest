//
//  Stop Models.swift
//  SeatCodeTest
//
//  Created by Angel Docampo on 17/12/25.
//

import Foundation
import CoreLocation



// ID Generator for StopDetail objects - Using a class with modern concurrency principles
class StopDetailIdGenerator: @unchecked Sendable {
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
        
        // Decode all other properties first
        self.stopTime = try container.decode(String.self, forKey: .stopTime)
        self.paid = try container.decode(Bool.self, forKey: .paid)
        self.address = try container.decode(String.self, forKey: .address)
        self.tripId = try container.decode(Int.self, forKey: .tripId)
        self.userName = try container.decode(String.self, forKey: .userName)
        self.point = try container.decode(Point.self, forKey: .point)
        self.price = try container.decode(Double.self, forKey: .price)
        
        // Get the next available ID from the decoder's userInfo
        // This should be called last to ensure each StopDetail gets a unique ID
        if let idGenerator = decoder.userInfo[.stopDetailIdGenerator] as? StopDetailIdGenerator {
            self.id = idGenerator.nextId()
            print("Generated StopDetail ID: \(self.id) for user: \(self.userName)")
        } else {
            // Fallback if no generator is provided
            self.id = 1
            print("No StopDetailIdGenerator provided, using default ID for user: \(self.userName)")
        }
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
    

    
}


