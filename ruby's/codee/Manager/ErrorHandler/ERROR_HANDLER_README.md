# Error Handler — How to Use

Centralized **error handling**: present alerts, log, and optional recovery.

---

## 1. Overview

**ErrorHandler** provides:

- **AppError** — Typed app errors (network, server, validation, auth).
- **Handle** — Log + present alert for any Error.
- **Custom present/log** — Override default behavior.
- **Result helper** — Unwrap Result or handle failure.

---

## 2. Quick Reference

| Need | Use |
|------|-----|
| Handle error (alert) | `ErrorHandler.handle(error, presentTo: self)` |
| Handle with custom message | `ErrorHandler.handle(error, customMessage: "Try again")` |
| Log only (no alert) | `ErrorHandler.handleSilently(error)` |
| Result unwrap | `ErrorHandler.handleResult(result, onSuccess: { ... })` |
| Create AppError | `AppError.validation(message: "Invalid email")` |
| Custom present | `ErrorHandler.present = { msg, title, vc in ... }` |
| Custom log | `ErrorHandler.log = { error in ... }` |

---

## 3. Setup

Add **ErrorHandler.swift** (and **ErrorHandler** folder) to your app target. Requires UIKit.

---

## 4. Basic Usage

```swift
do {
    try await fetchData()
} catch {
    ErrorHandler.handle(error, presentTo: self)
}
```

---

## 5. AppError

```swift
throw AppError.validation(message: "Email is invalid")
throw AppError.network(underlying: urlError)
throw AppError.server(message: "Server is down")
throw AppError.auth(message: "Session expired")
throw AppError.custom(message: "Custom message")
```

---

## 6. Custom Present (e.g. Snackbar)

```swift
ErrorHandler.present = { message, title, vc in
    SnackbarManager.show(message: message)
}
```

---

## 7. Custom Log (e.g. LoggerManager)

```swift
ErrorHandler.log = { error in
    LoggerManager.error(error.localizedDescription)
}
```

---

## 8. Result Helper

```swift
ErrorHandler.handleResult(apiResult, presentTo: self) { data in
    // use data
}
```

---

## 9. Summary

- **Handle:** `handle`, `handleSilently`, `handleResult`
- **AppError:** `network`, `server`, `validation`, `auth`, `unknown`, `custom`
- **Customize:** `present`, `log`, `logBeforePresent`

For more detail, see **ErrorHandler.swift**.
