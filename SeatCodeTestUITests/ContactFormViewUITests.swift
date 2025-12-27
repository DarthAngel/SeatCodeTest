//
//  ContactFormViewUITests.swift
//  SeatCodeTestUITests
//
//  Created on 27/12/25.
//

import XCTest

final class ContactFormViewUITests: XCTestCase {
    
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
    
    func testContactFormOpensFromMainView() throws {
        // Tap the exclamation bubble button to open contact form
        let reportButton = app.buttons["exclamationmark.bubble"]
        XCTAssertTrue(reportButton.exists, "Report button should exist in main view")
        
        reportButton.tap()
        
        // Verify contact form is presented
        let contactFormTitle = app.navigationBars["Report Issue"]
        XCTAssertTrue(contactFormTitle.waitForExistence(timeout: 2), "Contact form should be presented")
    }
    
    func testContactFormCanBeCancelled() throws {
        // Open contact form
        app.buttons["exclamationmark.bubble"].tap()
        
        // Tap cancel button
        let cancelButton = app.buttons["Cancel"]
        XCTAssertTrue(cancelButton.exists, "Cancel button should exist")
        cancelButton.tap()
        
        // Verify form is dismissed
        let mainViewTitle = app.navigationBars["Trip Manager"]
        XCTAssertTrue(mainViewTitle.waitForExistence(timeout: 2), "Should return to main view")
    }
    
    // MARK: - Form Field Tests
    
    func testFormFieldsExist() throws {
        // Open contact form
        app.buttons["exclamationmark.bubble"].tap()
        
        // Check all required form fields exist
        XCTAssertTrue(app.textFields["Name*"].exists, "Name field should exist")
        XCTAssertTrue(app.textFields["Surname*"].exists, "Surname field should exist")
        XCTAssertTrue(app.textFields["Email*"].exists, "Email field should exist")
        XCTAssertTrue(app.textFields["Phone (Optional)"].exists, "Phone field should exist")
        XCTAssertTrue(app.textViews.element.exists, "Description text view should exist")
        XCTAssertTrue(app.datePickers.element.exists, "Date picker should exist")
    }
    
    func testFormFieldsCanBeFilledOut() throws {
        // Open contact form
        app.buttons["exclamationmark.bubble"].tap()
        
        // Wait for contact form to be fully loaded
        let contactFormTitle = app.navigationBars["Report Issue"]
        XCTAssertTrue(contactFormTitle.waitForExistence(timeout: 2), "Contact form should be presented")
        
        // Fill out form fields
        let nameField = app.textFields["Name*"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2), "Name field should exist")
        nameField.tap()
        nameField.typeText("John")
        
        let surnameField = app.textFields["Surname*"]
        XCTAssertTrue(surnameField.waitForExistence(timeout: 2), "Surname field should exist")
        surnameField.tap()
        surnameField.typeText("Doe")
        
        let emailField = app.textFields["Email*"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 2), "Email field should exist")
        emailField.tap()
        emailField.typeText("john.doe@example.com")
        
        let phoneField = app.textFields["Phone (Optional)"]
        XCTAssertTrue(phoneField.waitForExistence(timeout: 2), "Phone field should exist")
        phoneField.tap()
        phoneField.typeText("123-456-7890")
        
        let descriptionField = app.textViews.element
        XCTAssertTrue(descriptionField.waitForExistence(timeout: 2), "Description field should exist")
        descriptionField.tap()
        descriptionField.typeText("This is a test report description")
        
        // Verify text was entered
        XCTAssertEqual(nameField.value as? String, "John")
        XCTAssertEqual(surnameField.value as? String, "Doe")
        XCTAssertEqual(emailField.value as? String, "john.doe@example.com")
        XCTAssertEqual(phoneField.value as? String, "123-456-7890")
    }
    
    // MARK: - Form Validation Tests
    
    func testSubmitButtonIsDisabledWithEmptyRequiredFields() throws {
        // Open contact form
        app.buttons["exclamationmark.bubble"].tap()
        
        let submitButton = app.buttons["Submit"]
        XCTAssertTrue(submitButton.exists, "Submit button should exist")
        XCTAssertFalse(submitButton.isEnabled, "Submit button should be disabled initially")
    }
    
    func testSubmitButtonIsEnabledWithValidInput() throws {
        // Open contact form
        app.buttons["exclamationmark.bubble"].tap()
        
        // Fill required fields with valid data
        fillRequiredFields()
        
        let submitButton = app.buttons["Submit"]
        XCTAssertTrue(submitButton.isEnabled, "Submit button should be enabled with valid input")
    }
    
    func testFormSubmissionWithValidData() throws {
        // Open contact form
        app.buttons["exclamationmark.bubble"].tap()
        
        // Fill required fields
        fillRequiredFields()
        
        // Submit form
        let submitButton = app.buttons["Submit"]
        submitButton.tap()
        
        // Wait for success alert
        let alert = app.alerts["Report Status"]
        XCTAssertTrue(alert.waitForExistence(timeout: 3), "Success alert should appear")
        
        // Verify success message
        let successMessage = alert.staticTexts["Report submitted successfully! Thank you for your feedback."]
        XCTAssertTrue(successMessage.exists, "Success message should be displayed")
        
        // Tap OK to dismiss alert and form
        alert.buttons["OK"].tap()
        
        // Verify return to main view
        let mainViewTitle = app.navigationBars["Trip Manager"]
        XCTAssertTrue(mainViewTitle.waitForExistence(timeout: 2), "Should return to main view after submission")
    }
    
    // MARK: - Reports List Navigation Tests
    
    func testNavigationToReportsList() throws {
        // Open contact form
        app.buttons["exclamationmark.bubble"].tap()
        
        // Tap view reports button
        let viewReportsButton = app.buttons["View previously submitted reports"]
        XCTAssertTrue(viewReportsButton.exists, "View reports button should exist")
        viewReportsButton.tap()
        
        // Verify reports list is presented
        let reportsTitle = app.navigationBars["All Reports"]
        XCTAssertTrue(reportsTitle.waitForExistence(timeout: 2), "Reports list should be presented")
    }
    
    
    // MARK: - Helper Methods
    
    private func fillRequiredFields() {
        // Wait for form elements to be available
        let nameField = app.textFields["Name*"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2), "Name field should exist")
        nameField.tap()
        nameField.typeText("John")
        
        let surnameField = app.textFields["Surname*"]
        XCTAssertTrue(surnameField.waitForExistence(timeout: 2), "Surname field should exist")
        surnameField.tap()
        surnameField.typeText("Doe")
        
        let emailField = app.textFields["Email*"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 2), "Email field should exist")
        emailField.tap()
        emailField.typeText("john.doe@example.com")
        
        let descriptionField = app.textViews.element
        XCTAssertTrue(descriptionField.waitForExistence(timeout: 2), "Description field should exist")
        descriptionField.tap()
        descriptionField.typeText("Test report description")
        
        // Dismiss keyboard
        app.tap()
    }
}
