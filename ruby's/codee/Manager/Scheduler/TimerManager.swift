//
//  TimerManager.swift
//  Centralized timers: delayed execution, repeating, debounce, throttle.
//
//  See SCHEDULER_README.md for setup and usage.
//

import Foundation

// MARK: - TimerManager

/// Centralized timers and scheduled execution.
public enum TimerManager {

    /// Work items for cancellation.
    private static var workItems: [String: DispatchWorkItem] = [:]
    private static let queue = DispatchQueue(label: "com.app.timermanager")

    // MARK: - Delay

    /// Executes block after delay. Returns cancellation key.
    @discardableResult
    public static func after(_ delay: TimeInterval, execute block: @escaping () -> Void) -> String {
        let key = UUID().uuidString
        let workItem = DispatchWorkItem { [weak block] in
            block()
            queue.async { workItems.removeValue(forKey: key) }
        }
        queue.async { workItems[key] = workItem }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
        return key
    }

    /// Cancels a delayed execution by key.
    public static func cancel(_ key: String) {
        queue.sync {
            workItems[key]?.cancel()
            workItems.removeValue(forKey: key)
        }
    }

    // MARK: - Debounce

    /// Returns a debounced version of the action.
    public static func debounce(interval: TimeInterval, key: String, action: @escaping () -> Void) {
        queue.async {
            workItems[key]?.cancel()
        }
        let workItem = DispatchWorkItem {
            action()
            queue.async { workItems.removeValue(forKey: key) }
        }
        queue.async { workItems[key] = workItem }
        DispatchQueue.main.asyncAfter(deadline: .now() + interval, execute: workItem)
    }

    // MARK: - Throttle

    private static var throttleLastRun: [String: Date] = [:]
    private static var throttleQueue = DispatchQueue(label: "com.app.timermanager.throttle")

    /// Executes action at most once per interval. Drops intermediate calls.
    public static func throttle(interval: TimeInterval, key: String, action: @escaping () -> Void) {
        throttleQueue.async {
            let now = Date()
            let last = throttleLastRun[key] ?? .distantPast
            guard now.timeIntervalSince(last) >= interval else { return }
            throttleLastRun[key] = now
            DispatchQueue.main.async { action() }
        }
    }

    // MARK: - Repeating

    /// Creates a repeating timer. Returns the timer (invalidate to stop).
    public static func repeating(interval: TimeInterval, block: @escaping (Timer) -> Void) -> Timer {
        Timer.scheduledTimer(withTimeInterval: interval, repeats: true, block: block)
    }

    /// Repeating on main run loop.
    public static func repeating(on queue: DispatchQueue = .main, interval: TimeInterval, block: @escaping () -> Void) -> DispatchSourceTimer {
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + interval, repeating: interval)
        timer.setEventHandler(handler: block)
        timer.resume()
        return timer
    }
}
