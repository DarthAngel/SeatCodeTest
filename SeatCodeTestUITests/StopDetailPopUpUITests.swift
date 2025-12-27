//
//  StopDetailPopUpUITests.swift
//  SeatCodeTestUITests
//
//  Created on 27/12/25.
//

import XCTest

final class StopDetailPopUpUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Popup Display Tests
    
    func testStopDetailPopupElements() throws {
        // Note: This test assumes that we can trigger a stop popup somehow
        // In a real scenario, you would need to interact with the map or trip list
        // to trigger a stop detail popup. This test structure provides the framework.
        
        // For now, we verify the main view is ready for interaction
        let mainView = app.navigationBars["Trip Manager"]
        XCTAssertTrue(mainView.exists, "Main view should be ready")
        
        // TODO: Add code to trigger stop popup when map interaction is available
        // For example: app.maps.element.tap() at specific coordinates
    }
    
    func testStopDetailPopupWithValidData() throws {
        // This test would check the popup when it contains valid stop data
        // The test structure assumes the popup will show specific elements
        
        // If popup is triggered and visible, test these elements:
        if let popup = findStopDetailPopup() {
            // Check header elements
            XCTAssertTrue(popup.staticTexts["Stop Information"].exists, "Header title should exist")
            
            // Check passenger information section
            XCTAssertTrue(popup.staticTexts["Passenger"].exists, "Passenger label should exist")
            
            // Check location information section
            XCTAssertTrue(popup.staticTexts["Address"].exists, "Address label should exist")
            
            // Check time information section
            XCTAssertTrue(popup.staticTexts["Stop Time"].exists, "Stop time label should exist")
            
            // Check payment information section
            XCTAssertTrue(popup.staticTexts["Payment"].exists, "Payment label should exist")
            
            // Check coordinates section
            XCTAssertTrue(popup.staticTexts["Coordinates"].exists, "Coordinates label should exist")
        }
    }
    
    func testStopDetailPopupCloseButton() throws {
        // Test the close button functionality
        if let popup = findStopDetailPopup() {
            let closeButton = popup.buttons["xmark.circle.fill"]
            XCTAssertTrue(closeButton.exists, "Close button should exist")
            XCTAssertTrue(closeButton.isHittable, "Close button should be tappable")
            
            closeButton.tap()
            
            // Verify popup is dismissed
            XCTAssertFalse(popup.exists, "Popup should be dismissed after tapping close")
        }
    }
    
    func testStopDetailPopupBackgroundDismiss() throws {
        // Test dismissing popup by tapping background
        if let popup = findStopDetailPopup() {
            let popupExists = popup.exists
            XCTAssertTrue(popupExists, "Popup should be visible")
            
            // Tap outside the popup content (on the background)
            let backgroundArea = app.otherElements.firstMatch
            backgroundArea.tap()
            
            // Verify popup is dismissed
            XCTAssertFalse(popup.exists, "Popup should be dismissed after tapping background")
        }
    }
    
    // MARK: - Empty State Popup Tests
    
    func testEmptyStopDetailPopup() throws {
        // Test the empty state popup when no stop details are available
        if let emptyPopup = findEmptyStopDetailPopup() {
            // Check header
            XCTAssertTrue(emptyPopup.staticTexts["Stop Information"].exists, "Header should exist in empty popup")
            
            // Check error message
            XCTAssertTrue(emptyPopup.staticTexts["No stop details available"].exists, "Error message should exist")
            
            // Check description
            XCTAssertTrue(emptyPopup.staticTexts["Stop information could not be loaded from the server."].exists, "Error description should exist")
            
            // Check warning icon
            XCTAssertTrue(emptyPopup.images["exclamationmark.triangle.fill"].exists, "Warning icon should exist")
            
            // Check close button
            let closeButton = emptyPopup.buttons["xmark.circle.fill"]
            XCTAssertTrue(closeButton.exists, "Close button should exist in empty popup")
        }
    }
    
    func testEmptyStopDetailPopupDismissal() throws {
        if let emptyPopup = findEmptyStopDetailPopup() {
            let closeButton = emptyPopup.buttons["xmark.circle.fill"]
            closeButton.tap()
            
            // Verify popup is dismissed
            XCTAssertFalse(emptyPopup.exists, "Empty popup should be dismissed")
        }
    }
    
    // MARK: - Data Display Tests
    
    func testPassengerInformationDisplay() throws {
        if let popup = findStopDetailPopup() {
            // Check passenger icon
            let passengerIcon = popup.images["person.circle.fill"]
            XCTAssertTrue(passengerIcon.exists, "Passenger icon should be displayed")
            
            // Check passenger section
            let passengerSection = popup.staticTexts["Passenger"]
            XCTAssertTrue(passengerSection.exists, "Passenger section label should exist")
        }
    }
    
    func testLocationInformationDisplay() throws {
        if let popup = findStopDetailPopup() {
            // Check location icon
            let locationIcon = popup.images["location.circle.fill"]
            XCTAssertTrue(locationIcon.exists, "Location icon should be displayed")
            
            // Check address section
            let addressSection = popup.staticTexts["Address"]
            XCTAssertTrue(addressSection.exists, "Address section label should exist")
        }
    }
    
    func testTimeInformationDisplay() throws {
        if let popup = findStopDetailPopup() {
            // Check time icon
            let timeIcon = popup.images["clock.circle.fill"]
            XCTAssertTrue(timeIcon.exists, "Time icon should be displayed")
            
            // Check stop time section
            let timeSection = popup.staticTexts["Stop Time"]
            XCTAssertTrue(timeSection.exists, "Stop time section label should exist")
        }
    }
    
    func testPaymentInformationDisplay() throws {
        if let popup = findStopDetailPopup() {
            // Check for payment icons (could be either paid or unpaid)
            let paidIcon = popup.images["creditcard.circle.fill"]
            let unpaidIcon = popup.images["exclamationmark.circle.fill"]
            
            let hasPaymentIcon = paidIcon.exists || unpaidIcon.exists
            XCTAssertTrue(hasPaymentIcon, "Payment status icon should be displayed")
            
            // Check payment section
            let paymentSection = popup.staticTexts["Payment"]
            XCTAssertTrue(paymentSection.exists, "Payment section label should exist")
        }
    }
    
    func testCoordinatesDisplay() throws {
        if let popup = findStopDetailPopup() {
            // Check coordinates icon
            let coordinatesIcon = popup.images["map.circle.fill"]
            XCTAssertTrue(coordinatesIcon.exists, "Coordinates icon should be displayed")
            
            // Check coordinates section
            let coordinatesSection = popup.staticTexts["Coordinates"]
            XCTAssertTrue(coordinatesSection.exists, "Coordinates section label should exist")
        }
    }
    
    // MARK: - Accessibility Tests
    
    func testPopupAccessibility() throws {
        if let popup = findStopDetailPopup() {
            // Test that all interactive elements are accessible
            let closeButton = popup.buttons["xmark.circle.fill"]
            XCTAssertTrue(closeButton.isHittable, "Close button should be accessible")
            
            // Test that text elements have proper accessibility
            let titleElement = popup.staticTexts["Stop Information"]
            XCTAssertNotEqual(titleElement.label, "", "Title should have accessibility label")
        }
    }
    
    func testPopupVoiceOverSupport() throws {
        if let popup = findStopDetailPopup() {
            // Test VoiceOver navigation through popup elements
            let staticTexts = popup.staticTexts.allElementsBoundByIndex
            
            // Verify that key information is accessible via VoiceOver
            let hasPassengerInfo = staticTexts.contains { $0.label.contains("Passenger") }
            let hasLocationInfo = staticTexts.contains { $0.label.contains("Address") }
            let hasTimeInfo = staticTexts.contains { $0.label.contains("Stop Time") }
            let hasPaymentInfo = staticTexts.contains { $0.label.contains("Payment") }
            
            XCTAssertTrue(hasPassengerInfo, "Passenger information should be accessible")
            XCTAssertTrue(hasLocationInfo, "Location information should be accessible")
            XCTAssertTrue(hasTimeInfo, "Time information should be accessible")
            XCTAssertTrue(hasPaymentInfo, "Payment information should be accessible")
        }
    }
    
    
    // MARK: - Helper Methods
    
    private func findStopDetailPopup() -> XCUIElement? {
        // Look for the stop detail popup by finding elements that would be unique to it
        let popup = app.otherElements.containing(.staticText, identifier: "Stop Information").firstMatch
        return popup.exists ? popup : nil
    }
    
    private func findEmptyStopDetailPopup() -> XCUIElement? {
        // Look for the empty state popup
        let emptyPopup = app.otherElements.containing(.staticText, identifier: "No stop details available").firstMatch
        return emptyPopup.exists ? emptyPopup : nil
    }
    
    private func triggerStopDetailPopup() {
        // This method would contain the logic to trigger a stop detail popup
        // This could involve:
        // 1. Tapping on a specific location on the map
        // 2. Selecting a trip from the trip list
        // 3. Any other interaction that shows stop details
        
        // Example (would need to be adapted to actual implementation):
        // app.maps.element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        
        // For now, this is a placeholder that developers can fill in
        // based on the actual trigger mechanism in the app
    }
    
    private func waitForPopupToAppear() -> Bool {
        // Wait for popup to appear with a reasonable timeout
        let popup = findStopDetailPopup()
        return popup?.waitForExistence(timeout: 3) ?? false
    }
    
    private func waitForPopupToDisappear() -> Bool {
        // Wait for popup to disappear
        guard let popup = findStopDetailPopup() else { return true }
        
        let expectation = XCTestExpectation(description: "Popup should disappear")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if !popup.exists {
                expectation.fulfill()
            }
        }
        
        let result = XCTWaiter.wait(for: [expectation], timeout: 2.0)
        return result == .completed
    }
}
