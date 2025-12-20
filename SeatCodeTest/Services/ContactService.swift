//
//  ContactService.swift
//  SeatCode
//
//  Created by Angel Docampo on 20/12/25.
//

import Foundation
import SwiftUI
import UserNotifications

@Observable
@MainActor
class ContactService {
    var reports: [ContactReport] = []
    
    private let userDefaults = UserDefaults.standard
    private let reportsKey = "ContactReports"
    
    init() {
        loadReports()
        updateAppBadge()
    }
    
    func saveReport(_ report: ContactReport) {
        reports.append(report)
        saveReports()
        updateAppBadge()
    }
    
    func deleteReport(at index: Int) {
        guard index >= 0 && index < reports.count else { return }
        reports.remove(at: index)
        saveReports()
        updateAppBadge()
    }
    
    func deleteReports(at indexSet: IndexSet) {
        reports.remove(atOffsets: indexSet)
        saveReports()
        updateAppBadge()
    }
    
    private func loadReports() {
        if let data = userDefaults.data(forKey: reportsKey),
           let decodedReports = try? JSONDecoder().decode([ContactReport].self, from: data) {
            reports = decodedReports
        }
    }
    
    private func saveReports() {
        if let encoded = try? JSONEncoder().encode(reports) {
            userDefaults.set(encoded, forKey: reportsKey)
        }
    }
    
    private func updateAppBadge() {
        Task {
            let center = UNUserNotificationCenter.current()
            do {
                let settings = await center.notificationSettings()
                if settings.badgeSetting == .enabled {
                    try await center.setBadgeCount(reports.count)
                }
            } catch {
                print("Failed to update app badge: \(error)")
            }
        }
    }
    
    func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        Task {
            do {
                _ = try await center.requestAuthorization(options: [.badge])
                updateAppBadge()
            } catch {
                print("Failed to request notification permission: \(error)")
            }
        }
    }
}
