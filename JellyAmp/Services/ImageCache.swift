//
//  ImageCache.swift
//  JellyAmp
//
//  Actor-based image cache with memory + disk layers
//

import UIKit
import os.log

actor ImageCache {
    static let shared = ImageCache()

    private let logger = Logger(subsystem: "com.jellyamp.app", category: "ImageCache")

    // MARK: - Memory Cache
    private let memoryCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.totalCostLimit = 100 * 1024 * 1024 // 100MB
        cache.countLimit = 300
        return cache
    }()

    // MARK: - Disk Cache
    private let diskCacheURL: URL = {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let dir = caches.appendingPathComponent("ImageCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    private let maxDiskBytes: UInt64 = 500 * 1024 * 1024 // 500MB
    private let diskExpiry: TimeInterval = 7 * 24 * 3600 // 7 days

    // MARK: - URL Session
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.urlCache = nil // We manage our own cache
        return URLSession(configuration: config)
    }()

    // MARK: - Public API

    /// Get image from cache (memory → disk) or nil
    func cachedImage(for url: URL) -> UIImage? {
        let key = cacheKey(for: url)

        // Memory
        if let img = memoryCache.object(forKey: key as NSString) {
            return img
        }

        // Disk
        let filePath = diskCacheURL.appendingPathComponent(key)
        guard FileManager.default.fileExists(atPath: filePath.path) else { return nil }

        // Check expiry
        if let attrs = try? FileManager.default.attributesOfItem(atPath: filePath.path),
           let modDate = attrs[.modificationDate] as? Date,
           Date().timeIntervalSince(modDate) > diskExpiry {
            try? FileManager.default.removeItem(at: filePath)
            return nil
        }

        guard let data = try? Data(contentsOf: filePath),
              let img = UIImage(data: data) else { return nil }

        // Promote to memory
        let cost = data.count
        memoryCache.setObject(img, forKey: key as NSString, cost: cost)
        return img
    }

    /// Download image, cache it, return it
    func loadImage(from url: URL) async throws -> UIImage {
        // Check cache first
        if let cached = cachedImage(for: url) {
            return cached
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode),
              let img = UIImage(data: data) else {
            throw URLError(.badServerResponse)
        }

        let key = cacheKey(for: url)

        // Memory
        memoryCache.setObject(img, forKey: key as NSString, cost: data.count)

        // Disk (fire and forget)
        let filePath = diskCacheURL.appendingPathComponent(key)
        try? data.write(to: filePath)

        return img
    }

    // MARK: - Helpers

    private func cacheKey(for url: URL) -> String {
        // SHA256-like hash using simple approach
        let str = url.absoluteString
        var hash: UInt64 = 5381
        for byte in str.utf8 {
            hash = ((hash << 5) &+ hash) &+ UInt64(byte)
        }
        return String(hash, radix: 16)
    }

    /// Evict expired disk entries (call occasionally)
    func evictExpired() {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: diskCacheURL, includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey]) else { return }

        for file in files {
            if let attrs = try? fm.attributesOfItem(atPath: file.path),
               let modDate = attrs[.modificationDate] as? Date,
               Date().timeIntervalSince(modDate) > diskExpiry {
                try? fm.removeItem(at: file)
            }
        }
    }
}
