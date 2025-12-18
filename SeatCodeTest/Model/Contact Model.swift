//
//  Contact Model.swift
//  SeatCodeTest
//
//  Created by Angel Docampo on 18/12/25.
//

import Foundation

struct ContactReport: Codable, Identifiable {
    let id = UUID()
    let name: String
    let surname: String
    let email: String
    let phone: String?
    let reportDate: Date
    let description: String
    
    var fullName: String {
        "\(name) \(surname)"
    }
}
