//
//  WatchJellyfinService.swift
//  JellyAmp Watch
//
//  Jellyfin API service for Apple Watch
//  Streams directly from Jellyfin server over cellular/WiFi
//

import Foundation
import Combine

class WatchJellyfinService: ObservableObject {
    static let shared = WatchJellyfinService()

    @Published var isAuthenticated = false
    @Published var baseURL = ""
    @Published var userName = ""

    private var accessToken: String?
    private var userId: String?
    private let deviceId = "JellyAmp-Watch"

    init() {
        loadCredentials()
    }

    // MARK: - Authentication

    func setCredentials(baseURL: String, accessToken: String, userId: String, userName: String) {
        self.baseURL = baseURL
        self.accessToken = accessToken
        self.userId = userId
        self.userName = userName

        // Save to UserDefaults (watch doesn't have shared keychain access)
        UserDefaults.standard.set(baseURL, forKey: "jellyfinBaseURL")
        UserDefaults.standard.set(accessToken, forKey: "jellyfinAccessToken")
        UserDefaults.standard.set(userId, forKey: "jellyfinUserId")
        UserDefaults.standard.set(userName, forKey: "jellyfinUserName")

        isAuthenticated = true
    }

    func loadCredentials() {
        if let url = UserDefaults.standard.string(forKey: "jellyfinBaseURL"),
           let token = UserDefaults.standard.string(forKey: "jellyfinAccessToken"),
           let uid = UserDefaults.standard.string(forKey: "jellyfinUserId"),
           let name = UserDefaults.standard.string(forKey: "jellyfinUserName") {
            baseURL = url
            accessToken = token
            userId = uid
            userName = name
            isAuthenticated = true
        }
    }

    func signOut() {
        UserDefaults.standard.removeObject(forKey: "jellyfinBaseURL")
        UserDefaults.standard.removeObject(forKey: "jellyfinAccessToken")
        UserDefaults.standard.removeObject(forKey: "jellyfinUserId")
        UserDefaults.standard.removeObject(forKey: "jellyfinUserName")

        baseURL = ""
        accessToken = nil
        userId = nil
        userName = ""
        isAuthenticated = false
    }

    // MARK: - Library Fetching

    func fetchArtists() async throws -> [WatchArtist] {
        guard let userId = userId, let token = accessToken else {
            throw NSError(domain: "WatchJellyfin", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        let endpoint = "\(baseURL)/Artists"
        let params = [
            "UserId": userId,
            "Recursive": "true",
            "SortBy": "SortName",
            "SortOrder": "Ascending",
            "Limit": "200",
            "Fields": "BasicSyncInfo"
        ]

        let url = buildURL(endpoint: endpoint, params: params)
        var request = URLRequest(url: url)
        request.addValue("MediaBrowser Token=\"\(token)\"", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(ItemsResponse.self, from: data)

        return response.Items.compactMap { WatchArtist(from: $0) }
    }

    func fetchAlbums(artistId: String? = nil) async throws -> [WatchAlbum] {
        guard let userId = userId, let token = accessToken else {
            throw NSError(domain: "WatchJellyfin", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        let endpoint = "\(baseURL)/Users/\(userId)/Items"
        var params: [String: String] = [
            "IncludeItemTypes": "MusicAlbum",
            "Recursive": "true",
            "SortBy": "SortName",
            "SortOrder": "Ascending",
            "Limit": "200",
            "Fields": "BasicSyncInfo,CanDelete,PrimaryImageAspectRatio,ProductionYear"
        ]

        if let artistId = artistId {
            params["ArtistIds"] = artistId
        }

        let url = buildURL(endpoint: endpoint, params: params)
        var request = URLRequest(url: url)
        request.addValue("MediaBrowser Token=\"\(token)\"", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(ItemsResponse.self, from: data)

        return response.Items.compactMap { WatchAlbum(from: $0) }
    }

    func fetchArtistTracks(artistId: String) async throws -> [WatchTrack] {
        guard let userId = userId, let token = accessToken else {
            throw NSError(domain: "WatchJellyfin", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        let endpoint = "\(baseURL)/Users/\(userId)/Items"
        let params = [
            "IncludeItemTypes": "Audio",
            "Recursive": "true",
            "ArtistIds": artistId,
            "SortBy": "Album,SortName",
            "Fields": "AudioInfo,ParentId"
        ]

        let url = buildURL(endpoint: endpoint, params: params)
        var request = URLRequest(url: url)
        request.addValue("MediaBrowser Token=\"\(token)\"", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(ItemsResponse.self, from: data)

        return response.Items.compactMap { WatchTrack(from: $0) }
    }

    func fetchAlbumTracks(albumId: String) async throws -> [WatchTrack] {
        guard let userId = userId, let token = accessToken else {
            throw NSError(domain: "WatchJellyfin", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        let endpoint = "\(baseURL)/Users/\(userId)/Items"
        let params = [
            "ParentId": albumId,
            "SortBy": "ParentIndexNumber,IndexNumber,SortName",
            "Fields": "AudioInfo,ParentId"
        ]

        let url = buildURL(endpoint: endpoint, params: params)
        var request = URLRequest(url: url)
        request.addValue("MediaBrowser Token=\"\(token)\"", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(ItemsResponse.self, from: data)

        return response.Items.compactMap { WatchTrack(from: $0) }
    }

    // MARK: - Streaming URL

    func getStreamingURL(for trackId: String) -> URL? {
        guard let token = accessToken else { return nil }

        let endpoint = "\(baseURL)/Audio/\(trackId)/universal"
        let params = [
            "UserId": userId ?? "",
            "DeviceId": deviceId,
            "MaxStreamingBitrate": "320000",
            "Container": "opus,mp3,aac,m4a,flac,webma,webm,wav,ogg",
            "TranscodingContainer": "aac",
            "TranscodingProtocol": "http",
            "AudioCodec": "aac",
            "api_key": token,
            "PlaySessionId": UUID().uuidString,
            "StartTimeTicks": "0"
        ]

        return buildURL(endpoint: endpoint, params: params)
    }

    // MARK: - Helper

    private func buildURL(endpoint: String, params: [String: String]) -> URL {
        var components = URLComponents(string: endpoint)!
        components.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        return components.url!
    }
}

// MARK: - Response Models

struct ItemsResponse: Codable {
    let Items: [ItemDto]
}

struct ItemDto: Codable {
    let Id: String
    let Name: String
    let `Type`: String?  // Escaped because Type is reserved keyword
    let RunTimeTicks: Int64?
    let AlbumArtist: String?
    let AlbumArtists: [NameIdPair]?
    let Artists: [String]?
    let Album: String?
    let ProductionYear: Int?
}

struct NameIdPair: Codable {
    let Name: String
    let Id: String
}

// MARK: - Watch Models

struct WatchArtist: Identifiable {
    let id: String
    let name: String

    init?(from dto: ItemDto) {
        guard dto.`Type` == "MusicArtist" else { return nil }
        self.id = dto.Id
        self.name = dto.Name
    }
}

struct WatchAlbum: Identifiable {
    let id: String
    let name: String
    let artist: String
    let year: Int?

    init?(from dto: ItemDto) {
        guard dto.`Type` == "MusicAlbum" else { return nil }
        self.id = dto.Id
        self.name = dto.Name
        self.artist = dto.AlbumArtist ?? dto.AlbumArtists?.first?.Name ?? "Unknown Artist"
        self.year = dto.ProductionYear
    }
}

struct WatchTrack: Identifiable {
    let id: String
    let name: String
    let artist: String
    let album: String
    let duration: TimeInterval

    init?(from dto: ItemDto) {
        guard dto.`Type` == "Audio" else { return nil }
        self.id = dto.Id
        self.name = dto.Name
        self.artist = dto.Artists?.first ?? dto.AlbumArtist ?? "Unknown Artist"
        self.album = dto.Album ?? ""

        if let ticks = dto.RunTimeTicks {
            self.duration = Double(ticks) / 10_000_000.0
        } else {
            self.duration = 0
        }
    }
}
