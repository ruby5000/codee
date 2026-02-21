//
//  ErrorHandler.swift
//  Centralized error handling: present alerts, log, and optional recovery.
//
//  See ERROR_HANDLER_README.md for setup and usage.
//

import Foundation
import UIKit

// MARK: - AppError

/// App-level error with user-facing message.
public enum AppError: Error, LocalizedError {
    case network(underlying: Error?)
    case server(message: String)
    case validation(message: String)
    case auth(message: String)
    case unknown(Error?)
    case custom(message: String)

    public var errorDescription: String? {
        switch self {
        case .network(let e): return e?.localizedDescription ?? "Network error. Please check your connection."
        case .server(let msg): return msg
        case .validation(let msg): return msg
        case .auth(let msg): return msg
        case .unknown(let e): return e?.localizedDescription ?? "Something went wrong."
        case .custom(let msg): return msg
        }
    }
}

// MARK: - ErrorHandler

/// Centralized error handling.
public enum ErrorHandler {

    /// Handler for presenting errors. Default shows UIAlertController.
    public static var present: (String, String?, UIViewController?) -> Void = { message, title, vc in
        DispatchQueue.main.async {
            guard let vc = vc ?? topViewController() else { return }
            let alert = UIAlertController(title: title ?? "Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            vc.present(alert, animated: true)
        }
    }

    /// Handler for logging errors.
    public static var log: (Error) -> Void = { error in
        #if DEBUG
        print("❌ Error: \(error.localizedDescription)")
        #endif
    }

    /// Whether to log before presenting.
    public static var logBeforePresent: Bool = true

    // MARK: - Handle

    /// Handles an error: logs and optionally presents.
    public static func handle(
        _ error: Error,
        presentTo viewController: UIViewController? = nil,
        title: String? = nil,
        showAlert: Bool = true
    ) {
        let message = error.localizedDescription

        if logBeforePresent {
            log(error)
        }

        if showAlert {
            present(message, title ?? "Error", viewController)
        }
    }

    /// Handles error with custom message override.
    public static func handle(
        _ error: Error,
        customMessage: String,
        presentTo viewController: UIViewController? = nil,
        title: String? = nil
    ) {
        if logBeforePresent { log(error) }
        present(customMessage, title ?? "Error", viewController)
    }

    /// Handles error silently (log only, no alert).
    public static func handleSilently(_ error: Error) {
        log(error)
    }

    // MARK: - Result Helper

    /// Unwraps Result or handles failure.
    public static func handleResult<T>(
        _ result: Result<T, Error>,
        onSuccess: (T) -> Void,
        presentTo viewController: UIViewController? = nil
    ) {
        switch result {
        case .success(let value):
            onSuccess(value)
        case .failure(let error):
            handle(error, presentTo: viewController)
        }
    }
}

// MARK: - Top View Controller

private func topViewController(base: UIViewController? = nil) -> UIViewController? {
    let base = base ?? UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap { $0.windows }
        .first { $0.isKeyWindow }?
        .rootViewController

    if let nav = base as? UINavigationController {
        return topViewController(base: nav.visibleViewController)
    }
    if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
        return topViewController(base: selected)
    }
    if let presented = base?.presentedViewController {
        return topViewController(base: presented)
    }
    return base
}
