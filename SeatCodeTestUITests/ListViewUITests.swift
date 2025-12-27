//
//  ReportsListViewUITests.swift
//  SeatCodeTestUITests
//
//  Created on 27/12/25.
//

import XCTest

final class ReportsListViewUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Navigation Tests
    
    func testNavigateToReportsListFromContactForm() throws {
        // Open contact form
        app.buttons["exclamationmark.bubble"].tap()
        
        // Tap view reports button
        let viewReportsButton = app.buttons["View previously submitted reports"]
        XCTAssertTrue(viewReportsButton.waitForExistence(timeout: 2), "View reports button should exist")
        viewReportsButton.tap()
        
        // Verify reports list is presented
        let reportsTitle = app.navigationBars["All Reports"]
        XCTAssertTrue(reportsTitle.waitForExistence(timeout: 3), "Reports list should be presented")
    }
    
    func testReportsListCanBeDismissed() throws {
        // Navigate to reports list
        navigateToReportsList()
        
        // Tap done button
        let doneButton = app.buttons["Done"]
        XCTAssertTrue(doneButton.exists, "Done button should exist")
        doneButton.tap()
        
        // Verify we're back to contact form
        let contactFormTitle = app.navigationBars["Report Issue"]
        XCTAssertTrue(contactFormTitle.waitForExistence(timeout: 2), "Should return to contact form")
    }
    

    
    func testReportRowDisplaysCorrectInformation() throws {
        // Submit a test report first
        submitTestReport()
        
        // Navigate to reports list
        navigateToReportsList()
        
        // Verify report information is displayed directly in the view
        XCTAssertTrue(app.staticTexts["John Doe"].waitForExistence(timeout: 2), "Name should be displayed")
        XCTAssertTrue(app.staticTexts["john.doe@example.com"].exists, "Email should be displayed")
        XCTAssertTrue(app.staticTexts["Test report description"].exists, "Description should be displayed")
    }
    
    // MARK: - Edit Mode and Deletion Tests
    
    func testEditButtonAppearsWhenReportsExist() throws {
        // Submit a test report first
        submitTestReport()
        
        // Navigate to reports list
        navigateToReportsList()
        
        // Check for edit button
        let editButton = app.buttons["Edit"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 2), "Edit button should appear when reports exist")
    }
    
    func testEditModeCanBeActivated() throws {
        // Submit a test report first
        submitTestReport()
        
        // Navigate to reports list
        navigateToReportsList()
        
        // Tap edit button
        let editButton = app.buttons["Edit"]
        editButton.tap()
        
        // Verify edit mode is active (Done button should appear)
        let doneEditButton = app.buttons["Done"]
        XCTAssertTrue(doneEditButton.exists, "Done button should replace Edit button in edit mode")
    }
    
    
    // MARK: - Date and Time Display Tests
    
    func testDateTimeFormatting() throws {
        // Submit a test report
        submitTestReport()
        
        // Navigate to reports list
        navigateToReportsList()
        
        // Check that date and time are properly formatted
        XCTAssertTrue(app.staticTexts["John Doe"].exists, "Report should exist")
        
        // Look for date-related text in the view - SwiftUI automatically formats dates
        let hasDateText = app.staticTexts.allElementsBoundByIndex.contains { element in
            let label = element.label
            // Check for common date patterns (month names, day numbers, etc.)
            return label.contains("/") || label.contains(",") || 
                   ["Jan", "Feb", "Mar", "Apr", "May", "Jun", 
                    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"].contains { label.contains($0) }
        }
        XCTAssertTrue(hasDateText, "Date should be displayed somewhere in the report view")
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilityElements() throws {
        // Navigate to reports list
        navigateToReportsList()
        
        // Check navigation bar accessibility
        let navigationBar = app.navigationBars["All Reports"]
        XCTAssertTrue(navigationBar.exists, "Navigation bar should be accessible")
        
        let doneButton = app.buttons["Done"]
        XCTAssertTrue(doneButton.isHittable, "Done button should be accessible")
    }
    

    
    // MARK: - Helper Methods
    
    private func navigateToReportsList() {
        // Open contact form
        app.buttons["exclamationmark.bubble"].tap()
        
        // Wait for contact form to appear - improved debugging
        let contactFormTitle = app.navigationBars["Report Issue"]
        let nameField = app.textFields["Name*"]
        
        // Try to wait for either the navigation bar or form fields
        let formAppeared = contactFormTitle.waitForExistence(timeout: 3) || nameField.waitForExistence(timeout: 3)
        
        if !formAppeared {
            print("Contact form debugging - Available navigation bars:")
            for navBar in app.navigationBars.allElementsBoundByIndex {
                if navBar.exists {
                    print("- NavBar: '\(navBar.identifier)' / '\(navBar.label)'")
                }
            }
            print("Available text fields:")
            for field in app.textFields.allElementsBoundByIndex {
                if field.exists {
                    print("- TextField: '\(field.identifier)' / '\(field.label)'")
                }
            }
            XCTFail("Contact form should appear - neither navigation bar nor form fields found")
        }
        
        // Look for the view reports button - it might be in a different form structure
        // Try different ways to access the button
        var viewReportsButton: XCUIElement?
        
        // Try as a regular button
        viewReportsButton = app.buttons["View previously submitted reports"]
        
        // If not found, try looking in static texts (might be a SwiftUI Text button)
        if !viewReportsButton!.exists {
            viewReportsButton = app.staticTexts["View previously submitted reports"]
        }
        
        // If still not found, try scrolling to find it
        if !viewReportsButton!.exists {
            // Scroll down to find the button
            app.swipeUp()
            viewReportsButton = app.buttons["View previously submitted reports"]
        }
        
        XCTAssertTrue(viewReportsButton!.waitForExistence(timeout: 2), "View reports button should exist")
        viewReportsButton!.tap()
        
        // Wait for reports list to appear
        let reportsTitle = app.navigationBars["All Reports"]
        XCTAssertTrue(reportsTitle.waitForExistence(timeout: 3), "Reports list should appear")
    }
    
    private func submitTestReport(name: String = "John", email: String = "john.doe@example.com") {
        // Open contact form
        app.buttons["exclamationmark.bubble"].tap()
        
        // Fill required fields
        app.textFields["Name*"].tap()
        app.textFields["Name*"].typeText(name)
        
        app.textFields["Surname*"].tap()
        app.textFields["Surname*"].typeText("Doe")
        
        app.textFields["Email*"].tap()
        app.textFields["Email*"].typeText(email)
        
        app.textViews.element.tap()
        app.textViews.element.typeText("Test report description")
        
        // Dismiss keyboard
        app.tap()
        
        // Submit form
        app.buttons["Submit"].tap()
        
        // Wait for success alert and dismiss
        let alert = app.alerts["Report Status"]
        _ = alert.waitForExistence(timeout: 3)
        alert.buttons["OK"].tap()
        
        // Wait for return to main view
        let mainViewTitle = app.navigationBars["Trip Manager"]
        _ = mainViewTitle.waitForExistence(timeout: 2)
    }
}
