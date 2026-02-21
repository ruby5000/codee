# App Configuration & Constants — How to Use

Centralized **app configuration**, **constants**, **URLs**, and **environment settings**. Single source of truth for app-wide values.

---

## 1. Overview

**AppConfigManager** provides:

- **Environment** — Debug, Release, Staging.
- **Version info** — App version, build number, full version string.
- **Base URL** — API base URL with path resolution.
- **Feature flags** — Enable/disable features at runtime.
- **Constants** — UserDefaults keys, product IDs, notification names.

All APIs are static on `AppConfigManager`. No external dependencies.

---

## 2. Quick Reference

| Need | Use |
|------|-----|
| App version | `AppConfigManager.appVersion` |
| Build number | `AppConfigManager.buildNumber` |
| Full version | `AppConfigManager.fullVersion` |
| Is debug? | `AppConfigManager.isDebug` |
| Environment | `AppConfigManager.environment` |
| Base URL | `AppConfigManager.baseURL` |
| Resolve path | `AppConfigManager.url(for: "api/users")` |
| Feature flag | `AppConfigManager.isFeatureEnabled("darkMode")` |
| Set feature | `AppConfigManager.setFeature("darkMode", enabled: true)` |
| UD keys | `AppConfigManager.UDKeys.userEmail` |
| Product IDs | `AppConfigManager.ProductIDs.monthProductId` |

---

## 3. Setup

### 3.1 Configure at App Launch

In `AppDelegate` or `@main`:

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    AppConfigManager.environment = .release
    AppConfigManager.baseURL = "https://api.example.com/api/"
    
    #if DEBUG
    AppConfigManager.environment = .debug
    AppConfigManager.baseURL = "https://staging-api.example.com/api/"
    #endif
    
    return true
}
```

### 3.2 Add to Xcode

Add **AppConfigManager.swift** (and **AppConfig** folder) to your app target.

---

## 4. Environment

```swift
// Set at launch
AppConfigManager.environment = .release

// Check
switch AppConfigManager.environment {
case .debug:
    // Use debug API, verbose logging
case .staging:
    // Staging server
case .release:
    // Production
}
```

---

## 5. Version Info

```swift
let version = AppConfigManager.appVersion      // "1.0.0"
let build = AppConfigManager.buildNumber      // "42"
let full = AppConfigManager.fullVersion       // "1.0.0 (42)"
let isDebug = AppConfigManager.isDebug        // true in Debug builds
```

---

## 6. URLs

### 6.1 Base URL

```swift
AppConfigManager.baseURL = "https://api.example.com/api/"
```

### 6.2 Resolve Path

```swift
let url = AppConfigManager.url(for: "users/profile")
// "https://api.example.com/api/users/profile"
```

Paths with or without leading slash work:

```swift
AppConfigManager.url(for: "users")   // .../api/users
AppConfigManager.url(for: "/users")   // .../api/users
```

---

## 7. Feature Flags

```swift
// Set at launch (e.g. from remote config)
AppConfigManager.setFeature("darkMode", enabled: true)
AppConfigManager.setFeature("newCheckout", enabled: false)

// Check
if AppConfigManager.isFeatureEnabled("darkMode") {
    // Enable dark mode UI
}
```

---

## 8. Constants

### 8.1 UserDefaults Keys

```swift
UserDefaults.standard.set(email, forKey: AppConfigManager.UDKeys.userEmail)
let token = UserDefaults.standard.string(forKey: AppConfigManager.UDKeys.userAccessToken)
```

### 8.2 Product IDs

```swift
let productId = AppConfigManager.ProductIDs.monthProductId
```

### 8.3 Notification Names

```swift
NotificationCenter.default.post(name: NSNotification.Name(AppConfigManager.Notifications.premiumSuccessCallback), object: nil)
```

---

## 9. Integration with Existing Constants

If you have `Constant.swift`, `UD.swift`, `URLs.swift`, you can:

1. **Keep them** — Use AppConfigManager for new code; migrate gradually.
2. **Migrate** — Point `Constants.UD` to `AppConfigManager.UDKeys` or alias.
3. **Replace** — Move all values into AppConfigManager and remove old files.

Example alias:

```swift
// In UD.swift or Constant.swift
extension Constants.UD {
    static let USER_EMAIL = AppConfigManager.UDKeys.userEmail
}
```

---

## 10. Summary

- **Environment:** `AppConfigManager.environment` (debug/release/staging).
- **Version:** `appVersion`, `buildNumber`, `fullVersion`, `isDebug`.
- **URLs:** `baseURL`, `url(for: path)`.
- **Features:** `isFeatureEnabled`, `setFeature`.
- **Constants:** `UDKeys`, `ProductIDs`, `Notifications`.

For more detail, see **AppConfigManager.swift**.
