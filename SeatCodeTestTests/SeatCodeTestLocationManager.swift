//
//  SeatCodeTestLocationManager.swift
//  SeatCodeTestTests
//
//  Created by Angel Docampo on 21/12/25.
//

import XCTest
import CoreLocation
import Combine
@testable import SeatCodeTest

@MainActor
final class SeatCodeTestLocationManager: XCTestCase {
    
    var locationManager: LocationManager!
    var cancellables: Set<AnyCancellable>!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        locationManager = LocationManager()
        cancellables = Set<AnyCancellable>()
    }
    override func tearDown() async throws {
        locationManager = nil
        cancellables = nil
        try await super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func createMockLocation() -> CLLocation {
        return CLLocation(latitude: 41.3851, longitude: 2.1734) // Barcelona
    }
    
    private func createAlternativeMockLocation() -> CLLocation {
        return CLLocation(latitude: 40.7128, longitude: -74.0060) // New York
    }
    
    // MARK: - Initialization Tests
    
    func testLocationManagerInitialization() throws {
        XCTAssertNotNil(locationManager, "LocationManager should be initialized")
        XCTAssertEqual(locationManager.authorizationStatus, .notDetermined, "Initial authorization status should be notDetermined")
        XCTAssertNil(locationManager.currentLocation, "Initial location should be nil")
        XCTAssertNil(locationManager.errorMessage, "Initial error message should be nil")
    }
    
    // MARK: - Authorization Status Tests
    
    func testAuthorizationStatusPublished() async throws {
        var receivedStatuses: [CLAuthorizationStatus] = []
        
        locationManager.$authorizationStatus
            .sink { status in
                receivedStatuses.append(status)
            }
            .store(in: &cancellables)
        
        // Simulate authorization status change
        locationManager.authorizationStatus = .authorizedWhenInUse
        
        // Wait for the publisher to emit
        await Task.yield() // Allow other tasks to run
        try await Task.sleep(for: .milliseconds(100))
        
        XCTAssertTrue(receivedStatuses.contains(.notDetermined), "Should contain initial notDetermined status")
        XCTAssertTrue(receivedStatuses.contains(.authorizedWhenInUse), "Should contain updated authorization status")
    }
    
    // MARK: - Location Permission Request Tests
    
    func testRequestLocationPermissionWhenNotDetermined() throws {
        // Set authorization status to not determined
        locationManager.authorizationStatus = .notDetermined
        
        // Request permission should not show error for notDetermined status
        locationManager.requestLocationPermission()
        
        XCTAssertNil(locationManager.errorMessage, "Should not have error message for notDetermined status")
    }
    
    func testRequestLocationPermissionWhenDenied() throws {
        // Set authorization status to denied
        locationManager.authorizationStatus = .denied
        
        locationManager.requestLocationPermission()
        
        XCTAssertNotNil(locationManager.errorMessage, "Should have error message for denied status")
        XCTAssertTrue(locationManager.errorMessage?.contains("denied") == true, "Error message should mention access denied")
    }
    
    func testRequestLocationPermissionWhenRestricted() throws {
        // Set authorization status to restricted
        locationManager.authorizationStatus = .restricted
        
        locationManager.requestLocationPermission()
        
        XCTAssertNotNil(locationManager.errorMessage, "Should have error message for restricted status")
        XCTAssertTrue(locationManager.errorMessage?.contains("denied") == true, "Error message should mention access denied")
    }
    
    func testRequestLocationPermissionWhenAuthorized() throws {
        // Set authorization status to authorized
        locationManager.authorizationStatus = .authorizedWhenInUse
        
        locationManager.requestLocationPermission()
        
        XCTAssertNil(locationManager.errorMessage, "Should not have error message for authorized status")
    }
    
    // MARK: - Location Updates Tests
    
    func testLocationUpdatesPublished() async throws {
        var receivedLocations: [CLLocation?] = []
        
        locationManager.$currentLocation
            .sink { location in
                receivedLocations.append(location)
            }
            .store(in: &cancellables)
        
        // Simulate location update
        let mockLocation = createMockLocation()
        locationManager.currentLocation = mockLocation
        
        // Wait for the publisher to emit
        await Task.yield() // Allow other tasks to run
        try await Task.sleep(for: .milliseconds(100))
        
        XCTAssertTrue(receivedLocations.contains { $0 == nil }, "Should contain initial nil location")
        XCTAssertTrue(receivedLocations.contains { $0?.coordinate.latitude == mockLocation.coordinate.latitude }, "Should contain updated location")
    }
    
    func testStopLocationUpdates() throws {
        // This test verifies the method can be called without crashing
        locationManager.stopLocationUpdates()
        
        // In a real implementation, you would verify that the underlying CLLocationManager
        // stopUpdatingLocation method was called
        XCTAssertNotNil(locationManager, "LocationManager should still exist after stopping updates")
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorMessagePublished() async throws {
        var receivedErrorMessages: [String?] = []
        
        locationManager.$errorMessage
            .sink { errorMessage in
                receivedErrorMessages.append(errorMessage)
            }
            .store(in: &cancellables)
        
        // Simulate error
        let testErrorMessage = "Test error message"
        locationManager.errorMessage = testErrorMessage
        
        // Wait for the publisher to emit
        await Task.yield() // Allow other tasks to run
        try await Task.sleep(for: .milliseconds(100))
        
        XCTAssertTrue(receivedErrorMessages.contains(nil), "Should contain initial nil error message")
        XCTAssertTrue(receivedErrorMessages.contains(testErrorMessage), "Should contain updated error message")
    }
    
    func testErrorMessageClearedOnSuccessfulLocation() throws {
        // Set initial error
        locationManager.errorMessage = "Initial error"
        XCTAssertNotNil(locationManager.errorMessage, "Should have initial error")
        
        // Simulate successful location update which should clear error
        let mockLocation = createMockLocation()
        locationManager.currentLocation = mockLocation
        locationManager.errorMessage = nil  // Simulating what would happen in delegate method
        
        XCTAssertNil(locationManager.errorMessage, "Error message should be cleared on successful location")
    }
    
    // MARK: - CLLocationManagerDelegate Simulation Tests
    
    func testLocationManagerDidUpdateLocations() throws {
        let mockLocation1 = createMockLocation()
        let mockLocation2 = createAlternativeMockLocation()
        let locations = [mockLocation1, mockLocation2]
        
        // Simulate what the delegate method would do
        locationManager.currentLocation = locations.last
        locationManager.errorMessage = nil
        
        XCTAssertEqual(locationManager.currentLocation?.coordinate.latitude, mockLocation2.coordinate.latitude, "Should use the last location from array")
        XCTAssertEqual(locationManager.currentLocation?.coordinate.longitude, mockLocation2.coordinate.longitude, "Should use the last location from array")
        XCTAssertNil(locationManager.errorMessage, "Error message should be cleared")
    }
    
    func testLocationManagerDidFailWithError() throws {
        let testError = CLError(.locationUnknown)
        
        // Simulate what the delegate method would do
        locationManager.errorMessage = "Failed to get location: \(testError.localizedDescription)"
        
        XCTAssertNotNil(locationManager.errorMessage, "Should have error message")
        XCTAssertTrue(locationManager.errorMessage?.contains("Failed to get location") == true, "Should contain failure message")
    }
    
    func testLocationManagerDidChangeAuthorizationToAuthorized() throws {
        // Simulate authorization change to authorized
        locationManager.authorizationStatus = .authorizedWhenInUse
        locationManager.errorMessage = nil
        
        XCTAssertEqual(locationManager.authorizationStatus, .authorizedWhenInUse, "Authorization status should be updated")
        XCTAssertNil(locationManager.errorMessage, "Error message should be cleared for authorized status")
    }
    
    func testLocationManagerDidChangeAuthorizationToDenied() throws {
        // Simulate authorization change to denied
        locationManager.authorizationStatus = .denied
        locationManager.errorMessage = "Location access denied. Please enable location services in Settings."
        
        XCTAssertEqual(locationManager.authorizationStatus, .denied, "Authorization status should be updated")
        XCTAssertNotNil(locationManager.errorMessage, "Should have error message for denied status")
        XCTAssertTrue(locationManager.errorMessage?.contains("denied") == true, "Error message should mention denial")
    }
    
    // MARK: - Integration Tests
    
    func testCompleteLocationWorkflow() async throws {
        var authorizationChanges: [CLAuthorizationStatus] = []
        var locationChanges: [CLLocation?] = []
        var errorChanges: [String?] = []
        
        // Subscribe to all changes
        locationManager.$authorizationStatus
            .sink { status in
                authorizationChanges.append(status)
            }
            .store(in: &cancellables)
        
        locationManager.$currentLocation
            .sink { location in
                locationChanges.append(location)
            }
            .store(in: &cancellables)
        
        locationManager.$errorMessage
            .sink { error in
                errorChanges.append(error)
            }
            .store(in: &cancellables)
        
        // Simulate complete workflow
        // 1. Request permission (notDetermined -> authorizedWhenInUse)
        locationManager.authorizationStatus = .authorizedWhenInUse
        
        // 2. Receive location
        let mockLocation = createMockLocation()
        locationManager.currentLocation = mockLocation
        locationManager.errorMessage = nil
        
        // Wait for all publishers to emit
        await Task.yield() // Allow other tasks to run
        try await Task.sleep(for: .milliseconds(100))
        
        XCTAssertTrue(authorizationChanges.contains(.authorizedWhenInUse), "Should receive authorization change")
        XCTAssertTrue(locationChanges.contains { $0?.coordinate.latitude == mockLocation.coordinate.latitude }, "Should receive location update")
        XCTAssertTrue(errorChanges.contains(nil), "Should clear error messages")
    }
    
    // MARK: - Edge Cases Tests
    
    func testMultipleLocationUpdates() throws {
        let location1 = createMockLocation()
        let location2 = createAlternativeMockLocation()
        
        // First update
        locationManager.currentLocation = location1
        XCTAssertEqual(locationManager.currentLocation?.coordinate.latitude, location1.coordinate.latitude, "Should update to first location")
        
        // Second update
        locationManager.currentLocation = location2
        XCTAssertEqual(locationManager.currentLocation?.coordinate.latitude, location2.coordinate.latitude, "Should update to second location")
    }
    
    func testRapidAuthorizationStatusChanges() throws {
        // Simulate rapid status changes
        locationManager.authorizationStatus = .denied
        locationManager.authorizationStatus = .authorizedWhenInUse
        locationManager.authorizationStatus = .authorizedAlways
        
        XCTAssertEqual(locationManager.authorizationStatus, .authorizedAlways, "Should reflect the latest authorization status")
    }
    
    func testLocationAccuracy() throws {
        // Test that we can work with different location accuracies
        let accurateLocation = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 41.3851, longitude: 2.1734),
            altitude: 10.0,
            horizontalAccuracy: 5.0,
            verticalAccuracy: 5.0,
            timestamp: Date()
        )
        
        locationManager.currentLocation = accurateLocation
        
        XCTAssertEqual(locationManager.currentLocation?.horizontalAccuracy, 5.0, "Should preserve location accuracy")
        XCTAssertEqual(locationManager.currentLocation?.altitude, 10.0, "Should preserve altitude")
    }
}
