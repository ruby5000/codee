//
//  ObservabilityManager.swift
//  Centralized observability: metrics, traces, performance monitoring.
//
//  See OBSERVABILITY_README.md for setup and usage.
//

import Foundation
import UIKit

// MARK: - ObservabilityManager

/// Centralized observability: metrics, performance, custom events.
public enum ObservabilityManager {

    /// Whether observability is enabled.
    public static var isEnabled: Bool = true

    /// Custom metric handler (e.g. send to backend).
    public static var onMetric: ((String, Double, [String: String]?) -> Void)?

    /// Custom trace handler.
    public static var onTrace: ((String, TimeInterval, [String: String]?) -> Void)?

    /// Custom event handler.
    public static var onEvent: ((String, [String: Any]?) -> Void)?

    // MARK: - Metrics

    /// Records a numeric metric.
    public static func recordMetric(_ name: String, value: Double, tags: [String: String]? = nil) {
        guard isEnabled else { return }
        onMetric?(name, value, tags)
    }

    /// Records a counter increment.
    public static func increment(_ name: String, by: Int = 1, tags: [String: String]? = nil) {
        recordMetric(name, value: Double(by), tags: tags)
    }

    // MARK: - Traces

    /// Measures execution time of a block.
    public static func trace<T>(_ name: String, tags: [String: String]? = nil, block: () throws -> T) rethrows -> T {
        let start = CFAbsoluteTimeGetCurrent()
        defer {
            let duration = CFAbsoluteTimeGetCurrent() - start
            recordTrace(name, duration: duration, tags: tags)
        }
        return try block()
    }

    /// Measures async execution time.
    public static func trace<T>(_ name: String, tags: [String: String]? = nil, block: () async throws -> T) async rethrows -> T {
        let start = CFAbsoluteTimeGetCurrent()
        defer {
            let duration = CFAbsoluteTimeGetCurrent() - start
            recordTrace(name, duration: duration, tags: tags)
        }
        return try await block()
    }

    /// Records a trace manually.
    public static func recordTrace(_ name: String, duration: TimeInterval, tags: [String: String]? = nil) {
        guard isEnabled else { return }
        onTrace?(name, duration, tags)
    }

    // MARK: - Events

    /// Records a custom event.
    public static func recordEvent(_ name: String, params: [String: Any]? = nil) {
        guard isEnabled else { return }
        onEvent?(name, params)
    }
}
