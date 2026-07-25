//
//  LibraryState.swift
//  JellyAmp
//
//  Persistent library state — survives NavigationStack push/pop so scroll
//  position and filter selection are restored when the user navigates back.
//

import SwiftUI
import Combine

class LibraryState: ObservableObject {
    static let shared = LibraryState()

    // Filter + view mode — persisted across sessions
    @AppStorage("librarySelectedFilter") var selectedFilter: String = "Artists"
    @AppStorage("librarySortOption") var sortOption: String = SortOption.nameAsc.rawValue
    @AppStorage("libraryViewMode") var viewModeRaw: String = ViewMode.list.rawValue

    var viewMode: ViewMode {
        get { ViewMode(rawValue: viewModeRaw) ?? .list }
        set { viewModeRaw = newValue.rawValue }
    }

    // Last-tapped item IDs — used to restore scroll position
    var lastTappedArtistId: String = ""
    var lastTappedAlbumId: String = ""
    var lastTappedPlaylistId: String = ""
    var lastTappedArtistAlbumIds: [String: String] = [:]

    // Cached data — keeps library loaded across navigation
    var albums: [Album] = []
    var artists: [Artist] = []
    var playlists: [Playlist] = []
    var genres: [Genre] = []
    var isLoaded = false
}
