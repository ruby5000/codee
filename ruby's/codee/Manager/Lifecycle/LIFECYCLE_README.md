# Lifecycle Manager — How to Use

Centralized **app lifecycle** observers: active, inactive, background, foreground, terminate.

---

## 1. Overview

**LifecycleManager** provides:

- **State** — active, inactive, background, terminated
- **Handlers** — onDidBecomeActive, onWillResignActive, onDidEnterBackground, onWillEnterForeground, onWillTerminate
- **Helpers** — isActive, isInBackground

---

## 2. Quick Reference

| Need | Use |
|------|-----|
| On active | `LifecycleManager.onDidBecomeActive = { ... }` |
| On inactive | `LifecycleManager.onWillResignActive = { ... }` |
| On background | `LifecycleManager.onDidEnterBackground = { ... }` |
| On foreground | `LifecycleManager.onWillEnterForeground = { ... }` |
| On terminate | `LifecycleManager.onWillTerminate = { ... }` |
| Is active? | `LifecycleManager.isActive` |
| Is background? | `LifecycleManager.isInBackground` |

---

## 3. Setup

### 3.1 SceneDelegate

```swift
func sceneDidBecomeActive(_ scene: UIScene) {
    LifecycleManager.didBecomeActive()
}

func sceneWillResignActive(_ scene: UIScene) {
    LifecycleManager.willResignActive()
}

func sceneDidEnterBackground(_ scene: UIScene) {
    LifecycleManager.didEnterBackground()
}

func sceneWillEnterForeground(_ scene: UIScene) {
    LifecycleManager.willEnterForeground()
}
```

### 3.2 AppDelegate (if no SceneDelegate)

```swift
func applicationDidBecomeActive(_ application: UIApplication) {
    LifecycleManager.didBecomeActive()
}

func applicationWillResignActive(_ application: UIApplication) {
    LifecycleManager.willResignActive()
}

func applicationDidEnterBackground(_ application: UIApplication) {
    LifecycleManager.didEnterBackground()
}

func applicationWillEnterForeground(_ application: UIApplication) {
    LifecycleManager.willEnterForeground()
}

func applicationWillTerminate(_ application: UIApplication) {
    LifecycleManager.willTerminate()
}
```

---

## 4. Usage

```swift
LifecycleManager.onDidEnterBackground = {
    CacheManager.clearMemory()
    BackgroundTaskManager.scheduleRefresh()
}

LifecycleManager.onWillEnterForeground = {
    Task { await SyncManager.syncIfNeeded() }
}
```

---

## 5. Summary

- **State:** active, inactive, background, terminated
- **Handlers:** onDidBecomeActive, onWillResignActive, onDidEnterBackground, onWillEnterForeground, onWillTerminate
- **Notify:** Call didBecomeActive, etc. from AppDelegate/SceneDelegate

For more detail, see **LifecycleManager.swift**.
