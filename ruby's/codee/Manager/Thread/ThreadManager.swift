//
//  ThreadManager.swift
//  A centralized, reusable utility for all threading operations in iOS apps.
//  Handles main thread, background tasks, delays, async execution, and more.
//
//  See THREAD_MANAGER_GUIDE.md for an in-depth description and step-by-step tutorials.
//

import Foundation

// MARK: - ThreadManager

/// Centralized helper for main thread, background work, delays, async execution, and common threading patterns.
public enum ThreadManager {

    // MARK: - Queues

    /// Shared background queue for general work (QoS: user-initiated).
    public static let backgroundQueue = DispatchQueue(label: "com.app.threadmanager.background", qos: .userInitiated)

    /// Dedicated queue for heavy/long-running work (QoS: utility).
    public static let heavyWorkQueue = DispatchQueue(label: "com.app.threadmanager.heavy", qos: .utility)

    /// Serial queue for thread-safe access to shared state.
    public static let serialSyncQueue = DispatchQueue(label: "com.app.threadmanager.serial")

    // MARK: - Main Thread

    /// Runs work on the main thread. If already on main, runs immediately; otherwise dispatches async.
    /// Use for UI updates.
    public static func onMain(_ work: @escaping () -> Void) {
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async(execute: work)
        }
    }

    /// Runs work on the main thread after a delay.
    public static func onMain(after delay: TimeInterval, _ work: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    /// Runs work on the main thread synchronously. Avoid in performance-critical paths; prefer `onMain` when possible.
    public static func onMainSync<T>(_ work: () throws -> T) rethrows -> T {
        if Thread.isMainThread {
            return try work()
        }
        return try DispatchQueue.main.sync(execute: work)
    }

    // MARK: - Background Execution

    /// Runs work on a background queue (user-initiated QoS).
    public static func onBackground(_ work: @escaping () -> Void) {
        backgroundQueue.async(execute: work)
    }

    /// Runs work on a background queue and then calls the completion on the main thread.
    public static func onBackground(thenOnMain completion: @escaping () -> Void, background work: @escaping () -> Void) {
        backgroundQueue.async {
            work()
            onMain(completion)
        }
    }

    /// Runs work on the heavy-work queue for CPU-intensive or long tasks.
    public static func onHeavyBackground(_ work: @escaping () -> Void) {
        heavyWorkQueue.async(execute: work)
    }

    /// Runs work on the global concurrent queue with specified QoS.
    public static func onGlobal(qos: DispatchQoS.QoSClass = .userInitiated, _ work: @escaping () -> Void) {
        DispatchQueue.global(qos: qos).async(execute: work)
    }

    // MARK: - Delays (Cancellable)

    /// Schedules work after a delay. Returns a cancellable token; call `cancel()` to prevent execution.
    @discardableResult
    public static func after(_ delay: TimeInterval, on queue: DispatchQueue = .main, _ work: @escaping () -> Void) -> DispatchWorkItem {
        let item = DispatchWorkItem(block: work)
        queue.asyncAfter(deadline: .now() + delay, execute: item)
        return item
    }

    /// Async/await: suspends for the given number of seconds. Prefer in async contexts.
    public static func delay(seconds: TimeInterval) async {
        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }

    /// Async/await: delay that respects task cancellation.
    public static func delay(seconds: TimeInterval) async throws {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }

    // MARK: - Async Execution with Result

    /// Runs work on a background queue and completes with a Result on the main thread.
    public static func runAsync<T>(
        on queue: DispatchQueue = ThreadManager.backgroundQueue,
        work: @escaping () throws -> T,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        queue.async {
            let result: Result<T, Error>
            do {
                result = .success(try work())
            } catch {
                result = .failure(error)
            }
            onMain { completion(result) }
        }
    }

    /// Async/await: runs throwing work on a background queue and returns the value.
    public static func runDetached<T>(_ work: @escaping () async throws -> T) async rethrows -> T {
        try await Task.detached(priority: .userInitiated, operation: work).value
    }

    /// Runs the given async work on the main actor and returns the result.
    @MainActor
    public static func runOnMainActor<T>(_ work: @escaping () async throws -> T) async rethrows -> T {
        try await work()
    }

    // MARK: - Thread-Safe Access

    /// Synchronizes access to a value using the serial sync queue. Use for reading/writing shared mutable state.
    public static func sync<T>(_ work: () throws -> T) rethrows -> T {
        try serialSyncQueue.sync(execute: work)
    }

    /// Async version: schedules work on the serial queue and returns the value via continuation.
    public static func syncAsync<T>(_ work: @escaping () throws -> T) async rethrows -> T {
        try await withCheckedThrowingContinuation { continuation in
            serialSyncQueue.async {
                do {
                    let value = try work()
                    continuation.resume(returning: value)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Debounce

    /// Returns a debounced version of the action: only the last invocation within `interval` is executed.
    public static func debounce(interval: TimeInterval, queue: DispatchQueue = .main, action: @escaping () -> Void) -> () -> Void {
        var workItem: DispatchWorkItem?
        return {
            workItem?.cancel()
            workItem = DispatchWorkItem(block: action)
            queue.asyncAfter(deadline: .now() + interval, execute: workItem!)
        }
    }

    // MARK: - Throttle

    /// Returns a throttled version: at most one execution per `interval`.
    public static func throttle(interval: TimeInterval, queue: DispatchQueue = .main, action: @escaping () -> Void) -> () -> Void {
        var lastRun = Date.distantPast
        let lock = NSLock()
        return {
            lock.lock()
            let now = Date()
            let elapsed = now.timeIntervalSince(lastRun)
            lock.unlock()
            if elapsed >= interval {
                lock.lock()
                lastRun = now
                lock.unlock()
                queue.async(execute: action)
            }
        }
    }

    // MARK: - Retry

    /// Retries the async work up to `maxAttempts` times with `delay` between attempts. Uses exponential backoff if `useBackoff` is true.
    public static func retry<T>(
        maxAttempts: Int = 3,
        delay: TimeInterval = 1.0,
        useBackoff: Bool = false,
        work: @escaping () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        var currentDelay = delay
        for attempt in 1...maxAttempts {
            do {
                return try await work()
            } catch {
                lastError = error
                if attempt == maxAttempts { throw error }
                try await Task.sleep(nanoseconds: UInt64(currentDelay * 1_000_000_000))
                if useBackoff { currentDelay *= 2 }
            }
        }
        throw lastError ?? NSError(domain: "ThreadManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Retry failed"])
    }

    // MARK: - Once

    private static var onceTokens = [String: Bool]()
    private static let onceLock = NSLock()

    /// Executes the block only once per token. Thread-safe.
    public static func once(token: String, _ block: () -> Void) {
        onceLock.lock()
        let alreadyRun = onceTokens[token] == true
        if !alreadyRun {
            onceTokens[token] = true
        }
        onceLock.unlock()
        if !alreadyRun {
            block()
        }
    }
}

// MARK: - Convenience Extensions

extension ThreadManager {

    /// Runs work on main only if not already on main (avoids redundant dispatch).
    public static func onMainIfNeeded(_ work: @escaping () -> Void) {
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async(execute: work)
        }
    }

    /// Convenience: run async work and deliver result on main; optional failure handler.
    public static func asyncOnBackground<T>(
        work: @escaping () throws -> T,
        completionOnMain: @escaping (T) -> Void,
        onFailure: ((Error) -> Void)? = nil
    ) {
        runAsync(work: work) { result in
            switch result {
            case .success(let value):
                completionOnMain(value)
            case .failure(let error):
                onFailure?(error)
            }
        }
    }
}
