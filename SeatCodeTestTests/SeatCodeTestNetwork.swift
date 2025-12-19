//
//  SeatCodeTestNetwork.swift
//  SeatCodeTestTests
//
//  Created by Angel Docampo on 18/12/25.
//

import XCTest
import CoreLocation
@testable import SeatCodeTest

// MARK: - Mock Network Session
class MockNetworkSession: NetworkSessionProtocol {
    var mockData: Data?
    var mockError: Error?
    var requestedURL: URL?
    
    func data(from url: URL) async throws -> (Data, URLResponse) {
        requestedURL = url
        
        if let error = mockError {
            throw error
        }
        
        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        ) ?? URLResponse()
        
        return (mockData ?? Data(), response)
    }
}

// MARK: - Test Configuration
struct TestNetworkConfiguration: NetworkConfigurationProtocol {
    let tripsURL = "https://test-api.com/trips.json"
    let stopsURL = "https://test-api.com/stops.json"
}

@MainActor
final class SeatCodeTestNetworkTests: XCTestCase {
    
    var networkService: NetworkService!
    var mockSession: MockNetworkSession!
    var testConfiguration: TestNetworkConfiguration!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        mockSession = MockNetworkSession()
        testConfiguration = TestNetworkConfiguration()
        networkService = NetworkService(
            session: mockSession,
            configuration: testConfiguration
        )
    }
    
    override func tearDown() async throws {
        networkService = nil
        mockSession = nil
        testConfiguration = nil
        try await super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func createMockTripsData() -> Data {
        let jsonString = """
        [
            {
                "id": 1,
                "description": "Test Trip 1",
                "driverName": "John Doe",
                "route": "Route A",
                "origin": {
                    "address": "123 Start Street",
                    "point": {
                        "_latitude": 40.7128,
                        "_longitude": -74.0060
                    }
                },
                "destination": {
                    "address": "456 End Avenue",
                    "point": {
                        "_latitude": 40.7589,
                        "_longitude": -73.9851
                    }
                },
                "startTime": "2024-01-01T09:00:00Z",
                "endTime": "2024-01-01T10:30:00Z",
                "status": "finalized",
                "stops": [
                    {
                        "id": 101,
                        "point": {
                            "_latitude": 40.7300,
                            "_longitude": -73.9950
                        }
                    }
                ]
            },
            {
                "id": 2,
                "description": "Test Trip 2",
                "driverName": "Jane Smith",
                "route": "Route B",
                "origin": {
                    "address": "789 Begin Blvd",
                    "point": {
                        "_latitude": 40.6892,
                        "_longitude": -74.0445
                    }
                },
                "destination": {
                    "address": "101 Finish Lane",
                    "point": {
                        "_latitude": 40.7505,
                        "_longitude": -73.9934
                    }
                },
                "startTime": "2024-01-01T14:00:00Z",
                "endTime": "2024-01-01T15:45:00Z",
                "status": "ongoing",
                "stops": []
            }
        ]
        """
        return jsonString.data(using: .utf8)!
    }
    
    private func createMockSingleStopData() -> Data {
        let jsonString = """
        {
            "id": 1,
            "tripId": 1,
            "stopTime": "2024-01-01T09:30:00Z",
            "address": "123 Test Street, Test City",
            "userName": "Test User",
            "price": 25.50,
            "paid": true,
            "point": {
                "_latitude": 40.7128,
                "_longitude": -74.0060
            }
        }
        """
        return jsonString.data(using: .utf8)!
    }
    
    private func createMockMultipleStopsData() -> Data {
        let jsonString = """
        [
            {
                "id": 1,
                "tripId": 1,
                "stopTime": "2024-01-01T09:30:00Z",
                "address": "123 Test Street, Test City",
                "userName": "Test User",
                "price": 25.50,
                "paid": true,
                "point": {
                    "_latitude": 40.7128,
                    "_longitude": -74.0060
                }
            },
            {
                "id": 2,
                "tripId": 2,
                "stopTime": "2024-01-01T14:15:00Z",
                "address": "456 Another Street, Another City",
                "userName": "Another User",
                "price": 30.75,
                "paid": false,
                "point": {
                    "_latitude": 40.7589,
                    "_longitude": -73.9851
                }
            }
        ]
        """
        return jsonString.data(using: .utf8)!
    }
    
    // MARK: - Trip Loading Tests
    
    func testLoadTripsSuccess() async throws {
        // Setup mock data
        mockSession.mockData = createMockTripsData()
        
        // Test successful loading of trips
        let trips = try await networkService.loadTrips()
        
        // Verify the correct URL was called
        XCTAssertEqual(mockSession.requestedURL?.absoluteString, testConfiguration.tripsURL)
        
        XCTAssertFalse(trips.isEmpty, "Trips array should not be empty")
        XCTAssertEqual(trips.count, 2, "Should load 2 trips from mock data")
        
        // Verify first trip
        let firstTrip = trips[0]
        XCTAssertEqual(firstTrip.id, 1)
        XCTAssertEqual(firstTrip.description, "Test Trip 1")
        XCTAssertEqual(firstTrip.driverName, "John Doe")
        XCTAssertEqual(firstTrip.route, "Route A")
        XCTAssertEqual(firstTrip.origin.address, "123 Start Street")
        XCTAssertEqual(firstTrip.destination.address, "456 End Avenue")
        
        // Verify coordinates
        let originCoord = firstTrip.origin.point.coordinate
        XCTAssertEqual(originCoord.latitude, 40.7128, accuracy: 0.0001)
        XCTAssertEqual(originCoord.longitude, -74.0060, accuracy: 0.0001)
    }
    
    func testLoadTripsVerifyTripStatus() async throws {
        // Setup mock data
        mockSession.mockData = createMockTripsData()
        
        // Test that trip statuses are properly decoded
        let trips = try await networkService.loadTrips()
        
        XCTAssertFalse(trips.isEmpty, "Trips should be loaded successfully")
        XCTAssertEqual(trips[0].status, .finalized)
        XCTAssertEqual(trips[1].status, .ongoing)
    }
    
    func testLoadTripsVerifyStopsStructure() async throws {
        // Setup mock data
        mockSession.mockData = createMockTripsData()
        
        // Test that stops within trips are properly structured
        let trips = try await networkService.loadTrips()
        
        XCTAssertFalse(trips.isEmpty, "Trips should be loaded successfully")
        
        // First trip should have one stop
        XCTAssertEqual(trips[0].stops.count, 1)
        let stop = trips[0].stops[0]
        XCTAssertNotNil(stop.point)
        
        let coord = stop.point!.coordinate
        XCTAssertEqual(coord.latitude, 40.7300, accuracy: 0.0001)
        XCTAssertEqual(coord.longitude, -73.9950, accuracy: 0.0001)
        
        // Second trip should have no stops
        XCTAssertEqual(trips[1].stops.count, 0)
    }
    
    func testLoadTripsNetworkError() async throws {
        // Setup mock error
        mockSession.mockError = URLError(.notConnectedToInternet)
        
        do {
            _ = try await networkService.loadTrips()
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(error is URLError)
        }
    }
    
    func testLoadTripsInvalidJSON() async throws {
        // Setup invalid JSON data
        mockSession.mockData = "invalid json".data(using: .utf8)
        
        do {
            _ = try await networkService.loadTrips()
            XCTFail("Should have thrown a decoding error")
        } catch {
            XCTAssertTrue(error is DecodingError)
        }
    }
    
    // MARK: - Stop Details Loading Tests
    
    func testLoadStopsSuccessWithSingleStop() async throws {
        // Setup mock data for single stop (current API behavior)
        mockSession.mockData = createMockSingleStopData()
        
        // Test successful loading of stop details
        let stops = try await networkService.loadStops()
        
        // Verify the correct URL was called
        XCTAssertEqual(mockSession.requestedURL?.absoluteString, testConfiguration.stopsURL)
        
        XCTAssertFalse(stops.isEmpty, "Stops array should not be empty")
        XCTAssertEqual(stops.count, 1, "Should load 1 stop from single object mock data")
        
        // Verify stop properties
        let stop = stops[0]
        XCTAssertEqual(stop.id, 1)
        XCTAssertEqual(stop.stopTime, "2024-01-01T09:30:00Z")
        XCTAssertEqual(stop.address, "123 Test Street, Test City")
        XCTAssertEqual(stop.userName, "Test User")
        XCTAssertEqual(stop.price, 25.50, accuracy: 0.01)
        
        // Verify coordinates
        let coord = stop.coordinate
        XCTAssertEqual(coord.latitude, 40.7128, accuracy: 0.0001)
        XCTAssertEqual(coord.longitude, -74.0060, accuracy: 0.0001)
    }
    
    func testLoadStopsSuccessWithMultipleStops() async throws {
        // Setup mock data for multiple stops (future API behavior)
        mockSession.mockData = createMockMultipleStopsData()
        
        // Test successful loading of multiple stop details
        let stops = try await networkService.loadStops()
        
        XCTAssertFalse(stops.isEmpty, "Stops array should not be empty")
        XCTAssertEqual(stops.count, 2, "Should load 2 stops from array mock data")
        
        // Verify first stop
        let firstStop = stops[0]
        XCTAssertEqual(firstStop.id, 1)
        XCTAssertEqual(firstStop.userName, "Test User")
        
        // Verify second stop
        let secondStop = stops[1]
        XCTAssertEqual(secondStop.id, 2)
        XCTAssertEqual(secondStop.userName, "Another User")
    }
    
    func testLoadStopsVerifyFormattedProperties() async throws {
        // Setup mock data
        mockSession.mockData = createMockSingleStopData()
        
        // Test that formatted properties work correctly
        let stops = try await networkService.loadStops()
        
        XCTAssertFalse(stops.isEmpty, "Stops should be loaded successfully")
        
        let stop = stops[0]
        
        // Test formatted time is not empty
        XCTAssertFalse(stop.formattedTime.isEmpty, "Formatted time should not be empty")
        
        // Test formatted price contains currency symbol
        XCTAssertTrue(stop.formattedPrice.contains("€"), "Formatted price should contain currency symbol")
        XCTAssertTrue(stop.formattedPrice.contains("25.50"), "Formatted price should contain the correct numeric value")
    }
    
    func testLoadStopsNetworkError() async throws {
        // Setup mock error
        mockSession.mockError = URLError(.timedOut)
        
        do {
            _ = try await networkService.loadStops()
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(error is URLError)
            let urlError = error as! URLError
            XCTAssertEqual(urlError.code, .timedOut)
        }
    }
    
    func testLoadStopsInvalidJSON() async throws {
        // Setup invalid JSON data
        mockSession.mockData = "{ invalid json }".data(using: .utf8)
        
        do {
            _ = try await networkService.loadStops()
            XCTFail("Should have thrown a decoding error")
        } catch {
            XCTAssertTrue(error is DecodingError)
        }
    }
    
    // MARK: - Integration Tests
    
    func testLoadTripsAndStopsDataAssociation() async throws {
        // Setup mock data for both endpoints
        mockSession.mockData = createMockTripsData()
        let trips = try await networkService.loadTrips()
        
        // Reset for stops call
        mockSession.mockData = createMockSingleStopData()
        let stops = try await networkService.loadStops()
        
        XCTAssertFalse(trips.isEmpty, "Trips should be loaded successfully")
        XCTAssertFalse(stops.isEmpty, "Stops should be loaded successfully")
        
        // Extract all trip IDs from trips
        let tripIds = Set(trips.compactMap { $0.id })
        
        // Verify stop references valid trip ID
        for stop in stops {
            XCTAssertTrue(tripIds.contains(stop.id), "Stop should reference a valid trip ID")
        }
    }
    
    // MARK: - URL Validation Tests
    
    func testLoadTripsCallsCorrectURL() async throws {
        mockSession.mockData = createMockTripsData()
        
        _ = try await networkService.loadTrips()
        
        XCTAssertEqual(mockSession.requestedURL?.absoluteString, testConfiguration.tripsURL)
    }
    
    func testLoadStopsCallsCorrectURL() async throws {
        mockSession.mockData = createMockSingleStopData()
        
        _ = try await networkService.loadStops()
        
        XCTAssertEqual(mockSession.requestedURL?.absoluteString, testConfiguration.stopsURL)
    }
    
    // MARK: - Edge Case Tests
    
    func testLoadTripsEmptyArray() async throws {
        mockSession.mockData = "[]".data(using: .utf8)
        
        let trips = try await networkService.loadTrips()
        
        XCTAssertTrue(trips.isEmpty, "Should handle empty array correctly")
    }
    
    func testLoadStopsEmptyArray() async throws {
        mockSession.mockData = "[]".data(using: .utf8)
        
        let stops = try await networkService.loadStops()
        
        XCTAssertTrue(stops.isEmpty, "Should handle empty array correctly")
    }
    
    func testInvalidURLError() async throws {
        // Create a configuration with invalid URLs
        struct InvalidURLConfiguration: NetworkConfigurationProtocol {
            let tripsURL = ""
            let stopsURL = ""
        }
        
        let invalidNetworkService = NetworkService(
            session: mockSession,
            configuration: InvalidURLConfiguration()
        )
        
        do {
            _ = try await invalidNetworkService.loadTrips()
            XCTFail("Should have thrown URLError.badURL")
        } catch {
            XCTAssertTrue(error is URLError)
            let urlError = error as! URLError
            XCTAssertEqual(urlError.code, .badURL)
        }
    }
    
   
    
    
}
