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
@MainActor
final class MockNetworkSession: NetworkSessionProtocol {
    private var _mockData: Data?
    private var _mockError: Error?
    private var _requestedURL: URL?
    
    var mockData: Data? {
        get { _mockData }
        set { _mockData = newValue }
    }
    
    var mockError: Error? {
        get { _mockError }
        set { _mockError = newValue }
    }
    
    var requestedURL: URL? {
        get { _requestedURL }
        set { _requestedURL = newValue }
    }
    
    func data(from url: URL) async throws -> (Data, URLResponse) {
        await MainActor.run {
            _requestedURL = url
        }
        
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
struct TestNetworkConfiguration: NetworkConfigurationProtocol, Sendable {
    let tripsURL = "https://test-api.com/trips.json"
    let stopsURL = "https://test-api.com/stops.json"
}

final class SeatCodeTestNetworkTests: XCTestCase {
    
    var networkService: NetworkService!
    var mockSession: MockNetworkSession!
    var testConfiguration: TestNetworkConfiguration!
    var decoder: JSONDecoder!
    var tripIdGenerator: TripIdGenerator!
    var stopDetailIdGenerator: StopDetailIdGenerator!
    
    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        mockSession = MockNetworkSession()
        testConfiguration = TestNetworkConfiguration()
        decoder = JSONDecoder()
        tripIdGenerator = TripIdGenerator()
        stopDetailIdGenerator = StopDetailIdGenerator()
        
        // Set up decoder with ID generators
        decoder.userInfo[.tripIdGenerator] = tripIdGenerator
        decoder.userInfo[.stopDetailIdGenerator] = stopDetailIdGenerator
        
        networkService = NetworkService(
            session: mockSession,
            configuration: testConfiguration,
            decoder: decoder
        )
    }
    
    @MainActor
    override func tearDown() async throws {
        // Clean up references explicitly
        networkService = nil
        mockSession = nil
        testConfiguration = nil
        decoder = nil
        tripIdGenerator = nil
        stopDetailIdGenerator = nil
        
        // Call super tearDown
        try await super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func createMockTripsData() -> Data {
        let jsonString = """
        [
            {
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
            "stopTime": "2024-01-01T09:30:00Z",
            "address": "123 Test Street, Test City",
            "userName": "Test User",
            "price": 25.50,
            "paid": true,
            "tripId": 1,
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
                "stopTime": "2024-01-01T09:30:00Z",
                "address": "123 Test Street, Test City",
                "userName": "Test User",
                "price": 25.50,
                "paid": true,
                "tripId": 1,
                "point": {
                    "_latitude": 40.7128,
                    "_longitude": -74.0060
                }
            },
            {
                "stopTime": "2024-01-01T14:15:00Z",
                "address": "456 Another Street, Another City",
                "userName": "Another User",
                "price": 30.75,
                "paid": false,
                "tripId": 2,
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
    
    @MainActor
    func testLoadTripsSuccess() async throws {
        // Setup mock data
        mockSession.mockData = createMockTripsData()
        
        // Test successful loading of trips
        let trips = try await networkService.loadTrips()
        
        // Verify the correct URL was called
        XCTAssertEqual(mockSession.requestedURL?.absoluteString, testConfiguration.tripsURL)
        
        XCTAssertFalse(trips.isEmpty, "Trips array should not be empty")
        XCTAssertEqual(trips.count, 2, "Should load 2 trips from mock data")
        
        // Verify first trip (IDs are now auto-generated, so they should be 1 and 2)
        let firstTrip = trips[0]
        XCTAssertEqual(firstTrip.id, 1, "First trip should have auto-generated ID 1")
        XCTAssertEqual(firstTrip.description, "Test Trip 1")
        XCTAssertEqual(firstTrip.driverName, "John Doe")
        XCTAssertEqual(firstTrip.route, "Route A")
        XCTAssertEqual(firstTrip.origin.address, "123 Start Street")
        XCTAssertEqual(firstTrip.destination.address, "456 End Avenue")
        
        // Verify coordinates
        let originCoord = firstTrip.origin.point.coordinate
        XCTAssertEqual(originCoord.latitude, 40.7128, accuracy: 0.0001)
        XCTAssertEqual(originCoord.longitude, -74.0060, accuracy: 0.0001)
        
        // Verify second trip has ID 2
        let secondTrip = trips[1]
        XCTAssertEqual(secondTrip.id, 2, "Second trip should have auto-generated ID 2")
        XCTAssertEqual(secondTrip.description, "Test Trip 2")
    }
    
    @MainActor
    func testLoadTripsVerifyTripStatus() async throws {
        // Setup mock data
        mockSession.mockData = createMockTripsData()
        
        // Test that trip statuses are properly decoded
        let trips = try await networkService.loadTrips()
        
        XCTAssertFalse(trips.isEmpty, "Trips should be loaded successfully")
        XCTAssertEqual(trips[0].status, .finalized)
        XCTAssertEqual(trips[1].status, .ongoing)
    }
    
    @MainActor
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
    
    @MainActor
    func testLoadTripsNetworkError() async throws {
        // Setup mock error
        mockSession.mockError = URLError(.notConnectedToInternet)
        
        do {
            _ = try await networkService.loadTrips()
            XCTFail("Should have thrown an error")
        } catch let networkError as NetworkError {
            // Verify it's wrapped in NetworkError.requestFailed
            switch networkError {
            case .requestFailed(let underlyingError):
                XCTAssertTrue(underlyingError is URLError)
            default:
                XCTFail("Expected NetworkError.requestFailed, got \(networkError)")
            }
        } catch {
            XCTFail("Expected NetworkError, got \(error)")
        }
    }
    
    @MainActor
    func testLoadTripsInvalidJSON() async throws {
        // Setup invalid JSON data
        mockSession.mockData = "invalid json".data(using: .utf8)
        
        do {
            _ = try await networkService.loadTrips()
            XCTFail("Should have thrown a decoding error")
        } catch let networkError as NetworkError {
            // Verify it's wrapped in NetworkError.decodingFailed
            switch networkError {
            case .decodingFailed:
                // Successfully caught the expected decodingFailed error
                break
            default:
                XCTFail("Expected NetworkError.decodingFailed, got \(networkError)")
            }
        } catch {
            XCTFail("Expected NetworkError, got \(error)")
        }
    }
    
    // MARK: - Stop Details Loading Tests
    
    @MainActor
    func testLoadStopsSuccessWithSingleStop() async throws {
        // Setup mock data for single stop (current API behavior)
        mockSession.mockData = createMockSingleStopData()
        
        // Test successful loading of stop details
        let stops = try await networkService.loadStops()
        
        // Verify the correct URL was called
        XCTAssertEqual(mockSession.requestedURL?.absoluteString, testConfiguration.stopsURL)
        
        XCTAssertFalse(stops.isEmpty, "Stops array should not be empty")
        XCTAssertEqual(stops.count, 1, "Should load 1 stop from single object mock data")
        
        // Verify stop properties (ID is now auto-generated)
        let stop = stops[0]
        XCTAssertEqual(stop.id, 1, "Stop should have auto-generated ID 1")
        XCTAssertEqual(stop.stopTime, "2024-01-01T09:30:00Z")
        XCTAssertEqual(stop.address, "123 Test Street, Test City")
        XCTAssertEqual(stop.userName, "Test User")
        XCTAssertEqual(stop.price, 25.50, accuracy: 0.01)
        XCTAssertEqual(stop.tripId, 1)
        
        // Verify coordinates
        let coord = stop.coordinate
        XCTAssertEqual(coord.latitude, 40.7128, accuracy: 0.0001)
        XCTAssertEqual(coord.longitude, -74.0060, accuracy: 0.0001)
    }
    
    @MainActor
    func testLoadStopsSuccessWithMultipleStops() async throws {
        // Setup mock data for multiple stops (future API behavior)
        mockSession.mockData = createMockMultipleStopsData()
        
        // Test successful loading of multiple stop details
        let stops = try await networkService.loadStops()
        
        XCTAssertFalse(stops.isEmpty, "Stops array should not be empty")
        XCTAssertEqual(stops.count, 2, "Should load 2 stops from array mock data")
        
        // Verify first stop (ID is now auto-generated)
        let firstStop = stops[0]
        XCTAssertEqual(firstStop.id, 1, "First stop should have auto-generated ID 1")
        XCTAssertEqual(firstStop.userName, "Test User")
        XCTAssertEqual(firstStop.tripId, 1)
        
        // Verify second stop
        let secondStop = stops[1]
        XCTAssertEqual(secondStop.id, 2, "Second stop should have auto-generated ID 2")
        XCTAssertEqual(secondStop.userName, "Another User")
        XCTAssertEqual(secondStop.tripId, 2)
    }
    
    @MainActor
    func testLoadStopsVerifyFormattedProperties() async throws {
        // Setup mock data
        mockSession.mockData = createMockSingleStopData()
        
        // Test that formatted properties work correctly
        let stops = try await networkService.loadStops()
        
        XCTAssertFalse(stops.isEmpty, "Stops should be loaded successfully")
        
        let stop = stops[0]
        
        // Test formatted time is not empty
        XCTAssertFalse(stop.stopTime.formatTime().isEmpty, "Formatted time should not be empty")
        
        // Test formatted price contains currency symbol
        let priceString = String(stop.price)
        let formattedPrice = priceString.formatPrice()
        XCTAssertTrue(formattedPrice.contains("€"), "Formatted price should contain currency symbol")
        XCTAssertTrue(formattedPrice.contains("25.50"), "Formatted price should contain the correct numeric value")
    }
    
    @MainActor
    func testLoadStopsNetworkError() async throws {
        // Setup mock error
        mockSession.mockError = URLError(.timedOut)
        
        do {
            _ = try await networkService.loadStops()
            XCTFail("Should have thrown an error")
        } catch let networkError as NetworkError {
            // Verify it's wrapped in NetworkError.requestFailed
            switch networkError {
            case .requestFailed(let underlyingError):
                XCTAssertTrue(underlyingError is URLError)
                let urlError = underlyingError as! URLError
                XCTAssertEqual(urlError.code, .timedOut)
            default:
                XCTFail("Expected NetworkError.requestFailed, got \(networkError)")
            }
        } catch {
            XCTFail("Expected NetworkError, got \(error)")
        }
    }
    
    @MainActor
    func testLoadStopsInvalidJSON() async throws {
        // Setup invalid JSON data
        mockSession.mockData = "{ invalid json }".data(using: .utf8)
        
        do {
            _ = try await networkService.loadStops()
            XCTFail("Should have thrown a decoding error")
        } catch let networkError as NetworkError {
            // Verify it's wrapped in NetworkError.decodingFailed
            switch networkError {
            case .decodingFailed:
                // Successfully caught the expected decodingFailed error
                break
            default:
                XCTFail("Expected NetworkError.decodingFailed, got \(networkError)")
            }
        } catch {
            XCTFail("Expected NetworkError, got \(error)")
        }
    }
    
    // MARK: - Integration Tests
    
    @MainActor
    func testLoadTripsAndStopsDataAssociation() async throws {
        // Setup mock data for both endpoints
        mockSession.mockData = createMockTripsData()
        let trips = try await networkService.loadTrips()
        
        // Reset ID generators to ensure clean IDs for stops test
        tripIdGenerator.reset()
        stopDetailIdGenerator.reset()
        
        // Reset for stops call
        mockSession.mockData = createMockSingleStopData()
        let stops = try await networkService.loadStops()
        
        XCTAssertFalse(trips.isEmpty, "Trips should be loaded successfully")
        XCTAssertFalse(stops.isEmpty, "Stops should be loaded successfully")
        
        // Extract all trip IDs from trips (these will be auto-generated: 1, 2)
        let tripIds = Set(trips.compactMap { $0.id })
        
        // Verify stop references valid trip ID from the tripId field in the JSON
        for stop in stops {
            // The stop.tripId comes from the JSON data and should reference a valid trip
            // Note: In the mock data, we have tripId: 1, which should match one of our generated trip IDs
            XCTAssertTrue(tripIds.contains(stop.tripId), "Stop should reference a valid trip ID. Stop tripId: \(stop.tripId), Available trip IDs: \(tripIds)")
        }
    }
    
    // MARK: - URL Validation Tests
    
    @MainActor
    func testLoadTripsCallsCorrectURL() async throws {
        mockSession.mockData = createMockTripsData()
        
        _ = try await networkService.loadTrips()
        
        XCTAssertEqual(mockSession.requestedURL?.absoluteString, testConfiguration.tripsURL)
    }
    
    @MainActor
    func testLoadStopsCallsCorrectURL() async throws {
        mockSession.mockData = createMockSingleStopData()
        
        _ = try await networkService.loadStops()
        
        XCTAssertEqual(mockSession.requestedURL?.absoluteString, testConfiguration.stopsURL)
    }
    
    // MARK: - Edge Case Tests
    
    @MainActor
    func testLoadTripsEmptyArray() async throws {
        mockSession.mockData = "[]".data(using: .utf8)
        
        let trips = try await networkService.loadTrips()
        
        XCTAssertTrue(trips.isEmpty, "Should handle empty array correctly")
    }
    
    @MainActor
    func testLoadStopsEmptyArray() async throws {
        mockSession.mockData = "[]".data(using: .utf8)
        
        let stops = try await networkService.loadStops()
        
        XCTAssertTrue(stops.isEmpty, "Should handle empty array correctly")
    }
    
    @MainActor
    func testInvalidURLError() async throws {
        // Create a configuration with invalid URLs
        struct InvalidURLConfiguration: NetworkConfigurationProtocol, Sendable {
            let tripsURL = ""
            let stopsURL = ""
        }
        
        let invalidNetworkService = NetworkService(
            session: mockSession,
            configuration: InvalidURLConfiguration(),
            decoder: decoder
        )
        
        do {
            _ = try await invalidNetworkService.loadTrips()
            XCTFail("Should have thrown NetworkError.invalidURL")
        } catch let networkError as NetworkError {
            switch networkError {
            case .invalidURL:
                // This is expected
                break
            default:
                XCTFail("Expected NetworkError.invalidURL, got \(networkError)")
            }
        } catch {
            XCTFail("Expected NetworkError, got \(error)")
        }
    }
    
    // MARK: - ID Generation Tests
    
    @MainActor
    func testTripIdGenerationIsSequential() async throws {
        // Setup mock data
        mockSession.mockData = createMockTripsData()
        
        // Load trips twice to verify ID generation is sequential
        let firstBatch = try await networkService.loadTrips()
        let secondBatch = try await networkService.loadTrips()
        
        XCTAssertEqual(firstBatch.count, 2)
        XCTAssertEqual(secondBatch.count, 2)
        
        // First batch should have IDs 1, 2
        XCTAssertEqual(firstBatch[0].id, 1)
        XCTAssertEqual(firstBatch[1].id, 2)
        
        // Second batch should continue with IDs 3, 4
        XCTAssertEqual(secondBatch[0].id, 3)
        XCTAssertEqual(secondBatch[1].id, 4)
    }
    
    @MainActor
    func testStopDetailIdGenerationIsSequential() async throws {
        // Setup mock data
        mockSession.mockData = createMockMultipleStopsData()
        
        // Load stops twice to verify ID generation is sequential
        let firstBatch = try await networkService.loadStops()
        let secondBatch = try await networkService.loadStops()
        
        XCTAssertEqual(firstBatch.count, 2)
        XCTAssertEqual(secondBatch.count, 2)
        
        // First batch should have IDs 1, 2
        XCTAssertEqual(firstBatch[0].id, 1)
        XCTAssertEqual(firstBatch[1].id, 2)
        
        // Second batch should continue with IDs 3, 4
        XCTAssertEqual(secondBatch[0].id, 3)
        XCTAssertEqual(secondBatch[1].id, 4)
    }
    
    @MainActor
    func testIdGeneratorsCanBeReset() async throws {
        // Load some trips first
        mockSession.mockData = createMockTripsData()
        let firstTrips = try await networkService.loadTrips()
        XCTAssertEqual(firstTrips[0].id, 1)
        XCTAssertEqual(firstTrips[1].id, 2)
        
        // Reset the generator and update the decoder
        tripIdGenerator.reset()
        decoder.userInfo[.tripIdGenerator] = tripIdGenerator
        
        // Create a new network service with the updated decoder
        networkService = NetworkService(
            session: mockSession,
            configuration: testConfiguration,
            decoder: decoder
        )
        
        // Load trips again, should start from 1
        let secondTrips = try await networkService.loadTrips()
        XCTAssertEqual(secondTrips[0].id, 1)
        XCTAssertEqual(secondTrips[1].id, 2)
    }
    
    func testNetworkErrorDescriptions() throws {
        let invalidURLError = NetworkError.invalidURL
        let decodingError = NetworkError.decodingFailed(DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Test")))
        let requestError = NetworkError.requestFailed(URLError(.notConnectedToInternet))
        
        XCTAssertEqual(invalidURLError.errorDescription, "The provided URL is invalid")
        XCTAssertTrue(decodingError.errorDescription?.contains("Failed to decode data") == true)
        XCTAssertTrue(requestError.errorDescription?.contains("Network request failed") == true)
    }
    
   
    
    
}
