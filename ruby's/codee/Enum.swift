import Foundation
import AVFoundation

enum Tab {
    case home, inbox
}

enum SharePlatform {
    case instagram
    case whatsapp
    case snapchat
    case tiktok
    
    var viewClassName: String {
        switch self {
        case .instagram: return "ShareView_INSTA"
        case .whatsapp: return "ShareView_WP_2"
        case .snapchat: return "ShareView_SNP"
        case .tiktok: return "ShareView_TIKTOK"
        }
    }
}

enum VideoCreationError: LocalizedError {
    case noAudioTrack
    case exportSessionCreationFailed
    case exportFailed(AVAssetExportSession.Status)  // ✅ Match type here

    var errorDescription: String? {
        switch self {
        case .noAudioTrack:
            return "No audio track found in the audio file"
        case .exportSessionCreationFailed:
            return "Failed to create video export session"
        case .exportFailed(let status):
            return "Video export failed with status: \(status.rawValue)"
        }
    }
}

enum VideoSourceType {
    case renderedImage
    case pickedImage
}
