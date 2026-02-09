//
//  PlaylistDetailView.swift
//  JellyAmp
//
//  Playlist detail page with track listing and management
//

import SwiftUI

struct PlaylistDetailView: View {
    let playlist: Playlist
    @ObservedObject var jellyfinService = JellyfinService.shared
    @ObservedObject var playerManager = PlayerManager.shared
    @ObservedObject var themeManager = ThemeManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var isFavorite: Bool
    @State private var playlistTracks: [Track] = []
    @State private var isLoadingTracks = true
    @State private var showAddToPlaylist = false
    @State private var selectedTrackIds: [String] = []

    init(playlist: Playlist) {
        self.playlist = playlist
        _isFavorite = State(initialValue: playlist.isFavorite)
    }

    var totalDuration: String {
        let total = playlistTracks.reduce(0) { $0 + $1.duration }
        let minutes = Int(total) / 60
        return "\(minutes) min"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main Content
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

                ScrollView {
                    VStack(spacing: 0) {
                        // Playlist Hero Section
                        playlistHeroSection

                        // Action Buttons
                        actionButtonsSection

                        // Playlist Info
                        playlistInfoSection

                        // Track Listing
                        trackListingSection

                        // Bottom padding for mini player
                        Color.clear.frame(height: 100)
                    }
                }

                // Navigation handled by NavigationStack
            }

        }
        .ignoresSafeArea(.keyboard)
        .onAppear {
            Task {
                await fetchPlaylistTracks()
            }
        }
        .sheet(isPresented: $showAddToPlaylist) {
            PlaylistSelectionSheet(trackIds: selectedTrackIds) {
                // Tracks added successfully
                selectedTrackIds = []
            }
        }
    }

    // MARK: - Fetch Playlist Tracks
    private func fetchPlaylistTracks() async {
        isLoadingTracks = true

        do {
            let tracks = try await jellyfinService.fetchTracks(parentId: playlist.id)
            let baseURL = jellyfinService.baseURL

            // Map and sort tracks by index number to preserve playlist order
            let mappedTracks = tracks.map { Track(from: $0, baseURL: baseURL) }
            self.playlistTracks = mappedTracks.sorted { track1, track2 in
                let index1 = track1.indexNumber ?? 0
                let index2 = track2.indexNumber ?? 0
                return index1 < index2
            }

            isLoadingTracks = false
        } catch {
            print("Error fetching playlist tracks: \(error)")
            isLoadingTracks = false
        }
    }

    // MARK: - Toggle Favorite
    private func toggleFavorite() {
        // Optimistic UI update
        withAnimation(.spring(response: 0.3)) {
            isFavorite.toggle()
        }

        // Call API in background
        Task {
            do {
                if isFavorite {
                    try await jellyfinService.markFavorite(itemId: playlist.id)
                } else {
                    try await jellyfinService.unmarkFavorite(itemId: playlist.id)
                }
            } catch {
                // Revert on failure
                await MainActor.run {
                    withAnimation(.spring(response: 0.3)) {
                        isFavorite.toggle()
                    }
                }
                print("Error toggling favorite: \(error)")
            }
        }
    }

    // MARK: - Playlist Hero Section
    private var playlistHeroSection: some View {
        VStack(spacing: 0) {
            // Playlist Artwork
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [
                        Color.neonPink.opacity(0.6),
                        Color.jellyAmpSecondary.opacity(0.6),
                        Color.neonPurple.opacity(0.7)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 380)

                // Playlist artwork
                if let artworkURL = playlist.artworkURL, let url = URL(string: artworkURL) {
                    CachedAsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            placeholderArtwork
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 260, height: 260)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color.neonPink.opacity(0.8),
                                                    Color.jellyAmpSecondary.opacity(0.8)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 2
                                        )
                                )
                                .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                        case .failure:
                            placeholderArtwork
                        @unknown default:
                            placeholderArtwork
                        }
                    }
                    .frame(width: 260, height: 260)
                } else {
                    placeholderArtwork
                }
            }
            .overlay(
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.jellyAmpBackground.opacity(0.9)
                    ],
                    startPoint: .center,
                    endPoint: .bottom
                )
            )

            // Playlist Title
            VStack(spacing: 8) {
                Text(playlist.name)
                    .font(.title2.weight(.bold))
                    .foregroundColor(Color.jellyAmpText)
                    .neonGlow(color: .neonPink, radius: 4)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                Text("Playlist")
                    .font(.jellyAmpHeadline)
                    .foregroundColor(.neonPink)
                    .neonGlow(color: .neonPink, radius: 6)
            }
            .padding(.top, -40)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Placeholder Artwork
    private var placeholderArtwork: some View {
        RoundedRectangle(cornerRadius: 20)
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
            .frame(width: 260, height: 260)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.neonPink.opacity(0.8),
                                Color.jellyAmpSecondary.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
            .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
            .overlay(
                Image(systemName: "music.note.list")
                    .font(.title)
                    .foregroundColor(.white.opacity(0.3))
            )
    }

    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        HStack(spacing: 12) {
            // Play All Button
            Button {
                guard !playlistTracks.isEmpty else { return }
                playerManager.play(tracks: playlistTracks, startingAt: 0)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                        .font(.title3)
                    Text("Play All")
                        .font(.jellyAmpBody)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(playlistTracks.isEmpty ? Color.gray : Color.neonPink)
                )
                .neonGlow(color: playlistTracks.isEmpty ? .clear : .neonPink, radius: 6)
            }
            .disabled(playlistTracks.isEmpty)

            // Shuffle Button
            Button {
                guard !playlistTracks.isEmpty else { return }
                playerManager.shuffleEnabled = true
                playerManager.play(tracks: playlistTracks, startingAt: 0)
            } label: {
                Image(systemName: "shuffle")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(Color.jellyAmpText)
                    .frame(width: 56, height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.neonPurple.opacity(0.5), lineWidth: 1)
                            )
                    )
                    .neonGlow(color: .neonPurple, radius: 8)
            }
            .disabled(playlistTracks.isEmpty)

            // Favorite Button
            Button {
                toggleFavorite()
            } label: {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(isFavorite ? .neonPink : .white)
                    .frame(width: 56, height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.neonPink.opacity(isFavorite ? 0.8 : 0.5), lineWidth: 1)
                            )
                    )
                    .neonGlow(color: .neonPink, radius: isFavorite ? 6 : 4)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
    }

    // MARK: - Playlist Info Section
    private var playlistInfoSection: some View {
        HStack(spacing: 30) {
            if let dateCreated = playlist.dateCreated {
                InfoBadge(icon: "calendar", value: dateCreated.formatted(date: .abbreviated, time: .omitted))
            }

            InfoBadge(icon: "music.note.list", value: "\(playlistTracks.count) tracks")

            InfoBadge(icon: "clock", value: totalDuration)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 30)
    }

    // MARK: - Track Listing Section
    private var trackListingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tracks")
                .font(.jellyAmpHeadline)
                .foregroundColor(Color.jellyAmpText)
                .padding(.horizontal, 20)

            if isLoadingTracks {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(.neonPink)
                    Text("Loading tracks...")
                        .font(.jellyAmpCaption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 12)
                    Spacer()
                }
                .padding(.vertical, 40)
            } else if playlistTracks.isEmpty {
                ContentUnavailableView {
                    Label("Empty Playlist", systemImage: "music.note.list")
                } description: {
                    Text("No tracks in playlist")
                }
                .padding(.vertical, 40)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(playlistTracks.enumerated()), id: \.element.id) { index, track in
                        PlaylistTrackRow(track: track, trackNumber: index + 1) {
                            // Play from this track
                            playerManager.play(tracks: playlistTracks, startingAt: index)
                        } onAddToPlaylist: {
                            // Add track to another playlist
                            selectedTrackIds = [track.id]
                            showAddToPlaylist = true
                        }
                        .padding(.horizontal, 20)

                        if index < playlistTracks.count - 1 {
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
                                .stroke(Color.neonPink.opacity(0.2), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)
            }
        }
        .padding(.bottom, 30)
    }
}

// MARK: - Playlist Track Row Component
struct PlaylistTrackRow: View {
    let track: Track
    let trackNumber: Int
    let action: () -> Void
    var onAddToPlaylist: (() -> Void)? = nil
    @ObservedObject var downloadManager = DownloadManager.shared
    @ObservedObject var playerManager = PlayerManager.shared

    private var isCurrentlyPlaying: Bool {
        playerManager.currentTrack?.id == track.id
    }

    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 16) {
                // Track number or waveform indicator
                if isCurrentlyPlaying {
                    Image(systemName: "waveform")
                        .font(.body.weight(.bold))
                        .foregroundColor(.jellyAmpAccent)
                        .symbolEffect(.variableColor.iterative, isActive: playerManager.isPlaying)
                        .frame(width: 28, alignment: .trailing)
                } else {
                    Text("\(trackNumber)")
                        .font(.system(.body, design: .monospaced).weight(.bold))
                        .foregroundColor(.neonPink)
                        .frame(width: 28, alignment: .trailing)
                }

                // Track info
                VStack(alignment: .leading, spacing: 4) {
                    Text(track.name)
                        .font(.jellyAmpBody)
                        .foregroundColor(isCurrentlyPlaying ? .jellyAmpAccent : Color.jellyAmpText)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        Text(track.artistName)
                            .font(.jellyAmpCaption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)

                        Text("•")
                            .foregroundColor(.secondary)

                        Text(track.durationFormatted)
                            .font(.jellyAmpCaption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Play button
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(.neonPink)
            }
            .padding(.vertical, 12)
            .background(
                isCurrentlyPlaying ?
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.jellyAmpAccent.opacity(0.08))
                        .padding(.horizontal, -8)
                    : nil
            )
            .contentShape(Rectangle())
        }
        .contextMenu {
            // Download/Delete option
            if downloadManager.isDownloaded(trackId: track.id) {
                Button(role: .destructive) {
                    downloadManager.deleteDownload(trackId: track.id)
                } label: {
                    Label("Delete Download", systemImage: "trash")
                }
            } else {
                Button {
                    downloadManager.downloadTrack(track)
                } label: {
                    Label("Download", systemImage: "arrow.down.circle")
                }
            }

            // Add to Playlist option
            if let onAddToPlaylist = onAddToPlaylist {
                Button {
                    onAddToPlaylist()
                } label: {
                    Label("Add to Playlist", systemImage: "plus.circle")
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    PlaylistDetailView(playlist: Playlist(id: "1", name: "My Playlist", trackCount: 10, artworkURL: nil, dateCreated: Date(), isFavorite: false))
}
