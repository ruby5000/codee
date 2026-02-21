//
//  ImageManager.swift
//  Centralized image loading and caching using SDWebImage.
//  Handles async download, memory + disk cache, placeholders, resize, and compression.
//
//  See IMAGE_MANAGER_README.md for setup and usage.
//  Requires: SDWebImage (Swift Package or CocoaPods).
//

import Foundation
import UIKit
import SDWebImage

// MARK: - ImageManager

/// Centralized image loading and caching. Uses SDWebImage for async download, memory/disk cache, placeholders, and optional resize/compression.
public enum ImageManager {

    /// Shared SDWebImage manager (memory + disk cache, downloader).
    public static var shared: SDWebImageManager { SDWebImageManager.shared }

    /// Shared image cache (memory + disk). Use for prefetch, clear, or custom store/query.
    public static var cache: SDImageCache { SDImageCache.shared }

    /// Shared downloader when you need download-only (no cache).
    public static var downloader: SDImageDownloader { SDImageDownloader.shared }

    // MARK: - Load into UIImageView

    /// Loads an image from URL into the image view with optional placeholder, options, transformer, and completion.
    /// Uses SDWebImage memory + disk cache by default.
    public static func load(
        into imageView: UIImageView,
        url: URL?,
        placeholder: UIImage? = nil,
        options: SDWebImageOptions = [],
        context: [SDWebImageContextOption: Any]? = nil,
        progress: ((Int, Int) -> Void)? = nil,
        completed: ((UIImage?, Error?, SDImageCacheType, URL?) -> Void)? = nil
    ) {
        imageView.sd_setImage(
            with: url,
            placeholderImage: placeholder,
            options: options,
            context: context,
            progress: progress.map { p in { received, expected, _ in p(received, expected) } },
            completed: completed
        )
    }

    /// Loads an image with a resize transformer so the decoded image is at most the given size (saves memory).
    public static func load(
        into imageView: UIImageView,
        url: URL?,
        placeholder: UIImage? = nil,
        maxSize: CGSize,
        scaleMode: SDImageScaleMode = .aspectFill,
        completed: ((UIImage?, Error?, SDImageCacheType, URL?) -> Void)? = nil
    ) {
        let transformer = SDImageResizingTransformer(size: maxSize, scaleMode: scaleMode)
        load(into: imageView, url: url, placeholder: placeholder, context: [.imageTransformer: transformer], completed: completed)
    }

    /// Cancels any in-flight load for the image view.
    public static func cancelLoad(on imageView: UIImageView) {
        imageView.sd_cancelCurrentImageLoad()
    }

    // MARK: - Programmatic load (no UIImageView)

    /// Loads an image for a URL with caching. Use when you need the image for something other than an image view (e.g. share sheet, export).
    public static func loadImage(
        url: URL?,
        options: SDWebImageOptions = [],
        context: [SDWebImageContextOption: Any]? = nil,
        progress: ((Int, Int) -> Void)? = nil
    ) async throws -> UIImage {
        guard let url = url else { throw ImageManagerError.invalidURL }
        return try await withCheckedThrowingContinuation { continuation in
            shared.loadImage(
                with: url,
                options: options,
                context: context,
                progress: progress.map { p in { received, expected, _ in p(received, expected) } }
            ) { image, data, error, cacheType, finished, imageURL in
                guard finished else { return }
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                if let image = image {
                    continuation.resume(returning: image)
                } else {
                    continuation.resume(throwing: ImageManagerError.noImage)
                }
            }
        }
    }

    /// Loads an image with a max size (resize transformer). Good for thumbnails and list cells.
    public static func loadImage(
        url: URL?,
        maxSize: CGSize,
        scaleMode: SDImageScaleMode = .aspectFill
    ) async throws -> UIImage {
        let transformer = SDImageResizingTransformer(size: maxSize, scaleMode: scaleMode)
        return try await loadImage(url: url, context: [.imageTransformer: transformer])
    }

    // MARK: - Prefetch

    /// Prefetches URLs into memory and disk cache. Call from a list screen to make scrolling smoother.
    public static func prefetch(urls: [URL], completion: (() -> Void)? = nil) {
        let prefetcher = SDWebImagePrefetcher.shared
        prefetcher.prefetchURLs(urls, progress: nil) { _, _ in completion?() }
    }

    // MARK: - Cache control

    /// Clears memory cache only (disk cache is kept). Use on memory warning if needed.
    public static func clearMemoryCache(completion: (() -> Void)? = nil) {
        cache.clearMemory { completion?() }
    }

    /// Clears disk cache. Optional completion when done.
    public static func clearDiskCache(completion: (() -> Void)? = nil) {
        cache.clearDisk { completion?() }
    }

    /// Removes cached image for a single URL.
    public static func removeCachedImage(for url: URL, completion: (() -> Void)? = nil) {
        let key = cache.cacheKey(for: url)
        cache.removeImage(forKey: key, fromDisk: true, withCompletion: completion)
    }

    /// Whether an image is in memory cache for the URL (fast check).
    public static func isCachedInMemory(url: URL) -> Bool {
        cache.containsImage(forKey: cache.cacheKey(for: url), cacheType: .memory)
    }

    /// Checks disk cache asynchronously.
    public static func isCachedOnDisk(url: URL, completion: @escaping (Bool) -> Void) {
        let key = cache.cacheKey(for: url)
        cache.diskImageExists(withKey: key) { completion($0) }
    }

    // MARK: - Resize / compression helpers

    /// Builds a resize transformer for use in load context. Cached images will be stored at this size.
    public static func resizeTransformer(size: CGSize, scaleMode: SDImageScaleMode = .aspectFill) -> SDImageResizingTransformer {
        SDImageResizingTransformer(size: size, scaleMode: scaleMode)
    }

    /// Compresses image to JPEG data. Use after load when you need to store or send a smaller payload.
    public static func compressToJPEG(_ image: UIImage, quality: CGFloat = 0.8) -> Data? {
        image.jpegData(compressionQuality: quality)
    }

    /// Compresses image to JPEG and returns a new image from that data (smaller in-memory footprint if you only need a thumbnail).
    public static func compressImage(_ image: UIImage, maxDimension: CGFloat, jpegQuality: CGFloat = 0.8) -> UIImage? {
        let size = image.size
        let ratio = min(maxDimension / size.width, maxDimension / size.height, 1)
        guard ratio < 1 else { return image }
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let scaled = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
        guard let data = scaled.jpegData(compressionQuality: jpegQuality),
              let decoded = UIImage(data: data) else { return scaled }
        return decoded
    }
}

// MARK: - Errors

public enum ImageManagerError: Error, LocalizedError {
    case invalidURL
    case noImage

    public var errorDescription: String? {
        switch self {
        case .invalidURL: return "Image URL is nil or invalid."
        case .noImage: return "No image was returned."
        }
    }
}

// MARK: - UIImageView convenience extension

extension UIImageView {

    /// Loads an image from URL with optional placeholder. Uses ImageManager (SDWebImage) and memory/disk cache.
    public func im_setImage(with url: URL?, placeholder: UIImage? = nil, completed: ((UIImage?, Error?, SDImageCacheType, URL?) -> Void)? = nil) {
        ImageManager.load(into: self, url: url, placeholder: placeholder, completed: completed)
    }

    /// Loads an image with a max size (e.g. for list cells). Placeholder and optional completion.
    public func im_setImage(with url: URL?, placeholder: UIImage? = nil, maxSize: CGSize, completed: ((UIImage?, Error?, SDImageCacheType, URL?) -> Void)? = nil) {
        ImageManager.load(into: self, url: url, placeholder: placeholder, maxSize: maxSize, completed: completed)
    }

    /// Cancels current image load.
    public func im_cancelLoad() {
        ImageManager.cancelLoad(on: self)
    }
}
