# Environment Manager — How to Use

**Environment detection**: debug, release, staging. API URLs and feature flags per environment.

---

## 1. Overview

**EnvironmentManager** provides:

- **Current environment** — debug, release, staging (auto from DEBUG flag)
- **API URLs** — Per-environment base URL
- **Feature flags** — Per-environment
- **Helpers** — loggingEnabled, analyticsEnabled

---

## 2. Quick Reference

| Need | Use |
|------|-----|
| Current env | `EnvironmentManager.current` |
| Set env | `EnvironmentManager.setEnvironment(.staging)` (BuildEnvironment) |
| API URL | `EnvironmentManager.currentAPIBaseURL` |
| Feature | `EnvironmentManager.isFeatureEnabled("key")` |
| Logging on? | `EnvironmentManager.loggingEnabled` |
| Analytics on? | `EnvironmentManager.analyticsEnabled` |

---

## 3. Setup

```swift
EnvironmentManager.apiBaseURL = [
    .debug: "https://dev-api.example.com/",
    .staging: "https://staging-api.example.com/",
    .release: "https://api.example.com/"
]

EnvironmentManager.featureFlags = [
    .debug: ["debugMenu": true, "verboseLogs": true],
    .staging: ["debugMenu": false],
    .release: [:]
]
```

---

## 4. Summary

- **Env:** current, setEnvironment
- **API:** apiBaseURL, currentAPIBaseURL
- **Features:** featureFlags, isFeatureEnabled
- **Helpers:** loggingEnabled, analyticsEnabled

For more detail, see **EnvironmentManager.swift**.
