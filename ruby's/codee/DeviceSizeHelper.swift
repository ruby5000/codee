import UIKit

public enum DeviceSeries: String, CaseIterable {
    case se        = "iPhone SE / 4.7\""
    case mini      = "iPhone Mini / 5.4\""
    case regular   = "iPhone Regular / 6.1\""
    case pro       = "iPhone Pro / 5.8\" or 6.1\" Pro"
    case proMax    = "iPhone Pro Max / 6.7+\""
    case plus      = "iPhone Plus / 5.5\""
    case unknown   = "Unknown"
}

public struct DeviceSeriesDetector {
    
    /// Return all series this helper covers
    public static func allCoveredSeries() -> [DeviceSeries] {
        return DeviceSeries.allCases.filter { $0 != .unknown }
    }
    
    /// Best-effort: return the series for the current device
    public static func currentSeries() -> DeviceSeries {
        // Prefer nativeBounds (physical pixels) for better distinction between similar logical sizes.
        let nativeHeight = Int(UIScreen.main.nativeBounds.height)
        let nativeWidth  = Int(UIScreen.main.nativeBounds.width)
        let maxNative = max(nativeHeight, nativeWidth)
        let minNative = min(nativeHeight, nativeWidth)
        
        // Known native heights -> series (covers common iPhones up through modern models)
        switch maxNative {
            
        // 4" family (iPhone 5 / 5s) -> treat as SE legacy
        case 1136:
            return .se
            
        // 4.7" family (iPhone 6/7/8 and SE 2/3)
        case 1334:
            return .se
            
        // 5.5" Plus family (6/7/8 Plus)
        case 2208, 1920: // some older devices may report 1920 in certain contexts -> still Plus class
            return .plus
            
        // 5.8" (iPhone X / Xs / 11 Pro / some 5.8" Pro)
        case 2436:
            return .pro
            
        // 5.4" (iPhone 12/13 mini family)
        case 2340:
            return .mini
            
        // 6.1" common logical (e.g., 12/13/14/15 regular) — native heights may vary by generation:
        case 2532, 2556, 2600, 2592:
            return .regular
            
        // 6.1" Pro variants or other slightly different natives also often fall here
        case 2560:
            return .pro
        
        // 6.5" / 6.7" older / larger family (iPhone XS Max / XR variants)
        case 2688:
            return .proMax
        
        // 6.7" newer Pro Max / Plus (12/13/14/15/16/17 Pro Max and many Plus-sized models)
        case 2778, 2796, 2808, 2856:
            return .proMax
            
        default:
            // If native bounds didn't match, fallback to point-based heuristic using bounds.height
            return heuristicFromPointBounds()
        }
    }
    
    /// Fallback heuristic using logical points (bounds). Not as precise as nativeBounds but useful as backup.
    private static func heuristicFromPointBounds() -> DeviceSeries {
        let height = max(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        
        // These thresholds are intentionally coarse and conservative
        if height < 667 {
            return .se
        }
        if height < 700 {
            return .se
        }
        if height < 812 {
            return .regular
        }
        // 812 could be Mini or a 5.8" Pro; we can't decide reliably by points only — prefer nativeBounds earlier
        if height == 812 {
            // guess "pro" (5.8") but note ambiguity
            return .pro
        }
        if height < 844 {
            return .mini
        }
        if height < 900 {
            return .regular
        }
        // bigger than 900 points -> large (Pro Max / Plus)
        return .proMax
    }
}
