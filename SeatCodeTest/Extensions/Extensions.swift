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
    
}
