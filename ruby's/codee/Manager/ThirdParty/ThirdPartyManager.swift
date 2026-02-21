//
//  ThirdPartyManager.swift
//  Centralized third-party SDK initialization: Firebase, AppsFlyer, etc.
//
//  See THIRD_PARTY_README.md for setup and usage.
//

import Foundation
import UIKit

// MARK: - ThirdPartyManager

/// Centralized third-party SDK init and config.
public enum ThirdPartyManager {

    /// SDKs to initialize. Add your SDK init blocks.
    public static var initializers: [String: () -> Void] = [:]

    /// Async initializers.
    public static var asyncInitializers: [String: () async -> Void] = [:]

    /// Whether an SDK has been initialized.
    public static private(set) var initialized: Set<String> = []

    // MARK: - Init

    /// Runs all sync initializers.
    public static func initializeAll() {
        for (key, block) in initializers {
            guard !initialized.contains(key) else { continue }
            block()
            initialized.insert(key)
        }
    }

    /// Runs all initializers (sync + async).
    public static func initializeAllAsync() async {
        initializeAll()
        for (key, block) in asyncInitializers {
            guard !initialized.contains(key) else { continue }
            await block()
            initialized.insert(key)
        }
    }

    /// Initializes a single SDK by key.
    public static func initialize(_ key: String) {
        initializers[key]?()
        initialized.insert(key)
    }

    /// Checks if SDK is initialized.
    public static func isInitialized(_ key: String) -> Bool {
        initialized.contains(key)
    }
}
