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
    @State private var albums: [Album] = []
    @State private var artists: [Artist] = []
    @State private var searchText = ""
    @State private var selectedFilter = "Artists"
    @State private var viewMode: ViewMode = .list
    @State private var sortOption: SortOption = .nameAsc
    @State private var showSortMenu = false
    @State private var selectedArtist: Artist?
    @State private var selectedAlbum: Album?
    @State private var isLoading = true
    @State private var errorMessage: String?

    let columns = [
        GridItem(.adaptive(minimum: 160), spacing: 16)
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
                    Color.darkBackground,
                    Color.darkMid,
                    Color.darkBackground
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerSection

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
                        .tint(.neonCyan)
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
                            .font(.system(size: 50))
                            .foregroundColor(.neonPink)
                        Text("Error Loading Library")
                            .font(.jellyAmpHeadline)
                            .foregroundColor(.white)
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
                                .fill(Color.neonCyan)
                        )
                        .neonGlow(color: .neonCyan, radius: 8)
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
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                        .padding(.top, 16)

                                    if viewMode == .grid {
                                        LazyVGrid(columns: columns, spacing: 16) {
                                            ForEach(filteredArtists) { artist in
                                                ArtistCard(artist: artist) {
                                                    selectedArtist = artist
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                    } else {
                                        LazyVStack(spacing: 0) {
                                            ForEach(filteredArtists) { artist in
                                                ArtistListRow(artist: artist) {
                                                    selectedArtist = artist
                                                }
                                                .padding(.horizontal, 20)

                                                if artist.id != filteredArtists.last?.id {
                                                    Divider()
                                                        .background(Color.neonCyan.opacity(0.2))
                                                        .padding(.horizontal, 20)
                                                }
                                            }
                                        }
                                    }
                                }

                                if !favoriteAlbums.isEmpty {
                                    Text("Favorite Albums")
                                        .font(.jellyAmpHeadline)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                        .padding(.top, filteredArtists.isEmpty ? 16 : 24)

                                    if viewMode == .grid {
                                        LazyVGrid(columns: columns, spacing: 16) {
                                            ForEach(favoriteAlbums) { album in
                                                AlbumCard(album: album) {
                                                    selectedAlbum = album
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                    } else {
                                        LazyVStack(spacing: 0) {
                                            ForEach(favoriteAlbums) { album in
                                                AlbumListRow(album: album) {
                                                    selectedAlbum = album
                                                }
                                                .padding(.horizontal, 20)

                                                if album.id != favoriteAlbums.last?.id {
                                                    Divider()
                                                        .background(Color.neonCyan.opacity(0.2))
                                                        .padding(.horizontal, 20)
                                                }
                                            }
                                        }
                                    }
                                }

                                if filteredArtists.isEmpty && favoriteAlbums.isEmpty {
                                    VStack(spacing: 16) {
                                        Image(systemName: "heart.slash")
                                            .font(.system(size: 60))
                                            .foregroundColor(.secondary.opacity(0.5))
                                        Text("No Favorites Yet")
                                            .font(.jellyAmpHeadline)
                                            .foregroundColor(.white)
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
                                        ArtistCard(artist: artist) {
                                            selectedArtist = artist
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 16)
                            } else {
                                LazyVStack(spacing: 0) {
                                    ForEach(filteredArtists) { artist in
                                        ArtistListRow(artist: artist) {
                                            selectedArtist = artist
                                        }
                                        .padding(.horizontal, 20)

                                        if artist.id != filteredArtists.last?.id {
                                            Divider()
                                                .background(Color.neonCyan.opacity(0.2))
                                                .padding(.horizontal, 20)
                                        }
                                    }
                                }
                                .padding(.top, 16)
                            }
                        } else {
                            // Albums View (and Recent for now)
                            if viewMode == .grid {
                                LazyVGrid(columns: columns, spacing: 16) {
                                    ForEach(filteredAndSortedAlbums) { album in
                                        AlbumCard(album: album) {
                                            selectedAlbum = album
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 16)
                            } else {
                                LazyVStack(spacing: 0) {
                                    ForEach(filteredAndSortedAlbums) { album in
                                        AlbumListRow(album: album) {
                                            selectedAlbum = album
                                        }
                                        .padding(.horizontal, 20)

                                        if album.id != filteredAndSortedAlbums.last?.id {
                                            Divider()
                                                .background(Color.neonCyan.opacity(0.2))
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
        .sheet(item: $selectedArtist) { artist in
            ArtistDetailView(artist: artist)
        }
        .sheet(item: $selectedAlbum) { album in
            AlbumDetailView(album: album)
        }
        .onAppear {
            if albums.isEmpty && artists.isEmpty {
                Task {
                    await fetchLibrary()
                }
            }
        }
    }

    // MARK: - Fetch Library
    private func fetchLibrary() async {
        // Check cache first for instant loading
        if let cachedAlbums = UserDefaults.standard.data(forKey: "cachedAlbums"),
           let cachedArtists = UserDefaults.standard.data(forKey: "cachedArtists"),
           let decodedAlbums = try? JSONDecoder().decode([Album].self, from: cachedAlbums),
           let decodedArtists = try? JSONDecoder().decode([Artist].self, from: cachedArtists) {

            // Load cached data immediately
            await MainActor.run {
                self.albums = decodedAlbums
                self.artists = decodedArtists
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
            // Fetch albums and artists in parallel with smart limits
            // Initial load: 300 albums and 200 artists (loads in ~1-2 seconds)
            // Users can load more later if needed
            async let albumsResult = jellyfinService.fetchMusicItems(includeItemTypes: "MusicAlbum", limit: 300)
            async let artistsResult = jellyfinService.fetchArtists(limit: 200)

            let (fetchedAlbums, fetchedArtists) = try await (albumsResult, artistsResult)

            // Convert BaseItemDto to our UI models
            let baseURL = jellyfinService.baseURL
            let newAlbums = fetchedAlbums.map { Album(from: $0, baseURL: baseURL) }
            let newArtists = fetchedArtists.map { Artist(from: $0, baseURL: baseURL) }

            await MainActor.run {
                self.albums = newAlbums
                self.artists = newArtists
                self.isLoading = false
            }

            // Cache the results for next launch
            if let albumsData = try? JSONEncoder().encode(newAlbums),
               let artistsData = try? JSONEncoder().encode(newArtists) {
                UserDefaults.standard.set(albumsData, forKey: "cachedAlbums")
                UserDefaults.standard.set(artistsData, forKey: "cachedArtists")
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
                    .foregroundColor(.white)
                    .neonGlow(color: .neonCyan, radius: 10)

                Text("\(albums.count) Albums")
                    .font(.jellyAmpCaption)
                    .foregroundColor(.secondary)
            }

            Spacer()
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
                .foregroundColor(.white)
                .tint(.neonCyan)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .glassEffect(.regular)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.neonCyan.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }

    // MARK: - Filter Section
    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(["Artists", "Albums", "Favorites", "Recent"], id: \.self) { filter in
                    FilterPill(
                        title: filter,
                        isSelected: selectedFilter == filter
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedFilter = filter
                        }
                    }
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
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .glassEffect(.regular)
                )
                .overlay(
                    Capsule()
                        .stroke(Color.neonPink.opacity(0.4), lineWidth: 1)
                )
            }
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
                                    .fill(viewMode == mode ? Color.neonCyan : Color.clear)
                            )
                    }
                }
            }
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.1))
                    .glassEffect(.regular)
            )
            .overlay(
                Capsule()
                    .stroke(Color.neonCyan.opacity(0.4), lineWidth: 1)
            )
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }
}

// MARK: - Album Card Component
struct AlbumCard: View {
    let album: Album
    let action: () -> Void
    @State private var isPressed = false

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
                                        Color.neonCyan.opacity(0.6),
                                        Color.neonPink.opacity(0.6)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .neonGlow(color: .neonCyan, radius: isPressed ? 8 : 12)
                } else {
                    placeholderArtwork
                }
            }

            // Album Info
            VStack(alignment: .leading, spacing: 4) {
                Text(album.name)
                    .font(.jellyAmpBody)
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(album.artistName)
                    .font(.jellyAmpCaption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                if let year = album.year {
                    Text(String(year))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.neonCyan.opacity(0.6))
                }
            }
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onTapGesture {
            isPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
                action()
            }
        }
    }

    private var placeholderArtwork: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                LinearGradient(
                    colors: [
                        Color.neonCyan.opacity(0.5),
                        Color.neonPink.opacity(0.5),
                        Color.neonPurple.opacity(0.5)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .aspectRatio(1, contentMode: .fit)
            .glassEffect(.regular)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.neonCyan.opacity(0.6),
                                Color.neonPink.opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .neonGlow(color: .neonCyan, radius: isPressed ? 8 : 12)
            .overlay(
                Image(systemName: "music.note")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.4))
            )
    }
}

// MARK: - Album List Row Component
struct AlbumListRow: View {
    let album: Album
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button {
            isPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
                action()
            }
        } label: {
            HStack(spacing: 16) {
                // Album artwork (square)
                if let artworkURL = album.artworkURL, let url = URL(string: artworkURL) {
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

                // Album info
                VStack(alignment: .leading, spacing: 8) {
                    // Album name - bold and prominent
                    Text(album.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    // Artist name - secondary
                    Text(album.artistName)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    // Year and track count - clear and separated
                    HStack(spacing: 0) {
                        if let year = album.year {
                            Text(String(year))
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(.neonCyan)
                        }

                        if let trackCount = album.trackCount {
                            if album.year != nil {
                                Text("  •  ")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary.opacity(0.5))
                            }
                            Text("\(trackCount) track\(trackCount == 1 ? "" : "s")")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary.opacity(0.8))
                        }
                    }
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.neonCyan.opacity(0.6))
            }
            .padding(.vertical, 14)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
        }
    }

    private var placeholderArtwork: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.neonPink.opacity(0.4),
                            Color.neonPurple.opacity(0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 64, height: 64)
                .glassEffect(.regular)

            Image(systemName: "music.note")
                .font(.system(size: 20))
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
                        .fill(isSelected ? Color.neonCyan : Color.white.opacity(0.1))
                        .glassEffect(.regular)
                )
                .overlay(
                    Capsule()
                        .stroke(Color.neonCyan.opacity(isSelected ? 0.8 : 0.3), lineWidth: 1)
                )
                .neonGlow(color: .neonCyan, radius: isSelected ? 8 : 0)
        }
    }
}

// MARK: - Artist Card Component
struct ArtistCard: View {
    let artist: Artist
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            isPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
                action()
            }
        }) {
            VStack(alignment: .leading, spacing: 8) {
                // Artist artwork (circular)
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.neonPurple.opacity(0.5),
                                    Color.neonPink.opacity(0.5),
                                    Color.neonCyan.opacity(0.5)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 160, height: 160)
                        .glassEffect(.regular)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.neonPurple.opacity(0.6),
                                            Color.neonPink.opacity(0.6)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .neonGlow(color: .neonPurple, radius: isPressed ? 8 : 12)

                    // Artist icon
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.4))
                }

                // Artist info
                VStack(alignment: .leading, spacing: 4) {
                    Text(artist.name)
                        .font(.jellyAmpBody)
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text("\(artist.albumCount) albums")
                        .font(.jellyAmpCaption)
                        .foregroundColor(.secondary)
                }
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
    }
}

// MARK: - Artist List Row Component
struct ArtistListRow: View {
    let artist: Artist
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            isPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
                action()
            }
        }) {
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
                                                colors: [Color.neonPurple, Color.neonPink],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 2
                                        )
                                )
                                .shadow(color: Color.neonPurple.opacity(0.5), radius: 8, x: 0, y: 4)
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
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text("\(artist.albumCount) album\(artist.albumCount == 1 ? "" : "s")")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary.opacity(0.9))
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.neonPurple.opacity(0.6))
            }
            .padding(.vertical, 14)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
        }
    }

    private var placeholderArtistArt: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.neonPurple.opacity(0.5),
                            Color.neonPink.opacity(0.5)
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
                                colors: [Color.neonPurple, Color.neonPink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )

            Image(systemName: "person.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(.white.opacity(0.4))
        }
    }
}

// MARK: - Preview
#Preview {
    LibraryView()
}
