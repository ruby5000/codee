import Foundation

// MARK: - Extensions
extension FileManager {
    static func getOutputVideoURL(for platform: String = "general") -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("merged_\(platform)_video_\(Date().timeIntervalSince1970).mp4")
    }
    
    static func getTemporaryImageVideoURL(for platform: String = "general") -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("temp_\(platform)_image_video_\(Date().timeIntervalSince1970).mp4")
    }
    
    static func getInstagramOptimizedVideoURL() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("instagram_optimized_\(Date().timeIntervalSince1970).mp4")
    }
    
    static func removeFileIfExists(at url: URL) {
        if FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
        }
    }
}
