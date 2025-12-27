//
//  MainViewUITests.swift
//  SeatCodeTestUITests
//
//  Created on 27/12/25.
//

import XCTest

final class MainViewUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Basic UI Tests
    
    func testMainViewLoads() throws {
        // Verify main view title exists
        let mainViewTitle = app.navigationBars["Trip Manager"]
        XCTAssertTrue(mainViewTitle.waitForExistence(timeout: 5), "Main view should load with 'Trip Manager' title")
    }
    
    func testNavigationBarElements() throws {
        // Verify navigation bar exists
        let navigationBar = app.navigationBars["Trip Manager"]
        XCTAssertTrue(navigationBar.exists, "Navigation bar should exist")
        
        // Verify report button exists in toolbar
        let reportButton = app.buttons["exclamationmark.bubble"]
        XCTAssertTrue(reportButton.exists, "Report button should exist in toolbar")
    }
    
    // MARK: - Map View Tests
    
    func testMapViewExists() throws {
        // Check if map view is present (maps usually show as a generic element)
        let mapView = app.maps.element
        XCTAssertTrue(mapView.exists, "Map view should be present in the main view")
    }
    

    
    // MARK: - Trip List Tests
    
    func testTripListAreaExists() throws {
        // The trip list view should be present (may be empty initially)
        // We can check if the scroll view or list exists
        let scrollViews = app.scrollViews
        XCTAssertTrue(scrollViews.count > 0, "Should have scroll views for trip list area")
    }
    
    // MARK: - Contact Form Navigation Tests
    
    func testContactFormCanBeOpened() throws {
        let reportButton = app.buttons["exclamationmark.bubble"]
        XCTAssertTrue(reportButton.exists, "Report button should exist")
        
        reportButton.tap()
        
        // Verify contact form sheet appears
        let contactFormTitle = app.navigationBars["Report Issue"]
        XCTAssertTrue(contactFormTitle.waitForExistence(timeout: 3), "Contact form should be presented as sheet")
    }
    
    func testContactFormCanBeDismissed() throws {
        // Open contact form
        app.buttons["exclamationmark.bubble"].tap()
        
        // Wait for form to appear
        let contactFormTitle = app.navigationBars["Report Issue"]
        XCTAssertTrue(contactFormTitle.waitForExistence(timeout: 3), "Contact form should appear")
        
        // Dismiss with cancel button
        let cancelButton = app.buttons["Cancel"]
        XCTAssertTrue(cancelButton.exists, "Cancel button should exist")
        cancelButton.tap()
        
        // Verify we're back to main view
        let mainViewTitle = app.navigationBars["Trip Manager"]
        XCTAssertTrue(mainViewTitle.waitForExistence(timeout: 2), "Should return to main view")
    }
    
    // MARK: - Stop Detail Popup Tests
    
    func testStopDetailPopupAppearance() throws {
        // Note: This test would require triggering a stop selection on the map
        // which might be complex in UI tests. This is a placeholder for when
        // you have actual map data and can tap on a stop.
        
        // First, we need to ensure the app has loaded and there are stops available
        // This test might need to be updated based on how stops are displayed
        
        // For now, we can test that the main view is ready for interaction
        let mainView = app.navigationBars["Trip Manager"]
        XCTAssertTrue(mainView.exists, "Main view should be ready for stop selection")
    }
    
    func testAppLaunchPerformance() throws {
        // Measure the time it takes to launch the app
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
    
    // MARK: - Layout and Geometry Tests
    
    func testMainViewLayout() throws {
        // Verify that the main components are properly laid out
        let mapView = app.maps.element
        XCTAssertTrue(mapView.exists, "Map view should exist")
        
        // The map should be in the upper portion of the screen
        let mapFrame = mapView.frame
        let screenHeight = app.windows.firstMatch.frame.height
        
        // Map should be in upper portion (approximately top 40%)
        XCTAssertTrue(mapFrame.minY < screenHeight * 0.5, "Map should be in upper portion of screen")
    }
    
    func testViewHierarchy() throws {
        // Test that the main view components are properly structured
        XCTAssertTrue(app.navigationBars.count >= 1, "Should have at least one navigation bar")
        XCTAssertTrue(app.maps.count >= 1, "Should have at least one map view")
        XCTAssertTrue(app.buttons.count >= 1, "Should have at least one button (report button)")
    }
    

    
    // MARK: - State Management Tests
    
    func testViewStateAfterBackgroundAndForeground() throws {
        // Test that the view maintains its state after backgrounding
        let initialTitle = app.navigationBars["Trip Manager"]
        XCTAssertTrue(initialTitle.exists, "Initial state should be correct")
        
        // Send app to background and bring back to foreground
        XCUIDevice.shared.press(.home)
        app.activate()
        
        // Verify state is maintained
        XCTAssertTrue(initialTitle.exists, "State should be maintained after backgrounding")
    }
    
    func testRotationSupport() throws {
        // Test device rotation if supported
        XCUIDevice.shared.orientation = .landscapeLeft
        
        // Verify main view still works in landscape
        let mainViewTitle = app.navigationBars["Trip Manager"]
        XCTAssertTrue(mainViewTitle.exists, "Main view should work in landscape")
        
        // Rotate back to portrait
        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(mainViewTitle.exists, "Main view should work in portrait")
    }
}
