# Sync Manager — How to Use

Centralized **sync logic**: pending queue, retry, and conflict resolution.

---

## 1. Overview

**SyncManager** provides:

- **Pending queue** — Queue items for sync.
- **Sync** — Run sync via `performSync` handler.
- **Status** — idle, syncing, success, failed.
- **Conflict resolution** — Local vs server timestamp.

---

## 2. Quick Reference

| Need | Use |
|------|-----|
| Queue item | `SyncManager.queueForSync(id: "123")` |
| Remove from queue | `SyncManager.removeFromQueue(id: "123")` |
| Clear queue | `SyncManager.clearPending()` |
| Has pending? | `SyncManager.hasPending` |
| Sync | `await SyncManager.sync()` |
| Sync if needed | `await SyncManager.syncIfNeeded()` |
| Status | `SyncManager.status` |
| Set sync handler | `SyncManager.performSync = { ... }` |
| Set conflict resolver | `SyncManager.resolveConflict = { ... }` |

---

## 3. Setup

### 3.1 Implement Sync Handler

```swift
SyncManager.performSync = {
    for id in SyncManager.pendingItems {
        try await api.uploadItem(id: id)
        SyncManager.removeFromQueue(id: id)
    }
}
```

### 3.2 Persist Pending (Optional)

```swift
SyncManager.pendingItemsDidChange = {
    UserDefaults.standard.set(SyncManager.pendingItems, forKey: "sync_pending")
}

// At launch
SyncManager.pendingItems = UserDefaults.standard.stringArray(forKey: "sync_pending") ?? []
```

---

## 4. Queue on Change

```swift
func saveItem(_ item: Item) {
    localDB.save(item)
    SyncManager.queueForSync(id: item.id)
}
```

---

## 5. Sync Triggers

```swift
// On app foreground
func sceneWillEnterForeground() {
    Task { await SyncManager.syncIfNeeded() }
}

// With BackgroundTaskManager
BackgroundTaskManager.onSync = { await SyncManager.sync() }
```

---

## 6. Conflict Resolution

```swift
SyncManager.resolveConflict = { itemId, localDate, serverDate in
    // true = use local, false = use server
    return localDate > serverDate
}
```

---

## 7. Summary

- **Queue:** `queueForSync`, `removeFromQueue`, `clearPending`, `hasPending`
- **Sync:** `sync`, `syncIfNeeded`, `performSync` handler
- **Status:** `status` (idle, syncing, success, failed)
- **Conflict:** `resolveConflict` handler

For more detail, see **SyncManager.swift**.
