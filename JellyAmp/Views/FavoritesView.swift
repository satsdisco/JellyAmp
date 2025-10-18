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

    @State private var favoriteTracks: [Track] = []
    @State private var favoriteAlbums: [Album] = []
    @State private var favoriteArtists: [Artist] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedAlbum: Album?
    @State private var selectedArtist: Artist?
    @State private var showNowPlaying = false

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
                        .font(.system(size: 50))
                        .foregroundColor(.neonPink)
                    Text("Error Loading Favorites")
                        .font(.jellyAmpHeadline)
                        .foregroundColor(.white)
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
                            .fill(Color.neonPink)
                    )
                    .neonGlow(color: .neonPink, radius: 8)
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
        .sheet(item: $selectedAlbum) { album in
            AlbumDetailView(album: album)
        }
        .sheet(item: $selectedArtist) { artist in
            ArtistDetailView(artist: artist)
        }
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
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .neonGlow(color: .neonPink, radius: 12)

                let totalCount = favoriteTracks.count + favoriteAlbums.count + favoriteArtists.count
                if totalCount > 0 {
                    Text("\(totalCount) favorite\(totalCount == 1 ? "" : "s")")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
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
                .font(.system(size: 70))
                .foregroundColor(.neonPink.opacity(0.5))
                .neonGlow(color: .neonPink, radius: 20)

            Text("No Favorites Yet")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("Tap the heart icon on tracks, albums, and artists to add them to your favorites")
                .font(.system(size: 16))
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
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("\(favoriteTracks.count)")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.neonPink)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.neonPink.opacity(0.2))
                    )

                Spacer()

                // Play All button
                Button {
                    playerManager.play(tracks: favoriteTracks)
                    showNowPlaying = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 14))
                        Text("Play All")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.neonPink)
                    )
                    .neonGlow(color: .neonPink, radius: 6)
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
                    .glassEffect(.regular)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.neonPink.opacity(0.2), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 20)

            if favoriteTracks.count > 10 {
                Text("Showing 10 of \(favoriteTracks.count) tracks")
                    .font(.system(size: 13))
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
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("\(favoriteAlbums.count)")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.neonCyan)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.neonCyan.opacity(0.2))
                    )
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(favoriteAlbums.prefix(10)) { album in
                        FavoriteAlbumCard(album: album) {
                            selectedAlbum = album
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
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("\(favoriteArtists.count)")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.neonPurple)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.neonPurple.opacity(0.2))
                    )
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(favoriteArtists.prefix(10)) { artist in
                        FavoriteArtistCard(artist: artist) {
                            selectedArtist = artist
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
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Text(track.artistName)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        Text("•")
                            .foregroundColor(.secondary.opacity(0.5))
                        Text(track.albumName)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                    .lineLimit(1)
                }

                Spacer()

                // Duration and play button
                HStack(spacing: 12) {
                    Text(track.durationFormatted)
                        .font(.system(size: 13, design: .monospaced))
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
                        colors: [Color.neonPink.opacity(0.3), Color.neonPurple.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 50, height: 50)

            Image(systemName: "music.note")
                .font(.system(size: 20))
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
                                        .stroke(Color.neonCyan.opacity(0.4), lineWidth: 1.5)
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
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text(album.artistName)
                        .font(.system(size: 12))
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
                        colors: [Color.neonCyan.opacity(0.4), Color.neonPurple.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 140, height: 140)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.neonCyan.opacity(0.4), lineWidth: 1.5)
                )

            Image(systemName: "music.note")
                .font(.system(size: 40))
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
                                colors: [Color.neonPurple.opacity(0.5), Color.neonPink.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .overlay(
                            Circle()
                                .stroke(Color.neonPurple.opacity(0.5), lineWidth: 2)
                        )

                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white.opacity(0.4))
                }

                // Artist name
                Text(artist.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
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
