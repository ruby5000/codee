# Thread Manager — Guide & Tutorial

This guide describes the **Thread Manager** Swift helper and how to use it across your iOS app for main thread, background work, delays, async execution, and other threading patterns.

---

## 1. Overview

**ThreadManager** is a single, centralized utility that provides:

- **Main thread** — Run code on the main thread (async/sync, with optional delay).
- **Background execution** — Run work on background queues (general and heavy).
- **Delays** — Schedule work after a time interval, with optional cancellation (GCD or async/await).
- **Async execution** — Run work in the background and get results (callbacks or async/await).
- **Thread-safe access** — Serialized read/write for shared state.
- **Debounce & throttle** — Limit how often a block runs (e.g. search, scroll).
- **Retry** — Retry async work with optional exponential backoff.
- **Once** — Run a block only once per token (thread-safe).

All APIs are static on `ThreadManager`; no instance is required.

---

## 2. Quick reference

| Need | Use |
|------|-----|
| Update UI | `ThreadManager.onMain { … }` |
| Do work off main, then update UI | `ThreadManager.onBackground(thenOnMain: { … }, background: { … })` |
| Run after delay | `ThreadManager.after(2.0) { … }` or `await ThreadManager.delay(seconds: 2)` |
| Cancellable delay | Keep `DispatchWorkItem` from `after(_:on:_:)` and call `.cancel()` |
| Background work + result on main | `ThreadManager.runAsync(work: completion:)` or `asyncOnBackground(work:completionOnMain:onFailure:)` |
| Async/await off main | `ThreadManager.runDetached { … }` |
| Thread-safe read/write | `ThreadManager.sync { … }` |
| Debounce (e.g. search) | `ThreadManager.debounce(interval:action:)` |
| Throttle (e.g. scroll) | `ThreadManager.throttle(interval:action:)` |
| Retry with backoff | `try await ThreadManager.retry(maxAttempts:delay:useBackoff:work:)` |
| Run once per token | `ThreadManager.once(token: "id", { … })` |

---

## 3. Step-by-step tutorials

### 3.1 Updating the UI from anywhere (main thread)

**Scenario:** You have a result from a callback or background queue and need to update labels, tables, or any UI.

**Steps:**

1. Wrap the UI update in a closure.
2. Call `ThreadManager.onMain` with that closure.

**Example:**

```swift
// From a completion handler or background queue
someAPI.fetchUser { user in
    ThreadManager.onMain {
        self.nameLabel.text = user.name
        self.tableView.reloadData()
    }
}
```

**If you need a delay before updating (e.g. hide a toast after 2 seconds):**

```swift
ThreadManager.onMain(after: 2.0) {
    self.toastView.isHidden = true
}
```

**When to use:** Any time you need to touch UIKit/AppKit from a non-main thread. Prefer `onMain`; use `onMainSync` only when you truly need to block until the work is done.

---

### 3.2 Doing work in the background, then updating the UI

**Scenario:** Load or process data off the main thread, then show the result in the UI.

**Steps:**

1. Put the heavy work in the `background` closure.
2. Put UI updates (or any main-thread work) in the `thenOnMain` closure.

**Example:**

```swift
ThreadManager.onBackground(thenOnMain: {
    self.spinner.stopAnimating()
    self.tableView.reloadData()
}, background: {
    let items = self.loadItemsFromDisk()  // slow
    self.cachedItems = items
})
```

Heavy work runs on a background queue; the completion runs on the main thread.

---

### 3.3 Running code after a delay (and cancelling it)

**Scenario:** Show a message for 3 seconds, or cancel the delayed action if the user navigates away.

**Steps:**

1. Use `ThreadManager.after(_:on:_:)` and store the returned `DispatchWorkItem`.
2. To cancel, call `workItem.cancel()` before the delay elapses.

**Example:**

```swift
// Schedule
let workItem = ThreadManager.after(3.0) {
    self.showMessage("Done")
}

// Later, if user leaves the screen:
workItem.cancel()
```

**Using async/await (e.g. in a view model or actor):**

```swift
func waitThenUpdate() async {
    await ThreadManager.delay(seconds: 2.0)
    await MainActor.run {
        self.status = "Ready"
    }
}
```

For cancellation-aware delay (e.g. when the `Task` is cancelled), use the throwing overload:

```swift
try await ThreadManager.delay(seconds: 2.0)  // throws if task cancelled
```

---

### 3.4 Getting a result from background work (callback style)

**Scenario:** Fetch or compute something in the background and handle success/error on the main thread.

**Steps:**

1. Use `ThreadManager.runAsync(work:completion:)` (or `asyncOnBackground(work:completionOnMain:onFailure:)`).
2. In `work`, return (or throw) the value.
3. In `completion`, handle `Result<T, Error>`; it’s called on the main thread.

**Example:**

```swift
ThreadManager.runAsync(
    work: { try self.api.fetchUser(id: userID) },
    completion: { result in
        switch result {
        case .success(let user):
            self.nameLabel.text = user.name
        case .failure(let error):
            self.showError(error)
        }
    }
)
```

With the convenience API:

```swift
ThreadManager.asyncOnBackground(
    work: { try self.api.fetchUser(id: userID) },
    completionOnMain: { user in
        self.nameLabel.text = user.name
    },
    onFailure: { error in
        self.showError(error)
    }
)
```

---

### 3.5 Using async/await with Thread Manager

**Scenario:** You’re in an async context and want to run work off the main actor or add a delay.

**Steps:**

1. Use `ThreadManager.runDetached` for non-main work that returns a value.
2. Use `ThreadManager.delay(seconds:)` for waiting.
3. Use `MainActor.run` or `ThreadManager.onMain` to hop back to main for UI.

**Example:**

```swift
func loadData() async {
    let data = await ThreadManager.runDetached {
        try await self.api.loadData()
    }
    await MainActor.run {
        self.applyData(data)
    }
}
```

With delay:

```swift
func refreshWithDelay() async {
    await ThreadManager.delay(seconds: 1.0)
    await MainActor.run {
        self.refresh()
    }
}
```

---

### 3.6 Thread-safe shared state

**Scenario:** Multiple threads read/write a shared dictionary or counter.

**Steps:**

1. Use `ThreadManager.sync { … }` for every read and write to that state.
2. Do the minimum work inside the block; avoid calling out to unknown code that might block.

**Example:**

```swift
private var cache: [String: Data] = [:]

func get(key: String) -> Data? {
    ThreadManager.sync { cache[key] }
}

func set(key: String, value: Data) {
    ThreadManager.sync { cache[key] = value }
}
```

For async callers that need the value:

```swift
func get(key: String) async -> Data? {
    try? await ThreadManager.syncAsync { cache[key] }
}
```

---

### 3.7 Debouncing user input (e.g. search)

**Scenario:** Run a search only after the user has stopped typing for a short time.

**Steps:**

1. Create a debounced action once (e.g. in `viewDidLoad` or init).
2. Call that debounced function on every text change.

**Example:**

```swift
private lazy var debouncedSearch = ThreadManager.debounce(interval: 0.3) { [weak self] in
    self?.performSearch()
}

func textFieldDidChange() {
    debouncedSearch()
}
```

Only the last call within 0.3 seconds will trigger `performSearch()`.

---

### 3.8 Throttling frequent events (e.g. scroll)

**Scenario:** Run an action at most once per time interval (e.g. every 0.5 s) while the user scrolls.

**Steps:**

1. Create a throttled action once.
2. Call it on every scroll (or other frequent event).

**Example:**

```swift
private lazy var throttledUpdate = ThreadManager.throttle(interval: 0.5) { [weak self] in
    self?.updateVisibleCells()
}

func scrollViewDidScroll(_ scrollView: UIScrollView) {
    throttledUpdate()
}
```

---

### 3.9 Retrying a network or async operation

**Scenario:** Call an API that might fail transiently; retry a few times with optional backoff.

**Steps:**

1. Put the failing operation in an async closure.
2. Call `ThreadManager.retry(maxAttempts:delay:useBackoff:work:)`.
3. Handle success or final failure.

**Example:**

```swift
let data = try await ThreadManager.retry(
    maxAttempts: 3,
    delay: 1.0,
    useBackoff: true,
    work: { try await self.api.fetchData() }
)
```

If `useBackoff` is `true`, delays between attempts increase (e.g. 1s, 2s, 4s).

---

### 3.10 Running a block only once per token

**Scenario:** Register for push notifications or run a one-time setup from several code paths.

**Steps:**

1. Choose a unique string token (e.g. `"registerPush"`).
2. Pass the token and the block to `ThreadManager.once(token:_:)`.

**Example:**

```swift
ThreadManager.once(token: "registerPush") {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { _, _ in }
}
```

No matter how many times this path is hit, the block runs only once per app launch (per token).

---

## 4. Integration in the project

1. **Add the file**  
   Add `ThreadManager.swift` to your app target (e.g. drag into Xcode or include in the target’s Build Phases → Compile Sources).

2. **No dependencies**  
   The helper uses only `Foundation`. It does not require Combine or UIKit in the implementation file (you use UIKit at call sites).

3. **Use from anywhere**  
   Call `ThreadManager.*` from view controllers, view models, services, or other Swift code. For SwiftUI, call from `Task { }` or from `@MainActor` when you need main-thread updates.

4. **Testing**  
   You can replace or wrap `ThreadManager` in tests (e.g. inject a protocol or use a test-only queue) to control timing and threading in unit tests.

---

## 5. Summary

- Use **`onMain`** for all UI updates from non-main threads.
- Use **`onBackground(thenOnMain:background:)`** for “work in background, then update UI”.
- Use **`after`** for delayed, cancellable work; use **`delay(seconds:)`** in async code.
- Use **`runAsync`** or **`asyncOnBackground`** for background work with a result on the main thread.
- Use **`runDetached`** and **`delay`** in async/await flows.
- Use **`sync`** (or **`syncAsync`**) for thread-safe shared state.
- Use **`debounce`** for search or input; use **`throttle`** for scroll or high-frequency events.
- Use **`retry`** for transient failures; use **`once`** for one-time setup.

With these, you have a single, consistent place for threading across the app and a clear pattern for each scenario.
