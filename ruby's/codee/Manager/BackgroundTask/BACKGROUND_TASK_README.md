# Background Task Manager — How to Use

Manages **iOS background tasks** (BGTaskScheduler) for deferred work like refresh and sync.

---

## 1. Overview

**BackgroundTaskManager** provides:

- **Schedule refresh** — Lightweight background refresh (e.g. 15 min).
- **Schedule sync** — Heavier processing (e.g. 30 min, requires network).
- **Register handlers** — Set up in AppDelegate.
- **Handlers** — `onRefresh`, `onSync` async closures.

---

## 2. Quick Reference

| Need | Use |
|------|-----|
| Schedule refresh | `BackgroundTaskManager.scheduleRefresh()` |
| Schedule sync | `BackgroundTaskManager.scheduleSync()` |
| Register handlers | `BackgroundTaskManager.registerTasks()` |
| Set refresh handler | `BackgroundTaskManager.onRefresh = { ... }` |
| Set sync handler | `BackgroundTaskManager.onSync = { ... }` |

---

## 3. Setup

### 3.1 Info.plist

Add to `UIBackgroundModes`:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>processing</string>
</array>
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.app.refresh</string>
    <string>com.app.sync</string>
</array>
```

### 3.2 AppDelegate

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    BackgroundTaskManager.registerTasks()
    BackgroundTaskManager.onRefresh = { await refreshData() }
    BackgroundTaskManager.onSync = { await syncData() }
    BackgroundTaskManager.scheduleRefresh()
    return true
}
```

### 3.3 After Foreground

```swift
func sceneWillEnterForeground(_ scene: UIScene) {
    BackgroundTaskManager.scheduleRefresh()
}
```

---

## 4. Handlers

```swift
BackgroundTaskManager.onRefresh = {
    await fetchLatestData()
    await CacheManager.clearMemory()
}

BackgroundTaskManager.onSync = {
    await SyncManager.syncPending()
}
```

---

## 5. Summary

- **Schedule:** `scheduleRefresh`, `scheduleSync`
- **Register:** `registerTasks` in AppDelegate
- **Handlers:** `onRefresh`, `onSync` (async closures)

For more detail, see **BackgroundTaskManager.swift**.
