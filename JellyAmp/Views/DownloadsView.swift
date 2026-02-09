//
//  DownloadsView.swift
//  JellyAmp
//
//  Displays downloaded tracks for offline playback with storage management
//

import SwiftUI

struct DownloadsView: View {
    @ObservedObject var downloadManager = DownloadManager.shared
    @ObservedObject var playerManager = PlayerManager.shared
    @ObservedObject var themeManager = ThemeManager.shared
    @State private var showDeleteAllConfirmation = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.jellyAmpBackground.ignoresSafeArea()

                if downloadManager.downloadedTracks.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Storage Usage Card
                            storageUsageCard

                            // Downloaded Albums List
                            downloadedAlbumsList

                            // Delete All Button
                            deleteAllButton

                            // Bottom padding
                            Color.clear.frame(height: 100)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Downloads")
            .navigationBarTitleDisplayMode(.large)
            .confirmationDialog("Delete All Downloads", isPresented: $showDeleteAllConfirmation) {
                Button("Delete All", role: .destructive) {
                    downloadManager.deleteAllDownloads()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete all \(downloadManager.downloadedTracks.count) tracks from \(downloadManager.downloadedAlbumCount) albums? This will free up \(downloadManager.formatBytes(downloadManager.totalStorageUsed)).")
            }
        }
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "arrow.down.circle")
                .font(.title)
                .foregroundColor(.jellyAmpAccent)
                .neonGlow(color: .jellyAmpAccent, radius: 20)

            Text("No Downloads")
                .font(.jellyAmpTitle)
                .foregroundColor(Color.jellyAmpText)

            Text("Download albums or tracks for offline playback.\nTap the download button on any album.")
                .font(.jellyAmpBody)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    // MARK: - Storage Usage Card
    private var storageUsageCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "internaldrive")
                    .font(.title2)
                    .foregroundColor(.jellyAmpAccent)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Storage Used")
                        .font(.jellyAmpCaption)
                        .foregroundColor(.secondary)

                    Text(downloadManager.formatBytes(downloadManager.totalStorageUsed))
                        .font(.title2.weight(.bold))
                        .foregroundColor(Color.jellyAmpText)
                        .neonGlow(color: .jellyAmpAccent, radius: 8)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Albums")
                        .font(.jellyAmpCaption)
                        .foregroundColor(.secondary)

                    Text("\(downloadManager.downloadedAlbumCount)")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.jellyAmpSecondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.jellyAmpMidBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.jellyAmpAccent.opacity(0.5), Color.jellyAmpSecondary.opacity(0.5)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
        }
    }

    // MARK: - Downloaded Albums List
    private var downloadedAlbumsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Downloaded Albums")
                    .font(.jellyAmpHeadline)
                    .foregroundColor(.jellyAmpAccent)

                Spacer()

                Text("\(downloadManager.downloadedTracks.count) tracks")
                    .font(.jellyAmpCaption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 4)

            VStack(spacing: 12) {
                ForEach(downloadManager.downloadedAlbums) { album in
                    NavigationLink(destination: DownloadedAlbumDetailView(album: album)) {
                        DownloadedAlbumRow(album: album)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Playback Actions
    private func playTrack(_ downloadedTrack: DownloadedTrack) {
        let track = downloadedTrack.toTrack()
        playerManager.play(tracks: [track], startingAt: 0)
    }

    private func playAllDownloads() {
        let tracks = downloadManager.downloadedTracks.map { $0.toTrack() }
        guard !tracks.isEmpty else { return }
        playerManager.play(tracks: tracks, startingAt: 0)
    }

    // MARK: - Delete All Button
    private var deleteAllButton: some View {
        Button {
            showDeleteAllConfirmation = true
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("Delete All Downloads")
                    .font(.jellyAmpHeadline)
                Spacer()
            }
            .foregroundColor(.red)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.red.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.red.opacity(0.5), lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Downloaded Track Row
struct DownloadedTrackRow: View {
    let downloadedTrack: DownloadedTrack
    let onPlay: () -> Void
    let onDelete: () -> Void
    @ObservedObject var themeManager = ThemeManager.shared

    var body: some View {
        Button {
            onPlay()
        } label: {
            HStack(spacing: 12) {
                // Music icon (playable)
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(.jellyAmpAccent)
                    .symbolRenderingMode(.hierarchical)

                // Track info
                VStack(alignment: .leading, spacing: 4) {
                    Text(downloadedTrack.trackName)
                        .font(.jellyAmpBody)
                        .foregroundColor(Color.jellyAmpText)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        Text(downloadedTrack.artistName)
                            .font(.jellyAmpCaption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)

                        Text("•")
                            .foregroundColor(.secondary)

                        Text(DownloadManager.shared.formatBytes(downloadedTrack.fileSize))
                            .font(.jellyAmpMono)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Delete button
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .font(.body)
                        .foregroundColor(.red.opacity(0.8))
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.jellyAmpMidBackground)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Downloaded Album Row
struct DownloadedAlbumRow: View {
    let album: DownloadedAlbum
    @ObservedObject var themeManager = ThemeManager.shared
    @ObservedObject var downloadManager = DownloadManager.shared
    @State private var artworkImage: UIImage? = nil

    var body: some View {
        HStack(spacing: 16) {
            // Album artwork (cached or placeholder)
            ZStack {
                if let artwork = artworkImage {
                    Image(uiImage: artwork)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [Color.jellyAmpAccent.opacity(0.3), Color.jellyAmpSecondary.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.6))
                        )
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: artworkImage != nil)
            .onAppear {
                loadArtwork()
            }

            // Album info
            VStack(alignment: .leading, spacing: 6) {
                Text(album.albumName)
                    .font(.jellyAmpBody)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.jellyAmpText)
                    .lineLimit(1)

                Text(album.artistName)
                    .font(.jellyAmpCaption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if let year = album.productionYear {
                        Text("\(year)")
                            .font(.jellyAmpCaption)
                            .foregroundColor(.secondary)

                        Text("•")
                            .foregroundColor(.secondary)
                    }

                    Text("\(album.trackCount) tracks")
                        .font(.jellyAmpCaption)
                        .foregroundColor(.secondary)

                    Text("•")
                        .foregroundColor(.secondary)

                    Text(album.formattedDuration)
                        .font(.jellyAmpMono)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.jellyAmpMidBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    private func loadArtwork() {
        // Load artwork asynchronously to avoid blocking UI
        Task {
            if let artworkURL = downloadManager.getCachedArtworkURL(for: album.albumId),
               let imageData = try? Data(contentsOf: artworkURL),
               let image = UIImage(data: imageData) {
                await MainActor.run {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        artworkImage = image
                    }
                }
            }
        }
    }
}

// MARK: - Downloaded Album Detail View
struct DownloadedAlbumDetailView: View {
    let album: DownloadedAlbum
    @ObservedObject var playerManager = PlayerManager.shared
    @ObservedObject var downloadManager = DownloadManager.shared
    @ObservedObject var themeManager = ThemeManager.shared
    @State private var showDeleteAlbumConfirmation = false
    @State private var artworkImage: UIImage? = nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Album header
                albumHeader

                // Tracks list
                tracksSection

                // Delete album button
                deleteAlbumButton

                // Bottom padding
                Color.clear.frame(height: 100)
            }
            .padding()
        }
        .background(Color.jellyAmpBackground.ignoresSafeArea())
        .navigationTitle(album.albumName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadArtwork()
        }
        .confirmationDialog("Delete Album", isPresented: $showDeleteAlbumConfirmation) {
            Button("Delete Album", role: .destructive) {
                deleteAlbum()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \"\(album.albumName)\"? This will delete all \(album.trackCount) tracks.")
        }
    }

    private var albumHeader: some View {
        VStack(spacing: 16) {
            // Album artwork
            ZStack {
                if let artwork = artworkImage {
                    Image(uiImage: artwork)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 200, height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .neonGlow(color: .jellyAmpAccent, radius: 20)
                } else {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [Color.jellyAmpAccent.opacity(0.4), Color.jellyAmpSecondary.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 200, height: 200)
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.title)
                                .foregroundColor(.white.opacity(0.6))
                        )
                        .neonGlow(color: .jellyAmpAccent, radius: 20)
                }
            }

            // Album info
            VStack(spacing: 8) {
                Text(album.albumName)
                    .font(.jellyAmpTitle)
                    .foregroundColor(Color.jellyAmpText)
                    .multilineTextAlignment(.center)

                Text(album.artistName)
                    .font(.jellyAmpHeadline)
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    if let year = album.productionYear {
                        Text("\(year)")
                    }
                    Text("•")
                    Text("\(album.trackCount) tracks")
                    Text("•")
                    Text(album.formattedDuration)
                }
                .font(.jellyAmpCaption)
                .foregroundColor(.secondary)

                Text(downloadManager.formatBytes(album.totalSize))
                    .font(.jellyAmpMono)
                    .foregroundColor(.jellyAmpAccent)
            }

            // Play all button
            Button {
                playAlbum()
            } label: {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Play Album")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color.jellyAmpAccent, Color.jellyAmpSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .buttonStyle(CypherpunkButtonStyle())
        }
    }

    private var tracksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tracks")
                .font(.jellyAmpHeadline)
                .foregroundColor(.jellyAmpAccent)
                .padding(.horizontal, 4)

            VStack(spacing: 1) {
                ForEach(album.tracks, id: \.trackId) { track in
                    DownloadedTrackRowInAlbum(
                        track: track,
                        onPlay: {
                            playFromTrack(track)
                        }
                    )
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.jellyAmpMidBackground)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }

    private var deleteAlbumButton: some View {
        Button {
            showDeleteAlbumConfirmation = true
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("Delete Album")
                    .font(.jellyAmpHeadline)
                Spacer()
            }
            .foregroundColor(.red)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.red.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.red.opacity(0.5), lineWidth: 1)
                    )
            )
        }
    }

    private func playAlbum() {
        let tracks = album.tracks.map { $0.toTrack() }
        playerManager.play(tracks: tracks, startingAt: 0)
    }

    private func playFromTrack(_ track: DownloadedTrack) {
        let tracks = album.tracks.map { $0.toTrack() }
        if let index = album.tracks.firstIndex(where: { $0.trackId == track.trackId }) {
            playerManager.play(tracks: tracks, startingAt: index)
        }
    }

    private func deleteAlbum() {
        // Delete all tracks in album
        for track in album.tracks {
            downloadManager.deleteDownload(trackId: track.trackId)
        }

        // Delete cached artwork
        downloadManager.deleteCachedArtwork(for: album.albumId)

        dismiss()
    }

    private func loadArtwork() {
        // Load artwork asynchronously to avoid blocking UI
        Task {
            if let artworkURL = downloadManager.getCachedArtworkURL(for: album.albumId),
               let imageData = try? Data(contentsOf: artworkURL),
               let image = UIImage(data: imageData) {
                await MainActor.run {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        artworkImage = image
                    }
                }
            }
        }
    }
}

// MARK: - Downloaded Track Row (in album view)
struct DownloadedTrackRowInAlbum: View {
    let track: DownloadedTrack
    let onPlay: () -> Void
    @ObservedObject var themeManager = ThemeManager.shared

    var body: some View {
        Button {
            onPlay()
        } label: {
            HStack(spacing: 12) {
                // Track number
                if let trackNum = track.trackNumber {
                    Text("\(trackNum)")
                        .font(.jellyAmpMono)
                        .foregroundColor(.secondary)
                        .frame(width: 30, alignment: .trailing)
                } else {
                    Image(systemName: "music.note")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 30)
                }

                // Track info
                VStack(alignment: .leading, spacing: 4) {
                    Text(track.trackName)
                        .font(.jellyAmpBody)
                        .foregroundColor(Color.jellyAmpText)
                        .lineLimit(1)

                    if let duration = track.duration {
                        Text(formatDuration(duration))
                            .font(.jellyAmpCaption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(.jellyAmpAccent.opacity(0.6))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.jellyAmpMidBackground)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Preview
#Preview {
    DownloadsView()
}
