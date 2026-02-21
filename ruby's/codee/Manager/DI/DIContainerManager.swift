//
//  DIContainerManager.swift
//  Dependency Injection Container. Registers and resolves services, view models, and factories.
//
//  See DI_README.md for setup and usage.
//

import Foundation
import UIKit

// MARK: - DIContainerManager

/// Dependency Injection Container. Register services and resolve them.
public final class DIContainerManager {

    public static let shared = DIContainerManager()
    private init() {}

    private var factories: [String: () -> Any] = [:]
    private var singletons: [String: Any] = [:]

    // MARK: - Register

    /// Registers a factory.
    public func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        factories[key] = { factory() }
    }

    /// Registers a singleton.
    public func registerSingleton<T>(_ type: T.Type, instance: T) {
        let key = String(describing: type)
        singletons[key] = instance
    }

    /// Registers a lazy singleton (created on first resolve).
    public func registerLazySingleton<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        factories[key] = { [weak self] in
            if let existing = self?.singletons[key] as? T {
                return existing
            }
            let instance = factory()
            self?.singletons[key] = instance
            return instance
        }
    }

    // MARK: - Resolve

    /// Resolves a dependency.
    public func resolve<T>(_ type: T.Type) -> T? {
        let key = String(describing: type)
        if let singleton = singletons[key] as? T {
            return singleton
        }
        return factories[key]?() as? T
    }

    /// Resolves or fails.
    public func resolve<T>(_ type: T.Type) -> T {
        guard let resolved = resolve(type) else {
            fatalError("DIContainer: No registration for \(type)")
        }
        return resolved
    }

    // MARK: - Reset

    /// Clears all registrations (for testing).
    public func reset() {
        factories.removeAll()
        singletons.removeAll()
    }
}

// MARK: - Convenience

extension DIContainerManager {

    /// Shorthand for container.
    public static var container: DIContainerManager { shared }

    /// Register and resolve shorthand.
    public func register<T>(_ factory: @escaping () -> T) {
        register(T.self, factory: factory)
    }

    public func resolve<T>() -> T? {
        resolve(T.self)
    }
}
