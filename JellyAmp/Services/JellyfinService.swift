//
//  JellyfinService.swift
//  JellyAmp
//
//  Core service for Jellyfin API interactions including Quick Connect authentication
//  and music streaming. Optimized for iOS 26.
//

import Foundation
import Combine
import UIKit
import SwiftUI
import os.log

/// Main service class for all Jellyfin API interactions
/// Handles authentication, music library fetching, and streaming
class JellyfinService: ObservableObject {
    static let shared = JellyfinService()

    private let logger = Logger(subsystem: "com.jellyamp.app", category: "JellyfinService")

    // MARK: - Properties
    // Server URL is user-configurable via Settings
    @Published var baseURL: String = UserDefaults.standard.string(forKey: "jellyfinServerURL") ?? "" {
        didSet {
            UserDefaults.standard.set(baseURL, forKey: "jellyfinServerURL")
        }
    }
    private let clientName = "JellyAmp"
    private let clientVersion = "1.0.0"
    private let deviceId = UUID().uuidString

    @Published var isAuthenticated = false
    @Published var currentUser: User?

    private var cancellables = Set<AnyCancellable>()
    private let session: URLSession

    // MARK: - Quick Connect Properties
    struct QuickConnectResponse: Codable {
        let Code: String
        let Secret: String
    }

    struct QuickConnectStatus: Codable {
        let Authenticated: Bool
        let Secret: String
        let Code: String
        let DeviceId: String?
        let DeviceName: String?
        let AppName: String?
        let AppVersion: String?
        let DateAdded: String?
    }

    struct User: Codable {
        let Id: String
        let Name: String
    }

    struct AuthenticationResult: Codable {
        let User: User?
        let AccessToken: String?
        let ServerId: String?
    }

    struct PlaylistCreationResult: Codable {
        let Id: String
    }

    // MARK: - Initialization
    init() {
        // Configure URLSession for network optimization
        let config = URLSessionConfiguration.default
        config.allowsCellularAccess = true
        config.timeoutIntervalForRequest = 10 // Fail faster for better UX
        config.timeoutIntervalForResource = 300 // 5 minutes for streaming
        config.waitsForConnectivity = false // Fail immediately when no network
        config.sessionSendsLaunchEvents = true // Background support

        self.session = URLSession(configuration: config)

        // Check for stored authentication - need BOTH token AND server URL
        if KeychainService.shared.getAccessToken() != nil && !baseURL.isEmpty {
            self.isAuthenticated = true
        }
    }

    // MARK: - Quick Connect Authentication

    /// Initiates Quick Connect flow
    /// Returns the 6-character code for user to enter on Jellyfin server
    func initiateQuickConnect() async throws -> (code: String, secret: String) {
        let url = URL(string: "\(baseURL)/QuickConnect/Initiate")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(generateAuthorizationHeader(token: nil), forHTTPHeaderField: "X-Emby-Authorization")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw JellyfinError.invalidResponse
        }

        let quickConnectResponse = try SafeJellyfinDecoder.decode(QuickConnectResponse.self, from: data)
        return (code: quickConnectResponse.Code, secret: quickConnectResponse.Secret)
    }

    /// Polls Quick Connect status
    /// Returns true when authenticated with access token stored
    func pollQuickConnect(secret: String) async throws -> Bool {
        let url = URL(string: "\(baseURL)/QuickConnect/Connect?secret=\(secret)")!

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(generateAuthorizationHeader(token: nil), forHTTPHeaderField: "X-Emby-Authorization")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw JellyfinError.invalidResponse
        }

        let status = try SafeJellyfinDecoder.decode(QuickConnectStatus.self, from: data)

        if status.Authenticated {
            // Exchange the secret for an access token
            let authorizeURL = URL(string: "\(baseURL)/Users/AuthenticateWithQuickConnect")!

            var authorizeRequest = URLRequest(url: authorizeURL)
            authorizeRequest.httpMethod = "POST"
            authorizeRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            authorizeRequest.setValue(generateAuthorizationHeader(token: nil), forHTTPHeaderField: "X-Emby-Authorization")

            let body = ["Secret": status.Secret]
            authorizeRequest.httpBody = try JSONEncoder().encode(body)

            let (authData, authResponse) = try await session.data(for: authorizeRequest)

            guard let httpAuthResponse = authResponse as? HTTPURLResponse,
                  httpAuthResponse.statusCode == 200 else {
                throw JellyfinError.invalidResponse
            }

            // Parse the authentication response
            if let authResult = try? JSONDecoder().decode(AuthenticationResult.self, from: authData),
               let token = authResult.AccessToken {
                // Store token securely
                KeychainService.shared.saveAccessToken(token)
                self.isAuthenticated = true
                self.currentUser = authResult.User

                // Store user ID
                if let userId = authResult.User?.Id {
                    UserDefaults.standard.set(userId, forKey: "jellyfinUserId")
                }

                return true
            }
        }

        return false
    }

    /// Check if Quick Connect is enabled on the server
    func checkQuickConnect() async throws -> Bool {
        let url = URL(string: "\(baseURL)/QuickConnect/Enabled")!

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            return false
        }

        // The response should be a simple boolean
        if let responseString = String(data: data, encoding: .utf8),
           let isEnabled = Bool(responseString.trimmingCharacters(in: .whitespacesAndNewlines)) {
            return isEnabled
        }

        return false
    }

    // MARK: - User Management

    /// Fetches current user information using access token
    private func fetchCurrentUser(token: String) async throws {
        let url = URL(string: "\(baseURL)/Users/Me")!

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(generateAuthorizationHeader(token: token), forHTTPHeaderField: "X-Emby-Authorization")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw JellyfinError.invalidResponse
        }

        let user = try SafeJellyfinDecoder.decode(User.self, from: data)
        self.currentUser = user

        // Store user ID for future use
        UserDefaults.standard.set(user.Id, forKey: "jellyfinUserId")
    }

    // MARK: - Music Library

    /// Fetches music items (albums, playlists) for the authenticated user
    func fetchMusicItems(includeItemTypes: String = "MusicAlbum,Playlist", artistIds: String? = nil, parentId: String? = nil, excludeItemTypes: String? = nil, limit: Int? = nil, startIndex: Int? = nil) async throws -> [BaseItemDto] {
        guard let token = KeychainService.shared.getAccessToken(),
              let userId = UserDefaults.standard.string(forKey: "jellyfinUserId") else {
            throw JellyfinError.notAuthenticated
        }

        var components = try buildURLComponents(path: "Users/\(userId)/Items")
        components.queryItems = [
            URLQueryItem(name: "IncludeItemTypes", value: includeItemTypes),
            URLQueryItem(name: "Recursive", value: "true"),
            URLQueryItem(name: "SortBy", value: "SortName"),
            URLQueryItem(name: "SortOrder", value: "Ascending"),
            URLQueryItem(name: "Fields", value: "BasicSyncInfo,MediaSources,Path,UserData")
        ]

        // Add pagination if specified
        if let limit = limit {
            components.queryItems?.append(URLQueryItem(name: "Limit", value: String(limit)))
        }
        if let startIndex = startIndex {
            components.queryItems?.append(URLQueryItem(name: "StartIndex", value: String(startIndex)))
        }

        // Add artist filter if provided
        if let artistIds = artistIds {
            components.queryItems?.append(URLQueryItem(name: "ArtistIds", value: artistIds))
        }

        // Add parent filter if provided (for library filtering)
        if let parentId = parentId {
            components.queryItems?.append(URLQueryItem(name: "ParentId", value: parentId))
        }

        // Add exclude types if provided
        if let excludeItemTypes = excludeItemTypes {
            components.queryItems?.append(URLQueryItem(name: "ExcludeItemTypes", value: excludeItemTypes))
        }

        let url = try buildURL(from: components)
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(generateAuthorizationHeader(token: token), forHTTPHeaderField: "X-Emby-Authorization")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw JellyfinError.invalidResponse
        }

        // Try to decode the response with error handling
        do {
            let itemsResponse = try SafeJellyfinDecoder.decode(ItemsResponse.self, from: data)
            return itemsResponse.Items
        } catch {
            logger.error("Failed to decode music items: \(error.localizedDescription)")
            return []
        }
    }

    /// Fetches all artists in the music library
    func fetchArtists(parentId: String? = nil, limit: Int? = nil, startIndex: Int? = nil) async throws -> [BaseItemDto] {
        guard let token = KeychainService.shared.getAccessToken(),
              let userId = UserDefaults.standard.string(forKey: "jellyfinUserId") else {
            throw JellyfinError.notAuthenticated
        }

        guard var components = URLComponents(string: "\(baseURL)/Artists") else {
            throw JellyfinError.invalidURL
        }

        components.queryItems = [
            URLQueryItem(name: "UserId", value: userId),
            URLQueryItem(name: "Recursive", value: "true"),
            URLQueryItem(name: "SortBy", value: "SortName"),
            URLQueryItem(name: "SortOrder", value: "Ascending"),
            URLQueryItem(name: "Fields", value: "PrimaryImageAspectRatio,BasicSyncInfo,UserData,AlbumCount,Overview"),
            URLQueryItem(name: "EnableImageTypes", value: "Primary,Backdrop,Banner,Thumb")
        ]

        // Add pagination if specified
        if let limit = limit {
            components.queryItems?.append(URLQueryItem(name: "Limit", value: String(limit)))
        }
        if let startIndex = startIndex {
            components.queryItems?.append(URLQueryItem(name: "StartIndex", value: String(startIndex)))
        }

        // Add parent filter if provided (for library filtering)
        if let parentId = parentId {
            components.queryItems?.append(URLQueryItem(name: "ParentId", value: parentId))
        }

        guard let url = components.url else {
            throw JellyfinError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(generateAuthorizationHeader(token: token), forHTTPHeaderField: "X-Emby-Authorization")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw JellyfinError.invalidResponse
        }

        let itemsResponse = try SafeJellyfinDecoder.decode(ItemsResponse.self, from: data)
        return itemsResponse.Items
    }

    /// Fetches tracks for an album or playlist
    func fetchTracks(parentId: String) async throws -> [BaseItemDto] {
        guard let token = KeychainService.shared.getAccessToken(),
              let userId = UserDefaults.standard.string(forKey: "jellyfinUserId") else {
            throw JellyfinError.notAuthenticated
        }

        var components = URLComponents(string: "\(baseURL)/Users/\(userId)/Items")!
        components.queryItems = [
            URLQueryItem(name: "ParentId", value: parentId),
            URLQueryItem(name: "IncludeItemTypes", value: "Audio"),
            URLQueryItem(name: "SortBy", value: "IndexNumber,SortName"),
            URLQueryItem(name: "SortOrder", value: "Ascending"),
            URLQueryItem(name: "Fields", value: "BasicSyncInfo")
        ]

        let url = try buildURL(from: components)
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(generateAuthorizationHeader(token: token), forHTTPHeaderField: "X-Emby-Authorization")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw JellyfinError.invalidResponse
        }

        // Decode the response with error handling
        do {
            let itemsResponse = try SafeJellyfinDecoder.decode(ItemsResponse.self, from: data)
            return itemsResponse.Items
        } catch {
            logger.error("Failed to decode tracks: \(error.localizedDescription)")
            return []
        }
    }

    /// Get tracks from an album
    func getAlbumTracks(albumId: String) async throws -> [BaseItemDto] {
        return try await fetchTracks(parentId: albumId)
    }

    /// Search for music items across all types
    func searchMusic(query: String, parentId: String? = nil) async throws -> [BaseItemDto] {
        guard let token = KeychainService.shared.getAccessToken(),
              let userId = UserDefaults.standard.string(forKey: "jellyfinUserId") else {
            throw JellyfinError.notAuthenticated
        }

        var components = URLComponents(string: "\(baseURL)/Users/\(userId)/Items")!
        components.queryItems = [
            URLQueryItem(name: "searchTerm", value: query),
            URLQueryItem(name: "IncludeItemTypes", value: "MusicArtist,MusicAlbum,Audio,Playlist"),
            URLQueryItem(name: "Recursive", value: "true"),
            URLQueryItem(name: "SortBy", value: "SortName"),
            URLQueryItem(name: "SortOrder", value: "Ascending"),
            URLQueryItem(name: "Fields", value: "BasicSyncInfo,MediaSources"),
            URLQueryItem(name: "Limit", value: "50")
        ]

        // Add parent filter if provided (for library filtering)
        if let parentId = parentId {
            components.queryItems?.append(URLQueryItem(name: "ParentId", value: parentId))
        }

        let url = try buildURL(from: components)
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(generateAuthorizationHeader(token: token), forHTTPHeaderField: "X-Emby-Authorization")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw JellyfinError.invalidResponse
        }

        let itemsResponse = try SafeJellyfinDecoder.decode(ItemsResponse.self, from: data)
        return itemsResponse.Items
    }

    // MARK: - Streaming

    /// Generates streaming URL for audio playback
    /// Optimized for high quality with 320kbps bitrate (iOS 26)
    func getStreamingURL(for itemId: String) -> URL? {
        return getStreamingURL(for: itemId, bitrate: 320)
    }

    /// Generates streaming URL with specific bitrate
    func getStreamingURL(for itemId: String, bitrate: Int) -> URL? {
        // Validate item ID
        guard !itemId.isEmpty else {
            logger.error("Empty item ID provided for streaming URL")
            return nil
        }

        guard let token = KeychainService.shared.getAccessToken(), !token.isEmpty else {
            logger.error("Failed to get streaming URL: No access token")
            return nil
        }

        // Ensure base URL is valid
        let cleanBaseURL = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanBaseURL.isEmpty else {
            logger.error("Base URL is empty")
            return nil
        }

        // Create URL with proper encoding
        // Use universal audio endpoint for best compatibility
        let normalizedBaseURL = cleanBaseURL.hasSuffix("/") ? String(cleanBaseURL.dropLast()) : cleanBaseURL
        let streamPath = "/Audio/\(itemId)/universal"
        let fullURLString = normalizedBaseURL + streamPath

        guard var components = URLComponents(string: fullURLString) else {
            logger.error("Failed to create URL components for streaming: \(fullURLString)")
            return nil
        }

        guard let userId = UserDefaults.standard.string(forKey: "jellyfinUserId") else {
            logger.error("No user ID found for streaming")
            return nil
        }

        // Build query items for universal audio endpoint
        // CRITICAL: Use "http" protocol instead of "hls" for background playback compatibility
        // HLS requires continuous segment downloads which iOS suspends in background
        components.queryItems = [
            URLQueryItem(name: "UserId", value: userId),
            URLQueryItem(name: "DeviceId", value: "JellyAmp-iOS"),
            URLQueryItem(name: "MaxStreamingBitrate", value: "\(bitrate * 1000)"),
            URLQueryItem(name: "Container", value: "opus,mp3,aac,m4a,flac,webma,webm,wav,ogg"),
            URLQueryItem(name: "TranscodingContainer", value: "aac"),
            URLQueryItem(name: "TranscodingProtocol", value: "http"),  // Use HTTP for background compatibility
            URLQueryItem(name: "AudioCodec", value: "aac"),
            URLQueryItem(name: "api_key", value: token),
            URLQueryItem(name: "PlaySessionId", value: UUID().uuidString),
            URLQueryItem(name: "StartTimeTicks", value: "0")
        ]

        guard let url = components.url else {
            logger.error("Failed to generate final streaming URL")
            return nil
        }

        logger.info("Generated streaming URL for item \(itemId): \(url.absoluteString)")
        return url
    }

    // MARK: - Favorites Management

    /// Mark an item as favorite
    func markFavorite(itemId: String) async throws {
        guard let token = KeychainService.shared.getAccessToken(),
              let userId = UserDefaults.standard.string(forKey: "jellyfinUserId") else {
            throw JellyfinError.notAuthenticated
        }

        guard let url = URL(string: "\(baseURL)/Users/\(userId)/FavoriteItems/\(itemId)") else {
            throw JellyfinError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(generateAuthorizationHeader(token: token), forHTTPHeaderField: "X-Emby-Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw JellyfinError.invalidResponse
        }
    }

    /// Remove item from favorites
    func unmarkFavorite(itemId: String) async throws {
        guard let token = KeychainService.shared.getAccessToken(),
              let userId = UserDefaults.standard.string(forKey: "jellyfinUserId") else {
            throw JellyfinError.notAuthenticated
        }

        guard let url = URL(string: "\(baseURL)/Users/\(userId)/FavoriteItems/\(itemId)") else {
            throw JellyfinError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue(generateAuthorizationHeader(token: token), forHTTPHeaderField: "X-Emby-Authorization")

        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw JellyfinError.invalidResponse
        }
    }

    /// Fetch user's favorite items
    func fetchFavorites(includeItemTypes: String = "Audio,MusicAlbum,Playlist") async throws -> [BaseItemDto] {
        guard let token = KeychainService.shared.getAccessToken(),
              let userId = UserDefaults.standard.string(forKey: "jellyfinUserId") else {
            throw JellyfinError.notAuthenticated
        }

        var components = URLComponents(string: "\(baseURL)/Users/\(userId)/Items")!
        components.queryItems = [
            URLQueryItem(name: "IncludeItemTypes", value: includeItemTypes),
            URLQueryItem(name: "Recursive", value: "true"),
            URLQueryItem(name: "SortBy", value: "DatePlayed,SortName"),
            URLQueryItem(name: "SortOrder", value: "Descending"),
            URLQueryItem(name: "Filters", value: "IsFavorite"),
            URLQueryItem(name: "Fields", value: "PrimaryImageAspectRatio,CanDelete,BasicSyncInfo"),
            URLQueryItem(name: "EnableImageTypes", value: "Primary,Backdrop,Banner,Thumb")
        ]

        guard let url = components.url else {
            throw JellyfinError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.setValue(generateAuthorizationHeader(token: token), forHTTPHeaderField: "X-Emby-Authorization")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw JellyfinError.invalidResponse
        }

        let itemsResponse = try SafeJellyfinDecoder.decode(ItemsResponse.self, from: data)
        return itemsResponse.Items
    }

    // MARK: - Helper Methods

    private func buildURLComponents(path: String) throws -> URLComponents {
        guard let components = URLComponents(string: "\(baseURL)/\(path)") else {
            throw JellyfinError.invalidURL
        }
        return components
    }

    private func buildURL(from components: URLComponents) throws -> URL {
        guard let url = components.url else {
            throw JellyfinError.invalidURL
        }
        return url
    }

    /// Generates authorization header for Jellyfin API
    private func generateAuthorizationHeader(token: String?) -> String {
        let deviceName = UIDevice.current.model // "iPhone" or "iPad"
        if let token = token {
            return "MediaBrowser Token=\"\(token)\", Client=\"\(clientName)\", Device=\"\(deviceName)\", DeviceId=\"\(deviceId)\", Version=\"\(clientVersion)\""
        } else {
            return "MediaBrowser Client=\"\(clientName)\", Device=\"\(deviceName)\", DeviceId=\"\(deviceId)\", Version=\"\(clientVersion)\""
        }
    }

    /// Validates current session
    func validateSession() async throws -> Bool {
        guard let token = authToken else { return false }
        do {
            try await fetchCurrentUser(token: token)
            return true
        } catch {
            return false
        }
    }

    /// Signs out and clears stored credentials
    func signOut() {
        // Stop playback before signing out
        PlayerManager.shared.pause()
        PlayerManager.shared.clearQueue()

        isAuthenticated = false
        currentUser = nil
        KeychainService.shared.deleteAccessToken()
        UserDefaults.standard.removeObject(forKey: "jellyfinUserId")
    }

    // MARK: - Public Computed Properties

    /// Current user ID from UserDefaults
    var currentUserId: String? {
        UserDefaults.standard.string(forKey: "jellyfinUserId")
    }

    /// Access token from Keychain
    var authToken: String? {
        KeychainService.shared.getAccessToken()
    }

    /// Get image URL for an item
    func getImageURL(itemId: String, imageTag: String, maxWidth: Int = 300, maxHeight: Int = 300) -> URL? {
        let urlString = "\(baseURL)/Items/\(itemId)/Images/Primary?maxWidth=\(maxWidth)&maxHeight=\(maxHeight)&tag=\(imageTag)&quality=90"
        return URL(string: urlString)
    }
}

// MARK: - Error Types

enum JellyfinError: LocalizedError {
    case notAuthenticated
    case invalidResponse
    case networkError(Error)
    case quickConnectTimeout
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not authenticated. Please sign in."
        case .invalidResponse:
            return "Invalid response from server."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .quickConnectTimeout:
            return "Quick Connect timed out. Please try again."
        case .invalidURL:
            return "Invalid server URL. Please check your server address."
        }
    }
}

// MARK: - Response Models

struct ItemsResponse: Codable {
    let Items: [BaseItemDto]
    let TotalRecordCount: Int

    // Custom decoder to skip bad items
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        TotalRecordCount = (try? container.decode(Int.self, forKey: .TotalRecordCount)) ?? 0

        // Decode items array manually to skip bad items
        if let itemsArray = try? container.decode([BaseItemDto].self, forKey: .Items) {
            Items = itemsArray
        } else {
            // If normal decode fails, try decoding one by one
            let itemsArrayContainer = try? container.nestedUnkeyedContainer(forKey: .Items)
            var validItems: [BaseItemDto] = []

            if var itemsArrayContainer = itemsArrayContainer {
                while !itemsArrayContainer.isAtEnd {
                    if let item = try? itemsArrayContainer.decode(BaseItemDto.self) {
                        validItems.append(item)
                    } else {
                        // Skip this bad item
                        _ = try? itemsArrayContainer.decode(AnyCodable.self)
                    }
                }
            }

            Items = validItems
        }
    }

    private enum CodingKeys: String, CodingKey {
        case Items, TotalRecordCount
    }
}

// Helper to decode and skip any value
private struct AnyCodable: Codable {
    let value: Any?

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let int = try? container.decode(Int.self) {
            value = int
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict
        } else {
            value = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        // Not needed
    }
}
