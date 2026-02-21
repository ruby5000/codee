# Observability Manager — How to Use

**Observability**: metrics, traces, performance monitoring.

---

## 1. Overview

**ObservabilityManager** provides:

- **Metrics** — recordMetric, increment
- **Traces** — trace block execution time
- **Events** — recordEvent
- **Handlers** — onMetric, onTrace, onEvent

---

## 2. Quick Reference

| Need | Use |
|------|-----|
| Record metric | `ObservabilityManager.recordMetric("api_latency", value: 0.5)` |
| Increment | `ObservabilityManager.increment("errors")` |
| Trace block | `ObservabilityManager.trace("fetch") { try await fetch() }` |
| Record event | `ObservabilityManager.recordEvent("screen_view", params: [...])` |
| Set handlers | `ObservabilityManager.onMetric = { ... }` |

---

## 3. Setup

```swift
ObservabilityManager.onMetric = { name, value, tags in
    // Send to backend, Firebase Performance, etc.
}

ObservabilityManager.onTrace = { name, duration, tags in
    // Log slow operations
    if duration > 1.0 { LoggerManager.warning("Slow: \(name) \(duration)s") }
}
```

---

## 4. Usage

```swift
let data = try ObservabilityManager.trace("api.fetchUsers") {
    try await api.fetchUsers()
}

ObservabilityManager.recordMetric("cache_hit_rate", value: 0.85)
ObservabilityManager.increment("button_taps", tags: ["screen": "home"])
```

---

## 5. Summary

- **Metrics:** recordMetric, increment
- **Traces:** trace (sync/async), recordTrace
- **Events:** recordEvent
- **Handlers:** onMetric, onTrace, onEvent

For more detail, see **ObservabilityManager.swift**.
