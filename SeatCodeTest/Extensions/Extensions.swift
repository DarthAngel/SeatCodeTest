//
//  Extensions.swift
//  SeatCode
//
//  Created by Angel Docampo on 18/12/25.
//

import Foundation

// MARK: - Extensions for String Date Formatting
extension String {

    
    func formatTime() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH.mm.ss.SSSZ"
        if let date = formatter.date(from: self) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .short
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        return "Invalid Time"
    }
    
    func formatPrice() -> String {
        if let price = Double(self) {
            return String(format: "%.2f€", price)
        }
        return "\(self)€" // Fallback if string can't be parsed as Double
    }
    
    // MARK: - CarPlay-specific formatting methods
    
    /// Format ISO8601 time string for CarPlay display (short time only)
    func formatTimeForCarPlay() -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: self) else { return self }
        let displayFormatter = DateFormatter()
        displayFormatter.timeStyle = .short
        return displayFormatter.string(from: date)
    }
}

// MARK: - Trip Extensions for CarPlay
extension Trip {
    
    var formattedDurationForCarPlay: String {
        let formatter = ISO8601DateFormatter()
        guard let start = formatter.date(from: startTime),
              let end = formatter.date(from: endTime) else { return "Unknown" }
        let interval = end.timeIntervalSince(start)
        let hours = Int(interval) / 3600
        let minutes = Int(interval) % 3600 / 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }
    
    var formattedStartTimeForCarPlay: String {
        return startTime.formatTimeForCarPlay()
    }
    
    var statusDisplayTextForCarPlay: String {
        switch status {
        case .ongoing: return "In Progress"
        case .scheduled: return "Scheduled"
        case .finalized: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }
}

// MARK: - StopDetail Extensions for CarPlay
extension StopDetail {
    
    var formattedPriceForCarPlay: String {
        return String(format: "%.2f€", price)
    }
    
    var formattedTimeForCarPlay: String {
        return stopTime.formatTimeForCarPlay()
    }
    
    var paymentStatusForCarPlay: String {
        return paid ? "Paid" : "Pending"
    }
}

// MARK: - Double Extensions for Price Formatting
extension Double {
    
    var formattedPriceForCarPlay: String {
        return String(format: "%.2f€", self)
    }
}
