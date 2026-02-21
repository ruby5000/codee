//
//  BackgroundTaskManager.swift
//  Manages iOS background tasks (BGTaskScheduler) for deferred work.
//
//  See BACKGROUND_TASK_README.md for setup and usage.
//  Requires: BackgroundTasks framework.
//

import Foundation
import UIKit

#if canImport(BackgroundTasks)
import BackgroundTasks
#endif

// MARK: - BackgroundTaskManager

/// Manages background tasks for deferred work (e.g. sync, refresh).
public enum BackgroundTaskManager {

    /// Task identifier. Must match Info.plist BGTaskSchedulerPermittedIdentifiers.
    public static var refreshTaskIdentifier: String = "com.app.refresh"

    /// Task identifier for sync.
    public static var syncTaskIdentifier: String = "com.app.sync"

    /// Handler for refresh task.
    public static var onRefresh: (() async -> Void)?

    /// Handler for sync task.
    public static var onSync: (() async -> Void)?

    // MARK: - Schedule

    /// Schedules a refresh task.
    public static func scheduleRefresh() {
        #if canImport(BackgroundTasks)
        let request = BGAppRefreshTaskRequest(identifier: refreshTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)  // 15 min
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Background refresh scheduled")
        } catch {
            print("Background refresh failed: \(error)")
        }
        #endif
    }

    /// Schedules a sync task.
    public static func scheduleSync() {
        #if canImport(BackgroundTasks)
        let request = BGProcessingTaskRequest(identifier: syncTaskIdentifier)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        request.earliestBeginDate = Date(timeIntervalSinceNow: 30 * 60)  // 30 min
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Background sync scheduled")
        } catch {
            print("Background sync failed: \(error)")
        }
        #endif
    }

    // MARK: - Register

    /// Registers task handlers. Call from AppDelegate.
    public static func registerTasks() {
        #if canImport(BackgroundTasks)
        BGTaskScheduler.shared.register(forTaskWithIdentifier: refreshTaskIdentifier, using: nil) { task in
            handleRefresh(task: task as! BGAppRefreshTask)
        }
        BGTaskScheduler.shared.register(forTaskWithIdentifier: syncTaskIdentifier, using: nil) { task in
            handleSync(task: task as! BGProcessingTask)
        }
        #endif
    }

    #if canImport(BackgroundTasks)
    private static func handleRefresh(task: BGAppRefreshTask) {
        task.expirationHandler = { task.setTaskCompleted(success: false) }
        Task {
            await onRefresh?()
            task.setTaskCompleted(success: true)
            scheduleRefresh()
        }
    }

    private static func handleSync(task: BGProcessingTask) {
        task.expirationHandler = { task.setTaskCompleted(success: false) }
        Task {
            await onSync?()
            task.setTaskCompleted(success: true)
            scheduleSync()
        }
    }
    #endif
}
