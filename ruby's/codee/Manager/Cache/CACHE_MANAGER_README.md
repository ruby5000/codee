# Cache Manager — How to Use

Centralized **in-memory and disk cache** for strings, data, and Codable objects. Use for API responses, user preferences, or any cacheable data.

---

## 1. Overview

**CacheManager** provides:

- **Store** — Data, String, or Encodable (JSON) by key.
- **Fetch** — Data, String, or Decodable by key. Memory first, then disk.
- **Exists** — Check if key is cached.
- **Remove** — Remove single key or clear all.
- **Async** — `performAsync` for off-main-thread operations.

All APIs are static. Thread-safe. No external dependencies.

---

## 2. Quick Reference

| Need | Use |
|------|-----|
| Store data | `try CacheManager.store(data, forKey: "key")` |
| Store string | `try CacheManager.store("value", forKey: "key")` |
| Store Codable | `try CacheManager.store(myObject, forKey: "key")` |
| Fetch data | `let data = try CacheManager.fetchData(forKey: "key")` |
| Fetch string | `let s = try CacheManager.fetchString(forKey: "key")` |
| Fetch Codable | `let obj = try CacheManager.fetch(MyType.self, forKey: "key")` |
| Exists? | `CacheManager.exists(forKey: "key")` |
| Remove key | `CacheManager.remove(forKey: "key")` |
| Clear memory | `CacheManager.clearMemory()` |
| Clear disk | `try CacheManager.clearDisk()` |
| Clear all | `try CacheManager.clearAll()` |

---

## 3. Setup

### 3.1 Add to Xcode

Add **CacheManager.swift** (and **Cache** folder) to your app target. No dependencies.

### 3.2 Optional Configuration

```swift
// Custom disk directory
CacheManager.diskCacheDirectory = customURL

// Disable disk (memory only)
CacheManager.useDisk = false
```

---

## 4. Store

### 4.1 Store Data

```swift
let data = Data([0x01, 0x02, 0x03])
try CacheManager.store(data, forKey: "binary")
```

### 4.2 Store String

```swift
try CacheManager.store("cached value", forKey: "user_pref")
```

### 4.3 Store Codable

```swift
struct UserProfile: Codable {
    let name: String
    let score: Int
}
let profile = UserProfile(name: "Jane", score: 100)
try CacheManager.store(profile, forKey: "profile")
```

---

## 5. Fetch

### 5.1 Fetch Data

```swift
let data = try CacheManager.fetchData(forKey: "binary")
```

### 5.2 Fetch String

```swift
let text = try CacheManager.fetchString(forKey: "user_pref")
```

### 5.3 Fetch Codable

```swift
let profile = try CacheManager.fetch(UserProfile.self, forKey: "profile")
```

### 5.4 Handle Miss

```swift
if CacheManager.exists(forKey: "key") {
    let value = try CacheManager.fetchString(forKey: "key")
} else {
    // Fetch from API, then cache
}
```

---

## 6. Remove and Clear

### 6.1 Remove Single Key

```swift
CacheManager.remove(forKey: "old_key")
```

### 6.2 Clear Memory Only

Use when you receive a memory warning:

```swift
CacheManager.clearMemory()
```

### 6.3 Clear Disk

```swift
try CacheManager.clearDisk()
```

### 6.4 Clear All

```swift
try CacheManager.clearAll()
```

---

## 7. Async Usage

For heavy operations without blocking the main thread:

```swift
let profile = try await CacheManager.performAsync {
    try CacheManager.fetch(UserProfile.self, forKey: "profile")
}
```

---

## 8. Cache API Responses

```swift
// After API call
let response = try await api.fetchUsers()
try CacheManager.store(response, forKey: "users_list")

// On next load
if CacheManager.exists(forKey: "users_list") {
    let cached = try CacheManager.fetch([User].self, forKey: "users_list")
    showUsers(cached)
} else {
    let fresh = try await api.fetchUsers()
    try CacheManager.store(fresh, forKey: "users_list")
    showUsers(fresh)
}
```

---

## 9. Key Naming

Use a consistent prefix to avoid collisions:

```swift
let key = "api.users.\(userId)"
try CacheManager.store(data, forKey: key)
```

---

## 10. Summary

- **Store:** `store(_:forKey:)` for Data/String/Encodable.
- **Fetch:** `fetchData`, `fetchString`, `fetch(_:forKey:)` for Decodable.
- **Exists:** `exists(forKey:)`.
- **Remove:** `remove(forKey:)`, `clearMemory()`, `clearDisk()`, `clearAll()`.
- **Async:** `performAsync` for background work.

For more detail, see **CacheManager.swift**.
