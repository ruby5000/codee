import Foundation
import UIKit

private var bundleKey: UInt8 = 0

class LanguageManager {
    
    static let shared = LanguageManager()
   

    private let supportedLanguages = ["en", "hi", "es"]
    private let defaultLanguage = "en"
    private let storageKey = "SelectedAppLanguage"
    private let deviceLanguageKey = "LastDeviceLanguage"
    
    // MARK: - CURRENT LANGUAGE
    
    var currentLanguage: String {
        let deviceLang = getDeviceLanguage()
        let lastDeviceLang = UserDefaults.standard.string(forKey: deviceLanguageKey)
        
        // Check if device language has changed
        let deviceLangChanged = lastDeviceLang != deviceLang
        
        // Always prioritize device language if it's supported
        if isLanguageSupported(deviceLang) {
            // Update stored device language
            if deviceLangChanged {
                UserDefaults.standard.set(deviceLang, forKey: deviceLanguageKey)
                // Clear saved language to use device language
                UserDefaults.standard.removeObject(forKey: storageKey)
                UserDefaults.standard.synchronize()
            }
            return deviceLang
        }
        
        // Device language is not supported - reset to default
        if deviceLangChanged {
            // Device language changed to unsupported, clear saved language and reset to default
            UserDefaults.standard.removeObject(forKey: storageKey)
            UserDefaults.standard.set(deviceLang, forKey: deviceLanguageKey)
            UserDefaults.standard.synchronize()
            return defaultLanguage
        }
        
        // Device language hasn't changed and is unsupported
        // Check if we have a valid saved language (shouldn't happen in normal flow, but handle it)
        if let saved = UserDefaults.standard.string(forKey: storageKey) {
            if isLanguageSupported(saved) {
                return saved
            } else {
                // Saved language is invalid, clear it
                UserDefaults.standard.removeObject(forKey: storageKey)
                UserDefaults.standard.synchronize()
            }
        }
        
        // Fall back to default
        return defaultLanguage
    }
    
    // MARK: - SET LANGUAGE
    
    func setLanguage(_ langCode: String) {
        let newLang = supportedLanguages.contains(langCode) ? langCode : defaultLanguage
        
        // Track current device language
        let deviceLang = getDeviceLanguage()
        UserDefaults.standard.set(deviceLang, forKey: deviceLanguageKey)
        
        UserDefaults.standard.set(newLang, forKey: storageKey)
        UserDefaults.standard.synchronize()
        
        Bundle.setLanguage(newLang)
        
        // Reload UI
        reloadAppUI()
    }
    
    // MARK: - INITIAL LANGUAGE WHEN APP STARTS
    
    private func determineInitialLanguage() -> String {
        let deviceLang = getDeviceLanguage()
        
        // Initialize device language tracking on first launch
        if UserDefaults.standard.string(forKey: deviceLanguageKey) == nil {
            UserDefaults.standard.set(deviceLang, forKey: deviceLanguageKey)
            UserDefaults.standard.synchronize()
        }
        
        if let match = supportedLanguages.first(where: { deviceLang.starts(with: $0) }) {
            return match
        }
        return defaultLanguage
    }
    
    // MARK: - HELPER METHODS
    
    /// Get the current device language code (first two characters)
    private func getDeviceLanguage() -> String {
        guard let deviceLang = Locale.preferredLanguages.first else {
            return defaultLanguage
        }
        // Extract language code (first 2 characters, e.g., "hi" from "hi-IN")
        let langCode = String(deviceLang.prefix(2))
        return langCode
    }
    
    /// Check if a language code is supported
    private func isLanguageSupported(_ langCode: String) -> Bool {
        return supportedLanguages.contains(langCode)
    }
    
    // MARK: - APP RELOAD
    
    private func reloadAppUI() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        window.rootViewController = storyboard.instantiateInitialViewController()
        window.makeKeyAndVisible()
    }
}

extension Bundle {
    class func setLanguage(_ language: String) {
        object_setClass(Bundle.main, PrivateBundle.self)
        
        let path = Bundle.main.path(forResource: language, ofType: "lproj") ?? Bundle.main.path(forResource: "en", ofType: "lproj")
        
        let value = path != nil ? Bundle(path: path!) : nil
        objc_setAssociatedObject(Bundle.main, &bundleKey, value, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

private class PrivateBundle: Bundle {
    override func localizedString(forKey key: String,
                                  value: String?,
                                  table tableName: String?) -> String {
        
        let bundle = objc_getAssociatedObject(self, &bundleKey) as? Bundle
        
        return bundle?.localizedString(forKey: key,
                                       value: value,
                                       table: tableName) ??
               super.localizedString(forKey: key,
                                     value: value,
                                     table: tableName)
    }
}
