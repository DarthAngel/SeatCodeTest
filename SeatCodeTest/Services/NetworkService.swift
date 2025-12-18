//
//  NetworkService.swift
//  SeatCodeTest
//
//  Created by Angel Docampo on 18/12/25.
//

import Foundation
import Combine

@MainActor
class TripService {

    
    private let tripsURL = "https://sandbox-giravolta-static.s3.eu-west-1.amazonaws.com/tech-test/trips.json"
    private let stopsURL = "https://sandbox-giravolta-static.s3.eu-west-1.amazonaws.com/tech-test/stops.json"
    
    func loadTrips() async throws -> [Trip]{
        
        do {
            guard let url = URL(string: tripsURL) else {
                throw URLError(.badURL)
            }
            
            let (data, _) = try await URLSession.shared.data(from: url)
            
            // Debug: Print raw JSON structure
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Trips JSON preview: \(String(jsonString.prefix(500)))...")
            }
            
            let decodedTrips = try JSONDecoder().decode([Trip].self, from: data)
            print("Successfully loaded \(decodedTrips.count) trips")
            return decodedTrips
            
        } catch {
            throw error
        }
        
        
    }
    
    func loadStops() async throws -> [StopDetail]{
        do {
            guard let url = URL(string: stopsURL) else {
                throw URLError(.badURL)
            }
            
            let (data, _) = try await URLSession.shared.data(from: url)
            
            // Debug: Print raw JSON structure
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Stops JSON preview: \(String(jsonString.prefix(500)))...")
            }
            
            let decodedStops = try JSONDecoder().decode([StopDetail].self, from: data)
            print("Successfully loaded \(decodedStops.count) stops")
            return decodedStops
            
        } catch {
            throw error
        }
    }
    

}
