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
    @Environment(\.horizontalSizeClass) private var sizeClass

    @State private var searchText = ""
    @State private var searchResults: [BaseItemDto] = []
    @State private var isSearching = false
    @State private var selectedFilter: SearchFilter = .all
    @State private var searchTask: Task<Void, Never>?
    @State private var searchError: String?
    @State private var lastTappedResultId: String?
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
                // Filter Tabs
                filterTabs

                // Results
                if searchText.isEmpty {
                    emptySearchView
                } else if isSearching {
                    loadingView
                } else if let searchError {
                    searchErrorView(searchError)
                } else if filteredResults.isEmpty {
                    noResultsView
                } else {
                    searchResultsList
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search artists, albums, tracks...")
        .onChange(of: searchText) { _, newValue in
            performSearch(query: newValue)
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
                            .foregroundColor(selectedFilter == filter ? .black : .jellyAmpAccent)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background {
                                if selectedFilter == filter {
                                    Capsule().fill(Color.jellyAmpAccent)
                                } else {
                                    Capsule().fill(.ultraThinMaterial)
                                }
                            }
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
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(filteredResults, id: \.id) { item in
                        if item.type == "MusicArtist" {
                            NavigationLink(value: Artist(from: item, baseURL: jellyfinService.baseURL)) {
                                SearchResultRow(item: item, baseURL: jellyfinService.baseURL)
                            }
                            .id(item.id)
                            .simultaneousGesture(TapGesture().onEnded { rememberResultTap(item) })
                            .buttonStyle(.plain)
                        } else if item.type == "MusicAlbum" {
                            NavigationLink(value: Album(from: item, baseURL: jellyfinService.baseURL)) {
                                SearchResultRow(item: item, baseURL: jellyfinService.baseURL)
                            }
                            .id(item.id)
                            .simultaneousGesture(TapGesture().onEnded { rememberResultTap(item) })
                            .buttonStyle(.plain)
                        } else {
                            Button { handleItemTap(item) } label: {
                                SearchResultRow(item: item, baseURL: jellyfinService.baseURL)
                            }
                            .id(item.id)
                            .buttonStyle(.plain)
                        }
                    }

                    // Bottom padding
                    Color.clear.frame(height: 100)
                }
                .padding(.top, 8)
            }
            .onAppear { restoreSearchScroll(using: proxy) }
            .onChange(of: filteredResults.map(\.id)) { _, _ in restoreSearchScroll(using: proxy) }
        }
    }

    // MARK: - Empty State
    private var emptySearchView: some View {
        ContentUnavailableView {
            Label("Search Your Library", systemImage: "magnifyingglass")
        } description: {
            Text("Find artists, albums, and tracks")
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
                .foregroundColor(.jellyAmpTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - No Results State
    private var noResultsView: some View {
        ContentUnavailableView {
            Label("No Results", systemImage: "music.note.list")
        } description: {
            Text("Try a different search term")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func searchErrorView(_ message: String) -> some View {
        ContentUnavailableView {
            Label("Search Failed", systemImage: "wifi.exclamationmark")
        } description: {
            Text(message)
        } actions: {
            Button("Try Again") {
                performSearch(query: searchText, immediate: true)
            }
            .buttonStyle(.borderedProminent)
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
    private func performSearch(query: String, immediate: Bool = false) {
        guard !query.isEmpty else {
            searchResults = []
            searchError = nil
            return
        }

        // Cancel previous search task to avoid race conditions
        searchTask?.cancel()
        searchTask = Task {
            if !immediate {
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
            }
            guard !Task.isCancelled else { return }

            await MainActor.run {
                isSearching = true
                searchError = nil
            }

            do {
                let results = try await jellyfinService.searchMusic(query: query)
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    searchResults = results
                    isSearching = false
                    searchError = nil
                }
            } catch {
                guard !Task.isCancelled else { return }
                print("Search error: \(error)")
                await MainActor.run {
                    searchResults = []
                    isSearching = false
                    searchError = userFriendlySearchError(error)
                }
            }
        }
    }

    private func rememberResultTap(_ item: BaseItemDto) {
        lastTappedResultId = item.id
    }

    private func restoreSearchScroll(using proxy: ScrollViewProxy) {
        guard let id = lastTappedResultId, filteredResults.contains(where: { $0.id == id }) else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.2)) {
                proxy.scrollTo(id, anchor: .center)
            }
        }
    }

    private func userFriendlySearchError(_ error: Error) -> String {
        let nsError = error as NSError
        switch nsError.code {
        case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
            return "No internet connection. Check your network and try again."
        case NSURLErrorTimedOut:
            return "Search timed out. Try again in a second."
        case NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost:
            return "Could not reach your Jellyfin server."
        default:
            return error.localizedDescription
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

    var body: some View {
        HStack(spacing: 16) {
                // Artwork/Icon
                if let imageTags = item.imageTags,
                   let primaryTag = imageTags["Primary"] {
                    let itemId = item.id
                    let imageURL = "\(baseURL)/Items/\(itemId)/Images/Primary?fillHeight=80&fillWidth=80&quality=90&tag=\(primaryTag)"

                    CachedAsyncImage(url: URL(string: imageURL)) { phase in
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
                                    .foregroundColor(.jellyAmpTextSecondary)
                                    .lineLimit(1)
                            }
                        } else if let artist = item.artists?.first {
                            // Show artist name for albums/tracks
                            Text(artist)
                                .font(.subheadline)
                                .foregroundColor(.jellyAmpTextSecondary)
                                .lineLimit(1)
                        }
                    }
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.jellyAmpTextSecondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.jellyAmpMidBackground.opacity(0.3))
            )
            .contentShape(Rectangle())
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
