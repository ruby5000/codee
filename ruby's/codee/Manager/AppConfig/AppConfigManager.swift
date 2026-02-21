//
//  AppConfigManager.swift
//  Centralized app configuration, constants, URLs, and environment settings.
//  Single source of truth for app-wide configuration.
//
//  See APP_CONFIG_README.md for setup and usage.
//

import Foundation
import UIKit

// MARK: - AppConfigManager

/// Centralized app configuration and constants. Use for URLs, API keys, feature flags, and environment settings.
public enum AppConfigManager {

    /// Current environment (debug, release, staging).
    public static var environment: AppEnvironment = .debug

    /// Base API URL. Override per environment if needed.
    public static var baseURL: String = ""

    /// App version string (e.g. "1.0.0").
    public static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    /// Build number (e.g. "42").
    public static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    /// Full version string: "1.0.0 (42)".
    public static var fullVersion: String {
        "\(appVersion) (\(buildNumber))"
    }

    /// Whether running in debug mode.
    public static var isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    // MARK: - URLs

    /// Resolves a path relative to base URL.
    public static func url(for path: String) -> String {
        let base = baseURL.hasSuffix("/") ? String(baseURL.dropLast()) : baseURL
        let p = path.hasPrefix("/") ? path : "/\(path)"
        return "\(base)\(p)"
    }

    // MARK: - Feature Flags

    /// Optional feature flags. Set at app launch from remote config or plist.
    public static var featureFlags: [String: Bool] = [:]

    /// Returns whether a feature is enabled. Defaults to false if not set.
    public static func isFeatureEnabled(_ key: String) -> Bool {
        featureFlags[key] ?? false
    }

    /// Sets a feature flag.
    public static func setFeature(_ key: String, enabled: Bool) {
        featureFlags[key] = enabled
    }

    // MARK: - Constants Access

    /// UserDefaults keys namespace.
    public enum UDKeys {
        public static let userFullName = "USER_FULL_NAME"
        public static let userAccessToken = "USER_ACCESS_TOKEN"
        public static let userEmail = "USER_EMAIL"
        public static let userName = "USER_NAME"
        public static let userDob = "USER_DOB"
        public static let currentLanguage = "CURRENT_DEVICE_LANGUAGE_CODE"
        public static let isUserAuth = "IS_USER_AUTH"
        public static let pauseLinkStatus = "PAUSE_LINK_STATUS"
        public static let userAvatar = "USER_AVTAR"
        public static let isPurchased = "IS_PURCHASED"
        public static let usersLink = "USERS_LINK"
        public static let deviceToken = "DEVICE_TOKEN"
        public static let selectedLanguage = "SelectedAppLanguage"
    }

    /// Subscription / IAP product IDs.
    public enum ProductIDs {
        public static var monthProductId = "lol.month.premium"
        public static var weekProductId = "lol.weekly.premium"
        public static var offerWeekProductId = "lol.discount.weekly.premium"
        public static var offerMonthProductId = "lol.discount.month.premium"
        public static var subscriptionKeyId = "9DX569246M"
    }

    /// Notification names.
    public enum Notifications {
        public static let premiumSuccessCallback = "PREMIUM_SUCCESS_CALLBACK"
    }
}

// MARK: - AppEnvironment

public enum AppEnvironment: String, CaseIterable {
    case debug
    case release
    case staging

    public var displayName: String { rawValue.capitalized }
}
