//
//  NetworkService.swift
//  SeatCodeTest
//
//  Created by Angel Docampo on 18/12/25.
//

import Foundation
import Combine

// MARK: - Network Error Types
enum NetworkError: LocalizedError {
    case invalidURL
    case decodingFailed(DecodingError)
    case requestFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The provided URL is invalid"
        case .decodingFailed(let decodingError):
            return "Failed to decode data: \(decodingError.localizedDescription)"
        case .requestFailed(let error):
            return "Network request failed: \(error.localizedDescription)"
        }
    }
}

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
    private let tripIdGenerator: TripIdGenerator
    private let stopDetailIdGenerator: StopDetailIdGenerator
    
    // MARK: - Initializers
    init(
        session: NetworkSessionProtocol = URLSession.shared,
        configuration: NetworkConfigurationProtocol = DefaultNetworkConfiguration(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.session = session
        self.configuration = configuration
        self.decoder = decoder
        self.tripIdGenerator = TripIdGenerator()
        self.stopDetailIdGenerator = StopDetailIdGenerator()
        
        // Set up the decoder with the ID generators
        self.decoder.userInfo[.tripIdGenerator] = self.tripIdGenerator
        self.decoder.userInfo[.stopDetailIdGenerator] = self.stopDetailIdGenerator
    }
    
    func loadTrips() async throws -> [Trip] {
        do {
            guard let url = URL(string: configuration.tripsURL) else {
                throw NetworkError.invalidURL
            }
            
            let (data, _) = try await session.data(from: url)
            
            // Debug: Print raw JSON structure
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Trips JSON preview: \(String(jsonString.prefix(500)))...")
            }
            
            do {
                let decodedTrips = try decoder.decode([Trip].self, from: data)
                print("Successfully loaded \(decodedTrips.count) trips")
                return decodedTrips
            } catch let decodingError as DecodingError {
                print("Failed to decode trips: \(decodingError.localizedDescription)")
                switch decodingError {
                case .typeMismatch(let type, let context):
                    print("Type mismatch for type \(type) at path: \(context.codingPath)")
                case .valueNotFound(let type, let context):
                    print("Value not found for type \(type) at path: \(context.codingPath)")
                case .keyNotFound(let key, let context):
                    print("Key '\(key)' not found at path: \(context.codingPath)")
                case .dataCorrupted(let context):
                    print("Data corrupted at path: \(context.codingPath)")
                @unknown default:
                    print("Unknown decoding error: \(decodingError)")
                }
                throw NetworkError.decodingFailed(decodingError)
            }
            
        } catch let networkError as NetworkError {
            throw networkError
        } catch {
            print("Network request failed: \(error.localizedDescription)")
            throw NetworkError.requestFailed(error)
        }
    }
    
    func loadStops() async throws -> [StopDetail] {
        do {
            guard let url = URL(string: configuration.stopsURL) else {
                throw NetworkError.invalidURL
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
            } catch let arrayDecodingError as DecodingError {
                print("Failed to decode stops as array: \(arrayDecodingError.localizedDescription)")
                do {
                    // If array decoding fails, try decoding as single object and wrap in array
                    let singleStop = try decoder.decode(StopDetail.self, from: data)
                    decodedStops = [singleStop]
                    print("Successfully decoded single stop and wrapped in array")
                } catch let singleDecodingError as DecodingError {
                    print("Failed to decode stops as single object: \(singleDecodingError.localizedDescription)")
                    print("Array decoding error details:")
                    logDecodingError(arrayDecodingError)
                    print("Single object decoding error details:")
                    logDecodingError(singleDecodingError)
                    throw NetworkError.decodingFailed(arrayDecodingError)
                }
            }
            
            print("Successfully loaded \(decodedStops.count) stops")
            return decodedStops
            
        } catch let networkError as NetworkError {
            throw networkError
        } catch {
            print("Network request failed: \(error.localizedDescription)")
            throw NetworkError.requestFailed(error)
        }
    }
    
    private func logDecodingError(_ error: DecodingError) {
        switch error {
        case .typeMismatch(let type, let context):
            print("Type mismatch for type \(type) at path: \(context.codingPath)")
            if let description = context.debugDescription.isEmpty ? nil : context.debugDescription {
                print("Context: \(description)")
            }
        case .valueNotFound(let type, let context):
            print("Value not found for type \(type) at path: \(context.codingPath)")
            if let description = context.debugDescription.isEmpty ? nil : context.debugDescription {
                print("Context: \(description)")
            }
        case .keyNotFound(let key, let context):
            print("Key '\(key)' not found at path: \(context.codingPath)")
            if let description = context.debugDescription.isEmpty ? nil : context.debugDescription {
                print("Context: \(description)")
            }
        case .dataCorrupted(let context):
            print("Data corrupted at path: \(context.codingPath)")
            if let description = context.debugDescription.isEmpty ? nil : context.debugDescription {
                print("Context: \(description)")
            }
        @unknown default:
            print("Unknown decoding error: \(error)")
        }
    }
    

}
