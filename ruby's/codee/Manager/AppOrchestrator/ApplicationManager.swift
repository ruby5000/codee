//
//  ApplicationManager.swift
//  App orchestrator: coordinates app startup, initialization order, and shutdown.
//
//  See APP_ORCHESTRATOR_README.md for setup and usage.
//

import Foundation
import UIKit

// MARK: - ApplicationManager

/// Orchestrates app lifecycle: startup sequence, initialization order, shutdown.
public enum ApplicationManager {

    /// Startup phases. Run in order.
    public enum StartupPhase {
        case config
        case logging
        case analytics
        case network
        case auth
        case ui
        case complete
    }

    /// Current phase.
    public static private(set) var currentPhase: StartupPhase = .config

    /// Phase handlers. Add your initialization logic.
    public static var onPhase: [StartupPhase: () -> Void] = [:]

    /// Async phase handlers.
    public static var onPhaseAsync: [StartupPhase: () async -> Void] = [:]

    /// Called when startup completes.
    public static var onStartupComplete: (() -> Void)?

    /// Called when app will terminate.
    public static var onWillTerminate: (() -> Void)?

    /// Whether startup has completed.
    public static var isReady: Bool { currentPhase == .complete }

    // MARK: - Startup

    /// Runs the startup sequence. Call from AppDelegate didFinishLaunching.
    public static func startup() {
        runPhase(.config)
        runPhase(.logging)
        runPhase(.analytics)
        runPhase(.network)
        runPhase(.auth)
        runPhase(.ui)
        currentPhase = .complete
        onStartupComplete?()
    }

    /// Async startup. Use when phases need async work.
    public static func startupAsync() async {
        await runPhaseAsync(.config)
        await runPhaseAsync(.logging)
        await runPhaseAsync(.analytics)
        await runPhaseAsync(.network)
        await runPhaseAsync(.auth)
        await runPhaseAsync(.ui)
        currentPhase = .complete
        onStartupComplete?()
    }

    private static func runPhase(_ phase: StartupPhase) {
        currentPhase = phase
        onPhase[phase]?()
    }

    private static func runPhaseAsync(_ phase: StartupPhase) async {
        currentPhase = phase
        onPhase[phase]?()
        await onPhaseAsync[phase]?()
    }

    // MARK: - Shutdown

    /// Call from applicationWillTerminate.
    public static func willTerminate() {
        onWillTerminate?()
    }
}
