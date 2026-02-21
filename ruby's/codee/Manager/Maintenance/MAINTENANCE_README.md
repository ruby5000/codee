# Maintenance Manager — How to Use

**App maintenance**: cache cleanup, storage cleanup, data migration.

---

## 1. Overview

**MaintenanceManager** provides:

- **Run maintenance** — Clear caches, clean storage, migrate
- **Scheduled** — Run if interval passed (`runIfNeeded`)
- **Handlers** — onClearCaches, onCleanStorage, onMigrate, performMaintenance

---

## 2. Quick Reference

| Need | Use |
|------|-----|
| Run if needed | `await MaintenanceManager.runIfNeeded()` |
| Run now | `await MaintenanceManager.run()` |
| Clear caches | `MaintenanceManager.clearCaches()` |
| Clean storage | `MaintenanceManager.cleanStorage()` |
| Migrate | `try MaintenanceManager.migrate()` |
| Set handlers | `MaintenanceManager.onClearCaches = { ... }` |
| Interval | `MaintenanceManager.maintenanceInterval = 86400` |

---

## 3. Setup

```swift
MaintenanceManager.onClearCaches = {
    CacheManager.clearMemory()
    ImageManager.clearMemoryCache {}
}

MaintenanceManager.onCleanStorage = {
    // Delete old temp files
    let temp = FileManager.default.temporaryDirectory
    try? FileManager.default.contentsOfDirectory(at: temp, includingPropertiesForKeys: nil)
        .forEach { try? FileManager.default.removeItem(at: $0) }
}

MaintenanceManager.onMigrate = {
    // Run schema migrations
}

LifecycleManager.onWillEnterForeground = {
    Task { await MaintenanceManager.runIfNeeded() }
}
```

---

## 4. Summary

- **Run:** `run()`, `runIfNeeded()`, `clearCaches()`, `cleanStorage()`, `migrate()`
- **Handlers:** onClearCaches, onCleanStorage, onMigrate, performMaintenance
- **Config:** maintenanceInterval, lastMaintenanceDate

For more detail, see **MaintenanceManager.swift**.
