//
//  LibraryView.swift
//  JellyAmp
//
//  Music library with grid/list views and sorting - iOS 26 Liquid Glass + Cypherpunk
//

import SwiftUI

enum ViewMode: String, CaseIterable {
    case grid = "Grid"
    case list = "List"

    var icon: String {
        switch self {
        case .grid: return "square.grid.2x2"
        case .list: return "list.bullet"
        }
    }
}

enum SortOption: String, CaseIterable {
    case nameAsc = "Name (A-Z)"
    case nameDesc = "Name (Z-A)"
    case artistAsc = "Artist (A-Z)"
    case artistDesc = "Artist (Z-A)"
    case yearNewest = "Year (Newest)"
    case yearOldest = "Year (Oldest)"

    func sort(_ albums: [Album]) -> [Album] {
        switch self {
        case .nameAsc:
            return albums.sorted { $0.name < $1.name }
        case .nameDesc:
            return albums.sorted { $0.name > $1.name }
        case .artistAsc:
            return albums.sorted { $0.artistName < $1.artistName }
        case .artistDesc:
            return albums.sorted { $0.artistName > $1.artistName }
        case .yearNewest:
            return albums.sorted { ($0.year ?? 0) > ($1.year ?? 0) }
        case .yearOldest:
            return albums.sorted { ($0.year ?? 0) < ($1.year ?? 0) }
        }
    }
}

struct LibraryView: View {
    @ObservedObject var jellyfinService = JellyfinService.shared
    @ObservedObject var themeManager = ThemeManager.shared
    @State private var albums: [Album] = []
    @State private var artists: [Artist] = []
    @State private var playlists: [Playlist] = []
    @State private var searchText = ""
    @State private var selectedFilter = "Artists"
    @State private var viewMode: ViewMode = .list
    @State private var sortOption: SortOption = .nameAsc
    @State private var showSortMenu = false
    // Navigation handled by NavigationStack and NavigationLink
    @State private var isLoading = true
    @State private var isSyncing = false
    @State private var errorMessage: String?
    @State private var showNewPlaylistSheet = false

    let columns = [
        GridItem(.adaptive(minimum: 130), spacing: 16)
    ]

    var filteredAndSortedAlbums: [Album] {
        let filtered: [Album]
        if searchText.isEmpty {
            filtered = albums
        } else {
            filtered = albums.filter { album in
                album.name.localizedCaseInsensitiveContains(searchText) ||
                album.artistName.localizedCaseInsensitiveContains(searchText)
            }
        }
        return sortOption.sort(filtered)
    }

    var filteredArtists: [Artist] {
        var filtered = artists

        // Apply favorites filter if needed
        if selectedFilter == "Favorites" {
            filtered = filtered.filter { $0.isFavorite }
        }

        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }

        return filtered.sorted { $0.name < $1.name }
    }

    var favoriteAlbums: [Album] {
        albums.filter { $0.isFavorite }
    }

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color.jellyAmpBackground,
                    Color.jellyAmpMidBackground,
                    Color.jellyAmpBackground
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Search Bar
                searchSection

                // Filter Pills
                filterSection

                // View Mode & Sort Controls
                viewControlsSection

                // Content based on filter
                if isLoading {
                    // Loading state
                    Spacer()
                    ProgressView()
                        .tint(.jellyAmpAccent)
                        .scaleEffect(1.5)
                    Text("Loading library...")
                        .font(.jellyAmpBody)
                        .foregroundColor(.secondary)
                        .padding(.top, 20)
                    Spacer()
                } else if let error = errorMessage {
                    // Error state
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.title)
                            .foregroundColor(.neonPink)
                        Text("Error Loading Library")
                            .font(.jellyAmpHeadline)
                            .foregroundColor(Color.jellyAmpText)
                        Text(error)
                            .font(.jellyAmpBody)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        Button("Try Again") {
                            Task {
                                await fetchLibrary()
                            }
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color.jellyAmpAccent)
                        )
                        .neonGlow(color: .jellyAmpAccent, radius: 8)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        if selectedFilter == "Favorites" {
                            // Favorites View - Show both artists and albums
                            VStack(alignment: .leading, spacing: 20) {
                                if !filteredArtists.isEmpty {
                                    Text("Favorite Artists")
                                        .font(.jellyAmpHeadline)
                                        .foregroundColor(Color.jellyAmpText)
                                        .padding(.horizontal, 20)
                                        .padding(.top, 16)

                                    if viewMode == .grid {
                                        LazyVGrid(columns: columns, spacing: 16) {
                                            ForEach(filteredArtists) { artist in
                                                NavigationLink(value: artist) {
                                                    ArtistCard(artist: artist)
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                    } else {
                                        LazyVStack(spacing: 0) {
                                            ForEach(filteredArtists) { artist in
                                                NavigationLink(value: artist) {
                                                    ArtistListRow(artist: artist)
                                                }
                                                .padding(.horizontal, 20)

                                                if artist.id != filteredArtists.last?.id {
                                                    Divider()
                                                        .background(Color.jellyAmpAccent.opacity(0.2))
                                                        .padding(.horizontal, 20)
                                                }
                                            }
                                        }
                                    }
                                }

                                if !favoriteAlbums.isEmpty {
                                    Text("Favorite Albums")
                                        .font(.jellyAmpHeadline)
                                        .foregroundColor(Color.jellyAmpText)
                                        .padding(.horizontal, 20)
                                        .padding(.top, filteredArtists.isEmpty ? 16 : 24)

                                    if viewMode == .grid {
                                        LazyVGrid(columns: columns, spacing: 16) {
                                            ForEach(favoriteAlbums) { album in
                                                NavigationLink(value: album) {
                                                    AlbumCard(album: album)
                                                }
                                                .accessibilityElement(children: .combine)
                                                .accessibilityLabel("Album: \(album.name) by \(album.artistName)")
                                                .accessibilityHint("Double tap to view album")
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                    } else {
                                        LazyVStack(spacing: 0) {
                                            ForEach(favoriteAlbums) { album in
                                                NavigationLink(value: album) {
                                                    AlbumListRow(album: album)
                                                }
                                                .accessibilityElement(children: .combine)
                                                .accessibilityLabel("Album: \(album.name) by \(album.artistName)")
                                                .accessibilityHint("Double tap to view album")
                                                .padding(.horizontal, 20)

                                                if album.id != favoriteAlbums.last?.id {
                                                    Divider()
                                                        .background(Color.jellyAmpAccent.opacity(0.2))
                                                        .padding(.horizontal, 20)
                                                }
                                            }
                                        }
                                    }
                                }

                                if filteredArtists.isEmpty && favoriteAlbums.isEmpty {
                                    VStack(spacing: 16) {
                                        Image(systemName: "heart.slash")
                                            .font(.title)
                                            .foregroundColor(.secondary.opacity(0.5))
                                        Text("No Favorites Yet")
                                            .font(.jellyAmpHeadline)
                                            .foregroundColor(Color.jellyAmpText)
                                        Text("Tap the heart icon on albums and artists to add them here")
                                            .font(.jellyAmpBody)
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 40)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.top, 100)
                                }
                            }
                        } else if selectedFilter == "Artists" {
                            // Artists View
                            if viewMode == .grid {
                                LazyVGrid(columns: columns, spacing: 16) {
                                    ForEach(filteredArtists) { artist in
                                        NavigationLink(value: artist) {
                                            ArtistCard(artist: artist)
                                        }
                                        .accessibilityElement(children: .combine)
                                        .accessibilityLabel("Artist: \(artist.name)")
                                        .accessibilityHint("Double tap to view artist albums")
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 16)
                            } else {
                                LazyVStack(spacing: 0) {
                                    ForEach(filteredArtists) { artist in
                                        NavigationLink(value: artist) {
                                            ArtistListRow(artist: artist)
                                        }
                                        .accessibilityElement(children: .combine)
                                        .accessibilityLabel("Artist: \(artist.name)")
                                        .accessibilityHint("Double tap to view artist albums")
                                        .padding(.horizontal, 20)

                                        if artist.id != filteredArtists.last?.id {
                                            Divider()
                                                .background(Color.jellyAmpAccent.opacity(0.2))
                                                .padding(.horizontal, 20)
                                        }
                                    }
                                }
                                .padding(.top, 16)
                            }
                        } else if selectedFilter == "Playlists" {
                            // Playlists View
                            if playlists.isEmpty {
                                VStack(spacing: 16) {
                                    Image(systemName: "music.note.list")
                                        .font(.title)
                                        .foregroundColor(.secondary.opacity(0.5))
                                    Text("No Playlists Yet")
                                        .font(.jellyAmpHeadline)
                                        .foregroundColor(Color.jellyAmpText)
                                    Text("Create your first playlist to organize your favorite tracks")
                                        .font(.jellyAmpBody)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 40)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 100)
                            } else {
                                if viewMode == .grid {
                                    LazyVGrid(columns: columns, spacing: 16) {
                                        ForEach(playlists) { playlist in
                                            NavigationLink(value: playlist) {
                                                PlaylistCard(playlist: playlist)
                                            }
                                            .accessibilityElement(children: .combine)
                                            .accessibilityLabel("Playlist: \(playlist.name), \(playlist.trackCount) track\(playlist.trackCount == 1 ? "" : "s")")
                                            .accessibilityHint("Double tap to view playlist")
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.top, 16)
                                } else {
                                    LazyVStack(spacing: 0) {
                                        ForEach(playlists) { playlist in
                                            NavigationLink(value: playlist) {
                                                PlaylistListRow(playlist: playlist)
                                            }
                                            .accessibilityElement(children: .combine)
                                            .accessibilityLabel("Playlist: \(playlist.name), \(playlist.trackCount) track\(playlist.trackCount == 1 ? "" : "s")")
                                            .accessibilityHint("Double tap to view playlist")
                                            .padding(.horizontal, 20)

                                            if playlist.id != playlists.last?.id {
                                                Divider()
                                                    .background(Color.jellyAmpAccent.opacity(0.2))
                                                    .padding(.horizontal, 20)
                                            }
                                        }
                                    }
                                    .padding(.top, 16)
                                }
                            }
                        } else {
                            // Albums View (and Recent for now)
                            if viewMode == .grid {
                                LazyVGrid(columns: columns, spacing: 16) {
                                    ForEach(filteredAndSortedAlbums) { album in
                                        NavigationLink(value: album) {
                                            AlbumCard(album: album)
                                        }
                                        .accessibilityElement(children: .combine)
                                        .accessibilityLabel("Album: \(album.name) by \(album.artistName)")
                                        .accessibilityHint("Double tap to view album")
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 16)
                            } else {
                                LazyVStack(spacing: 0) {
                                    ForEach(filteredAndSortedAlbums) { album in
                                        NavigationLink(value: album) {
                                            AlbumListRow(album: album)
                                        }
                                        .accessibilityElement(children: .combine)
                                        .accessibilityLabel("Album: \(album.name) by \(album.artistName)")
                                        .accessibilityHint("Double tap to view album")
                                        .padding(.horizontal, 20)

                                        if album.id != filteredAndSortedAlbums.last?.id {
                                            Divider()
                                                .background(Color.jellyAmpAccent.opacity(0.2))
                                                .padding(.horizontal, 20)
                                        }
                                    }
                                }
                                .padding(.top, 16)
                            }
                        }
                    }
                }
            }
        }
        .navigationDestination(for: Artist.self) { artist in
            ArtistDetailView(artist: artist)
        }
        .navigationDestination(for: Album.self) { album in
            AlbumDetailView(album: album)
        }
        .navigationDestination(for: Playlist.self) { playlist in
            PlaylistDetailView(playlist: playlist)
        }
        .navigationTitle("Library")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                // New Playlist button (only show when Playlists filter is selected)
                if selectedFilter == "Playlists" {
                    Button {
                        showNewPlaylistSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.neonPink)
                    }
                    .accessibilityLabel("Create new playlist")
                }
                
                // Sync button
                Button {
                    Task {
                        await syncLibrary()
                    }
                } label: {
                    if isSyncing {
                        ProgressView()
                            .tint(.jellyAmpAccent)
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundColor(.jellyAmpAccent)
                    }
                }
                .accessibilityLabel(isSyncing ? "Syncing library" : "Sync library")
                .disabled(isSyncing)
            }
        }
        .sheet(isPresented: $showNewPlaylistSheet) {
            NewPlaylistSheet { playlistId in
                // Refresh playlists after creation
                Task {
                    await syncLibrary()
                }
            }
        }
        .onAppear {
            if albums.isEmpty && artists.isEmpty {
                Task {
                    await fetchLibrary()
                }
            }
        }
    }

    // MARK: - Library Management

    /// Sync library - force refresh from server
    private func syncLibrary() async {
        await MainActor.run {
            isSyncing = true
        }

        // Clear cache to force fresh fetch
        UserDefaults.standard.removeObject(forKey: "cachedAlbums")
        UserDefaults.standard.removeObject(forKey: "cachedArtists")
        UserDefaults.standard.removeObject(forKey: "cachedPlaylists")

        // Fetch fresh data
        await fetchAndCache()

        await MainActor.run {
            isSyncing = false
        }
    }

    // MARK: - Fetch Library
    private func fetchLibrary() async {
        // Check cache first for instant loading
        if let cachedAlbums = UserDefaults.standard.data(forKey: "cachedAlbums"),
           let cachedArtists = UserDefaults.standard.data(forKey: "cachedArtists"),
           let cachedPlaylists = UserDefaults.standard.data(forKey: "cachedPlaylists"),
           let decodedAlbums = try? JSONDecoder().decode([Album].self, from: cachedAlbums),
           let decodedArtists = try? JSONDecoder().decode([Artist].self, from: cachedArtists),
           let decodedPlaylists = try? JSONDecoder().decode([Playlist].self, from: cachedPlaylists) {

            // Load cached data immediately
            await MainActor.run {
                self.albums = decodedAlbums
                self.artists = decodedArtists
                self.playlists = decodedPlaylists
                self.isLoading = false
            }

            // Then fetch fresh data in background to update cache
            Task {
                await fetchAndCache()
            }
            return
        }

        // No cache - fetch with loading indicator
        await fetchAndCache()
    }

    private func fetchAndCache() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            // Fetch albums, artists, and playlists in parallel with smart limits
            // Initial load: 300 albums, 200 artists, and all playlists (loads in ~1-2 seconds)
            async let albumsResult = jellyfinService.fetchMusicItems(includeItemTypes: "MusicAlbum", limit: 300)
            async let artistsResult = jellyfinService.fetchArtists(limit: 200)
            async let playlistsResult = jellyfinService.fetchPlaylists()

            let (fetchedAlbums, fetchedArtists, fetchedPlaylists) = try await (albumsResult, artistsResult, playlistsResult)

            // Convert BaseItemDto to our UI models
            let baseURL = jellyfinService.baseURL
            let newAlbums = fetchedAlbums.map { Album(from: $0, baseURL: baseURL) }
            let newArtists = fetchedArtists.map { Artist(from: $0, baseURL: baseURL) }
            let newPlaylists = fetchedPlaylists.map { Playlist(from: $0, baseURL: baseURL) }

            await MainActor.run {
                self.albums = newAlbums
                self.artists = newArtists
                self.playlists = newPlaylists
                self.isLoading = false
            }

            // Cache the results for next launch
            if let albumsData = try? JSONEncoder().encode(newAlbums),
               let artistsData = try? JSONEncoder().encode(newArtists),
               let playlistsData = try? JSONEncoder().encode(newPlaylists) {
                UserDefaults.standard.set(albumsData, forKey: "cachedAlbums")
                UserDefaults.standard.set(artistsData, forKey: "cachedArtists")
                UserDefaults.standard.set(playlistsData, forKey: "cachedPlaylists")
            }
        } catch {
            await MainActor.run {
                errorMessage = userFriendlyError(error)
                isLoading = false
            }
        }
    }

    private func userFriendlyError(_ error: Error) -> String {
        // Convert technical errors to user-friendly messages
        let nsError = error as NSError

        switch nsError.code {
        case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
            return "No internet connection. Please check your network and try again."
        case NSURLErrorTimedOut:
            return "Request timed out. Please check your connection and try again."
        case NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost:
            return "Cannot connect to server. Please check your server URL."
        case NSURLErrorUserAuthenticationRequired, 401:
            return "Authentication failed. Please sign in again."
        default:
            return error.localizedDescription
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Library")
                    .font(.jellyAmpTitle)
                    .foregroundColor(Color.jellyAmpText)
                    .neonGlow(color: .jellyAmpAccent, radius: 10)

                Text("\(albums.count) Albums · \(artists.count) Artists")
                    .font(.jellyAmpCaption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // New Playlist button (only show when Playlists filter is selected)
            if selectedFilter == "Playlists" {
                Button {
                    showNewPlaylistSheet = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.jellyAmpMidBackground)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Circle()
                                    .stroke(Color.neonPink.opacity(0.5), lineWidth: 1)
                            )

                        Image(systemName: "plus.circle.fill")
                            .font(.title3.weight(.semibold))
                            .foregroundColor(.neonPink)
                    }
                    .neonGlow(color: .neonPink, radius: 8)
                }
            }

            // Sync button
            Button {
                Task {
                    await syncLibrary()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.jellyAmpMidBackground)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(Color.jellyAmpAccent.opacity(0.5), lineWidth: 1)
                        )

                    if isSyncing {
                        ProgressView()
                            .tint(.jellyAmpAccent)
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.headline.weight(.semibold))
                            .foregroundColor(.jellyAmpAccent)
                    }
                }
                .neonGlow(color: .jellyAmpAccent, radius: 8)
            }
            .disabled(isSyncing)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 20)
    }

    // MARK: - Search Section
    private var searchSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.neonCyan)

            TextField("Search albums, artists...", text: $searchText)
                .foregroundColor(Color.jellyAmpText)
                .tint(.jellyAmpAccent)
                .accessibilityLabel("Search albums and artists")

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.jellyAmpAccent.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }

    // MARK: - Filter Section
    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(["Artists", "Albums", "Playlists", "Favorites", "Recent"], id: \.self) { filter in
                    FilterPill(
                        title: filter,
                        isSelected: selectedFilter == filter
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedFilter = filter
                        }
                    }
                    .accessibilityLabel("Filter: \(filter)")
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAddTraits(selectedFilter == filter ? .isSelected : [])
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 16)
    }

    // MARK: - View Controls Section
    private var viewControlsSection: some View {
        HStack(spacing: 12) {
            // Sort Button
            Button {
                showSortMenu = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.caption)
                    Text(sortOption.rawValue)
                        .font(.jellyAmpCaption)
                }
                .foregroundColor(Color.jellyAmpText)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                )
                .overlay(
                    Capsule()
                        .stroke(Color.jellyAmpSecondary.opacity(0.4), lineWidth: 1)
                )
            }
            .accessibilityLabel("Sort by \(sortOption.rawValue)")
            .confirmationDialog("Sort By", isPresented: $showSortMenu, titleVisibility: .visible) {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Button(option.rawValue) {
                        withAnimation(.spring(response: 0.3)) {
                            sortOption = option
                        }
                    }
                }
            }

            Spacer()

            // View Mode Toggle
            HStack(spacing: 0) {
                ForEach(ViewMode.allCases, id: \.self) { mode in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            viewMode = mode
                        }
                    } label: {
                        Image(systemName: mode.icon)
                            .font(.caption)
                            .foregroundColor(viewMode == mode ? .black : .white)
                            .frame(width: 36, height: 30)
                            .background(
                                RoundedRectangle(cornerRadius: viewMode == mode ? 8 : 0)
                                    .fill(viewMode == mode ? Color.jellyAmpAccent : Color.clear)
                            )
                    }
                    .accessibilityLabel("\(mode.rawValue) view")
                    .accessibilityAddTraits(viewMode == mode ? .isSelected : [])
                }
            }
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.1))
            )
            .overlay(
                Capsule()
                    .stroke(Color.jellyAmpAccent.opacity(0.4), lineWidth: 1)
            )
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }
}

// MARK: - Album Card Component
struct AlbumCard: View {
    let album: Album

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Album Artwork
            ZStack {
                if let artworkURL = album.artworkURL, let url = URL(string: artworkURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            placeholderArtwork
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 160, height: 160)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        case .failure:
                            placeholderArtwork
                        @unknown default:
                            placeholderArtwork
                        }
                    }
                    .frame(width: 160, height: 160)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.jellyAmpAccent.opacity(0.6),
                                        Color.jellyAmpSecondary.opacity(0.6)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .neonGlow(color: .jellyAmpAccent, radius: 12)
                } else {
                    placeholderArtwork
                }
            }

            // Album Info
            VStack(alignment: .leading, spacing: 4) {
                Text(album.name)
                    .font(.jellyAmpBody)
                    .foregroundColor(Color.jellyAmpText)
                    .lineLimit(1)

                Text(album.artistName)
                    .font(.jellyAmpCaption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                if let year = album.year {
                    Text(String(year))
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.neonCyan.opacity(0.6))
                }
            }
        }
    }

    private var placeholderArtwork: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                LinearGradient(
                    colors: [
                        Color.jellyAmpAccent.opacity(0.5),
                        Color.jellyAmpSecondary.opacity(0.5),
                        Color.jellyAmpTertiary.opacity(0.5)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.jellyAmpAccent.opacity(0.6),
                                Color.jellyAmpSecondary.opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .neonGlow(color: .jellyAmpAccent, radius: 12)
            .overlay(
                Image(systemName: "music.note")
                    .font(.title)
                    .foregroundColor(.white.opacity(0.4))
            )
    }
}

// MARK: - Album List Row Component
struct AlbumListRow: View {
    let album: Album

    var body: some View {
            HStack(spacing: 16) {
                // Album artwork (square, larger and properly centered)
                if let artworkURL = album.artworkURL, let url = URL(string: artworkURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            placeholderArtwork
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color.jellyAmpAccent.opacity(0.5),
                                                    Color.jellyAmpSecondary.opacity(0.5)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1.5
                                        )
                                )
                                .shadow(color: Color.jellyAmpAccent.opacity(0.2), radius: 8, x: 0, y: 4)
                        case .failure:
                            placeholderArtwork
                        @unknown default:
                            placeholderArtwork
                        }
                    }
                    .frame(width: 80, height: 80)
                } else {
                    placeholderArtwork
                }

                // Album info
                VStack(alignment: .leading, spacing: 6) {
                    // Album name - bold and prominent
                    Text(album.name)
                        .font(.headline.weight(.bold))
                        .foregroundColor(Color.jellyAmpText)
                        .lineLimit(2)

                    // Artist name - secondary
                    Text(album.artistName)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    // Year and track count - clear and separated
                    HStack(spacing: 8) {
                        if let year = album.year {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .font(.caption2)
                                    .foregroundColor(.neonCyan)
                                Text(String(year))
                                    .font(.subheadline.weight(.bold))
                                    .foregroundColor(.neonCyan)
                            }
                        }

                        if let trackCount = album.trackCount {
                            HStack(spacing: 4) {
                                Image(systemName: "music.note.list")
                                    .font(.caption2)
                                    .foregroundColor(.neonPink.opacity(0.8))
                                Text("\(trackCount)")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.neonCyan.opacity(0.6))
            }
            .padding(.vertical, 12)
    }

    private var placeholderArtwork: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.jellyAmpAccent.opacity(0.5),
                            Color.jellyAmpSecondary.opacity(0.5),
                            Color.jellyAmpTertiary.opacity(0.5)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.jellyAmpAccent.opacity(0.5),
                                    Color.jellyAmpSecondary.opacity(0.5)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )

            Image(systemName: "music.note")
                .font(.title2)
                .foregroundColor(.white.opacity(0.4))
        }
    }
}

// MARK: - Filter Pill Component
struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.jellyAmpCaption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .black : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.jellyAmpAccent : Color.white.opacity(0.1))
                )
                .overlay(
                    Capsule()
                        .stroke(Color.jellyAmpAccent.opacity(isSelected ? 0.8 : 0.3), lineWidth: 1)
                )
                .neonGlow(color: .jellyAmpAccent, radius: isSelected ? 8 : 0)
        }
    }
}

// MARK: - Artist Card Component
struct ArtistCard: View {
    let artist: Artist

    var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                // Artist artwork (circular with photo if available)
                if let artworkURL = artist.artworkURL, let url = URL(string: artworkURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            placeholderArtwork
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 130, height: 130)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color.jellyAmpTertiary.opacity(0.6),
                                                    Color.jellyAmpSecondary.opacity(0.6)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1.5
                                        )
                                )
                                .neonGlow(color: .jellyAmpTertiary, radius: 12)
                        case .failure:
                            placeholderArtwork
                        @unknown default:
                            placeholderArtwork
                        }
                    }
                    .frame(width: 130, height: 130)
                } else {
                    placeholderArtwork
                }

                // Artist info
                VStack(alignment: .leading, spacing: 4) {
                    Text(artist.name)
                        .font(.jellyAmpBody)
                        .foregroundColor(Color.jellyAmpText)
                        .lineLimit(1)
                }
            }
    }

    private var placeholderArtwork: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.jellyAmpTertiary.opacity(0.5),
                            Color.jellyAmpSecondary.opacity(0.5),
                            Color.jellyAmpAccent.opacity(0.5)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 130, height: 130)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.jellyAmpTertiary.opacity(0.6),
                                    Color.jellyAmpSecondary.opacity(0.6)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .neonGlow(color: .jellyAmpTertiary, radius: 12)

            // Artist icon
            Image(systemName: "person.circle.fill")
                .font(.title)
                .foregroundColor(.white.opacity(0.4))
        }
    }
}

// MARK: - Artist List Row Component
struct ArtistListRow: View {
    let artist: Artist

    var body: some View {
            HStack(spacing: 16) {
                // Artist artwork (circular with photo if available)
                if let artworkURL = artist.artworkURL, let url = URL(string: artworkURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            placeholderArtistArt
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 64, height: 64)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(
                                            LinearGradient(
                                                colors: [Color.jellyAmpTertiary, Color.jellyAmpSecondary],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 2
                                        )
                                )
                                .shadow(color: Color.jellyAmpTertiary.opacity(0.5), radius: 8, x: 0, y: 4)
                        case .failure:
                            placeholderArtistArt
                        @unknown default:
                            placeholderArtistArt
                        }
                    }
                    .frame(width: 64, height: 64)
                } else {
                    placeholderArtistArt
                }

                // Artist info
                VStack(alignment: .leading, spacing: 4) {
                    Text(artist.name)
                        .font(.body.weight(.semibold))
                        .foregroundColor(Color.jellyAmpText)
                        .lineLimit(1)
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.neonPurple.opacity(0.6))
            }
            .padding(.vertical, 14)
    }

    private var placeholderArtistArt: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.jellyAmpTertiary.opacity(0.5),
                            Color.jellyAmpSecondary.opacity(0.5)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 64, height: 64)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.jellyAmpTertiary, Color.jellyAmpSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )

            Image(systemName: "person.circle.fill")
                .font(.title2)
                .foregroundColor(.white.opacity(0.4))
        }
    }
}

// MARK: - Playlist Card Component
struct PlaylistCard: View {
    let playlist: Playlist

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Playlist Artwork
            ZStack {
                if let artworkURL = playlist.artworkURL, let url = URL(string: artworkURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            placeholderArtwork
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 160, height: 160)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        case .failure:
                            placeholderArtwork
                        @unknown default:
                            placeholderArtwork
                        }
                    }
                    .frame(width: 160, height: 160)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.neonPink.opacity(0.6),
                                        Color.jellyAmpSecondary.opacity(0.6)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .neonGlow(color: .neonPink, radius: 12)
                } else {
                    placeholderArtwork
                }
            }

            // Playlist Info
            VStack(alignment: .leading, spacing: 4) {
                Text(playlist.name)
                    .font(.jellyAmpBody)
                    .foregroundColor(Color.jellyAmpText)
                    .lineLimit(1)

                Text("\(playlist.trackCount) track\(playlist.trackCount == 1 ? "" : "s")")
                    .font(.jellyAmpCaption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
    }

    private var placeholderArtwork: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                LinearGradient(
                    colors: [
                        Color.neonPink.opacity(0.5),
                        Color.jellyAmpSecondary.opacity(0.5),
                        Color.neonPurple.opacity(0.5)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.neonPink.opacity(0.6),
                                Color.jellyAmpSecondary.opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .neonGlow(color: .neonPink, radius: 12)
            .overlay(
                Image(systemName: "music.note.list")
                    .font(.title)
                    .foregroundColor(.white.opacity(0.4))
            )
    }
}

// MARK: - Playlist List Row Component
struct PlaylistListRow: View {
    let playlist: Playlist

    var body: some View {
            HStack(spacing: 16) {
                // Playlist artwork (square)
                if let artworkURL = playlist.artworkURL, let url = URL(string: artworkURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            placeholderArtwork
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 64, height: 64)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.neonPink.opacity(0.3), lineWidth: 1)
                                )
                        case .failure:
                            placeholderArtwork
                        @unknown default:
                            placeholderArtwork
                        }
                    }
                    .frame(width: 64, height: 64)
                } else {
                    placeholderArtwork
                }

                // Playlist info
                VStack(alignment: .leading, spacing: 8) {
                    // Playlist name - bold and prominent
                    Text(playlist.name)
                        .font(.body.weight(.semibold))
                        .foregroundColor(Color.jellyAmpText)
                        .lineLimit(1)

                    // Track count and date
                    HStack(spacing: 0) {
                        Text("\(playlist.trackCount) track\(playlist.trackCount == 1 ? "" : "s")")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.secondary.opacity(0.8))

                        if let dateCreated = playlist.dateCreated {
                            Text("  •  ")
                                .font(.caption)
                                .foregroundColor(.secondary.opacity(0.5))

                            Text(dateCreated, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary.opacity(0.6))
                        }
                    }
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.neonPink.opacity(0.6))
            }
            .padding(.vertical, 14)
    }

    private var placeholderArtwork: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.neonPink.opacity(0.4),
                            Color.jellyAmpSecondary.opacity(0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 64, height: 64)

            Image(systemName: "music.note.list")
                .font(.title3)
                .foregroundColor(.white.opacity(0.4))
        }
    }
}

// MARK: - Preview
#Preview {
    LibraryView()
}
