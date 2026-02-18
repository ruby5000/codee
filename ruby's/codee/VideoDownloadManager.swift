import Foundation
import Alamofire

final class VideoDownloadManager {

    static let shared = VideoDownloadManager()
    private let session: Session
    
    private init() {
        // Create session configuration to ensure maximum quality download
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCache = nil // Disable cache to ensure fresh download
        configuration.httpMaximumConnectionsPerHost = 1
        configuration.timeoutIntervalForRequest = 300 // 5 minutes for large video files
        configuration.timeoutIntervalForResource = 600 // 10 minutes total
        
        // Create persistent session that won't be deallocated
        self.session = Session(configuration: configuration)
    }

    // MARK: - Download Video
    @discardableResult
    func downloadVideo(
        from urlString: String,
        fileName: String? = nil,
        progress: ((Double) -> Void)? = nil,
        completion: @escaping (Result<URL, Error>) -> Void
    ) -> DownloadRequest? {

        guard let url = URL(string: urlString) else {
            completion(.failure(VideoDownloadError.invalidURL))
            return nil
        }

        let finalFileName = (fileName?.isEmpty == false)
            ? fileName!
            : UUID().uuidString

        let destination: DownloadRequest.Destination = { _, _ in
            let documents = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            )[0]

            let fileURL = documents
                .appendingPathComponent(finalFileName)
                .appendingPathExtension("mp4")

            return (fileURL, [
                .removePreviousFile,
                .createIntermediateDirectories
            ])
        }

        // Create download request with headers to request original quality
        // Note: We don't set Accept-Encoding as video files are already compressed (H.264/H.265)
        // and we want the server to send the file as-is without additional HTTP compression
        var headers = HTTPHeaders()
        headers["Accept"] = "video/mp4,video/*;q=0.9,*/*;q=0.8"
        headers["Cache-Control"] = "no-cache" // Ensure fresh download
        
        // Use the persistent session instance to avoid deallocation issues
        let request = session.download(url, headers: headers, to: destination)
            .downloadProgress { prog in
                DispatchQueue.main.async {
                    progress?(prog.fractionCompleted)
                }
            }
            .validate()
            .response { response in
                if let error = response.error {
                    completion(.failure(error))
                    return
                }

                guard let fileURL = response.fileURL else {
                    completion(.failure(VideoDownloadError.fileNotFound))
                    return
                }
                
                // Verify file was downloaded correctly
                if let fileSize = try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int64 {
                    print("✅ Video downloaded successfully: \(fileURL.path)")
                    print("📊 Video file size: \(Double(fileSize) / 1024.0 / 1024.0) MB")
                }

                completion(.success(fileURL))
            }

        return request
    }
}

// MARK: - Custom Errors
enum VideoDownloadError: LocalizedError {
    case invalidURL
    case fileNotFound

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid video URL"
        case .fileNotFound:
            return "Downloaded video file not found"
        }
    }
}
