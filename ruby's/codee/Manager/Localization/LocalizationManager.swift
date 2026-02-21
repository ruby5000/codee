//
//  LocalizationManager.swift
//  Centralized localization and language switching. Manages current language, strings, and UI reload.
//
//  See LOCALIZATION_README.md for setup and usage.
//

import Foundation
import UIKit
import ObjectiveC

// MARK: - LocalizationManager

/// Centralized localization. Use for current language, switching language, and localized strings.
public enum LocalizationManager {

    /// Supported language codes (e.g. "en", "hi", "es").
    public static var supportedLanguages: [String] = ["en", "hi", "es"]

    /// Default language when device language is not supported.
    public static var defaultLanguage: String = "en"

    /// UserDefaults key for selected language override.
    public static var storageKey: String = "SelectedAppLanguage"

    /// UserDefaults key for last known device language (for change detection).
    private static let deviceLanguageKey = "LocalizationManager.LastDeviceLanguage"

    /// Custom UserDefaults. Use nil for standard.
    public static var userDefaults: UserDefaults = .standard

    // MARK: - Current Language

    /// Current app language. Prioritizes device language if supported; otherwise saved override or default.
    public static var currentLanguage: String {
        let deviceLang = deviceLanguageCode
        let lastDeviceLang = userDefaults.string(forKey: deviceLanguageKey)
        let deviceLangChanged = lastDeviceLang != deviceLang

        if isLanguageSupported(deviceLang) {
            if deviceLangChanged {
                userDefaults.set(deviceLang, forKey: deviceLanguageKey)
                userDefaults.removeObject(forKey: storageKey)
                userDefaults.synchronize()
            }
            return deviceLang
        }

        if deviceLangChanged {
            userDefaults.removeObject(forKey: storageKey)
            userDefaults.set(deviceLang, forKey: deviceLanguageKey)
            userDefaults.synchronize()
            return defaultLanguage
        }

        if let saved = userDefaults.string(forKey: storageKey), isLanguageSupported(saved) {
            return saved
        }

        userDefaults.removeObject(forKey: storageKey)
        userDefaults.synchronize()
        return defaultLanguage
    }

    /// Device language code (first 2 chars, e.g. "en" from "en-US").
    public static var deviceLanguageCode: String {
        guard let first = Locale.preferredLanguages.first else { return defaultLanguage }
        return String(first.prefix(2))
    }

    // MARK: - Set Language

    /// Sets the app language and optionally reloads the root UI.
    public static func setLanguage(_ langCode: String, reloadUI: Bool = true) {
        let newLang = supportedLanguages.contains(langCode) ? langCode : defaultLanguage
        let deviceLang = deviceLanguageCode
        userDefaults.set(deviceLang, forKey: deviceLanguageKey)
        userDefaults.set(newLang, forKey: storageKey)
        userDefaults.synchronize()

        Bundle.setLanguage(newLang)

        if reloadUI {
            reloadAppRoot()
        }
    }

    // MARK: - Localized String

    /// Returns localized string for the key. Uses current language bundle.
    public static func string(_ key: String, tableName: String? = nil, value: String? = nil) -> String {
        let bundle = currentBundle
        return bundle.localizedString(forKey: key, value: value ?? key, table: tableName)
    }

    /// Convenience: `LocalizationManager.string("key")`
    public static func tr(_ key: String, tableName: String? = nil) -> String {
        string(key, tableName: tableName)
    }

    // MARK: - Bundle

    /// Bundle for current language. Used by `Bundle.setLanguage` and string lookups.
    private static var currentBundle: Bundle {
        if let path = Bundle.main.path(forResource: currentLanguage, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }
        if let path = Bundle.main.path(forResource: defaultLanguage, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }
        return Bundle.main
    }

    // MARK: - Helpers

    private static func isLanguageSupported(_ code: String) -> Bool {
        supportedLanguages.contains(code)
    }

    private static func reloadAppRoot() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else { return }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        window.rootViewController = storyboard.instantiateInitialViewController()
        window.makeKeyAndVisible()
    }
}

// MARK: - Bundle Extension

private var bundleKey: UInt8 = 0

extension Bundle {
    /// Swaps main bundle's localizedString to use the given language.
    class func setLanguage(_ language: String) {
        object_setClass(Bundle.main, PrivateBundle.self)
        let path = Bundle.main.path(forResource: language, ofType: "lproj")
            ?? Bundle.main.path(forResource: "en", ofType: "lproj")
        let value = path != nil ? Bundle(path: path!) : nil
        objc_setAssociatedObject(Bundle.main, &bundleKey, value, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

private class PrivateBundle: Bundle {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        let bundle = objc_getAssociatedObject(self, &bundleKey) as? Bundle
        return bundle?.localizedString(forKey: key, value: value, table: tableName)
            ?? super.localizedString(forKey: key, value: value, table: tableName)
    }
}
