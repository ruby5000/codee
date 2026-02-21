//
//  DeepLinkManager.swift
//  Centralized deep link and universal link handling. Routes URLs to app screens.
//
//  See DEEPLINK_README.md for setup and usage.
//

import Foundation
import UIKit

// MARK: - DeepLinkRoute

/// Represents a parsed deep link destination.
public enum DeepLinkRoute: Equatable {
    case home
    case profile(userId: String?)
    case inbox
    case settings
    case premium
    case custom(path: String, query: [String: String])
    case unknown
}

// MARK: - DeepLinkManager

/// Centralized deep link handling. Parse URLs and route to app screens.
public enum DeepLinkManager {

    /// Base URL scheme (e.g. "myapp" for myapp://).
    public static var urlScheme: String = "myapp"

    /// Associated domains host (e.g. "links.example.com" for universal links).
    public static var universalLinkHost: String?

    /// Handler called when a deep link is received. Return true if handled.
    public static var onHandle: ((DeepLinkRoute) -> Bool)?

    // MARK: - Parse URL

    /// Parses a URL into a DeepLinkRoute.
    public static func parse(_ url: URL) -> DeepLinkRoute {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return .unknown
        }

        let path = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let pathComponents = path.isEmpty ? [] : path.split(separator: "/").map(String.init)
        let query = parseQuery(components.queryItems)

        // myapp://profile/123 or https://links.example.com/profile/123
        if pathComponents.isEmpty {
            return .home
        }

        switch pathComponents[0].lowercased() {
        case "home":
            return .home
        case "profile":
            let userId = pathComponents.count > 1 ? pathComponents[1] : query["userId"]
            return .profile(userId: userId)
        case "inbox":
            return .inbox
        case "settings":
            return .settings
        case "premium":
            return .premium
        default:
            return .custom(path: path, query: query)
        }
    }

    /// Parses URL string. Returns nil if invalid.
    public static func parse(_ urlString: String) -> DeepLinkRoute? {
        guard let url = URL(string: urlString) else { return nil }
        return parse(url)
    }

    private static func parseQuery(_ items: [URLQueryItem]?) -> [String: String] {
        guard let items = items else { return [:] }
        return items.reduce(into: [:]) { dict, item in
            if let value = item.value { dict[item.name] = value }
        }
    }

    // MARK: - Handle

    /// Handles a URL. Parses it, calls onHandle, returns true if handled.
    public static func handle(_ url: URL) -> Bool {
        let route = parse(url)
        return onHandle?(route) ?? false
    }

    /// Handles URL from scene/openURL. Call from AppDelegate/SceneDelegate.
    public static func handleOpenURL(_ url: URL) -> Bool {
        handle(url)
    }

    /// Handles userActivity from universal links. Call from scene/continueUserActivity.
    public static func handleUserActivity(_ userActivity: NSUserActivity) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL else { return false }
        return handle(url)
    }

    // MARK: - Build URL

    /// Builds a deep link URL for the given route.
    public static func buildURL(for route: DeepLinkRoute, query: [String: String] = [:]) -> URL? {
        var path: String
        var extraQuery = query

        switch route {
        case .home:
            path = "home"
        case .profile(let userId):
            path = "profile"
            if let id = userId { extraQuery["userId"] = id }
        case .inbox:
            path = "inbox"
        case .settings:
            path = "settings"
        case .premium:
            path = "premium"
        case .custom(let p, let q):
            path = p
            extraQuery.merge(q) { _, new in new }
        case .unknown:
            return nil
        }

        var components = URLComponents()
        components.scheme = urlScheme
        components.host = ""
        components.path = "/\(path)"
        if !extraQuery.isEmpty {
            components.queryItems = extraQuery.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        return components.url
    }
}
