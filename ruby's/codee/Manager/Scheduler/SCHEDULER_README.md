# Scheduler / Timer Manager — How to Use

**Timers**: delayed execution, debounce, throttle, repeating.

---

## 1. Overview

**TimerManager** provides:

- **After** — Execute after delay, with cancellation
- **Debounce** — Delay until calls stop
- **Throttle** — At most once per interval
- **Repeating** — Timer or DispatchSourceTimer

---

## 2. Quick Reference

| Need | Use |
|------|-----|
| After delay | `TimerManager.after(2.0) { ... }` |
| Cancel | `TimerManager.cancel(key)` |
| Debounce | `TimerManager.debounce(interval: 0.3, key: "search") { ... }` |
| Throttle | `TimerManager.throttle(interval: 1.0, key: "scroll") { ... }` |
| Repeating | `TimerManager.repeating(interval: 5) { _ in ... }` |
| Repeating (Dispatch) | `TimerManager.repeating(on: .main, interval: 5) { ... }` |

---

## 3. Setup

Add **TimerManager.swift** to your target. No dependencies.

---

## 4. Usage

```swift
// Delay
let key = TimerManager.after(3) { showToast("Done") }
TimerManager.cancel(key)

// Debounce (e.g. search)
TimerManager.debounce(interval: 0.3, key: "search") {
    performSearch(query)
}

// Throttle (e.g. scroll)
TimerManager.throttle(interval: 1.0, key: "scroll") {
    logScrollPosition()
}
```

---

## 5. Summary

- **Delay:** after, cancel
- **Debounce:** debounce
- **Throttle:** throttle
- **Repeating:** repeating (Timer or DispatchSourceTimer)

For more detail, see **TimerManager.swift**.
