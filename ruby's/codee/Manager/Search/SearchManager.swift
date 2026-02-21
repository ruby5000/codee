//
//  SearchManager.swift
//  Debounced search, filtering, and search state management.
//
//  See SEARCH_README.md for setup and usage.
//

import Foundation

// MARK: - SearchManager

/// Debounced search and search state.
public enum SearchManager {

    /// Default debounce interval (seconds).
    public static var debounceInterval: TimeInterval = 0.3

    /// Minimum characters before search.
    public static var minSearchLength: Int = 1

    /// Max results to return (optional limit).
    public static var maxResults: Int?

    // MARK: - Debounce

    /// Returns a debounced version of the action. Call with each keystroke.
    public static func debounced(
        interval: TimeInterval = debounceInterval,
        action: @escaping (String) -> Void
    ) -> (String) -> Void {
        var workItem: DispatchWorkItem?
        return { query in
            workItem?.cancel()
            workItem = DispatchWorkItem {
                action(query)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + interval, execute: workItem!)
        }
    }

    /// Creates a debounced search handler.
    public static func makeDebouncedSearch(
        minLength: Int = minSearchLength,
        interval: TimeInterval = debounceInterval,
        onSearch: @escaping (String) -> Void
    ) -> (String) -> Void {
        let debounced = debounced(interval: interval, action: onSearch)
        return { query in
            let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.count >= minLength else {
                if trimmed.isEmpty { onSearch("") }
                return
            }
            debounced(trimmed)
        }
    }

    // MARK: - Filter

    /// Filters array by search query (case-insensitive contains).
    public static func filter<T: Collection>(
        _ items: T,
        query: String,
        keyPath: KeyPath<T.Element, String>
    ) -> [T.Element] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return Array(items) }
        return items.filter { $0[keyPath: keyPath].lowercased().contains(trimmed) }
    }

    /// Filters by multiple key paths (OR).
    public static func filter<T: Collection>(
        _ items: T,
        query: String,
        keyPaths: [KeyPath<T.Element, String>]
    ) -> [T.Element] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return Array(items) }
        return items.filter { item in
            keyPaths.contains { item[keyPath: $0].lowercased().contains(trimmed) }
        }
    }

    /// Filters with custom predicate.
    public static func filter<T>(
        _ items: [T],
        query: String,
        predicate: (T, String) -> Bool
    ) -> [T] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return items }
        return items.filter { predicate($0, trimmed) }
    }

    // MARK: - Limit

    /// Applies max results limit.
    public static func limit<T>(_ results: [T], max: Int?) -> [T] {
        guard let m = max, results.count > m else { return results }
        return Array(results.prefix(m))
    }
}
