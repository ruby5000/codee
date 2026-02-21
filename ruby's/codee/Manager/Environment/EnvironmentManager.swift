//
//  EnvironmentManager.swift
//  Environment detection: debug, release, staging. API URLs, feature flags per environment.
//
//  See ENVIRONMENT_README.md for setup and usage.
//

import Foundation

// MARK: - BuildEnvironment

public enum BuildEnvironment: String, CaseIterable {
    case debug
    case release
    case staging

    public var isDebug: Bool { self == .debug }
    public var isRelease: Bool { self == .release }
}

// MARK: - EnvironmentManager

/// Environment detection and per-environment config.
public enum EnvironmentManager {

    /// Current environment. Set at launch or auto-detect.
    public static var current: BuildEnvironment = {
        #if DEBUG
        return .debug
        #else
        return .release
        #endif
    }()

    /// Override to force environment (e.g. for testing).
    public static func setEnvironment(_ env: BuildEnvironment) {
        current = env
    }

    /// Base API URL per environment.
    public static var apiBaseURL: [BuildEnvironment: String] = [
        .debug: "https://staging-api.example.com/api/",
        .staging: "https://staging-api.example.com/api/",
        .release: "https://api.example.com/api/"
    ]

    /// Current API base URL.
    public static var currentAPIBaseURL: String {
        apiBaseURL[current] ?? apiBaseURL[.release]!
    }

    /// Feature flags per environment.
    public static var featureFlags: [BuildEnvironment: [String: Bool]] = [:]

    /// Whether feature is enabled in current environment.
    public static func isFeatureEnabled(_ key: String) -> Bool {
        featureFlags[current]?[key] ?? false
    }

    /// Logging enabled in current environment.
    public static var loggingEnabled: Bool {
        current != .release
    }

    /// Analytics enabled in current environment.
    public static var analyticsEnabled: Bool {
        current == .release || current == .staging
    }
}
