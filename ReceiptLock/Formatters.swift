//
//  Formatters.swift
//  ReceiptLock
//
//  Created by Leandro Afonso on 08/08/2025.
//

import SwiftUI

// MARK: - Formatter Store

/// Centralized formatter store for consistent date formatting across the app
struct FormatterStore {
    
    /// Short expiry date formatter respecting user's locale
    static let expiryShort: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    /// Long date formatter with full date and time
    static let fullDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter
    }()
    
    /// Time-only formatter
    static let timeOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
    
    /// ISO8601 formatter for API communication
    static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        return formatter
    }()
}

// MARK: - Date Extensions

extension Date {
    /// Formats the date using the expiry short formatter
    var formattedExpiry: String {
        return FormatterStore.expiryShort.string(from: self)
    }
    
    /// Formats the date using full date and time
    var formattedFullDateTime: String {
        return FormatterStore.fullDateTime.string(from: self)
    }
    
    /// Formats the time only
    var formattedTime: String {
        return FormatterStore.timeOnly.string(from: self)
    }
    
    /// ISO8601 string representation
    var iso8601String: String {
        return FormatterStore.iso8601.string(from: self)
    }
}

// MARK: - Date FormatStyle Extensions

extension Date.FormatStyle {
    /// Custom expiry date format style
    static func expiryShort(locale: Locale = .current) -> Date.FormatStyle {
        Date.FormatStyle()
            .locale(locale)
            .year(.defaultDigits)
            .month(.abbreviated)
            .day(.twoDigits)
    }
}

