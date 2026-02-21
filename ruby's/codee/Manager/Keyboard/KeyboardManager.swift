//
//  KeyboardManager.swift
//  Keyboard observers: frame, height, show/hide notifications.
//
//  See KEYBOARD_README.md for setup and usage.
//

import Foundation
import UIKit

// MARK: - KeyboardManager

/// Keyboard frame and visibility observers.
public enum KeyboardManager {

    /// Current keyboard frame (in screen coordinates).
    public static private(set) var keyboardFrame: CGRect = .zero

    /// Current keyboard height.
    public static var keyboardHeight: CGFloat {
        keyboardFrame.height
    }

    /// Whether keyboard is visible.
    public static var isVisible: Bool {
        keyboardFrame.height > 0
    }

    /// Animation duration for keyboard show/hide.
    public static private(set) var animationDuration: TimeInterval = 0.25

    /// Animation curve.
    public static private(set) var animationCurve: UIView.AnimationOptions = .curveEaseOut

    /// Called when keyboard will show.
    public static var onWillShow: ((CGRect, TimeInterval) -> Void)?

    /// Called when keyboard will hide.
    public static var onWillHide: ((TimeInterval) -> Void)?

    /// Called when keyboard frame changes.
    public static var onFrameChange: ((CGRect) -> Void)?

    private static var isObserving = false
    private static var observers: [NSObjectProtocol] = []

    // MARK: - Observe

    /// Starts observing keyboard. Call from AppDelegate.
    public static func startObserving() {
        guard !isObserving else { return }
        isObserving = true
        observers = [
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { handleShow($0) },
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { handleHide($0) },
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardDidChangeFrameNotification, object: nil, queue: .main) { handleFrameChange($0) }
        ]
    }

    /// Stops observing.
    public static func stopObserving() {
        guard isObserving else { return }
        isObserving = false
        observers.forEach { NotificationCenter.default.removeObserver($0) }
        observers = []
    }

    private static func handleShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let frame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
              let curve = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else { return }
        keyboardFrame = frame
        animationDuration = duration
        animationCurve = UIView.AnimationOptions(rawValue: curve)
        onWillShow?(frame, duration)
        onFrameChange?(frame)
    }

    private static func handleHide(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else { return }
        keyboardFrame = .zero
        onWillHide?(duration)
        onFrameChange?(.zero)
    }

    private static func handleFrameChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let frame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        keyboardFrame = frame
        onFrameChange?(frame)
    }

    // MARK: - Adjust View

    /// Adjusts scroll view content inset for keyboard.
    public static func adjustScrollView(_ scrollView: UIScrollView, for keyboardFrame: CGRect, in view: UIView) {
        let converted = view.convert(keyboardFrame, from: nil)
        let overlap = view.bounds.intersection(converted).height
        scrollView.contentInset.bottom = overlap
        scrollView.verticalScrollIndicatorInsets.bottom = overlap
    }
}
