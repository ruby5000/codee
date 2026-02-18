import TTGSnackbar
import UIKit

class SnackbarManager {
    
    private static var currentSnackbar: TTGSnackbar?
    
    private static func configure(
        _ snackbar: TTGSnackbar, fixedHeight: CGFloat = 48
    ) {
        snackbar.messageTextFont =
        UIFont(name: Constants.Fonts.HELVETICA_REGULAR, size: 16) ?? .systemFont(ofSize: 16)
        snackbar.animationType = .slideFromBottomBackToBottom
        
        // Set background color based on current appearance
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            
            let isDarkMode = window.traitCollection.userInterfaceStyle == .dark
            snackbar.backgroundColor = isDarkMode ? 
                UIColor(named: "SNACKBAR_LIGHT") : 
                UIColor(named: "SNACKBAR_DARK")
        }
        
        let labelHeight = snackbar.messageLabel.intrinsicContentSize.height
        let verticalPadding = max((fixedHeight - labelHeight) / 2, 0)
        snackbar.contentInset = UIEdgeInsets(
            top: verticalPadding,
            left: 22,
            bottom: verticalPadding,
            right: 22
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            
            snackbar.containerView = window
            
            snackbar.leftMargin = 16
            snackbar.rightMargin = 16
            snackbar.cornerRadius = 4
            
            let safeAreaBottom = window.safeAreaInsets.bottom
            snackbar.bottomMargin = -safeAreaBottom + 15
        }
    }
    
    
    static func show(message: String) {
        // Immediately dismiss and clear any existing snackbar
        if let existingSnackbar = currentSnackbar {
            existingSnackbar.dismiss()
            currentSnackbar = nil
        }
        
        let snackbar = TTGSnackbar(message: message, duration: .middle)
        configure(snackbar)
        
        // Set completion handler to clear current snackbar reference
        snackbar.dismissBlock = { (snackbar: TTGSnackbar) in
            if currentSnackbar === snackbar {
                currentSnackbar = nil
            }
        }
        
        currentSnackbar = snackbar
        snackbar.show()
    }
    
    static func showNoInternet() {
        // Immediately dismiss and clear any existing snackbar
        if let existingSnackbar = currentSnackbar {
            existingSnackbar.dismiss()
            currentSnackbar = nil
            
            
        }
        
        let message = NSLocalizedString("no_internet_message", comment: "")
        let snackbar = TTGSnackbar(message: message, duration: .middle)
        configure(snackbar)
        
        // Set completion handler to clear current snackbar reference
        snackbar.dismissBlock = { (snackbar: TTGSnackbar) in
            if currentSnackbar === snackbar {
                currentSnackbar = nil
            }
        }
        
        currentSnackbar = snackbar
        snackbar.show()
    }
    
    // MARK: - Helper to create attributed message with bold quoted text
    private static func createAttributedMessage(for key: String) -> NSAttributedString {
        let message = NSLocalizedString(key, comment: "")
        let attributedString = NSMutableAttributedString(string: message)
        
        // Set default regular font for the entire string (snackbar default size is 16)
        let defaultFont = UIFont(name: Constants.Fonts.HELVETICA_REGULAR, size: 16) ?? UIFont.systemFont(ofSize: 16)
        attributedString.addAttribute(.font, value: defaultFont, range: NSRange(location: 0, length: message.utf16.count))
        
        // Find text between quotes (including the quotes)
        let pattern = "\"[^\"]+\""
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let matches = regex.matches(in: message, options: [], range: NSRange(location: 0, length: message.utf16.count))
            
            for match in matches {
                // Apply bold font only to the quoted text (including quotes)
                let boldFont = UIFont(name: Constants.Fonts.HELVETICA_BOLD, size: 16) ?? UIFont.boldSystemFont(ofSize: 16)
                attributedString.addAttribute(.font, value: boldFont, range: match.range)
            }
        }
        
        return attributedString
    }
    
    // MARK: - Show message with attributed string (for messages with bold quoted text)
    static func showAttributedMessage(for key: String) {
        // Immediately dismiss and clear any existing snackbar
        if let existingSnackbar = currentSnackbar {
            existingSnackbar.dismiss()
            currentSnackbar = nil
        }
        
        // Create snackbar with empty message first
        let snackbar = TTGSnackbar(message: "", duration: .middle)
        configure(snackbar)
        
        // Set attributed text on the message label
        let attributedMessage = createAttributedMessage(for: key)
        snackbar.messageLabel.attributedText = attributedMessage
        
        // Set completion handler to clear current snackbar reference
        snackbar.dismissBlock = { (snackbar: TTGSnackbar) in
            if currentSnackbar === snackbar {
                currentSnackbar = nil
            }
        }
        
        currentSnackbar = snackbar
        snackbar.show()
    }
}
