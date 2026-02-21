# Dependency Injection Container — How to Use

**DIContainerManager** provides a simple dependency injection container for services and view models.

---

## 1. Overview

- **Register** — Factory, singleton, or lazy singleton.
- **Resolve** — Get instance by type.
- **Reset** — Clear all (for tests).

---

## 2. Quick Reference

| Need | Use |
|------|-----|
| Register factory | `container.register(MyService.self) { MyService() }` |
| Register singleton | `container.registerSingleton(MyService.self, instance: instance)` |
| Register lazy | `container.registerLazySingleton(MyService.self) { MyService() }` |
| Resolve | `container.resolve(MyService.self)` |
| Resolve (force) | `container.resolve(MyService.self)` (fatal if not registered) |

---

## 3. Setup

### 3.1 Configure at App Launch

```swift
let c = DIContainerManager.shared

c.register(APIServiceProtocol.self) { APIService() }
c.registerSingleton(AppNetworkMonitor.self, instance: AppNetworkMonitor.shared)
c.registerLazySingleton(CreditAPIServiceProtocol.self) { CreditAPIService() }

c.register { CreditViewModel(
    creditAPIService: c.resolve()!,
    networkMonitor: c.resolve()!
) }
```

### 3.2 Resolve in View Controllers

```swift
let viewModel = DIContainerManager.shared.resolve(CreditViewModel.self)!
```

---

## 4. Migration from DIContainer

If you have an existing `DIContainer` class:

```swift
// In DIContainer.swift
class DIContainer {
    static let shared = DIContainer()
    lazy var creditAPIService: CreditAPIServiceProtocol = CreditAPIService()
    lazy var networkMonitor: AppNetworkMonitor = AppNetworkMonitor.shared
    func makeCreditViewModel() -> CreditViewModelProtocol { ... }
}
```

Migrate to DIContainerManager:

```swift
DIContainerManager.shared.registerLazySingleton(CreditAPIServiceProtocol.self) { CreditAPIService() }
DIContainerManager.shared.registerSingleton(AppNetworkMonitor.self, instance: AppNetworkMonitor.shared)
DIContainerManager.shared.register { CreditViewModel(creditAPIService: c.resolve()!, networkMonitor: c.resolve()!) }
```

---

## 5. Summary

- **Register:** `register`, `registerSingleton`, `registerLazySingleton`
- **Resolve:** `resolve(_:)`
- **Reset:** `reset()` for tests

For more detail, see **DIContainerManager.swift**.
