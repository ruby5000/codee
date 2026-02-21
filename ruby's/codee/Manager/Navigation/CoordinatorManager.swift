//
//  CoordinatorManager.swift
//  A modular Navigation / Coordinator layer for iOS apps.
//  Handles push/pop, deep linking, tab routing, and coordinator lifecycle.
//
//  See COORDINATOR_MANAGER_README.md for setup and usage.
//  Requires: UIKit (iOS).
//

import Foundation
import UIKit

// MARK: - Deep link & route types

/// Represents a deep link target: tab switch, in-app route, or raw URL.
public enum DeepLink {
    /// Switch to a tab by index (e.g. home=0, profile=1).
    case tab(index: Int)
    /// In-app route path (e.g. "profile/settings", "product/123").
    case route(path: String, query: [String: String]?)
    /// Raw URL for custom parsing or universal links.
    case url(URL)
}

/// Navigation action that a coordinator can request (push, pop, present, tab switch).
public enum NavigationCommand {
    case push(UIViewController)
    case pop
    case popToRoot
    case present(UIViewController, completion: (() -> Void)?)
    case dismiss(completion: (() -> Void)?)
    case switchTab(Int)
}

// MARK: - Coordinator protocol

/// Base protocol for all coordinators. Manages child coordinators and navigation flow.
public protocol Coordinator: AnyObject {
    /// Child coordinators; parent should add/remove and retain.
    var childCoordinators: [Coordinator] { get set }
    /// Called once to start this coordinator's flow (e.g. set root or push first screen).
    func start()
}

/// Optional: coordinators that can handle deep links return true if they consumed the link.
public protocol DeepLinkHandling: AnyObject {
    func handle(deepLink: DeepLink) -> Bool
}

/// Optional: coordinators that own a navigation stack can perform push/pop.
public protocol NavigationCoordinating: Coordinator {
    var navigationController: UINavigationController { get }
}

// MARK: - AppCoordinator (root)

/// Root coordinator that owns the window, tab bar (if any), and dispatches deep links.
public final class AppCoordinator: Coordinator, DeepLinkHandling {

    public var childCoordinators: [Coordinator] = []
    private let window: UIWindow
    private var tabBarController: UITabBarController?
    private var deepLinkHandlers: [DeepLinkHandling] = []

    public init(window: UIWindow) {
        self.window = window
    }

    /// Call once at launch to set the initial root (e.g. tab bar or single nav).
    public func start() {
        // Override or configure in your app: set window.rootViewController.
        // Example: window.rootViewController = makeTabBarController()
    }

    /// Set the root view controller (e.g. after building tab bar or login flow).
    public func setRoot(_ viewController: UIViewController) {
        window.rootViewController = viewController
        if let tabBar = viewController as? UITabBarController {
            tabBarController = tabBar
        } else {
            tabBarController = nil
        }
    }

    /// Keep a reference to the tab bar for tab routing and deep links.
    public func setTabBarController(_ tabBar: UITabBarController?) {
        tabBarController = tabBar
    }

    /// Register a coordinator (or any object) that can handle deep links. Order matters.
    public func addDeepLinkHandler(_ handler: DeepLinkHandling) {
        deepLinkHandlers.append(handler)
    }

    /// Handle incoming deep link; returns true if any handler consumed it.
    public func handle(deepLink: DeepLink) -> Bool {
        for handler in deepLinkHandlers {
            if handler.handle(deepLink: deepLink) { return true }
        }
        // Default: handle tab switch if we have a tab bar
        if case .tab(let index) = deepLink, let tabBar = tabBarController, index >= 0, index < (tabBar.viewControllers?.count ?? 0) {
            tabBar.selectedIndex = index
            return true
        }
        return false
    }

    /// Tab routing: switch to tab by index. No-op if index invalid or no tab bar.
    public func switchTab(index: Int) {
        guard let tabBar = tabBarController,
              index >= 0,
              index < (tabBar.viewControllers?.count ?? 0) else { return }
        tabBar.selectedIndex = index
    }

    /// Execute a navigation command in the current context (selected tab’s nav or root).
    public func perform(_ command: NavigationCommand) {
        switch command {
        case .switchTab(let index):
            switchTab(index: index)
        case .push(let vc):
            currentNavigationController()?.pushViewController(vc, animated: true)
        case .pop:
            currentNavigationController()?.popViewController(animated: true)
        case .popToRoot:
            currentNavigationController()?.popToRootViewController(animated: true)
        case .present(let vc, let completion):
            topViewController()?.present(vc, animated: true, completion: completion)
        case .dismiss(let completion):
            topViewController()?.dismiss(animated: true, completion: completion)
        }
    }

    /// The navigation controller in the currently selected tab (if any).
    public func currentNavigationController() -> UINavigationController? {
        guard let tabBar = tabBarController,
              let selected = tabBar.selectedViewController else {
            return window.rootViewController as? UINavigationController
        }
        return selected as? UINavigationController
    }

    /// Top-most view controller for present/dismiss (selected tab’s top or root).
    public func topViewController() -> UIViewController? {
        if let nav = currentNavigationController() {
            return nav.topViewController ?? nav
        }
        return window.rootViewController
    }

    /// Add a child coordinator and start it; remove from children when it finishes (e.g. flow end).
    public func startChild(_ coordinator: Coordinator) {
        childCoordinators.append(coordinator)
        coordinator.start()
    }

    /// Remove a child coordinator (call when its flow ends).
    public func removeChild(_ coordinator: Coordinator) {
        childCoordinators.removeAll { $0 === coordinator }
    }
}

// MARK: - Deep link parsing

/// Parses a URL or path string into a `DeepLink`. Use in AppDelegate / SceneDelegate for universal links or URL schemes.
public enum DeepLinkParser {

    /// Parse a URL (e.g. myapp://tab/1 or myapp://profile/settings?section=privacy).
    public static func parse(url: URL) -> DeepLink? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        let pathComponents = components.path.split(separator: "/").map(String.init)
        var query: [String: String]?
        if let items = components.queryItems, !items.isEmpty {
            query = Dictionary(uniqueKeysWithValues: items.compactMap { item in
                guard let value = item.value else { return nil }
                return (item.name, value)
            })
        }

        if pathComponents.first?.lowercased() == "tab", pathComponents.count > 1, let index = Int(pathComponents[1]) {
            return .tab(index: index)
        }
        if !pathComponents.isEmpty {
            let path = pathComponents.joined(separator: "/")
            return .route(path: path, query: query)
        }
        return .url(url)
    }

    /// Parse a path string (e.g. "profile/settings" or "tab/0").
    public static func parse(path: String, query: [String: String]? = nil) -> DeepLink? {
        let parts = path.split(separator: "/").map(String.init)
        if parts.first?.lowercased() == "tab", parts.count > 1, let index = Int(parts[1]) {
            return .tab(index: index)
        }
        if !parts.isEmpty {
            return .route(path: path, query: query)
        }
        return nil
    }
}
