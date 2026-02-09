//
//  AlbumDetailView.swift
//  JellyAmp
//
//  Album detail page with track listing - iOS 26 Liquid Glass + Cypherpunk
//

import SwiftUI

struct AlbumDetailView: View {
    let album: Album
    @ObservedObject var jellyfinService = JellyfinService.shared
    @ObservedObject var playerManager = PlayerManager.shared
    @ObservedObject var downloadManager = DownloadManager.shared
    @ObservedObject var themeManager = ThemeManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var isFavorite: Bool
    @State private var albumTracks: [Track] = []
    @State private var isLoadingTracks = true
    @State private var showNowPlaying = false
    @State private var showAddToPlaylist = false
    @State private var selectedTrackIds: [String] = []

    init(album: Album) {
        self.album = album
        _isFavorite = State(initialValue: album.isFavorite)
    }

    // Calculate download state for album
    private var albumDownloadState: DownloadState {
        guard !albumTracks.isEmpty else { return .notDownloaded }

        let downloadedCount = albumTracks.filter { downloadManager.isDownloaded(trackId: $0.id) }.count
        let totalCount = albumTracks.count

        if downloadedCount == totalCount {
            return .downloaded
        } else if downloadedCount > 0 {
            let progress = Double(downloadedCount) / Double(totalCount)
            return .downloading(progress: progress)
        } else {
            // Check if any are actively downloading
            for track in albumTracks {
                if case .downloading = downloadManager.downloadStates[track.id] {
                    return .downloading(progress: 0)
                }
            }
            return .notDownloaded
        }
    }

    var totalDuration: String {
        let total = albumTracks.reduce(0) { $0 + $1.duration }
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
                        // Album Hero Section
                        albumHeroSection

                        // Action Buttons
                        actionButtonsSection

                        // Album Info
                        albumInfoSection

                        // Track Listing
                        trackListingSection

                        // Bottom padding for mini player
                        Color.clear.frame(height: 100)
                    }
                }

                // Navigation handled by NavigationStack
            }

            // Mini Player (fixed at bottom)
            if playerManager.currentTrack != nil {
                MiniPlayerView(showNowPlaying: $showNowPlaying)
            }
        }
        .ignoresSafeArea(.keyboard)
        .onAppear {
            Task {
                await fetchAlbumTracks()
            }
        }
        .sheet(isPresented: $showNowPlaying) {
            NowPlayingView()
        }
        .sheet(isPresented: $showAddToPlaylist) {
            PlaylistSelectionSheet(trackIds: selectedTrackIds) {
                // Tracks added successfully
                selectedTrackIds = []
            }
        }
    }

    // MARK: - Fetch Album Tracks
    private func fetchAlbumTracks() async {
        isLoadingTracks = true

        do {
            let tracks = try await jellyfinService.getAlbumTracks(albumId: album.id)
            let baseURL = jellyfinService.baseURL

            // Map and sort tracks by disc number then track number
            let mappedTracks = tracks.map { Track(from: $0, baseURL: baseURL) }
            self.albumTracks = mappedTracks.sorted { track1, track2 in
                // Sort by disc number first (ParentIndexNumber)
                let disc1 = track1.parentIndexNumber ?? 0
                let disc2 = track2.parentIndexNumber ?? 0

                if disc1 != disc2 {
                    return disc1 < disc2
                }

                // Then by track number (IndexNumber)
                let index1 = track1.indexNumber ?? 0
                let index2 = track2.indexNumber ?? 0
                return index1 < index2
            }

            isLoadingTracks = false
        } catch {
            print("Error fetching album tracks: \(error)")
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
                    try await jellyfinService.markFavorite(itemId: album.id)
                } else {
                    try await jellyfinService.unmarkFavorite(itemId: album.id)
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

    // MARK: - Download Management
    private func toggleDownload() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if albumDownloadState.isDownloaded {
                // Delete all downloaded tracks
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.warning)

                for track in albumTracks {
                    downloadManager.deleteDownload(trackId: track.id)
                }
            } else {
                // Download all tracks
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()

                downloadManager.downloadAlbum(tracks: albumTracks)
            }
        }
    }

    private var downloadIconName: String {
        switch albumDownloadState {
        case .notDownloaded:
            return "arrow.down.circle"
        case .downloading:
            return "arrow.down.circle.fill"
        case .downloaded:
            return "checkmark.circle.fill"
        case .failed:
            return "exclamationmark.circle"
        }
    }

    private var downloadIconColor: Color {
        switch albumDownloadState {
        case .notDownloaded:
            return Color.jellyAmpText
        case .downloading:
            return .jellyAmpAccent
        case .downloaded:
            return .jellyAmpSuccess
        case .failed:
            return .red
        }
    }

    // MARK: - Album Hero Section
    private var albumHeroSection: some View {
        VStack(spacing: 0) {
            // Album Artwork
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [
                        Color.jellyAmpAccent.opacity(0.6),
                        Color.jellyAmpSecondary.opacity(0.6),
                        Color.jellyAmpTertiary.opacity(0.7)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(maxWidth: .infinity, maxHeight: 380)

                // Album artwork
                if let artworkURL = album.artworkURL, let url = URL(string: artworkURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            placeholderArtwork
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 260, height: 260)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color.jellyAmpAccent.opacity(0.8),
                                                    Color.jellyAmpSecondary.opacity(0.8)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 2
                                        )
                                )
                                .neonGlow(color: .jellyAmpSecondary, radius: 20)
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
            .frame(height: 380)
            .clipped()
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

            // Album Title & Artist
            VStack(spacing: 8) {
                Text(album.name)
                    .font(.title2.weight(.bold))
                    .foregroundColor(Color.jellyAmpText)
                    .neonGlow(color: .jellyAmpAccent, radius: 10)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                Text(album.artistName)
                    .font(.jellyAmpHeadline)
                    .foregroundColor(.neonPink)
                    .neonGlow(color: .jellyAmpSecondary, radius: 6)
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
                        Color.jellyAmpSecondary.opacity(0.5),
                        Color.jellyAmpTertiary.opacity(0.5)
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
                                Color.jellyAmpAccent.opacity(0.8),
                                Color.jellyAmpSecondary.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
            .neonGlow(color: .jellyAmpSecondary, radius: 20)
            .overlay(
                Image(systemName: "music.note")
                    .font(.title)
                    .foregroundColor(.white.opacity(0.3))
            )
    }

    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        HStack(spacing: 12) {
            // Play All Button
            Button {
                guard !albumTracks.isEmpty else { return }
                playerManager.play(tracks: albumTracks, startingAt: 0)
                showNowPlaying = true
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
                        .fill(albumTracks.isEmpty ? Color.gray : Color.jellyAmpAccent)
                )
                .neonGlow(color: albumTracks.isEmpty ? .clear : .neonCyan, radius: 12)
            }
            .disabled(albumTracks.isEmpty)

            // Shuffle Button
            Button {
                guard !albumTracks.isEmpty else { return }
                playerManager.shuffleEnabled = true
                playerManager.play(tracks: albumTracks, startingAt: 0)
                showNowPlaying = true
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
                                    .stroke(Color.jellyAmpTertiary.opacity(0.5), lineWidth: 1)
                            )
                    )
                    .neonGlow(color: .jellyAmpTertiary, radius: 8)
            }
            .disabled(albumTracks.isEmpty)

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
                                    .stroke(Color.jellyAmpSecondary.opacity(isFavorite ? 0.8 : 0.5), lineWidth: 1)
                            )
                    )
                    .neonGlow(color: .jellyAmpSecondary, radius: isFavorite ? 12 : 8)
            }

            // Download Button
            Button {
                toggleDownload()
            } label: {
                ZStack {
                    // Background
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(downloadIconColor.opacity(0.5), lineWidth: 1)
                        )
                        .frame(width: 56, height: 56)

                    // Icon or Progress
                    if case .downloading(let progress) = albumDownloadState {
                        // Show progress ring
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 3)

                            Circle()
                                .trim(from: 0, to: progress)
                                .stroke(downloadIconColor, lineWidth: 3)
                                .rotationEffect(.degrees(-90))

                            Text("\(Int(progress * 100))%")
                                .font(.system(.caption2, design: .monospaced).weight(.bold))
                                .foregroundColor(downloadIconColor)
                        }
                        .frame(width: 36, height: 36)
                    } else {
                        Image(systemName: downloadIconName)
                            .font(.title3.weight(.semibold))
                            .foregroundColor(downloadIconColor)
                    }
                }
                .neonGlow(color: downloadIconColor, radius: albumDownloadState.isDownloaded ? 12 : 8)
            }
            .disabled(albumTracks.isEmpty)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
    }

    // MARK: - Album Info Section
    private var albumInfoSection: some View {
        HStack(spacing: 30) {
            if let year = album.year {
                InfoBadge(icon: "calendar", value: String(year))
            }

            InfoBadge(icon: "music.note.list", value: "\(albumTracks.count) tracks")

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
                        .tint(.jellyAmpAccent)
                    Text("Loading tracks...")
                        .font(.jellyAmpCaption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 12)
                    Spacer()
                }
                .padding(.vertical, 40)
            } else if albumTracks.isEmpty {
                HStack {
                    Spacer()
                    Text("No tracks found")
                        .font(.jellyAmpBody)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.vertical, 40)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(albumTracks.enumerated()), id: \.element.id) { index, track in
                        AlbumTrackRow(track: track, trackNumber: index + 1) {
                            // Play from this track
                            playerManager.play(tracks: albumTracks, startingAt: index)
                            showNowPlaying = true
                        } onAddToPlaylist: {
                            // Add track to playlist
                            selectedTrackIds = [track.id]
                            showAddToPlaylist = true
                        }
                        .padding(.horizontal, 20)

                        if index < albumTracks.count - 1 {
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
                                .stroke(Color.jellyAmpAccent.opacity(0.2), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)
            }
        }
        .padding(.bottom, 30)
    }
}

// MARK: - Info Badge Component
struct InfoBadge: View {
    let icon: String
    let value: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.neonCyan)

            Text(value)
                .font(.system(.caption, design: .monospaced).weight(.medium))
                .foregroundColor(Color.jellyAmpText)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.1))
        )
        .overlay(
            Capsule()
                .stroke(Color.jellyAmpAccent.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Album Track Row Component
struct AlbumTrackRow: View {
    let track: Track
    let trackNumber: Int
    let action: () -> Void
    var onAddToPlaylist: (() -> Void)? = nil
    @State private var isPressed = false
    @ObservedObject var downloadManager = DownloadManager.shared

    var body: some View {
        Button {
            isPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
                action()
            }
        } label: {
            HStack(spacing: 16) {
                // Track number
                Text("\(trackNumber)")
                    .font(.system(.body, design: .monospaced).weight(.bold))
                    .foregroundColor(.neonCyan)
                    .frame(width: 28, alignment: .trailing)

                // Track info
                VStack(alignment: .leading, spacing: 4) {
                    Text(track.name)
                        .font(.jellyAmpBody)
                        .foregroundColor(Color.jellyAmpText)
                        .lineLimit(1)

                    Text(track.durationFormatted)
                        .font(.jellyAmpCaption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Play button
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(.neonCyan)
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
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
    AlbumDetailView(album: Album.mockAlbums[0])
}
