//
//  FavoritesView.swift
//  JellyAmp
//
//  Dedicated Favorites tab showing favorite tracks, albums, and artists
//

import SwiftUI

struct FavoritesView: View {
    @ObservedObject var jellyfinService = JellyfinService.shared
    @ObservedObject var playerManager = PlayerManager.shared
    @ObservedObject var themeManager = ThemeManager.shared

    @State private var favoriteTracks: [Track] = []
    @State private var favoriteAlbums: [Album] = []
    @State private var favoriteArtists: [Artist] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    // Navigation handled by NavigationStack
    @State private var showNowPlaying = false

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

            if isLoading {
                // Loading state
                VStack(spacing: 16) {
                    ProgressView()
                        .tint(.neonPink)
                        .scaleEffect(1.5)
                    Text("Loading favorites...")
                        .font(.jellyAmpBody)
                        .foregroundColor(.secondary)
                }
            } else if let error = errorMessage {
                // Error state
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title)
                        .foregroundColor(.neonPink)
                    Text("Error Loading Favorites")
                        .font(.jellyAmpHeadline)
                        .foregroundColor(Color.jellyAmpText)
                    Text(error)
                        .font(.jellyAmpBody)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    Button("Try Again") {
                        Task {
                            await fetchFavorites()
                        }
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(Color.jellyAmpSecondary)
                    )
                    .neonGlow(color: .jellyAmpSecondary, radius: 8)
                    .accessibilityLabel("Retry loading favorites")
                }
            } else if favoriteTracks.isEmpty && favoriteAlbums.isEmpty && favoriteArtists.isEmpty {
                // Empty state
                emptyStateView
            } else {
                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        // Header
                        headerSection

                        // Favorite Tracks
                        if !favoriteTracks.isEmpty {
                            favoriteTracksSection
                        }

                        // Favorite Albums
                        if !favoriteAlbums.isEmpty {
                            favoriteAlbumsSection
                        }

                        // Favorite Artists
                        if !favoriteArtists.isEmpty {
                            favoriteArtistsSection
                        }

                        // Bottom padding for mini player
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
        .sheet(isPresented: $showNowPlaying) {
            NowPlayingView()
        }
        .onAppear {
            if favoriteTracks.isEmpty && favoriteAlbums.isEmpty && favoriteArtists.isEmpty {
                Task {
                    await fetchFavorites()
                }
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Favorites")
                    .font(.title.weight(.bold))
                    .foregroundColor(Color.jellyAmpText)
                    .neonGlow(color: .jellyAmpSecondary, radius: 12)

                let totalCount = favoriteTracks.count + favoriteAlbums.count + favoriteArtists.count
                if totalCount > 0 {
                    Text("\(totalCount) favorite\(totalCount == 1 ? "" : "s")")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.leading, 20)

            Spacer()
        }
        .padding(.top, 60)
        .padding(.bottom, 10)
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "heart.slash")
                .font(.title)
                .foregroundColor(.neonPink.opacity(0.5))
                .neonGlow(color: .jellyAmpSecondary, radius: 20)

            Text("No Favorites Yet")
                .font(.title2.weight(.bold))
                .foregroundColor(Color.jellyAmpText)

            Text("Tap the heart icon on tracks, albums, and artists to add them to your favorites")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 50)
        }
    }

    // MARK: - Favorite Tracks Section
    private var favoriteTracksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Favorite Tracks")
                    .font(.title3.weight(.bold))
                    .foregroundColor(Color.jellyAmpText)

                Text("\(favoriteTracks.count)")
                    .font(.system(.body, design: .monospaced).weight(.bold))
                    .foregroundColor(.neonPink)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.jellyAmpSecondary.opacity(0.2))
                    )

                Spacer()

                // Play All button
                Button {
                    playerManager.play(tracks: favoriteTracks)
                    showNowPlaying = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "play.fill")
                            .font(.subheadline)
                        Text("Play All")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.jellyAmpSecondary)
                    )
                    .neonGlow(color: .jellyAmpSecondary, radius: 6)
                }
            }
            .padding(.horizontal, 20)

            VStack(spacing: 0) {
                ForEach(Array(favoriteTracks.prefix(10).enumerated()), id: \.element.id) { index, track in
                    FavoriteTrackRow(track: track) {
                        playerManager.play(tracks: favoriteTracks, startingAt: index)
                        showNowPlaying = true
                    }
                    .padding(.horizontal, 20)

                    if index < min(9, favoriteTracks.count - 1) {
                        Divider()
                            .background(Color.white.opacity(0.1))
                            .padding(.horizontal, 20)
                    }
                }
            }
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.jellyAmpSecondary.opacity(0.2), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 20)

            if favoriteTracks.count > 10 {
                Text("Showing 10 of \(favoriteTracks.count) tracks")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Favorite Albums Section
    private var favoriteAlbumsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Favorite Albums")
                    .font(.title3.weight(.bold))
                    .foregroundColor(Color.jellyAmpText)

                Text("\(favoriteAlbums.count)")
                    .font(.system(.body, design: .monospaced).weight(.bold))
                    .foregroundColor(.neonCyan)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.jellyAmpAccent.opacity(0.2))
                    )
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(favoriteAlbums.prefix(10)) { album in
                        NavigationLink(value: album) {
                            FavoriteAlbumCard(album: album) {
                                // Action now handled by NavigationLink
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Favorite Artists Section
    private var favoriteArtistsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Favorite Artists")
                    .font(.title3.weight(.bold))
                    .foregroundColor(Color.jellyAmpText)

                Text("\(favoriteArtists.count)")
                    .font(.system(.body, design: .monospaced).weight(.bold))
                    .foregroundColor(.neonPurple)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.jellyAmpTertiary.opacity(0.2))
                    )
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(favoriteArtists.prefix(10)) { artist in
                        NavigationLink(value: artist) {
                            FavoriteArtistCard(artist: artist) {
                                // Action now handled by NavigationLink
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Fetch Favorites
    private func fetchFavorites() async {
        isLoading = true
        errorMessage = nil

        do {
            // Fetch all favorites from Jellyfin
            let items = try await jellyfinService.fetchFavorites(includeItemTypes: "Audio,MusicAlbum,MusicArtist")
            let baseURL = jellyfinService.baseURL

            // Separate into tracks, albums, and artists
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
                self.favoriteTracks = tracks
                self.favoriteAlbums = albums
                self.favoriteArtists = artists
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

// MARK: - Favorite Track Row Component
struct FavoriteTrackRow: View {
    let track: Track
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
            HStack(spacing: 12) {
                // Album artwork
                if let artworkURL = track.artworkURL, let url = URL(string: artworkURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 50, height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        default:
                            placeholderArtwork
                        }
                    }
                    .frame(width: 50, height: 50)
                } else {
                    placeholderArtwork
                }

                // Track info
                VStack(alignment: .leading, spacing: 4) {
                    Text(track.name)
                        .font(.body.weight(.semibold))
                        .foregroundColor(Color.jellyAmpText)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Text(track.artistName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("•")
                            .foregroundColor(.secondary.opacity(0.5))
                        Text(track.albumName)
                            .font(.subheadline)
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                    .lineLimit(1)
                }

                Spacer()

                // Duration and play button
                HStack(spacing: 12) {
                    Text(track.durationFormatted)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary.opacity(0.7))

                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                        .foregroundColor(.neonPink)
                }
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
        }
    }

    private var placeholderArtwork: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [Color.jellyAmpSecondary.opacity(0.3), Color.jellyAmpTertiary.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 50, height: 50)

            Image(systemName: "music.note")
                .font(.title3)
                .foregroundColor(.white.opacity(0.6))
        }
    }
}

// MARK: - Favorite Album Card Component
struct FavoriteAlbumCard: View {
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
            VStack(alignment: .leading, spacing: 8) {
                // Album artwork
                if let artworkURL = album.artworkURL, let url = URL(string: artworkURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 140, height: 140)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.jellyAmpAccent.opacity(0.4), lineWidth: 1.5)
                                )
                        default:
                            placeholderArtwork
                        }
                    }
                    .frame(width: 140, height: 140)
                } else {
                    placeholderArtwork
                }

                // Album info
                VStack(alignment: .leading, spacing: 2) {
                    Text(album.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color.jellyAmpText)
                        .lineLimit(1)

                    Text(album.artistName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .frame(width: 140)
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
    }

    private var placeholderArtwork: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [Color.jellyAmpAccent.opacity(0.4), Color.jellyAmpTertiary.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 140, height: 140)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.jellyAmpAccent.opacity(0.4), lineWidth: 1.5)
                )

            Image(systemName: "music.note")
                .font(.title)
                .foregroundColor(.white.opacity(0.4))
        }
    }
}

// MARK: - Favorite Artist Card Component
struct FavoriteArtistCard: View {
    let artist: Artist
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
            VStack(spacing: 8) {
                // Artist artwork (circular)
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.jellyAmpTertiary.opacity(0.5), Color.jellyAmpSecondary.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .overlay(
                            Circle()
                                .stroke(Color.jellyAmpTertiary.opacity(0.5), lineWidth: 2)
                        )

                    Image(systemName: "person.circle.fill")
                        .font(.title)
                        .foregroundColor(.white.opacity(0.4))
                }

                // Artist name
                Text(artist.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color.jellyAmpText)
                    .lineLimit(1)
                    .frame(width: 120)
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
    }
}

// MARK: - Preview
#Preview {
    FavoritesView()
}
