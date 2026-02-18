import UIKit
import Foundation


extension UIViewController {
    func hideKeyboardTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    func addFullScreenBlur(style: UIBlurEffect.Style = .systemUltraThinMaterialDark) {
        BlurHelper.addFullScreenBlur(style: style)
    }
    
    /// Remove full-screen blur effect from the window
    func removeFullScreenBlur() {
        BlurHelper.removeFullScreenBlur()
    }
    
    /// Check if full-screen blur is currently applied
    func hasFullScreenBlur() -> Bool {
        return BlurHelper.hasFullScreenBlur()
    }
}
