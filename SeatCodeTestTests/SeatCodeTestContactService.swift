//
//  SeatCodeTestContactService.swift
//  SeatCodeTestTests
//
//  Created by Angel Docampo on 21/12/25.
//

import XCTest
import UserNotifications
@testable import SeatCodeTest

@MainActor
final class SeatCodeTestContactService: XCTestCase {
    
    var contactService: ContactService!
    
    override class func setUp() {
        super.setUp()
        // Clear any persistent data once before all tests
        UserDefaults.standard.removeObject(forKey: "ContactReports")
        UserDefaults.standard.synchronize()
    }
    
    override class func tearDown() {
        // Clean up after all tests
        UserDefaults.standard.removeObject(forKey: "ContactReports")
        UserDefaults.standard.synchronize()
        super.tearDown()
    }
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Clear UserDefaults before each test
        UserDefaults.standard.removeObject(forKey: "ContactReports")
        UserDefaults.standard.synchronize()
        
        // Create fresh ContactService for each test
        contactService = ContactService()
        
        // Verify we start with empty reports
        if !contactService.reports.isEmpty {
            print("Warning: ContactService has \(contactService.reports.count) reports on initialization")
            // Force clear if needed
            while !contactService.reports.isEmpty {
                contactService.deleteReport(at: 0)
            }
        }
        
        XCTAssertTrue(contactService.reports.isEmpty, "ContactService should start with empty reports in test setup")
    }
    
    override func tearDown() async throws {
        // Clear all data after each test to ensure clean state
        contactService?.reports.removeAll()
        UserDefaults.standard.removeObject(forKey: "ContactReports")
        UserDefaults.standard.synchronize()
        
        contactService = nil
        try await super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func createMockContactReport() -> ContactReport {
        return ContactReport(
            name: "John",
            surname: "Doe",
            email: "john.doe@example.com",
            phone: "+34123456789",
            reportDate: Date(),
            description: "Test report description"
        )
    }
    
    private func createMockContactReportWithoutPhone() -> ContactReport {
        return ContactReport(
            name: "Jane",
            surname: "Smith",
            email: "jane.smith@example.com",
            phone: nil,
            reportDate: Date(),
            description: "Test report without phone"
        )
    }
    
    private func verifyCleanState() {
        XCTAssertTrue(contactService.reports.isEmpty, "ContactService should have empty reports at start of test, but has \(contactService.reports.count) reports")
    }
    
    // MARK: - Initialization Tests
    
    func testContactServiceInitialization() throws {
        XCTAssertNotNil(contactService, "ContactService should be initialized")
        XCTAssertTrue(contactService.reports.isEmpty, "Reports should be empty on fresh initialization, but found \(contactService.reports.count) reports")
    }
    
    // MARK: - Save Report Tests
    
    func testSaveReport() throws {
        let initialCount = contactService.reports.count
        let report = createMockContactReport()
        
        contactService.saveReport(report)
        
        XCTAssertEqual(contactService.reports.count, initialCount + 1, "Reports count should increase by 1")
        XCTAssertEqual(contactService.reports.last?.name, "John", "Last report should have correct name")
        XCTAssertEqual(contactService.reports.last?.surname, "Doe", "Last report should have correct surname")
        XCTAssertEqual(contactService.reports.last?.email, "john.doe@example.com", "Last report should have correct email")
    }
    
    func testSaveMultipleReports() throws {
        verifyCleanState()
        
        let report1 = createMockContactReport()
        let report2 = createMockContactReportWithoutPhone()
        
        contactService.saveReport(report1)
        contactService.saveReport(report2)
        
        XCTAssertEqual(contactService.reports.count, 2, "Should have 2 reports")
        XCTAssertEqual(contactService.reports[0].name, "John", "First report should be John")
        XCTAssertEqual(contactService.reports[1].name, "Jane", "Second report should be Jane")
    }
    
    func testSaveReportWithoutPhone() throws {
        verifyCleanState()
        
        let report = createMockContactReportWithoutPhone()
        
        contactService.saveReport(report)
        
        XCTAssertEqual(contactService.reports.count, 1, "Should have 1 report")
        XCTAssertNil(contactService.reports[0].phone, "Phone should be nil")
        XCTAssertEqual(contactService.reports[0].fullName, "Jane Smith", "Full name should be correct")
    }
    
    // MARK: - Delete Report Tests
    
    func testDeleteReportAtValidIndex() throws {
        verifyCleanState()
        
        let report1 = createMockContactReport()
        let report2 = createMockContactReportWithoutPhone()
        
        contactService.saveReport(report1)
        contactService.saveReport(report2)
        
        XCTAssertEqual(contactService.reports.count, 2, "Should start with 2 reports")
        
        contactService.deleteReport(at: 0)
        
        XCTAssertEqual(contactService.reports.count, 1, "Should have 1 report after deletion")
        XCTAssertEqual(contactService.reports[0].name, "Jane", "Remaining report should be Jane")
    }
    
    func testDeleteReportAtInvalidIndex() throws {
        let report = createMockContactReport()
        contactService.saveReport(report)
        
        let initialCount = contactService.reports.count
        
        // Test negative index
        contactService.deleteReport(at: -1)
        XCTAssertEqual(contactService.reports.count, initialCount, "Count should remain unchanged for negative index")
        
        // Test index out of bounds
        contactService.deleteReport(at: 10)
        XCTAssertEqual(contactService.reports.count, initialCount, "Count should remain unchanged for out of bounds index")
    }
    
    func testDeleteReportsWithIndexSet() throws {
        verifyCleanState()
        
        let report1 = createMockContactReport()
        let report2 = createMockContactReportWithoutPhone()
        let report3 = ContactReport(
            name: "Bob",
            surname: "Johnson",
            email: "bob@example.com",
            phone: "+34987654321",
            reportDate: Date(),
            description: "Third report"
        )
        
        contactService.saveReport(report1)
        contactService.saveReport(report2)
        contactService.saveReport(report3)
        
        XCTAssertEqual(contactService.reports.count, 3, "Should start with 3 reports")
        
        // Delete first and third reports (indices 0 and 2)
        let indexSet = IndexSet([0, 2])
        contactService.deleteReports(at: indexSet)
        
        XCTAssertEqual(contactService.reports.count, 1, "Should have 1 report after deletion")
        XCTAssertEqual(contactService.reports[0].name, "Jane", "Remaining report should be Jane")
    }
    
    func testDeleteReportsFromEmptyArray() throws {
        verifyCleanState()
        
        let indexSet = IndexSet([0])
        contactService.deleteReports(at: indexSet)
        
        XCTAssertTrue(contactService.reports.isEmpty, "Should remain empty after attempting to delete from empty array")
    }
    
    // MARK: - Contact Report Model Tests
    
    func testContactReportFullName() throws {
        let report = createMockContactReport()
        XCTAssertEqual(report.fullName, "John Doe", "Full name should combine name and surname")
    }
    
    func testContactReportUniqueIDs() throws {
        let report1 = createMockContactReport()
        let report2 = createMockContactReport()
        
        XCTAssertNotEqual(report1.id, report2.id, "Each report should have a unique ID")
    }
    
    func testContactReportCodable() throws {
        let report = createMockContactReport()
        
        // Test encoding
        let encoded = try JSONEncoder().encode(report)
        XCTAssertFalse(encoded.isEmpty, "Encoded data should not be empty")
        
        // Test decoding
        let decoded = try JSONDecoder().decode(ContactReport.self, from: encoded)
        XCTAssertEqual(decoded.name, report.name, "Decoded name should match original")
        XCTAssertEqual(decoded.surname, report.surname, "Decoded surname should match original")
        XCTAssertEqual(decoded.email, report.email, "Decoded email should match original")
        XCTAssertEqual(decoded.phone, report.phone, "Decoded phone should match original")
        XCTAssertEqual(decoded.description, report.description, "Decoded description should match original")
    }
    
    // MARK: - Notification Permission Tests
    
    func testRequestNotificationPermission() async throws {
        // This test verifies the method doesn't crash and can be called
        // In a real test environment, you would mock UNUserNotificationCenter
        contactService.requestNotificationPermission()
        
        // Wait a brief moment for the async operation
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // The method should complete without throwing
        XCTAssertNotNil(contactService, "ContactService should still exist after permission request")
    }
    
    // MARK: - Integration Tests
    
    func testSaveAndDeleteWorkflow() throws {
        // Start with empty reports
        verifyCleanState()
        
        // Add some reports
        let report1 = createMockContactReport()
        let report2 = createMockContactReportWithoutPhone()
        
        contactService.saveReport(report1)
        contactService.saveReport(report2)
        
        XCTAssertEqual(contactService.reports.count, 2, "Should have 2 reports after saving")
        
        // Delete one report
        contactService.deleteReport(at: 0)
        
        XCTAssertEqual(contactService.reports.count, 1, "Should have 1 report after deletion")
        XCTAssertEqual(contactService.reports[0].name, "Jane", "Remaining report should be correct")
        
        // Delete remaining report
        contactService.deleteReport(at: 0)
        
        XCTAssertTrue(contactService.reports.isEmpty, "Should be empty after deleting all reports")
    }
    
    // MARK: - Edge Cases Tests
    
    func testReportsArrayConsistency() throws {
        let report = createMockContactReport()
        
        // Verify array operations maintain consistency
        contactService.saveReport(report)
        let countAfterSave = contactService.reports.count
        
        contactService.deleteReport(at: 0)
        let countAfterDelete = contactService.reports.count
        
        XCTAssertEqual(countAfterSave - countAfterDelete, 1, "Count should decrease by exactly 1 after delete")
    }
    
    func testEmptyStringHandling() throws {
        verifyCleanState()
        
        let reportWithEmptyStrings = ContactReport(
            name: "",
            surname: "",
            email: "",
            phone: nil, // Use nil instead of empty string for phone
            reportDate: Date(),
            description: ""
        )
        
        contactService.saveReport(reportWithEmptyStrings)
        
        XCTAssertEqual(contactService.reports.count, 1, "Should save report with empty strings")
        // Full name for empty strings should be " " (empty + space + empty = space)
        XCTAssertEqual(contactService.reports[0].fullName, " ", "Full name should be a space for empty name and surname")
        XCTAssertEqual(contactService.reports[0].name, "", "Name should be empty string")
        XCTAssertEqual(contactService.reports[0].surname, "", "Surname should be empty string")
    }
}
