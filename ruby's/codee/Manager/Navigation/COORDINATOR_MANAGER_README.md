# Coordinator Manager — How to Use

This guide explains the **Navigation / Coordinator Manager** and how to use it for push/pop, deep linking, tab routing, and modular navigation in iOS apps.

---

## 1. Overview

The Coordinator Manager provides:

- **Push / pop** — Navigate within a `UINavigationController` (push screens, pop, pop to root).
- **Deep linking** — Handle URLs and route strings (e.g. `myapp://tab/1`, `profile/settings?section=privacy`).
- **Tab routing** — Switch tabs by index and integrate with deep links.
- **Modular navigation** — Coordinator protocol, child coordinators, and optional `DeepLinkHandling` for per-flow logic.

Central types:

- **`Coordinator`** — Protocol: `childCoordinators`, `start()`.
- **`AppCoordinator`** — Root coordinator: owns window, tab bar reference, deep link dispatch, and `perform(NavigationCommand)`.
- **`DeepLink`** — `.tab(index:)`, `.route(path:query:)`, `.url(URL)`.
- **`NavigationCommand`** — `.push`, `.pop`, `.popToRoot`, `.present`, `.dismiss`, `.switchTab(index:)`.
- **`DeepLinkParser`** — Parse URLs or path strings into `DeepLink`.

---

## 2. Quick reference

| Need | Use |
|------|-----|
| Set app root (tab bar or single VC) | `appCoordinator.setRoot(viewController)` |
| Push a screen | `appCoordinator.perform(.push(myVC))` |
| Pop | `appCoordinator.perform(.pop)` |
| Pop to root | `appCoordinator.perform(.popToRoot)` |
| Switch tab | `appCoordinator.switchTab(index: 1)` or `perform(.switchTab(1))` |
| Present / dismiss | `perform(.present(vc, completion: nil))`, `perform(.dismiss(completion: nil))` |
| Handle deep link (URL) | `DeepLinkParser.parse(url:)` then `appCoordinator.handle(deepLink:)` |
| Handle deep link (path) | `DeepLinkParser.parse(path:query:)` then `handle(deepLink:)` |
| Register custom deep link handler | `appCoordinator.addDeepLinkHandler(myCoordinator)` |
| Start a child flow | `appCoordinator.startChild(coordinator)`; when done, `removeChild(coordinator)` |

---

## 3. Setup

### 3.1 Create and retain the AppCoordinator

In your **AppDelegate** or **SceneDelegate**, create the coordinator with the window and call `start()`:

```swift
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var appCoordinator: AppCoordinator?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        self.window = window

        let coordinator = AppCoordinator(window: window)
        self.appCoordinator = coordinator
        coordinator.start()

        window.makeKeyAndVisible()
    }
}
```

### 3.2 Set the root in `start()`

Inside `start()`, build your initial UI and set it as the root. Example with a tab bar:

```swift
// In your AppCoordinator subclass or where you configure it:
func start() {
    let tabBar = UITabBarController()
    let homeNav = UINavigationController(rootViewController: HomeViewController())
    let profileNav = UINavigationController(rootViewController: ProfileViewController())
    tabBar.setViewControllers([homeNav, profileNav], animated: false)
    tabBar.selectedIndex = 0

    setRoot(tabBar)
    // Optional: setTabBarController(tabBar) is already done inside setRoot when root is UITabBarController
}
```

If you use a single navigation stack (no tabs), just set that nav as root; `currentNavigationController()` will still work.

---

## 4. Push / pop screens

Use **`perform(_ command: NavigationCommand)`** so the app coordinator uses the *current* navigation controller (selected tab’s nav or root).

**Push:**

```swift
let detailVC = DetailViewController()
appCoordinator.perform(.push(detailVC))
```

**Pop:**

```swift
appCoordinator.perform(.pop)
```

**Pop to root of current stack:**

```swift
appCoordinator.perform(.popToRoot)
```

If you prefer to hold a reference to a specific `UINavigationController` (e.g. in a child coordinator), you can push/pop on that nav directly; the coordinator manager is there when you want a single place to perform navigation in the “current” context.

---

## 5. Tab routing

**Switch tab by index:**

```swift
appCoordinator.switchTab(index: 1)
```

Or:

```swift
appCoordinator.perform(.switchTab(1))
```

Ensure you’ve set the tab bar with `setRoot(tabBar)` or `setTabBarController(tabBar)` so the coordinator knows which tab bar to use.

---

## 6. Deep linking

### 6.1 Parse incoming URLs

In **AppDelegate** or **SceneDelegate**, when you receive a URL (e.g. universal link or custom URL scheme):

```swift
func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    guard let url = URLContexts.first?.url else { return }
    guard let deepLink = DeepLinkParser.parse(url: url) else { return }
    appCoordinator?.handle(deepLink: deepLink)
}
```

**URL examples:**

- `myapp://tab/0` → `.tab(index: 0)`
- `myapp://tab/1` → `.tab(index: 1)`
- `myapp://profile/settings?section=privacy` → `.route(path: "profile/settings", query: ["section": "privacy"])`
- Other paths → `.route(path:query:)` or `.url(url)` as fallback

### 6.2 Parse path strings

If you get a path (e.g. from a notification or router):

```swift
if let deepLink = DeepLinkParser.parse(path: "profile/settings", query: ["section": "privacy"]) {
    appCoordinator?.handle(deepLink: deepLink)
}
```

Paths like `"tab/0"` are parsed as `.tab(index: 0)`.

### 6.3 Custom deep link handlers

Register coordinators (or any `DeepLinkHandling` object) to handle routes your app knows about:

```swift
appCoordinator.addDeepLinkHandler(profileCoordinator)
```

Implement `DeepLinkHandling`:

```swift
extension ProfileCoordinator: DeepLinkHandling {
    func handle(deepLink: DeepLink) -> Bool {
        guard case .route(let path, let query) = deepLink, path.hasPrefix("profile/") else { return false }
        // e.g. push Settings VC with query
        return true
    }
}
```

Return `true` if you consumed the deep link; the app coordinator will stop dispatching. The built-in handling for `.tab(index:)` runs only if no handler returns `true` first.

---

## 7. Modular navigation (Coordinator pattern)

### 7.1 Child coordinators

Start a flow in a child coordinator and remove it when the flow ends:

```swift
let authCoordinator = AuthCoordinator(appCoordinator: appCoordinator)
appCoordinator.startChild(authCoordinator)
```

When login/signup finishes:

```swift
appCoordinator.removeChild(self)
```

The parent holds `childCoordinators` and keeps the child alive until you call `removeChild`.

### 7.2 Coordinator that owns a navigation stack

Conform to **`NavigationCoordinating`** when a coordinator owns a `UINavigationController`:

```swift
final class OnboardingCoordinator: Coordinator, NavigationCoordinating {
    var childCoordinators: [Coordinator] = []
    let navigationController: UINavigationController
    private weak var appCoordinator: AppCoordinator?

    init(navigationController: UINavigationController, appCoordinator: AppCoordinator?) {
        self.navigationController = navigationController
        self.appCoordinator = appCoordinator
    }

    func start() {
        let first = WelcomeViewController()
        first.onNext = { [weak self] in self?.showStep2() }
        navigationController.setViewControllers([first], animated: false)
    }

    private func showStep2() {
        let second = PermissionsViewController()
        second.onDone = { [weak self] in self?.finish() }
        navigationController.pushViewController(second, animated: true)
    }

    private func finish() {
        appCoordinator?.removeChild(self)
        // e.g. switch to main tab or set new root
    }
}
```

Push/pop inside this flow with `navigationController.pushViewController` / `popViewController`, and use the app coordinator only when you need to change root, tab, or hand back control.

### 7.3 Passing the AppCoordinator

View controllers or child coordinators that need to trigger navigation can hold a weak reference to `AppCoordinator` and call `perform(_:)`, `switchTab(index:)`, or `handle(deepLink:)` as needed. Keep navigation logic in coordinators where possible; VCs can call closures or delegate back to the coordinator.

---

## 8. Summary

- **AppCoordinator** — Create with `UIWindow`, set root in `start()`, use `setRoot` / `setTabBarController` for tab routing.
- **Push / pop** — `perform(.push(vc))`, `perform(.pop)`, `perform(.popToRoot)`; uses current tab’s nav when available.
- **Tab routing** — `switchTab(index:)` or `perform(.switchTab(index))`.
- **Deep linking** — `DeepLinkParser.parse(url:)` or `parse(path:query:)`, then `handle(deepLink:)`; add custom handlers with `addDeepLinkHandler`.
- **Modular flows** — Use child coordinators with `startChild` / `removeChild`; implement `NavigationCoordinating` when a coordinator owns a nav stack; implement `DeepLinkHandling` for route-specific handling.

For more examples, see the inline documentation in **CoordinatorManager.swift**.
