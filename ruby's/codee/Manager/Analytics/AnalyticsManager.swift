//
//  AnalyticsManager.swift
//  Centralized analytics: Firebase, custom events, screen tracking. Single entry point for all analytics.
//
//  See ANALYTICS_README.md for setup and usage.
//  Requires: FirebaseAnalytics (optional; can be disabled for testing).
//

import Foundation
import UIKit

#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif

// MARK: - AnalyticsEvent

/// Represents an analytics event.
public struct AnalyticsEvent {
    public let name: String
    public let parameters: [String: Any]?

    public init(name: String, parameters: [String: Any]? = nil) {
        self.name = name
        self.parameters = parameters
    }
}

// MARK: - AnalyticsManager

/// Centralized analytics. Log events, screen views, and user properties.
public enum AnalyticsManager {

    /// Whether analytics is enabled. Set to false for debug or privacy.
    public static var isEnabled: Bool = true

    /// Custom handler for testing or forwarding to other providers.
    public static var customHandler: ((String, [String: Any]?) -> Void)?

    // MARK: - Log Event

    /// Logs an analytics event.
    public static func logEvent(_ name: String, parameters: [String: Any]? = nil) {
        guard isEnabled else { return }

        #if canImport(FirebaseAnalytics)
        Analytics.logEvent(name, parameters: parameters)
        #endif

        customHandler?(name, parameters)
    }

    /// Logs an AnalyticsEvent.
    public static func log(_ event: AnalyticsEvent) {
        logEvent(event.name, parameters: event.parameters)
    }

    // MARK: - Screen View

    /// Logs a screen view.
    public static func logScreenView(_ screenName: String, screenClass: String? = nil) {
        var params: [String: Any] = ["screen_name": screenName]
        if let cls = screenClass {
            params["screen_class"] = cls
        }
        logEvent("screen_view", parameters: params)
    }

    // MARK: - User Properties

    /// Sets a user property.
    public static func setUserProperty(_ value: String?, forName name: String) {
        guard isEnabled else { return }

        #if canImport(FirebaseAnalytics)
        Analytics.setUserProperty(value, forName: name)
        #endif
    }

    /// Sets user ID.
    public static func setUserId(_ userId: String?) {
        guard isEnabled else { return }

        #if canImport(FirebaseAnalytics)
        Analytics.setUserID(userId)
        #endif
    }

    // MARK: - Predefined Events

    /// Logs a purchase/success event.
    public static func logPurchaseSuccess(productId: String, value: Double? = nil) {
        var params: [String: Any] = [
            "item_id": productId,
            "status": "success"
        ]
        if let v = value {
            params["value"] = v
        }
        logEvent("ios_purchase_success", parameters: params)
    }

    /// Logs a button click.
    public static func logButtonClick(buttonName: String, screen: String? = nil) {
        var params: [String: Any] = ["button": buttonName]
        if let s = screen { params["screen"] = s }
        logEvent("button_clicked", parameters: params)
    }

    /// Logs a share event.
    public static func logShare(contentType: String, itemId: String? = nil) {
        var params: [String: Any] = ["content_type": contentType]
        if let id = itemId { params["item_id"] = id }
        logEvent("share", parameters: params)
    }

    /// Logs a login event.
    public static func logLogin(method: String) {
        logEvent("login", parameters: ["method": method])
    }

    /// Logs a sign up event.
    public static func logSignUp(method: String) {
        logEvent("sign_up", parameters: ["method": method])
    }
}
