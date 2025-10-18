//
//  BaseItemDto.swift
//  JellyAmp
//
//  Data models for Jellyfin API responses
//  Represents music items including tracks, albums, and playlists
//

import Foundation

/// Base model for all Jellyfin media items
/// Conforms to Jellyfin's BaseItemDto structure
struct BaseItemDto: Codable, Identifiable, Equatable {
    let Id: String
    let Name: String
    let ServerId: String?
    let `Type`: ItemType

    // Audio-specific properties
    let RunTimeTicks: Int64?
    let Album: String?
    let AlbumArtist: String?
    let Artists: [String]?
    let AlbumId: String?
    let AlbumPrimaryImageTag: String?
    let ImageTags: ImageTagsWrapper?

    // Playlist/Album properties
    let ChildCount: Int?
    let CumulativeRunTimeTicks: Int64?

    // Additional metadata
    let IndexNumber: Int?
    let ParentIndexNumber: Int?
    let PremiereDate: String?
    let ProductionYear: Int?
    let Overview: String?
    let Genres: [String]?

    // Date fields
    let DateCreated: String?

    // Library-specific properties
    let CollectionType: String?

    // Additional fields
    let Path: String?
    let ChannelId: String?
    let IsFolder: Bool?

    // Artist-specific properties
    let AlbumCount: Int?
    let SongCount: Int?

    // Play statistics
    let PlayCount: Int?

    // Playback information
    let CanDownload: Bool?
    let UserData: UserItemData?

    // Custom decoder to handle type mismatches gracefully
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Required fields
        Id = try container.decode(String.self, forKey: .Id)
        Name = try container.decode(String.self, forKey: .Name)
        ServerId = try? container.decode(String.self, forKey: .ServerId)
        `Type` = (try? container.decode(ItemType.self, forKey: .ItemType)) ?? .Unknown

        // Optional fields - safely decode or default to nil
        RunTimeTicks = try? container.decode(Int64.self, forKey: .RunTimeTicks)
        Album = try? container.decode(String.self, forKey: .Album)
        AlbumArtist = try? container.decode(String.self, forKey: .AlbumArtist)
        Artists = try? container.decode([String].self, forKey: .Artists)
        AlbumId = try? container.decode(String.self, forKey: .AlbumId)
        AlbumPrimaryImageTag = try? container.decode(String.self, forKey: .AlbumPrimaryImageTag)
        ImageTags = try? container.decode(ImageTagsWrapper.self, forKey: .ImageTags)

        ChildCount = try? container.decode(Int.self, forKey: .ChildCount)
        CumulativeRunTimeTicks = try? container.decode(Int64.self, forKey: .CumulativeRunTimeTicks)

        IndexNumber = try? container.decode(Int.self, forKey: .IndexNumber)
        ParentIndexNumber = try? container.decode(Int.self, forKey: .ParentIndexNumber)
        PremiereDate = try? container.decode(String.self, forKey: .PremiereDate)
        ProductionYear = try? container.decode(Int.self, forKey: .ProductionYear)
        Overview = try? container.decode(String.self, forKey: .Overview)
        Genres = try? container.decode([String].self, forKey: .Genres)

        DateCreated = try? container.decode(String.self, forKey: .DateCreated)
        CollectionType = try? container.decode(String.self, forKey: .CollectionType)
        Path = try? container.decode(String.self, forKey: .Path)
        ChannelId = try? container.decode(String.self, forKey: .ChannelId)
        IsFolder = try? container.decode(Bool.self, forKey: .IsFolder)

        AlbumCount = try? container.decode(Int.self, forKey: .AlbumCount)
        SongCount = try? container.decode(Int.self, forKey: .SongCount)
        PlayCount = try? container.decode(Int.self, forKey: .PlayCount)

        CanDownload = try? container.decode(Bool.self, forKey: .CanDownload)
        UserData = try? container.decode(UserItemData.self, forKey: .UserData)
    }

    // Custom encoder
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(Id, forKey: .Id)
        try container.encode(Name, forKey: .Name)
        try container.encodeIfPresent(ServerId, forKey: .ServerId)
        try container.encode(`Type`, forKey: .ItemType)

        try container.encodeIfPresent(RunTimeTicks, forKey: .RunTimeTicks)
        try container.encodeIfPresent(Album, forKey: .Album)
        try container.encodeIfPresent(AlbumArtist, forKey: .AlbumArtist)
        try container.encodeIfPresent(Artists, forKey: .Artists)
        try container.encodeIfPresent(AlbumId, forKey: .AlbumId)
        try container.encodeIfPresent(AlbumPrimaryImageTag, forKey: .AlbumPrimaryImageTag)
        try container.encodeIfPresent(ImageTags, forKey: .ImageTags)

        try container.encodeIfPresent(ChildCount, forKey: .ChildCount)
        try container.encodeIfPresent(CumulativeRunTimeTicks, forKey: .CumulativeRunTimeTicks)

        try container.encodeIfPresent(IndexNumber, forKey: .IndexNumber)
        try container.encodeIfPresent(ParentIndexNumber, forKey: .ParentIndexNumber)
        try container.encodeIfPresent(PremiereDate, forKey: .PremiereDate)
        try container.encodeIfPresent(ProductionYear, forKey: .ProductionYear)
        try container.encodeIfPresent(Overview, forKey: .Overview)
        try container.encodeIfPresent(Genres, forKey: .Genres)

        try container.encodeIfPresent(DateCreated, forKey: .DateCreated)
        try container.encodeIfPresent(CollectionType, forKey: .CollectionType)
        try container.encodeIfPresent(Path, forKey: .Path)
        try container.encodeIfPresent(ChannelId, forKey: .ChannelId)
        try container.encodeIfPresent(IsFolder, forKey: .IsFolder)

        try container.encodeIfPresent(AlbumCount, forKey: .AlbumCount)
        try container.encodeIfPresent(SongCount, forKey: .SongCount)
        try container.encodeIfPresent(PlayCount, forKey: .PlayCount)

        try container.encodeIfPresent(CanDownload, forKey: .CanDownload)
        try container.encodeIfPresent(UserData, forKey: .UserData)
    }

    // CodingKeys enum
    private enum CodingKeys: String, CodingKey {
        case Id, Name, ServerId
        case ItemType = "Type"  // Renamed to avoid conflict with Swift's Type
        case RunTimeTicks, Album, AlbumArtist, Artists, AlbumId, AlbumPrimaryImageTag, ImageTags
        case ChildCount, CumulativeRunTimeTicks
        case IndexNumber, ParentIndexNumber, PremiereDate, ProductionYear, Overview, Genres
        case DateCreated, CollectionType, Path, ChannelId, IsFolder
        case AlbumCount, SongCount, PlayCount
        case CanDownload, UserData
    }

    // Memberwise initializer
    init(Id: String, Name: String, ServerId: String? = nil, Type: ItemType,
         RunTimeTicks: Int64? = nil, Album: String? = nil, AlbumArtist: String? = nil,
         Artists: [String]? = nil, AlbumId: String? = nil, AlbumPrimaryImageTag: String? = nil,
         ImageTags: ImageTagsWrapper? = nil, ChildCount: Int? = nil,
         CumulativeRunTimeTicks: Int64? = nil, IndexNumber: Int? = nil,
         ParentIndexNumber: Int? = nil, PremiereDate: String? = nil,
         ProductionYear: Int? = nil, Overview: String? = nil, Genres: [String]? = nil,
         DateCreated: String? = nil,
         CollectionType: String? = nil,
         Path: String? = nil, ChannelId: String? = nil, IsFolder: Bool? = nil,
         AlbumCount: Int? = nil, SongCount: Int? = nil, PlayCount: Int? = nil,
         CanDownload: Bool? = nil, UserData: UserItemData? = nil) {
        self.Id = Id
        self.Name = Name
        self.ServerId = ServerId
        self.Type = Type
        self.RunTimeTicks = RunTimeTicks
        self.Album = Album
        self.AlbumArtist = AlbumArtist
        self.Artists = Artists
        self.AlbumId = AlbumId
        self.AlbumPrimaryImageTag = AlbumPrimaryImageTag
        self.ImageTags = ImageTags
        self.ChildCount = ChildCount
        self.CumulativeRunTimeTicks = CumulativeRunTimeTicks
        self.IndexNumber = IndexNumber
        self.ParentIndexNumber = ParentIndexNumber
        self.PremiereDate = PremiereDate
        self.ProductionYear = ProductionYear
        self.Overview = Overview
        self.Genres = Genres
        self.DateCreated = DateCreated
        self.CollectionType = CollectionType
        self.Path = Path
        self.ChannelId = ChannelId
        self.IsFolder = IsFolder
        self.AlbumCount = AlbumCount
        self.SongCount = SongCount
        self.PlayCount = PlayCount
        self.CanDownload = CanDownload
        self.UserData = UserData
    }

    // Computed properties for convenience
    var id: String { Id }
    var name: String? { Name }
    var type: String { Type.rawValue }
    var artists: [String]? { Artists }
    var imageTags: [String: String]? {
        guard let wrapper = ImageTags else { return nil }
        // Convert ImageTagsWrapper to dictionary
        if let primary = wrapper.primaryTag {
            return ["Primary": primary]
        }
        return nil
    }

    /// Duration in seconds
    var durationSeconds: Double? {
        guard let ticks = RunTimeTicks else { return nil }
        return Double(ticks) / 10_000_000
    }

    /// Formatted duration string (MM:SS)
    var formattedDuration: String {
        guard let seconds = durationSeconds else { return "--:--" }
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }

    /// Display artist name
    var artistName: String {
        if let artists = Artists, !artists.isEmpty {
            return artists.joined(separator: ", ")
        } else if let albumArtist = AlbumArtist {
            return albumArtist
        }
        return "Unknown Artist"
    }

    /// URL for album artwork
    func albumArtworkURL(baseURL: String, maxWidth: Int = 300) -> URL? {
        var itemId: String?
        var imageTag: String?

        if `Type` == .Audio {
            // For audio tracks, use album image
            itemId = AlbumId
            imageTag = AlbumPrimaryImageTag
        } else {
            // For albums/playlists, use their own image
            itemId = Id
            imageTag = ImageTags?.primaryTag
        }

        guard let id = itemId, let tag = imageTag else { return nil }

        return URL(string: "\(baseURL)/Items/\(id)/Images/Primary?maxWidth=\(maxWidth)&tag=\(tag)")
    }

    /// URL for artist image
    func artistImageURL(baseURL: String, maxWidth: Int = 300) -> URL? {
        guard `Type` == .MusicArtist else { return nil }
        guard let tag = ImageTags?.primaryTag else { return nil }

        return URL(string: "\(baseURL)/Items/\(Id)/Images/Primary?maxWidth=\(maxWidth)&tag=\(tag)")
    }

    /// Static method to format duration from ticks
    static func formatDuration(from ticks: Int64) -> String {
        let seconds = Int(ticks / 10_000_000)
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

/// Jellyfin item types
enum ItemType: String, Codable {
    case Audio = "Audio"
    case MusicAlbum = "MusicAlbum"
    case Playlist = "Playlist"
    case MusicArtist = "MusicArtist"
    case Folder = "Folder"
    case CollectionFolder = "CollectionFolder"
    case MusicGenre = "MusicGenre"
    case Unknown = "Unknown"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)

        self = ItemType(rawValue: rawValue) ?? .Unknown
    }
}

/// Wrapper to handle ImageTags that might come as string, object, number, or boolean
enum ImageTagsWrapper: Codable, Equatable {
    case tags(JellyfinImageTags)
    case string(String)
    case none

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        // Try different decoding strategies
        do {
            // First try as object
            let tags = try container.decode(JellyfinImageTags.self)
            self = .tags(tags)
            return
        } catch {
            // Not an object, continue
        }

        do {
            // Then try as string
            let string = try container.decode(String.self)
            self = .string(string)
            return
        } catch {
            // Not a string, continue
        }

        // Try as Bool (sometimes Jellyfin returns true/false)
        if let _ = try? container.decode(Bool.self) {
            self = .none
            return
        }

        // Try as Int (sometimes Jellyfin returns numbers)
        if let _ = try? container.decode(Int.self) {
            self = .none
            return
        }

        // Check if nil
        if (try? container.decodeNil()) == true {
            self = .none
            return
        }

        // Default to none if we can't decode
        print("⚠️ ImageTagsWrapper: Unhandled type, defaulting to none")
        self = .none
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .tags(let tags):
            try container.encode(tags)
        case .string(let string):
            try container.encode(string)
        case .none:
            try container.encodeNil()
        }
    }

    var primaryTag: String? {
        switch self {
        case .tags(let tags):
            return tags.Primary
        case .string, .none:
            return nil
        }
    }
}

/// Image tags for different image types
struct JellyfinImageTags: Codable, Equatable {
    let Primary: String?
    let Art: String?
    let Backdrop: String?
    let Banner: String?
    let Logo: String?
    let Thumb: String?

    // Memberwise initializer
    init(Primary: String? = nil, Art: String? = nil, Backdrop: String? = nil, Banner: String? = nil, Logo: String? = nil, Thumb: String? = nil) {
        self.Primary = Primary
        self.Art = Art
        self.Backdrop = Backdrop
        self.Banner = Banner
        self.Logo = Logo
        self.Thumb = Thumb
    }

    // Custom decoder to handle type mismatches
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        Primary = try? container.decode(String.self, forKey: .Primary)
        Art = try? container.decode(String.self, forKey: .Art)
        Backdrop = try? container.decode(String.self, forKey: .Backdrop)
        Banner = try? container.decode(String.self, forKey: .Banner)
        Logo = try? container.decode(String.self, forKey: .Logo)
        Thumb = try? container.decode(String.self, forKey: .Thumb)
    }

    private enum CodingKeys: String, CodingKey {
        case Primary, Art, Backdrop, Banner, Logo, Thumb
    }
}

/// User-specific data for items
struct UserItemData: Codable, Equatable {
    let PlaybackPositionTicks: Int64?
    let PlayCount: Int?
    let IsFavorite: Bool?
    let Played: Bool?
    let Key: String?

    // Custom decoder to handle type mismatches
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        PlaybackPositionTicks = try? container.decode(Int64.self, forKey: .PlaybackPositionTicks)
        PlayCount = try? container.decode(Int.self, forKey: .PlayCount)
        IsFavorite = try? container.decode(Bool.self, forKey: .IsFavorite)
        Played = try? container.decode(Bool.self, forKey: .Played)
        Key = try? container.decode(String.self, forKey: .Key)
    }

    // Custom encoder
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encodeIfPresent(PlaybackPositionTicks, forKey: .PlaybackPositionTicks)
        try container.encodeIfPresent(PlayCount, forKey: .PlayCount)
        try container.encodeIfPresent(IsFavorite, forKey: .IsFavorite)
        try container.encodeIfPresent(Played, forKey: .Played)
        try container.encodeIfPresent(Key, forKey: .Key)
    }

    private enum CodingKeys: String, CodingKey {
        case PlaybackPositionTicks, PlayCount, IsFavorite, Played, Key
    }

    // Memberwise initializer
    init(PlaybackPositionTicks: Int64? = nil, PlayCount: Int? = nil, IsFavorite: Bool? = nil, Played: Bool? = nil, Key: String? = nil) {
        self.PlaybackPositionTicks = PlaybackPositionTicks
        self.PlayCount = PlayCount
        self.IsFavorite = IsFavorite
        self.Played = Played
        self.Key = Key
    }
}

/// Extension for array of items (for playlist/album contents)
extension Array where Element == BaseItemDto {
    /// Total duration of all tracks in seconds
    var totalDurationSeconds: Double {
        return self.compactMap { $0.durationSeconds }.reduce(0, +)
    }

    /// Formatted total duration string (HH:MM:SS)
    var formattedTotalDuration: String {
        let totalSeconds = Int(totalDurationSeconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}
