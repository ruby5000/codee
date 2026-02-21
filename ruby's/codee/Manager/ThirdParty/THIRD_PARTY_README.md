# Third Party Manager — How to Use

Centralized **third-party SDK** initialization: Firebase, AppsFlyer, etc.

---

## 1. Overview

**ThirdPartyManager** provides:

- **Register initializers** — Sync or async per SDK
- **Initialize all** — Run all at startup
- **Initialize one** — Run single SDK
- **Track** — Which SDKs are initialized

---

## 2. Quick Reference

| Need | Use |
|------|-----|
| Add init | `ThirdPartyManager.initializers["firebase"] = { FirebaseApp.configure() }` |
| Add async | `ThirdPartyManager.asyncInitializers["analytics"] = { ... }` |
| Init all | `ThirdPartyManager.initializeAll()` |
| Init all async | `await ThirdPartyManager.initializeAllAsync()` |
| Init one | `ThirdPartyManager.initialize("firebase")` |
| Is init? | `ThirdPartyManager.isInitialized("firebase")` |

---

## 3. Setup

```swift
ThirdPartyManager.initializers["firebase"] = {
    FirebaseApp.configure()
}

ThirdPartyManager.initializers["appsflyer"] = {
    AppsFlyerLib.shared().start()
}

ApplicationManager.onPhase[.analytics] = {
    ThirdPartyManager.initializeAll()
}
```

---

## 4. Summary

- **Register:** initializers, asyncInitializers
- **Init:** initializeAll, initializeAllAsync, initialize
- **Track:** initialized, isInitialized

For more detail, see **ThirdPartyManager.swift**.
