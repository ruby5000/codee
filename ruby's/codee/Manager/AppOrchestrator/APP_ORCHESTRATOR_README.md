# App Orchestrator / Application Manager — How to Use

Orchestrates **app startup**, initialization order, and shutdown.

---

## 1. Overview

**ApplicationManager** provides:

- **Startup phases** — config, logging, analytics, network, auth, ui, complete
- **Phase handlers** — Sync or async per phase
- **Startup** — `startup()` or `startupAsync()`
- **Shutdown** — `willTerminate()`

---

## 2. Quick Reference

| Need | Use |
|------|-----|
| Run startup | `ApplicationManager.startup()` |
| Async startup | `await ApplicationManager.startupAsync()` |
| Add phase handler | `ApplicationManager.onPhase[.config] = { ... }` |
| Add async handler | `ApplicationManager.onPhaseAsync[.auth] = { ... }` |
| On complete | `ApplicationManager.onStartupComplete = { ... }` |
| On terminate | `ApplicationManager.onWillTerminate = { ... }` |
| Is ready? | `ApplicationManager.isReady` |

---

## 3. Setup

### 3.1 AppDelegate

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    ApplicationManager.onPhase[.config] = { AppConfigManager.baseURL = "https://api.example.com" }
    ApplicationManager.onPhase[.logging] = { LoggerManager.minimumLevel = .debug }
    ApplicationManager.onPhase[.analytics] = { AnalyticsManager.setUserId(SessionManager.currentUserId) }
    ApplicationManager.onPhase[.network] = { _ = AppNetworkMonitor.shared }
    ApplicationManager.startup()
    return true
}

func applicationWillTerminate(_ application: UIApplication) {
    ApplicationManager.willTerminate()
}
```

---

## 4. Phase Order

1. **config** — AppConfig, constants
2. **logging** — Logger setup
3. **analytics** — Analytics init
4. **network** — Network monitor
5. **auth** — Session restore
6. **ui** — UI preload
7. **complete** — Ready

---

## 5. Summary

- **Phases:** config, logging, analytics, network, auth, ui, complete
- **Handlers:** `onPhase`, `onPhaseAsync`
- **Startup:** `startup()`, `startupAsync()`
- **Shutdown:** `willTerminate()`, `onWillTerminate`

For more detail, see **ApplicationManager.swift**.
