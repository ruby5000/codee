//
//  ValidatorFormatter.swift
//  Centralized validation and formatting utilities for strings, emails, URLs, numbers, dates.
//
//  See VALIDATOR_FORMATTER_README.md for setup and usage.
//

import Foundation
import UIKit

// MARK: - Validator

/// Validation utilities.
public enum Validator {

    // MARK: - Email

    /// Validates email format.
    public static func isValidEmail(_ string: String) -> Bool {
        let pattern = #"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,64}"#
        return string.range(of: pattern, options: .regularExpression) != nil
    }

    // MARK: - URL

    /// Validates URL format.
    public static func isValidURL(_ string: String) -> Bool {
        guard let url = URL(string: string),
              url.scheme != nil,
              url.host != nil else { return false }
        return true
    }

    /// Validates and normalizes URL (adds https if needed).
    public static func normalizeURL(_ string: String) -> String? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let lower = trimmed.lowercased()
        let withScheme = (lower.hasPrefix("http://") || lower.hasPrefix("https://")) ? trimmed : "https://\(trimmed)"
        return URL(string: withScheme) != nil ? withScheme : nil
    }

    // MARK: - Phone

    /// Validates phone (digits only, 10–15 chars).
    public static func isValidPhone(_ string: String) -> Bool {
        let digits = string.filter { $0.isNumber }
        return digits.count >= 10 && digits.count <= 15
    }

    // MARK: - Non-empty

    /// Returns true if string is non-empty after trimming.
    public static func isNonEmpty(_ string: String?) -> Bool {
        guard let s = string else { return false }
        return !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Length

    /// Validates string length is within range.
    public static func isLength(_ string: String, min: Int, max: Int) -> Bool {
        let count = string.count
        return count >= min && count <= max
    }

    // MARK: - Numeric

    /// Validates string is numeric.
    public static func isNumeric(_ string: String) -> Bool {
        Double(string) != nil
    }

    /// Validates string is integer.
    public static func isInteger(_ string: String) -> Bool {
        Int(string) != nil
    }
}

// MARK: - Formatter

/// Formatting utilities.
public enum Formatter {

    // MARK: - Phone

    /// Formats phone for display (e.g. "+1 (555) 123-4567").
    public static func formatPhone(_ string: String) -> String {
        let digits = string.filter { $0.isNumber }
        switch digits.count {
        case 10:
            return "(\(digits.prefix(3))) \(digits.dropFirst(3).prefix(3))-\(digits.suffix(4))"
        case 11 where digits.hasPrefix("1"):
            return "+1 (\(digits.dropFirst().prefix(3))) \(digits.dropFirst(4).prefix(3))-\(digits.suffix(4))"
        default:
            return string
        }
    }

    // MARK: - Currency

    /// Formats number as currency.
    public static func formatCurrency(_ value: Double, locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    // MARK: - Number

    /// Formats number with grouping (e.g. 1,234,567).
    public static func formatNumber(_ value: Double, decimals: Int = 0) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = decimals
        formatter.maximumFractionDigits = decimals
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    /// Formats compact number (e.g. 1.2K, 3.5M).
    public static func formatCompact(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 0
        if value >= 1_000_000 {
            return (formatter.string(from: NSNumber(value: value / 1_000_000)) ?? "") + "M"
        }
        if value >= 1_000 {
            return (formatter.string(from: NSNumber(value: value / 1_000)) ?? "") + "K"
        }
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    // MARK: - Date

    /// Formats date with given style.
    public static func formatDate(_ date: Date, style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    /// Formats date and time.
    public static func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    /// Formats date with custom format (e.g. "yyyy-MM-dd").
    public static func formatDate(_ date: Date, format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: date)
    }

    /// Formats relative time (e.g. "2 hours ago").
    public static func formatRelative(_ date: Date, locale: Locale = .current) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.locale = locale
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    // MARK: - String

    /// Trims and collapses whitespace.
    public static func normalizeWhitespace(_ string: String) -> String {
        string.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    /// Truncates string with ellipsis.
    public static func truncate(_ string: String, maxLength: Int, suffix: String = "...") -> String {
        guard string.count > maxLength else { return string }
        let end = string.index(string.startIndex, offsetBy: maxLength - suffix.count)
        return String(string[..<end]) + suffix
    }
}
