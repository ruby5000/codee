//
//  MediaManager.swift
//  Centralized media handling: video playback, audio, thumbnails, and media file operations.
//  Complements ImageManager for images; handles video and audio.
//
//  See MEDIA_MANAGER_README.md for setup and usage.
//

import Foundation
import UIKit
import AVFoundation
import Photos

// MARK: - MediaType

public enum MediaType {
    case image
    case video
    case audio
}

// MARK: - MediaManagerError

public enum MediaManagerError: Error, LocalizedError {
    case invalidURL
    case fileNotFound
    case loadFailed(String)
    case exportFailed

    public var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid media URL."
        case .fileNotFound: return "Media file not found."
        case .loadFailed(let msg): return "Load failed: \(msg)."
        case .exportFailed: return "Export failed."
        }
    }
}

// MARK: - MediaManager

/// Centralized media handling for video and audio. Use ImageManager for images.
public enum MediaManager {

    // MARK: - Video Thumbnail

    /// Generates a thumbnail image from a video URL at the given time.
    public static func thumbnail(
        for videoURL: URL,
        at time: CMTime = .zero
    ) async throws -> UIImage {
        let asset = AVURLAsset(url: videoURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 400, height: 400)

        let (cgImage, _) = try await generator.image(at: time)
        return UIImage(cgImage: cgImage)
    }

    /// Generates a thumbnail from a local video path.
    public static func thumbnail(
        for path: String,
        in documents: Bool = true
    ) async throws -> UIImage {
        let dir = documents
            ? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            : FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let url = dir.appendingPathComponent(path)
        return try await thumbnail(for: url)
    }

    // MARK: - Video Duration

    /// Returns video duration in seconds.
    public static func duration(of videoURL: URL) async throws -> Double {
        let asset = AVURLAsset(url: videoURL)
        let duration = try await asset.load(.duration)
        return CMTimeGetSeconds(duration)
    }

    /// Returns formatted duration string (e.g. "1:23").
    public static func formattedDuration(of videoURL: URL) async throws -> String {
        let seconds = try await duration(of: videoURL)
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    // MARK: - Save to Photos

    /// Saves a video file to the user's photo library. Requires Photos permission.
    public static func saveVideo(toPhotos url: URL) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            }) { success, error in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: error ?? MediaManagerError.exportFailed)
                }
            }
        }
    }

    /// Saves an image to the user's photo library.
    public static func saveImage(toPhotos image: UIImage) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { success, error in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: error ?? MediaManagerError.exportFailed)
                }
            }
        }
    }

    // MARK: - File Size

    /// Returns file size in bytes for a media URL.
    public static func fileSize(of url: URL) -> Int64? {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attrs[.size] as? Int64 else { return nil }
        return size
    }

    /// Returns formatted file size string (e.g. "2.5 MB").
    public static func formattedFileSize(of url: URL) -> String? {
        guard let bytes = fileSize(of: url) else { return nil }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    // MARK: - Media Type Detection

    /// Guesses media type from URL or file extension.
    public static func mediaType(for url: URL) -> MediaType {
        let ext = url.pathExtension.lowercased()
        let videoExts = ["mp4", "mov", "m4v", "avi", "mkv"]
        let audioExts = ["mp3", "m4a", "wav", "aac"]
        if videoExts.contains(ext) { return .video }
        if audioExts.contains(ext) { return .audio }
        return .image
    }
}

