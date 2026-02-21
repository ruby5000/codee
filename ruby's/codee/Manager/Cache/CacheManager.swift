//
//  CacheManager.swift
//  Centralized in-memory and disk cache for arbitrary data, strings, and Codable objects.
//
//  See CACHE_MANAGER_README.md for setup and usage.
//

import Foundation

// MARK: - CacheManagerError

public enum CacheManagerError: Error, LocalizedError {
    case encodingFailed
    case decodingFailed(Error)
    case writeFailed
    case readFailed

    public var errorDescription: String? {
        switch self {
        case .encodingFailed: return "Failed to encode value for cache."
        case .decodingFailed(let e): return "Failed to decode: \(e.localizedDescription)."
        case .writeFailed: return "Failed to write to cache."
        case .readFailed: return "Failed to read from cache."
        }
    }
}

// MARK: - CacheManager

/// Centralized cache for strings, data, and Codable objects. Supports memory + disk.
public enum CacheManager {

    /// In-memory cache (key → Data). Thread-safe via serial queue.
    private static var memoryCache: [String: Data] = [:]
    private static let queue = DispatchQueue(label: "com.app.cachemanager.serial", qos: .utility)

    /// Base directory for disk cache. Default: Caches/CacheManager/
    public static var diskCacheDirectory: URL = {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return caches.appendingPathComponent("CacheManager", isDirectory: true)
    }()

    /// Whether to use disk cache. Default: true.
    public static var useDisk: Bool = true

    /// Default TTL in seconds. nil = no expiry. Not enforced for memory; used for disk metadata if you add it.
    public static var defaultTTL: TimeInterval? = nil

    // MARK: - Store

    /// Stores data in memory and optionally on disk.
    public static func store(_ data: Data, forKey key: String) throws {
        queue.sync { memoryCache[key] = data }
        if useDisk {
            try storeOnDisk(data, forKey: key)
        }
    }

    /// Stores a string (UTF-8).
    public static func store(_ string: String, forKey key: String) throws {
        guard let data = string.data(using: .utf8) else { throw CacheManagerError.encodingFailed }
        try store(data, forKey: key)
    }

    /// Stores an Encodable value as JSON.
    public static func store<T: Encodable>(_ value: T, forKey key: String, encoder: JSONEncoder = JSONEncoder()) throws {
        let data = try encoder.encode(value)
        try store(data, forKey: key)
    }

    // MARK: - Fetch

    /// Fetches data from cache. Memory first, then disk.
    public static func fetchData(forKey key: String) throws -> Data {
        if let data = queue.sync(execute: { memoryCache[key] }) {
            return data
        }
        if useDisk {
            return try fetchFromDisk(forKey: key)
        }
        throw CacheManagerError.readFailed
    }

    /// Fetches string.
    public static func fetchString(forKey key: String) throws -> String {
        let data = try fetchData(forKey: key)
        guard let string = String(data: data, encoding: .utf8) else {
            throw CacheManagerError.decodingFailed(NSError(domain: "CacheManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid UTF-8"]))
        }
        return string
    }

    /// Fetches and decodes a Decodable value.
    public static func fetch<T: Decodable>(_ type: T.Type, forKey key: String, decoder: JSONDecoder = JSONDecoder()) throws -> T {
        let data = try fetchData(forKey: key)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw CacheManagerError.decodingFailed(error)
        }
    }

    // MARK: - Exists

    /// Returns whether the key exists in memory or disk.
    public static func exists(forKey key: String) -> Bool {
        if queue.sync(execute: { memoryCache[key] != nil }) { return true }
        if useDisk {
            let url = diskURL(forKey: key)
            return FileManager.default.fileExists(atPath: url.path)
        }
        return false
    }

    // MARK: - Remove

    /// Removes cached value for key.
    public static func remove(forKey key: String) {
        queue.sync { memoryCache.removeValue(forKey: key) }
        if useDisk {
            let url = diskURL(forKey: key)
            try? FileManager.default.removeItem(at: url)
        }
    }

    /// Clears all memory cache.
    public static func clearMemory() {
        queue.sync { memoryCache.removeAll() }
    }

    /// Clears all disk cache in the cache directory.
    public static func clearDisk() throws {
        if FileManager.default.fileExists(atPath: diskCacheDirectory.path) {
            try FileManager.default.removeItem(at: diskCacheDirectory)
        }
        try FileManager.default.createDirectory(at: diskCacheDirectory, withIntermediateDirectories: true)
    }

    /// Clears both memory and disk.
    public static func clearAll() throws {
        clearMemory()
        try clearDisk()
    }

    // MARK: - Disk Helpers

    private static func diskURL(forKey key: String) -> URL {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "._-")
        let safe = key.addingPercentEncoding(withAllowedCharacters: allowed) ?? key
        return diskCacheDirectory.appendingPathComponent(safe)
    }

    private static func ensureDiskDirectory() throws {
        if !FileManager.default.fileExists(atPath: diskCacheDirectory.path) {
            try FileManager.default.createDirectory(at: diskCacheDirectory, withIntermediateDirectories: true)
        }
    }

    private static func storeOnDisk(_ data: Data, forKey key: String) throws {
        try ensureDiskDirectory()
        let url = diskURL(forKey: key)
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            throw CacheManagerError.writeFailed
        }
    }

    private static func fetchFromDisk(forKey key: String) throws -> Data {
        let url = diskURL(forKey: key)
        guard FileManager.default.fileExists(atPath: url.path) else { throw CacheManagerError.readFailed }
        do {
            return try Data(contentsOf: url)
        } catch {
            throw CacheManagerError.readFailed
        }
    }

    // MARK: - Async

    /// Performs a cache operation on the internal queue.
    public static func performAsync<T>(_ block: @escaping () throws -> T) async rethrows -> T {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    let result = try block()
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
