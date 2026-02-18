import UIKit

import UIKit

class BlurHelper {
    
    /// Apply a consistent blur effect that does NOT change with light/dark mode
    /// - Parameters:
    ///   - view: The UIView to apply blur on
    ///   - blurRadius: Blur intensity (default 10, range typically 0-50)
    ///   - tintColor: Optional color overlay
    ///   - intensity: Alpha for the entire blur view (0.0–1.0)
    static func applyStaticBlur(
        to view: UIView,
        blurRadius: CGFloat = 10,
        tintColor: UIColor = UIColor.white.withAlphaComponent(0.2),
        intensity: CGFloat = 0.9
    ) {
        // Remove existing blur if already applied
        if let existing = view.viewWithTag(9999) {
            existing.removeFromSuperview()
        }
        
        // Create a snapshot of the view's background
        let blurContainer = UIView(frame: view.bounds)
        blurContainer.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurContainer.backgroundColor = tintColor
        blurContainer.layer.cornerRadius = view.layer.cornerRadius
        blurContainer.clipsToBounds = true
        blurContainer.tag = 9999
        blurContainer.alpha = intensity
        
        // Create a blur layer using CALayer filter (iOS 9+)
        // This method provides consistent blur without system adaptation
        let blurLayer = CALayer()
        blurLayer.frame = view.bounds
        
        // Apply Gaussian blur filter
        if let filter = CIFilter(name: "CIGaussianBlur") {
            filter.setValue(blurRadius, forKey: kCIInputRadiusKey)
            blurLayer.backgroundFilters = [filter]
        }
        
        blurContainer.layer.addSublayer(blurLayer)
        view.insertSubview(blurContainer, at: 0)
    }
    
    /// Alternative: Use fixed UIBlurEffect style (still uses UIVisualEffectView but non-adaptive)
    /// For iOS 13+, force a specific user interface style
    static func applyBlur(
        to view: UIView,
        style: UIBlurEffect.Style = .light,
        intensity: CGFloat = 0.75,
        forceStyle: UIUserInterfaceStyle? = .light
    ) {
        // Remove existing blur if already applied
        if let existing = view.viewWithTag(9999) {
            existing.removeFromSuperview()
        }
        
        let blurEffect = UIBlurEffect(style: style)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = view.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurView.alpha = intensity
        blurView.layer.cornerRadius = view.layer.cornerRadius
        blurView.layer.masksToBounds = true
        blurView.tag = 9999
        
        // Force a specific interface style (iOS 13+)
        if let forcedStyle = forceStyle {
            blurView.overrideUserInterfaceStyle = forcedStyle
        }
        
        view.insertSubview(blurView, at: 0)
    }
    
    /// Remove blur effect (if any)
    static func removeBlur(from view: UIView) {
        view.viewWithTag(9999)?.removeFromSuperview()
    }
    
    // MARK: - Window Level Blur (Full Screen)
    
    /// Add full-screen blur effect to the window (covers entire screen including navigation bar)
    /// - Parameter style: The blur effect style (default: .systemUltraThinMaterialDark)
    static func addFullScreenBlur(style: UIBlurEffect.Style = .systemUltraThinMaterialDark) {
        // Try to get window from connected scenes first (iOS 13+)
        let window: UIWindow?
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let firstWindow = windowScene.windows.first {
            window = firstWindow
        } else {
            window = UIApplication.shared.windows.first
        }
        
        guard let window = window else { return }
        
        // Remove existing blur if already applied
        if window.viewWithTag(999) != nil { return }
        
        let blurEffect = UIBlurEffect(style: style)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = window.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurView.tag = 999
        
        window.addSubview(blurView)
    }
    
    /// Remove full-screen blur effect from the window
    static func removeFullScreenBlur() {
        // Try to get window from connected scenes first (iOS 13+)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.viewWithTag(999)?.removeFromSuperview()
        } else if let window = UIApplication.shared.windows.first {
            // Fallback for older iOS versions
            window.viewWithTag(999)?.removeFromSuperview()
        }
    }
    
    /// Check if full-screen blur is currently applied
    static func hasFullScreenBlur() -> Bool {
        // Try to get window from connected scenes first (iOS 13+)
        let window: UIWindow?
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let firstWindow = windowScene.windows.first {
            window = firstWindow
        } else {
            window = UIApplication.shared.windows.first
        }
        
        guard let window = window else { return false }
        return window.viewWithTag(999) != nil
    }
}
