//
//  MaintenanceManager.swift
//  App maintenance: cache cleanup, storage cleanup, data migration.
//
//  See MAINTENANCE_README.md for setup and usage.
//

import Foundation
import UIKit

// MARK: - MaintenanceManager

/// Centralized maintenance: cache cleanup, storage, migration.
public enum MaintenanceManager {

    /// Performs periodic maintenance. Call on app launch or foreground.
    public static var performMaintenance: (() async -> Void)?

    /// Cache cleanup handler.
    public static var onClearCaches: (() -> Void)?

    /// Storage cleanup (e.g. old temp files).
    public static var onCleanStorage: (() -> Void)?

    /// Data migration handler.
    public static var onMigrate: (() throws -> Void)?

    /// Last maintenance date.
    public static var lastMaintenanceDate: Date? {
        get { UserDefaults.standard.object(forKey: "MaintenanceManager.lastRun") as? Date }
        set { UserDefaults.standard.set(newValue, forKey: "MaintenanceManager.lastRun") }
    }

    /// Minimum interval between full maintenance (default 24h).
    public static var maintenanceInterval: TimeInterval = 24 * 60 * 60

    // MARK: - Run

    /// Runs maintenance if interval has passed.
    public static func runIfNeeded() async {
        let now = Date()
        guard let last = lastMaintenanceDate else {
            lastMaintenanceDate = now
            await run()
            return
        }
        guard now.timeIntervalSince(last) >= maintenanceInterval else { return }
        lastMaintenanceDate = now
        await run()
    }

    /// Runs maintenance immediately.
    public static func run() async {
        onClearCaches?()
        onCleanStorage?()
        try? onMigrate?()
        await performMaintenance?()
    }

    /// Clears caches only.
    public static func clearCaches() {
        onClearCaches?()
    }

    /// Cleans storage only.
    public static func cleanStorage() {
        onCleanStorage?()
    }

    /// Runs migration only.
    public static func migrate() throws {
        try onMigrate?()
    }
}
