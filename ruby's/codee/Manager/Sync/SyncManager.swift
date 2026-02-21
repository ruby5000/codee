//
//  SyncManager.swift
//  Centralized sync logic: pending queue, retry, conflict resolution.
//
//  See SYNC_README.md for setup and usage.
//

import Foundation

// MARK: - SyncStatus

public enum SyncStatus {
    case idle
    case syncing
    case success
    case failed(Error)
}

// MARK: - Syncable

/// Protocol for items that can be synced.
public protocol Syncable {
    var syncId: String { get }
    var lastModified: Date { get }
}

// MARK: - SyncManager

/// Centralized sync: queue pending items, sync with server, handle conflicts.
public enum SyncManager {

    /// Current sync status.
    public static private(set) var status: SyncStatus = .idle

    /// Pending items to sync. Override with your storage (UserDefaults, CoreData).
    public static var pendingItems: [String] = [] {
        didSet { pendingItemsDidChange?() }
    }

    /// Called when pending items change.
    public static var pendingItemsDidChange: (() -> Void)?

    /// Sync handler. Implement your API sync logic.
    public static var performSync: (() async throws -> Void)?

    /// Conflict resolver. Return true to overwrite server, false to keep server.
    public static var resolveConflict: ((String, Date, Date) -> Bool)?

    // MARK: - Queue

    /// Adds item to pending queue.
    public static func queueForSync(id: String) {
        guard !pendingItems.contains(id) else { return }
        pendingItems.append(id)
    }

    /// Removes item from pending queue.
    public static func removeFromQueue(id: String) {
        pendingItems.removeAll { $0 == id }
    }

    /// Clears pending queue.
    public static func clearPending() {
        pendingItems.removeAll()
    }

    /// Whether there are pending items.
    public static var hasPending: Bool {
        !pendingItems.isEmpty
    }

    // MARK: - Sync

    /// Performs sync. Calls performSync handler.
    public static func sync() async {
        guard status != .syncing else { return }
        status = .syncing

        do {
            try await performSync?()
            status = .success
        } catch {
            status = .failed(error)
        }
    }

    /// Syncs if there are pending items.
    public static func syncIfNeeded() async {
        guard hasPending else { return }
        await sync()
    }

    // MARK: - Conflict

    /// Resolves conflict between local and server timestamps.
    public static func resolve(localDate: Date, serverDate: Date, itemId: String) -> Bool {
        resolveConflict?(itemId, localDate, serverDate) ?? (localDate > serverDate)
    }
}
