//
//  NetworkService.swift
//  SeatCodeTest
//
//  Created by Angel Docampo on 18/12/25.
//

import Foundation
import Combine

// MARK: - Network Dependencies Protocol
protocol NetworkSessionProtocol {
    func data(from url: URL) async throws -> (Data, URLResponse)
}

extension URLSession: NetworkSessionProtocol {}

// MARK: - Configuration Protocol
protocol NetworkConfigurationProtocol {
    var tripsURL: String { get }
    var stopsURL: String { get }
}

struct DefaultNetworkConfiguration: NetworkConfigurationProtocol {
    let tripsURL = "https://sandbox-giravolta-static.s3.eu-west-1.amazonaws.com/tech-test/trips.json"
    let stopsURL = "https://sandbox-giravolta-static.s3.eu-west-1.amazonaws.com/tech-test/stops.json"
}

@MainActor
class NetworkService {
    
    private let session: NetworkSessionProtocol
    private let configuration: NetworkConfigurationProtocol
    private let decoder: JSONDecoder
    
    // MARK: - Initializers
    init(
        session: NetworkSessionProtocol = URLSession.shared,
        configuration: NetworkConfigurationProtocol = DefaultNetworkConfiguration(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.session = session
        self.configuration = configuration
        self.decoder = decoder
    }
    
    func loadTrips() async throws -> [Trip] {
        do {
            guard let url = URL(string: configuration.tripsURL) else {
                throw URLError(.badURL)
            }
            
            let (data, _) = try await session.data(from: url)
            
            // Debug: Print raw JSON structure
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Trips JSON preview: \(String(jsonString.prefix(500)))...")
            }
            
            let decodedTrips = try decoder.decode([Trip].self, from: data)
            print("Successfully loaded \(decodedTrips.count) trips")
            return decodedTrips
            
        } catch {
            throw error
        }
    }
    
    func loadStops() async throws -> [StopDetail] {
        do {
            guard let url = URL(string: configuration.stopsURL) else {
                throw URLError(.badURL)
            }
            
            let (data, _) = try await session.data(from: url)
            
            // Debug: Print raw JSON structure
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Stops JSON preview: \(String(jsonString.prefix(500)))...")
            }
            
            // Try to decode as array first, if that fails, try to decode as single object
            let decodedStops: [StopDetail]
            do {
                // Try decoding as array
                decodedStops = try decoder.decode([StopDetail].self, from: data)
            } catch {
                // If array decoding fails, try decoding as single object and wrap in array
                let singleStop = try decoder.decode(StopDetail.self, from: data)
                decodedStops = [singleStop]
            }
            
            print("Successfully loaded \(decodedStops.count) stops")
            return decodedStops
            
        } catch {
            throw error
        }
    }
    

}
