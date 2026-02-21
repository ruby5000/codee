//
//  LifecycleManager.swift
//  App lifecycle events: foreground, background, active, inactive. Centralized observers.
//
//  See LIFECYCLE_README.md for setup and usage.
//

import Foundation
import UIKit

// MARK: - AppLifecycleState

public enum AppLifecycleState {
    case active
    case inactive
    case background
    case terminated
}

// MARK: - LifecycleManager

/// Centralized app lifecycle observers.
public enum LifecycleManager {

    /// Current state.
    public static private(set) var state: AppLifecycleState = .inactive

    /// Called when app becomes active.
    public static var onDidBecomeActive: (() -> Void)?

    /// Called when app becomes inactive.
    public static var onWillResignActive: (() -> Void)?

    /// Called when app enters background.
    public static var onDidEnterBackground: (() -> Void)?

    /// Called when app will enter foreground.
    public static var onWillEnterForeground: (() -> Void)?

    /// Called when app will terminate.
    public static var onWillTerminate: (() -> Void)?

    /// Whether app is in foreground.
    public static var isActive: Bool { state == .active }

    /// Whether app is in background.
    public static var isInBackground: Bool { state == .background }

    // MARK: - Notify (call from AppDelegate/SceneDelegate)

    public static func didBecomeActive() {
        state = .active
        onDidBecomeActive?()
    }

    public static func willResignActive() {
        state = .inactive
        onWillResignActive?()
    }

    public static func didEnterBackground() {
        state = .background
        onDidEnterBackground?()
    }

    public static func willEnterForeground() {
        onWillEnterForeground?()
    }

    public static func willTerminate() {
        state = .terminated
        onWillTerminate?()
    }
}
