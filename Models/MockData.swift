//
//  MockData.swift
//  JellyAmp
//
//  Mock data for UI development
//

import Foundation

// MARK: - Track Model
struct Track: Identifiable {
    let id: String
    let name: String
    let artistName: String
    let albumName: String
    let duration: TimeInterval
    let artworkURL: String?

    // Metadata for proper organization
    let trackNumber: Int?
    let discNumber: Int?
    let albumId: String?
    let artistId: String?
    let productionYear: Int?

    var durationFormatted: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    // Initializer with defaults for optional metadata
    init(id: String, name: String, artistName: String, albumName: String,
         duration: TimeInterval, artworkURL: String?,
         trackNumber: Int? = nil, discNumber: Int? = nil,
         albumId: String? = nil, artistId: String? = nil,
         productionYear: Int? = nil) {
        self.id = id
        self.name = name
        self.artistName = artistName
        self.albumName = albumName
        self.duration = duration
        self.artworkURL = artworkURL
        self.trackNumber = trackNumber
        self.discNumber = discNumber
        self.albumId = albumId
        self.artistId = artistId
        self.productionYear = productionYear
    }
}

// MARK: - Mock Data
extension Track {
    static let mockTrack1 = Track(
        id: "1",
        name: "Neon Dreams",
        artistName: "Cyber Synthwave",
        albumName: "Digital Horizons",
        duration: 245,
        artworkURL: nil
    )

    static let mockTrack2 = Track(
        id: "2",
        name: "Electric Pulse",
        artistName: "Neon Collective",
        albumName: "Future Retro",
        duration: 198,
        artworkURL: nil
    )

    static let mockTrack3 = Track(
        id: "3",
        name: "Crystal Rain",
        artistName: "Glitch Artists",
        albumName: "Digital Dreams",
        duration: 312,
        artworkURL: nil
    )

    static let mockPlaylist = [mockTrack1, mockTrack2, mockTrack3]
}

// MARK: - Mock Album Model
struct Album: Identifiable {
    let id: String
    let name: String
    let artistName: String
    let year: Int?
    let artworkURL: String?
}

// MARK: - Playlist Model
struct Playlist: Identifiable, Codable {
    let id: String
    let name: String
    var trackCount: Int
    let artworkURL: String?
    let dateCreated: Date?
    var isFavorite: Bool
}

extension Album {
    static let mockAlbums = [
        Album(id: "1", name: "Digital Horizons", artistName: "Cyber Synthwave", year: 2024, artworkURL: nil),
        Album(id: "2", name: "Future Retro", artistName: "Neon Collective", year: 2023, artworkURL: nil),
        Album(id: "3", name: "Digital Dreams", artistName: "Glitch Artists", year: 2025, artworkURL: nil),
        Album(id: "4", name: "Neon Nights", artistName: "Synth Masters", year: 2024, artworkURL: nil),
        Album(id: "5", name: "Electric Dreams", artistName: "Wave Riders", year: 2023, artworkURL: nil),
        Album(id: "6", name: "Cyber City", artistName: "Digital Souls", year: 2025, artworkURL: nil)
    ]
}
