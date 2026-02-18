
import UIKit
import AppsFlyerLib
import AppTrackingTransparency
import AdSupport
import TikTokBusinessSDK

class AppsflyerManager: NSObject, AppsFlyerLibDelegate {
    
    static let shared = AppsflyerManager()
    
    private let devKey = "YwFmSnDNyUSqZNcNUJUi4H"
    private let appID  = "6670788272"
    private var isStarted = false
    
    // :siren: ONLY start when ATT allowed
    func requestATTAndStartIfAllowed() {
        // Small delay to ensure notification permission dialog has fully dismissed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Ensure app is active before showing ATT dialog
            guard UIApplication.shared.applicationState == .active else {
                // Retry after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.requestATTAndStartIfAllowed()
                }
                return
            }
            
            ATTrackingManager.requestTrackingAuthorization { status in
                DispatchQueue.main.async { [self] in
                    print(" >>>>>> ✅ ATT permission result: \(self.attStatusDescription(status))")
                    
                    if status == .authorized {
                        // Print IDFA when ATT is allowed
                        
                        let idfa = ASIdentifierManager.shared()
                            .advertisingIdentifier.uuidString
                        AppsFlyerLib.shared().customerUserID = idfa
                        print("IDFA >>> \(idfa)")
                        
                        startAppsFlyer()
                        initializeTikTokBusinessSDK()
                        
                    } else if status == .denied {
                        // Print IDFA when user selected "Ask App Not to Track"
                        
                        print("Permission denined IDFA")
                        startAppsFlyer()
                        initializeTikTokBusinessSDK()
                    }
                    else {
                        print("ATT Denied – Appsflyer WILL NOT START")
                    }
                }
            }
        }
        
    }
    
    private func attStatusDescription(_ status: ATTrackingManager.AuthorizationStatus) -> String {
        switch status {
        case .authorized: return "authorized"
        case .denied: return "denied"
        case .restricted: return "restricted"
        case .notDetermined: return "not_determined"
        @unknown default: return "unknown"
        }
    }
    
    private func startAppsFlyer() {
        guard !isStarted else { return }
        AppsFlyerLib.shared().appsFlyerDevKey = devKey
        AppsFlyerLib.shared().appleAppID = appID
        AppsFlyerLib.shared().delegate = self
        
        AppsFlyerLib.shared().isDebug = true
        AppsFlyerLib.shared().start()
        isStarted = true
    }
    
    // foreground aave tyare pan TABHI start
    func appDidBecomeActive() {
        if isStarted {
            AppsFlyerLib.shared().start()
        }
    }
}

extension AppsflyerManager {
    func onConversionDataSuccess(
        _ data: [AnyHashable : Any]
    ) {
        print("AF RAW = \(data)")
    }
    func onConversionDataFail(_ error: Error) {
        print("AF Error = \(error.localizedDescription)")
    }
    
    // MARK: - TikTok Business SDK Initialization
    func initializeTikTokBusinessSDK() {
        // TikTok Business SDK
        let config = TikTokConfig.init(appId: "6670788272", tiktokAppId: "7582196732063285256")
        
        TikTokBusiness.initialize()
        print("✅ >>>>>> Tiktok config setup: \(config)")
        TikTokBusiness.initializeSdk(config) { success, error in
            if (!success) { // initialization failed
                print("❌ >>>>>> TikTokBusiness initialization failed: \(success)")
                if let error = error {
                    print("❌ >>>>>> TikTokBusiness error: \(error.localizedDescription)")
                } else {
                    print("❌ >>>>>> TikTokBusiness error: Unknown error")
                }
            } else { // initialization successful
                print("✅ >>>>>> TikTokBusiness initialization successful")
                if let error = error {
                    print("✅ >>>>>> TikTokBusiness info: \(error.localizedDescription)")
                }
            }
        }
    }
}
