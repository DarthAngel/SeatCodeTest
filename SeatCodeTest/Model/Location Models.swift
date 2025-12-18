//
//  Location Models.swift
//  SeatCodeTest
//
//  Created by Angel Docampo on 17/12/25.
//

import Foundation
import CoreLocation

struct Location: Codable {
    let address: String
    let point: Point
}

struct Point: Codable {
    let latitude: Double
    let longitude: Double
    
    enum CodingKeys: String, CodingKey {
        case latitude = "_latitude"
        case longitude = "_longitude"
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
