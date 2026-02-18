import UIKit

class AppChecker {
    
    // MARK: - Instagram
    static var isInstagramInstalled: Bool {
        return canOpen(urlScheme: "instagram://")
    }
    
    // MARK: - WhatsApp
    static var isWhatsAppInstalled: Bool {
        return canOpen(urlScheme: "whatsapp://")
    }
    
    // MARK: - Snapchat
    static var isSnapchatInstalled: Bool {
        return canOpen(urlScheme: "snapchat://")
    }
    
    // MARK: - TikTok
    static var isTikTokInstalled: Bool {
        return canOpen(urlScheme: "snssdk1233://")   // official known scheme
        ||  canOpen(urlScheme: "musically://")       // fallback older scheme
    }
    
    // MARK: - Base Method
    private static func canOpen(urlScheme: String) -> Bool {
        guard let url = URL(string: urlScheme) else { return false }
        return UIApplication.shared.canOpenURL(url)
    }
}

class AppStoreRedirect {
    
    // MARK: - Instagram
    static func openInstagram() {
        open(appStoreID: "389801252")
    }
    
    // MARK: - WhatsApp
    static func openWhatsApp() {
        open(appStoreID: "310633997")
    }
    
    // MARK: - Snapchat
    static func openSnapchat() {
        open(appStoreID: "447188370")
    }
    
    // MARK: - TikTok
    static func openTikTok() {
        open(appStoreID: "1235601864")
    }
    
    // MARK: - Helper
    private static func open(appStoreID: String) {
        let urlString = "https://apps.apple.com/app/id\(appStoreID)"
        guard let url = URL(string: urlString) else { return }
        
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
