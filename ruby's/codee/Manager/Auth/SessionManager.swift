//
//  SessionManager.swift
//  Centralized auth state and session handling. Tracks current user, tokens, and login status.
//
//  See AUTH_SESSION_README.md for setup and usage.
//  Integrates with: GoogleAuthManager, AppleAuthManager, FacebookAuthManager, Firebase Auth.
//

import Foundation
import UIKit

// MARK: - SessionState

/// Current session state.
public enum SessionState {
    case loggedOut
    case loggedIn(userId: String, email: String?)
}

// MARK: - SessionManager

/// Centralized session and auth state. Use for checking login status, storing tokens, and clearing session on logout.
public enum SessionManager {

    /// UserDefaults suite for session data. Use nil for standard suite.
    public static var userDefaults: UserDefaults = .standard

    /// Key prefix for all session keys.
    private static let keyPrefix = "SessionManager."

    // MARK: - Session State

    /// Whether a user is currently logged in.
    public static var isLoggedIn: Bool {
        userDefaults.bool(forKey: keyPrefix + "isLoggedIn")
    }

    /// Current user ID if logged in.
    public static var currentUserId: String? {
        userDefaults.string(forKey: keyPrefix + "userId")
    }

    /// Current user email if available.
    public static var currentUserEmail: String? {
        userDefaults.string(forKey: keyPrefix + "userEmail")
    }

    /// Current user display name if available.
    public static var currentUserName: String? {
        userDefaults.string(forKey: keyPrefix + "userName")
    }

    /// Access token if stored.
    public static var accessToken: String? {
        userDefaults.string(forKey: keyPrefix + "accessToken")
    }

    /// Current session state.
    public static var state: SessionState {
        if isLoggedIn, let uid = currentUserId {
            return .loggedIn(userId: uid, email: currentUserEmail)
        }
        return .loggedOut
    }

    // MARK: - Update Session

    /// Updates session after successful login. Call from your auth providers (Google, Apple, Firebase).
    public static func setSession(
        userId: String,
        email: String? = nil,
        name: String? = nil,
        accessToken: String? = nil
    ) {
        userDefaults.set(true, forKey: keyPrefix + "isLoggedIn")
        userDefaults.set(userId, forKey: keyPrefix + "userId")
        userDefaults.set(email, forKey: keyPrefix + "userEmail")
        userDefaults.set(name, forKey: keyPrefix + "userName")
        userDefaults.set(accessToken, forKey: keyPrefix + "accessToken")
        userDefaults.synchronize()
    }

    /// Updates a single session value.
    public static func updateSession(email: String? = nil, name: String? = nil, accessToken: String? = nil) {
        if email != nil { userDefaults.set(email, forKey: keyPrefix + "userEmail") }
        if name != nil { userDefaults.set(name, forKey: keyPrefix + "userName") }
        if accessToken != nil { userDefaults.set(accessToken, forKey: keyPrefix + "accessToken") }
        userDefaults.synchronize()
    }

    // MARK: - Logout

    /// Clears session and optionally performs additional cleanup (e.g. Firebase signOut, clear Keychain).
    public static func logout(additionalCleanup: (() -> Void)? = nil) {
        userDefaults.removeObject(forKey: keyPrefix + "isLoggedIn")
        userDefaults.removeObject(forKey: keyPrefix + "userId")
        userDefaults.removeObject(forKey: keyPrefix + "userEmail")
        userDefaults.removeObject(forKey: keyPrefix + "userName")
        userDefaults.removeObject(forKey: keyPrefix + "accessToken")
        userDefaults.synchronize()

        additionalCleanup?()
    }

    // MARK: - Observers

    /// Notification posted when session changes (login or logout).
    public static let sessionDidChangeNotification = Notification.Name("SessionManager.sessionDidChange")

    /// Call after setSession or logout to notify observers.
    public static func notifySessionChanged() {
        NotificationCenter.default.post(name: sessionDidChangeNotification, object: nil)
    }
}
