//
//  FavoritesView.swift
//  JellyAmp
//
//  Favorites page — redesigned to match PWA with filter pills and sections
//

import SwiftUI

struct FavoritesView: View {
    @ObservedObject var jellyfinService = JellyfinService.shared
    @ObservedObject var playerManager = PlayerManager.shared
    @Environment(\.horizontalSizeClass) private var sizeClass

    @State private var favoriteTracks: [Track] = []
    @State private var favoriteAlbums: [Album] = []
    @State private var favoriteArtists: [Artist] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedFilter = "All"

    private let filters = ["All", "Artists", "Albums", "Tracks"]

    private var columns: [GridItem] {
        sizeClass == .regular
            ? [GridItem(.adaptive(minimum: 180, maximum: 220), spacing: 16)]
            : [GridItem(.adaptive(minimum: 130), spacing: 16)]
    }

    var body: some View {
        ZStack {
            Color.jellyAmpBackground
                .ignoresSafeArea()

            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .tint(.neonPink)
                        .scaleEffect(1.5)
                    Text("Loading favorites...")
                        .font(.jellyAmpBody)
                        .foregroundColor(.jellyAmpTextSecondary)
                }
            } else if let error = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.neonPink)
                    Text("Error Loading Favorites")
                        .font(.jellyAmpHeadline)
                        .foregroundColor(Color.jellyAmpText)
                    Text(error)
                        .font(.jellyAmpBody)
                        .foregroundColor(.jellyAmpTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    Button("Try Again") {
                        Task { await fetchFavorites() }
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(Color.neonPink))
                }
            } else if favoriteTracks.isEmpty && favoriteAlbums.isEmpty && favoriteArtists.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Header
                        headerSection
                            .padding(.horizontal, 20)
                            .padding(.bottom, 16)

                        // Filter pills
                        filterPills
                            .padding(.horizontal, 20)
                            .padding(.bottom, 24)

                        // Sections
                        VStack(alignment: .leading, spacing: 32) {
                            if showArtists {
                                artistsSection
                            }
                            if showAlbums {
                                albumsSection
                            }
                            if showTracks {
                                tracksSection
                            }
                        }
                        .padding(.horizontal, 20)

                        Color.clear.frame(height: 100)
                    }
                }
            }
        }
        .navigationDestination(for: Album.self) { album in
            AlbumDetailView(album: album)
        }
        .navigationDestination(for: Artist.self) { artist in
            ArtistDetailView(artist: artist)
        }
        .navigationTitle("Favorites")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            if favoriteTracks.isEmpty && favoriteAlbums.isEmpty && favoriteArtists.isEmpty {
                Task { await fetchFavorites() }
            }
        }
    }

    // MARK: - Computed
    private var showArtists: Bool { selectedFilter == "All" || selectedFilter == "Artists" }
    private var showAlbums: Bool { selectedFilter == "All" || selectedFilter == "Albums" }
    private var showTracks: Bool { selectedFilter == "All" || selectedFilter == "Tracks" }

    // MARK: - Header
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !isLoading {
                Text("\(favoriteArtists.count) artists · \(favoriteAlbums.count) albums · \(favoriteTracks.count) tracks")
                    .font(.jellyAmpMono)
                    .foregroundColor(.jellyAmpTextSecondary)
            }
        }
    }

    // MARK: - Filter Pills
    private var filterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(filters, id: \.self) { filter in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedFilter = filter
                        }
                    } label: {
                        Text(filter)
                            .font(.jellyAmpCaption)
                            .fontWeight(.medium)
                            .foregroundColor(selectedFilter == filter ? .black : .jellyAmpTextSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedFilter == filter ? Color.neonCyan : Color.white.opacity(0.08))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(selectedFilter == filter ? Color.clear : Color.white.opacity(0.1), lineWidth: 1)
                            )
                    }
                }
            }
        }
    }

    // MARK: - Artists Section
    private var artistsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if selectedFilter == "All" {
                sectionHeader(title: "Favorite Artists", count: favoriteArtists.count)
            }

            if favoriteArtists.isEmpty {
                sectionEmpty("No favorite artists yet")
            } else {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(favoriteArtists) { artist in
                        NavigationLink(value: artist) {
                            ArtistCard(artist: artist)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Albums Section
    private var albumsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if selectedFilter == "All" {
                sectionHeader(title: "Favorite Albums", count: favoriteAlbums.count)
            }

            if favoriteAlbums.isEmpty {
                sectionEmpty("No favorite albums yet")
            } else {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(favoriteAlbums) { album in
                        NavigationLink(value: album) {
                            AlbumCard(album: album)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Tracks Section
    private var tracksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if selectedFilter == "All" {
                HStack {
                    sectionHeader(title: "Favorite Tracks", count: favoriteTracks.count)
                    Spacer()
                    if !favoriteTracks.isEmpty {
                        Button {
                            playerManager.play(tracks: favoriteTracks)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "play.fill")
                                    .font(.caption2)
                                Text("Play All")
                                    .font(.jellyAmpCaption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.jellyAmpTextSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white.opacity(0.08))
                            )
                        }
                    }
                }
            }

            if favoriteTracks.isEmpty {
                sectionEmpty("No favorite tracks yet")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(favoriteTracks.enumerated()), id: \.element.id) { index, track in
                        FavoriteTrackRow(track: track) {
                            playerManager.play(tracks: favoriteTracks, startingAt: index)
                        }

                        if index < favoriteTracks.count - 1 {
                            Divider()
                                .background(Color.white.opacity(0.06))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Section Components
    private func sectionHeader(title: String, count: Int) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.jellyAmpHeadline)
                .foregroundColor(Color.jellyAmpText)
            Text("(\(count))")
                .font(.jellyAmpCaption)
                .foregroundColor(.jellyAmpTextMuted)
        }
    }

    private func sectionEmpty(_ text: String) -> some View {
        Text(text)
            .font(.jellyAmpCaption)
            .foregroundColor(.jellyAmpTextMuted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.2))
            Text("No Favorites Yet")
                .font(.jellyAmpTitle)
                .foregroundColor(Color.jellyAmpText)
            Text("Tap the heart on albums, artists, and tracks to add them here.")
                .font(.jellyAmpBody)
                .foregroundColor(.jellyAmpTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    // MARK: - Fetch
    private func fetchFavorites() async {
        isLoading = true
        errorMessage = nil

        do {
            let items = try await jellyfinService.fetchFavorites(includeItemTypes: "Audio,MusicAlbum,MusicArtist")
            let baseURL = jellyfinService.baseURL

            var tracks: [Track] = []
            var albums: [Album] = []
            var artists: [Artist] = []

            for item in items {
                switch item.Type {
                case .Audio:
                    tracks.append(Track(from: item, baseURL: baseURL))
                case .MusicAlbum:
                    albums.append(Album(from: item, baseURL: baseURL))
                case .MusicArtist:
                    artists.append(Artist(from: item, baseURL: baseURL))
                default:
                    break
                }
            }

            await MainActor.run {
                self.favoriteTracks = tracks.sorted { $0.artistName < $1.artistName }
                self.favoriteAlbums = albums.sorted { $0.artistName < $1.artistName }
                self.favoriteArtists = artists.sorted { $0.name < $1.name }
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}

// MARK: - Favorite Track Row
struct FavoriteTrackRow: View {
    let track: Track
    let action: () -> Void
    @ObservedObject var playerManager = PlayerManager.shared

    private var isCurrentlyPlaying: Bool {
        playerManager.currentTrack?.id == track.id
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Artwork
                if let artworkURL = track.artworkURL, let url = URL(string: artworkURL) {
                    CachedAsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().aspectRatio(contentMode: .fill)
                        default:
                            Rectangle().fill(Color.jellyAmpMidBackground)
                                .overlay(Image(systemName: "music.note").font(.caption).foregroundColor(.white.opacity(0.3)))
                        }
                    }
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                }

                // Now playing indicator
                if isCurrentlyPlaying {
                    Image(systemName: "waveform")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.neonCyan)
                        .symbolEffect(.variableColor.iterative, isActive: playerManager.isPlaying)
                        .frame(width: 16)
                }

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(track.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(isCurrentlyPlaying ? .neonCyan : .white.opacity(0.7))
                        .lineLimit(1)
                    Text(track.artistName)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.35))
                        .lineLimit(1)
                }

                Spacer()

                Text(track.durationFormatted)
                    .font(.jellyAmpMono)
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button { playerManager.playNext(track: track) } label: {
                Label("Play Next", systemImage: "text.line.first.and.arrowtriangle.forward")
            }
            Button { playerManager.playLast(track: track) } label: {
                Label("Play Last", systemImage: "text.line.last.and.arrowtriangle.forward")
            }
            Button { playerManager.addToQueue(track: track) } label: {
                Label("Add to Queue", systemImage: "text.append")
            }
        }
    }
}

#Preview {
    FavoritesView()
}
