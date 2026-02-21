# Analytics Manager — How to Use

Centralized **analytics** for events, screen views, and user properties. Integrates with Firebase Analytics; works without it for testing.

---

## 1. Overview

**AnalyticsManager** provides:

- **Log events** — Custom events with optional parameters.
- **Screen views** — Track screen navigation.
- **User properties** — Set user ID and custom properties.
- **Predefined events** — Purchase, login, share, button click.
- **Custom handler** — Forward to other providers or test.

---

## 2. Quick Reference

| Need | Use |
|------|-----|
| Log event | `AnalyticsManager.logEvent("event_name", parameters: [...])` |
| Screen view | `AnalyticsManager.logScreenView("HomeScreen")` |
| User ID | `AnalyticsManager.setUserId("123")` |
| User property | `AnalyticsManager.setUserProperty("value", forName: "key")` |
| Purchase | `AnalyticsManager.logPurchaseSuccess(productId: "x")` |
| Button click | `AnalyticsManager.logButtonClick(buttonName: "buy")` |
| Share | `AnalyticsManager.logShare(contentType: "video")` |
| Login | `AnalyticsManager.logLogin(method: "google")` |
| Disable | `AnalyticsManager.isEnabled = false` |

---

## 3. Setup

### 3.1 Add Firebase (Optional)

Add FirebaseAnalytics via SPM or CocoaPods. AnalyticsManager will use it when available.

### 3.2 Configure at Launch

```swift
AnalyticsManager.isEnabled = !AppConfigManager.isDebug  // Disable in debug
```

---

## 4. Log Events

```swift
AnalyticsManager.logEvent("level_complete", parameters: [
    "level": 5,
    "score": 1200
])
```

---

## 5. Screen Tracking

In `viewDidAppear`:

```swift
override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    AnalyticsManager.logScreenView("HomeScreen", screenClass: "HomeViewController")
}
```

---

## 6. User Properties

```swift
AnalyticsManager.setUserId(SessionManager.currentUserId)
AnalyticsManager.setUserProperty("premium", forName: "subscription_tier")
```

---

## 7. Predefined Events

```swift
AnalyticsManager.logPurchaseSuccess(productId: "month.premium", value: 9.99)
AnalyticsManager.logButtonClick(buttonName: "purchase", screen: "Premium")
AnalyticsManager.logShare(contentType: "card", itemId: "123")
AnalyticsManager.logLogin(method: "apple")
```

---

## 8. Custom Handler (Testing)

```swift
AnalyticsManager.customHandler = { name, params in
    print("Analytics: \(name) \(params ?? [:])")
}
```

---

## 9. Integration with FirebaseEventManager

Replace direct `FirebaseEventManager` calls with `AnalyticsManager`:

```swift
// Before
FirebaseEventManager.shared.logPurchaseSuccess(productId: id)

// After
AnalyticsManager.logPurchaseSuccess(productId: id)
```

---

## 10. Summary

- **Events:** `logEvent`, `log`
- **Screens:** `logScreenView`
- **User:** `setUserId`, `setUserProperty`
- **Predefined:** `logPurchaseSuccess`, `logButtonClick`, `logShare`, `logLogin`, `logSignUp`
- **Config:** `isEnabled`, `customHandler`

For more detail, see **AnalyticsManager.swift**.
