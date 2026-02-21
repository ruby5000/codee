# Deep Link Manager — How to Use

Centralized **deep link** and **universal link** handling. Parses URLs and routes to app screens.

---

## 1. Overview

**DeepLinkManager** provides:

- **Parse URL** — Convert URL to `DeepLinkRoute` (home, profile, inbox, etc.).
- **Handle** — Process incoming URLs and route via `onHandle` callback.
- **Build URL** — Create deep link URLs for sharing.
- **Universal links** — Handle `NSUserActivity` from web links.

---

## 2. Quick Reference

| Need | Use |
|------|-----|
| Parse URL | `DeepLinkManager.parse(url)` |
| Handle URL | `DeepLinkManager.handle(url)` |
| Handle open URL | `DeepLinkManager.handleOpenURL(url)` |
| Handle universal link | `DeepLinkManager.handleUserActivity(userActivity)` |
| Build URL | `DeepLinkManager.buildURL(for: .profile(userId: "123"))` |
| Set handler | `DeepLinkManager.onHandle = { route in ... }` |

---

## 3. Setup

### 3.1 Configure Scheme

In `AppDelegate` or at launch:

```swift
DeepLinkManager.urlScheme = "myapp"  // myapp://
DeepLinkManager.universalLinkHost = "links.example.com"
```

### 3.2 Set Handler

```swift
DeepLinkManager.onHandle = { route in
    switch route {
    case .home:
        navigateToHome()
    case .profile(let userId):
        navigateToProfile(userId: userId)
    case .inbox:
        navigateToInbox()
    case .premium:
        navigateToPremium()
    default:
        return false
    }
    return true
}
```

### 3.3 AppDelegate / SceneDelegate

**URL Scheme (myapp://):**

```swift
func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
    return DeepLinkManager.handleOpenURL(url)
}
```

**Universal Links:**

```swift
func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
    _ = DeepLinkManager.handleUserActivity(userActivity)
}
```

---

## 4. Routes

| Route | Example URL |
|-------|-------------|
| home | myapp://home |
| profile | myapp://profile/123 or myapp://profile?userId=123 |
| inbox | myapp://inbox |
| settings | myapp://settings |
| premium | myapp://premium |
| custom | myapp://custom/path?key=value |

---

## 5. Add Custom Routes

Edit `parse(_:)` in DeepLinkManager.swift to add routes:

```swift
case "game":
    let gameId = pathComponents.count > 1 ? pathComponents[1] : nil
    return .custom(path: "game", query: ["gameId": gameId ?? ""])
```

Or extend `DeepLinkRoute` with new cases.

---

## 6. Build Shareable Links

```swift
if let url = DeepLinkManager.buildURL(for: .profile(userId: "123")) {
    // url = myapp://profile?userId=123
    share(url)
}
```

---

## 7. Info.plist

**URL Scheme:**

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array><string>myapp</string></array>
        <key>CFBundleURLName</key>
        <string>com.yourapp.deepLink</string>
    </dict>
</array>
```

**Universal Links:** Add associated domains in Signing & Capabilities.

---

## 8. Summary

- **Parse:** `parse(url)` → `DeepLinkRoute`
- **Handle:** `handle`, `handleOpenURL`, `handleUserActivity`
- **Build:** `buildURL(for:route:query:)`
- **Config:** `urlScheme`, `universalLinkHost`, `onHandle`

For more detail, see **DeepLinkManager.swift**.
