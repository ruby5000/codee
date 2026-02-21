# Logger Manager — How to Use

Central logging with **log levels**, **emoji prefixes**, and **timestamps**. Use one API for debug, info, success, warning, error, and custom data prints.

---

## 1. Overview

**LoggerManager** provides:

- **Log levels** — Verbose, Debug, Info, Success, Warning, Error (each with a distinct emoji).
- **Timestamps** — Every line includes time (e.g. `14:32:01.234`); format is configurable.
- **Emoji system** — Quick visual scan in the console (🔍 debug, ℹ️ info, ✅ success, ⚠️ warning, ❌ error, etc.).
- **Print data** — Log any value (strings, numbers, arrays, dictionaries) with an optional emoji and label.
- **Categories** — Optional category/tag (e.g. Network, Cache, Auth).
- **Optional file:line** — Turn on for debug to see where each log came from.
- **Minimum level** — Filter out logs below a level (e.g. only warnings and errors in Release).

All APIs are static on `LoggerManager`; no instance needed.

---

## 2. Quick reference

| Need | Use |
|------|-----|
| Debug message | `LoggerManager.debug("message")` |
| Info | `LoggerManager.info("message")` |
| Success | `LoggerManager.success("message")` |
| Warning | `LoggerManager.warning("message")` |
| Error | `LoggerManager.error("message")` |
| Verbose / trace | `LoggerManager.verbose("message")` |
| Log any data (emoji + time) | `LoggerManager.printData(value, emoji: "📦", label: "DATA")` |
| Quick dump for debug | `LoggerManager.dump(someValue)` |
| Custom emoji + label | `LoggerManager.custom(emoji: "🎯", label: "CUSTOM", "message")` |
| Network log | `LoggerManager.network("GET /api/users")` |
| Cache log | `LoggerManager.cache("Hit for key x")` |
| With category | `LoggerManager.info("Done", category: "Sync")` |
| Only errors in Release | Set `LoggerManager.minimumLevel = .error` |

---

## 3. Emoji reference

| Level / use | Emoji | Method |
|-------------|--------|--------|
| Verbose | 📋 | `verbose(_:)` |
| Debug | 🔍 | `debug(_:)` |
| Info | ℹ️ | `info(_:)` |
| Success | ✅ | `success(_:)` |
| Warning | ⚠️ | `warning(_:)` |
| Error | ❌ | `error(_:)` |
| Data / dump | 📦 (or 🔍 for dump) | `printData(_:emoji:label:)`, `dump(_:)` |
| Network | 📤 | `network(_:)` |
| Cache | 💾 | `cache(_:)` |
| UI | 🖼️ | `ui(_:)` |
| Auth | 🔐 | `auth(_:)` |
| Analytics | 📊 | `analytics(_:)` |
| Custom | Any | `custom(emoji:label:_:)` |

---

## 4. Basic usage

### 4.1 Level-based logging

```swift
LoggerManager.debug("Fetching user profile")
LoggerManager.info("Screen appeared")
LoggerManager.success("Login completed")
LoggerManager.warning("API rate limit approaching")
LoggerManager.error("Failed to save: \(error.localizedDescription)")
LoggerManager.verbose("Detail: \(someVar)")
```

**Example output:**

```
14:32:01.234 🔍 [DEBUG] → Fetching user profile
14:32:01.235 ℹ️ [INFO] → Screen appeared
14:32:01.240 ✅ [SUCCESS] → Login completed
14:32:01.245 ⚠️ [WARNING] → API rate limit approaching
14:32:01.250 ❌ [ERROR] → Failed to save: The file could not be saved.
```

### 4.2 With category

```swift
LoggerManager.info("Request started", category: "Network")
LoggerManager.cache("Miss for key: \(key)")
LoggerManager.auth("Token refreshed")
```

**Example output:**

```
14:32:01.100 ℹ️ [INFO] Network → Request started
14:32:01.101 💾 [CACHE] → Miss for key: user.123
14:32:01.102 🔐 [AUTH] → Token refreshed
```

### 4.3 Print data (any type, with time + emoji)

```swift
LoggerManager.printData(userId, emoji: "🆔", label: "USER_ID")
LoggerManager.printData(["a", "b", "c"], emoji: "📋", label: "LIST")
LoggerManager.printData(["name": "Jane", "age": 30], emoji: "📦", label: "DATA")
```

For quick debug dumps:

```swift
LoggerManager.dump(responseDictionary)
LoggerManager.dump(apiError)
```

---

## 5. Configuration

### 5.1 Minimum log level

Only messages at or above this level are printed. Use in Release to reduce noise.

```swift
// In AppDelegate or init, e.g. for Release:
#if !DEBUG
LoggerManager.minimumLevel = .warning  // only warning and error
// or
LoggerManager.minimumLevel = .error    // only errors
#endif
```

### 5.2 Show file and line

Useful during development to see where each log came from.

```swift
LoggerManager.showFileLine = true
LoggerManager.debug("Check this")
// 14:32:01.234 🔍 [DEBUG] ViewController.swift:42 → Check this
```

### 5.3 Timestamp format

Default is `HH:mm:ss.SSS`. Change if you want date or different precision.

```swift
LoggerManager.timeFormat = "yyyy-MM-dd HH:mm:ss"
LoggerManager.updateTimeFormat()
```

### 5.4 Default category

Apply a category to every log (e.g. module name).

```swift
LoggerManager.defaultCategory = "MyFeature"
LoggerManager.info("Started")  // → ... [INFO] MyFeature → Started
```

---

## 6. Custom emoji and labels

Use `custom(emoji:label:_:)` for any emoji and label:

```swift
LoggerManager.custom(emoji: "🚀", label: "LAUNCH", "App did finish launching")
LoggerManager.custom(emoji: "📍", label: "LOCATION", "Lat: \(lat), Lon: \(lon)")
```

Use `printData(_:emoji:label:)` when the message is the string representation of a value:

```swift
LoggerManager.printData(deviceModel, emoji: "📱", label: "DEVICE")
```

---

## 7. Summary

- **Levels:** `verbose`, `debug`, `info`, `success`, `warning`, `error` — each with a fixed emoji and timestamp.
- **Data:** `printData(_:emoji:label:)` for any value; `dump(_:)` for quick debug.
- **Convenience:** `network`, `cache`, `ui`, `auth`, `analytics` for common domains.
- **Config:** `minimumLevel`, `showFileLine`, `timeFormat`, `defaultCategory`.
- **Custom:** `custom(emoji:label:_:)` for your own emoji and label.

All logging is thread-safe and prints in a consistent format: **time emoji [LABEL] (category) (file:line) → message**.
