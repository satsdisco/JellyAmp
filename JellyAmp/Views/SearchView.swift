//
//  SearchView.swift
//  JellyAmp
//
//  Search across artists, albums, and tracks - Cypherpunk theme
//

import SwiftUI

struct SearchView: View {
    @ObservedObject var jellyfinService = JellyfinService.shared
    @ObservedObject var themeManager = ThemeManager.shared
    @ObservedObject var playerManager = PlayerManager.shared

    @State private var searchText = ""
    @State private var searchResults: [BaseItemDto] = []
    @State private var isSearching = false
    @State private var selectedFilter: SearchFilter = .all
    // Navigation handled by NavigationStack

    enum SearchFilter: String, CaseIterable {
        case all = "All"
        case artists = "Artists"
        case albums = "Albums"
        case tracks = "Tracks"
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
                // Header
                searchHeader

                // Search Bar
                searchBar

                // Filter Tabs
                filterTabs

                // Results
                if searchText.isEmpty {
                    emptySearchView
                } else if isSearching {
                    loadingView
                } else if filteredResults.isEmpty {
                    noResultsView
                } else {
                    searchResultsList
                }
            }
        }
        .navigationDestination(for: Album.self) { album in
            AlbumDetailView(album: album)
        }
        .navigationDestination(for: Artist.self) { artist in
            ArtistDetailView(artist: artist)
        }
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Header
    private var searchHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Search")
                    .font(.title.weight(.bold))
                    .foregroundColor(Color.jellyAmpText)
                    .neonGlow(color: .jellyAmpAccent, radius: 12)

                if !searchResults.isEmpty {
                    Text("\(filteredResults.count) result\(filteredResults.count == 1 ? "" : "s")")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.leading, 20)

            Spacer()
        }
        .padding(.top, 60)
        .padding(.bottom, 20)
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: 12) {
            // Search Icon
            Image(systemName: "magnifyingglass")
                .font(.headline.weight(.semibold))
                .foregroundColor(.neonCyan)

            // Text Field
            TextField("Search artists, albums, tracks...", text: $searchText)
                .font(.body)
                .foregroundColor(Color.jellyAmpText)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .accessibilityLabel("Search music library")
                .onChange(of: searchText) { _, newValue in
                    performSearch(query: newValue)
                }

            // Clear Button
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    searchResults = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.jellyAmpMidBackground.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.jellyAmpAccent.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Filter Tabs
    private var filterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(SearchFilter.allCases, id: \.self) { filter in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedFilter = filter
                        }
                    } label: {
                        Text(filter.rawValue)
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(selectedFilter == filter ? .black : .neonCyan)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(selectedFilter == filter ? Color.jellyAmpAccent : Color.jellyAmpAccent.opacity(0.15))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color.jellyAmpAccent.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .accessibilityLabel("Filter: \(filter.rawValue)")
                    .accessibilityAddTraits(selectedFilter == filter ? .isSelected : [])
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 16)
    }

    // MARK: - Results List
    private var searchResultsList: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(filteredResults, id: \.id) { item in
                    if item.type == "MusicArtist" {
                        NavigationLink(value: Artist(from: item, baseURL: jellyfinService.baseURL)) {
                            SearchResultRow(
                                item: item,
                                baseURL: jellyfinService.baseURL,
                                onTap: {
                                    // Action now handled by NavigationLink
                                }
                            )
                        }
                    } else if item.type == "MusicAlbum" {
                        NavigationLink(value: Album(from: item, baseURL: jellyfinService.baseURL)) {
                            SearchResultRow(
                                item: item,
                                baseURL: jellyfinService.baseURL,
                                onTap: {
                                    // Action now handled by NavigationLink
                                }
                            )
                        }
                    } else {
                        SearchResultRow(
                            item: item,
                            baseURL: jellyfinService.baseURL,
                            onTap: {
                                handleItemTap(item)
                            }
                        )
                    }
                }

                // Bottom padding
                Color.clear.frame(height: 100)
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Empty State
    private var emptySearchView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.title)
                .foregroundColor(.neonCyan.opacity(0.5))

            Text("Search Your Library")
                .font(.title3.weight(.bold))
                .foregroundColor(Color.jellyAmpText)

            Text("Find artists, albums, and tracks")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Loading State
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(.jellyAmpAccent)
                .scaleEffect(1.5)

            Text("Searching...")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - No Results State
    private var noResultsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note.list")
                .font(.title)
                .foregroundColor(.secondary.opacity(0.5))

            Text("No Results")
                .font(.title3.weight(.bold))
                .foregroundColor(Color.jellyAmpText)

            Text("Try a different search term")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Computed Properties
    private var filteredResults: [BaseItemDto] {
        switch selectedFilter {
        case .all:
            return searchResults
        case .artists:
            return searchResults.filter { $0.type == "MusicArtist" }
        case .albums:
            return searchResults.filter { $0.type == "MusicAlbum" }
        case .tracks:
            return searchResults.filter { $0.type == "Audio" }
        }
    }

    // MARK: - Actions
    private func performSearch(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        // Debounce search
        Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds

            // Check if query is still the same
            guard searchText == query else { return }

            await MainActor.run {
                isSearching = true
            }

            do {
                let results = try await jellyfinService.searchMusic(query: query)

                await MainActor.run {
                    searchResults = results
                    isSearching = false
                }
            } catch {
                print("Search error: \(error)")
                await MainActor.run {
                    searchResults = []
                    isSearching = false
                }
            }
        }
    }

    private func handleItemTap(_ item: BaseItemDto) {
        switch item.type {
        case "Audio":
            // Play track
            let track = Track(from: item, baseURL: jellyfinService.baseURL)
            playerManager.play(tracks: [track])

        default:
            break
        }
    }
}

// MARK: - Search Result Row
struct SearchResultRow: View {
    let item: BaseItemDto
    let baseURL: String
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            isPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
                onTap()
            }
        } label: {
            HStack(spacing: 16) {
                // Artwork/Icon
                if let imageTags = item.imageTags,
                   let primaryTag = imageTags["Primary"] {
                    let itemId = item.id
                    let imageURL = "\(baseURL)/Items/\(itemId)/Images/Primary?fillHeight=80&fillWidth=80&quality=90&tag=\(primaryTag)"

                    AsyncImage(url: URL(string: imageURL)) { phase in
                        switch phase {
                        case .empty:
                            placeholderImage
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        case .failure:
                            placeholderImage
                        @unknown default:
                            placeholderImage
                        }
                    }
                    .frame(width: 60, height: 60)
                } else {
                    placeholderImage
                }

                // Item Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.name ?? "Unknown")
                        .font(.body.weight(.semibold))
                        .foregroundColor(Color.jellyAmpText)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        // Type Badge
                        Text(itemTypeLabel)
                            .font(.caption.weight(.bold))
                            .foregroundColor(itemTypeColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(itemTypeColor.opacity(0.2))
                            )

                        // Additional Info based on type
                        if item.type == "MusicArtist" {
                            // Show album count for artists
                            if let albumCount = item.AlbumCount {
                                Text("\(albumCount) album\(albumCount == 1 ? "" : "s")")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        } else if let artist = item.artists?.first {
                            // Show artist name for albums/tracks
                            Text(artist)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.jellyAmpMidBackground.opacity(isPressed ? 0.5 : 0.3))
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
    }

    private var placeholderImage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [Color.jellyAmpAccent.opacity(0.3), Color.jellyAmpTertiary.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 60, height: 60)

            Image(systemName: itemTypeIcon)
                .font(.title2)
                .foregroundColor(.white.opacity(0.6))
        }
    }

    private var itemTypeLabel: String {
        switch item.type {
        case "MusicArtist": return "ARTIST"
        case "MusicAlbum": return "ALBUM"
        case "Audio": return "TRACK"
        default: return item.type
        }
    }

    private var itemTypeColor: Color {
        switch item.type {
        case "MusicArtist": return .neonCyan
        case "MusicAlbum": return .neonPink
        case "Audio": return .neonPurple
        default: return .neonCyan
        }
    }

    private var itemTypeIcon: String {
        switch item.type {
        case "MusicArtist": return "person.circle.fill"
        case "MusicAlbum": return "square.stack.fill"
        case "Audio": return "music.note"
        default: return "music.note"
        }
    }
}

// MARK: - Preview
#Preview {
    SearchView()
}
