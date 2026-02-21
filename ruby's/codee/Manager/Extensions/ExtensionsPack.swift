//
//  ExtensionsPack.swift
//  Common extensions for String, Array, Date, UIView, and more.
//
//  See EXTENSIONS_README.md for setup and usage.
//

import Foundation
import UIKit

// MARK: - String

public extension String {

    /// Safe subscript by index.
    subscript(safe index: Int) -> Character? {
        guard index >= 0, index < count else { return nil }
        return self[self.index(startIndex, offsetBy: index)]
    }

    /// Returns nil if empty after trim.
    var nilIfEmpty: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }

    /// Adds https:// if no scheme.
    var asURLString: String {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return trimmed }
        let lower = trimmed.lowercased()
        if lower.hasPrefix("http://") || lower.hasPrefix("https://") { return trimmed }
        return "https://\(trimmed)"
    }

    /// Replaces occurrences.
    func replacing(_ target: String, with replacement: String) -> String {
        replacingOccurrences(of: target, with: replacement)
    }
}

// MARK: - Array

public extension Array {

    /// Safe subscript.
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }

    /// Removes duplicates preserving order (Element must be Hashable).
    func uniqued<T: Hashable>(by keyPath: KeyPath<Element, T>) -> [Element] {
        var seen = Set<T>()
        return filter { seen.insert($0[keyPath: keyPath]).inserted }
    }

    /// Chunked into arrays of given size.
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

public extension Array where Element: Hashable {

    /// Removes duplicates preserving order.
    var uniqued: [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

// MARK: - Date

public extension Date {

    /// Start of day in current calendar.
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// End of day (23:59:59.999).
    var endOfDay: Date {
        var comp = DateComponents()
        comp.day = 1
        comp.second = -1
        return Calendar.current.date(byAdding: comp, to: startOfDay) ?? self
    }

    /// Is today?
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// Adds days.
    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }
}

// MARK: - Optional

public extension Optional where Wrapped: Collection {

    /// True if nil or empty.
    var isNilOrEmpty: Bool {
        self?.isEmpty ?? true
    }
}

// MARK: - UIView

public extension UIView {

    /// Round corners.
    func roundCorners(radius: CGFloat) {
        layer.cornerRadius = radius
        layer.masksToBounds = true
    }

    /// Add border.
    func addBorder(width: CGFloat, color: UIColor) {
        layer.borderWidth = width
        layer.borderColor = color.cgColor
    }

    /// Load from nib.
    static func loadFromNib(named name: String? = nil) -> Self {
        let nibName = name ?? String(describing: self)
        let nib = UINib(nibName: nibName, bundle: nil)
        return nib.instantiate(withOwner: nil, options: nil).first as! Self
    }
}

// MARK: - UIViewController

public extension UIViewController {

    /// Presents alert with OK.
    func showAlert(title: String?, message: String?, okTitle: String = "OK", handler: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: okTitle, style: .default) { _ in handler?() })
        present(alert, animated: true)
    }

    /// Hides keyboard on tap.
    func hideKeyboardOnTap() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}

// MARK: - Collection

public extension Collection {

    /// Safe subscript.
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
