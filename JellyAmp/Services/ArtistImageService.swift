//
//  ArtistImageService.swift
//  JellyAmp
//
//  Fetches artist images from Wikipedia when Jellyfin doesn't have one.
//  Matches PWA's artistInfo.ts approach — Wikipedia REST API, 7-day cache.
//

import Foundation

actor ArtistImageService {
    static let shared = ArtistImageService()

    private var cache: [String: CachedImage] = [:]
    private let cacheTTL: TimeInterval = 7 * 24 * 60 * 60 // 7 days

    private struct CachedImage: Codable {
        let imageUrl: String?
        let fetchedAt: Date
    }

    private init() {
        loadCache()
    }

    /// Get an artist image URL, checking Jellyfin first, then Wikipedia
    func getImageURL(for artistName: String) async -> String? {
        let key = cacheKey(artistName)

        // Check memory/disk cache
        if let cached = cache[key], Date().timeIntervalSince(cached.fetchedAt) < cacheTTL {
            return cached.imageUrl
        }

        // Fetch from Wikipedia
        let imageUrl = await fetchWikipediaImage(artistName: artistName)

        // Cache result (even nil — avoids re-fetching for artists with no Wikipedia page)
        let entry = CachedImage(imageUrl: imageUrl, fetchedAt: Date())
        cache[key] = entry
        saveCache()

        return imageUrl
    }

    private func fetchWikipediaImage(artistName: String) async -> String? {
        let slug = artistName.replacingOccurrences(of: " ", with: "_")
        guard let encodedSlug = slug.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "https://en.wikipedia.org/api/rest_v1/page/summary/\(encodedSlug)") else {
            return nil
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return nil
            }

            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

            // Prefer thumbnail for list views (smaller, faster)
            if let thumbnail = json?["thumbnail"] as? [String: Any],
               let source = thumbnail["source"] as? String {
                return source
            }

            // Fallback to original image
            if let original = json?["originalimage"] as? [String: Any],
               let source = original["source"] as? String {
                return source
            }

            return nil
        } catch {
            return nil
        }
    }

    // MARK: - Disk Cache

    private func cacheKey(_ name: String) -> String {
        name.lowercased().replacingOccurrences(of: " ", with: "-")
    }

    private var cacheFileURL: URL {
        let docs = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("artist-image-cache.json")
    }

    private func loadCache() {
        guard let data = try? Data(contentsOf: cacheFileURL),
              let decoded = try? JSONDecoder().decode([String: CachedImage].self, from: data) else {
            return
        }
        cache = decoded
    }

    private func saveCache() {
        guard let data = try? JSONEncoder().encode(cache) else { return }
        try? data.write(to: cacheFileURL)
    }
}
