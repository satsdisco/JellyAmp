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
    @Environment(\.dismiss) var dismiss
    @State private var isFavorite: Bool
    @State private var albumTracks: [Track] = []
    @State private var isLoadingTracks = true
    @State private var showNowPlaying = false

    init(album: Album) {
        self.album = album
        _isFavorite = State(initialValue: album.isFavorite)
    }

    var totalDuration: String {
        let total = albumTracks.reduce(0) { $0 + $1.duration }
        let minutes = Int(total) / 60
        return "\(minutes) min"
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

            // Back Button (floating)
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(Color.darkMid)
                                    .glassEffect(.regular)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.neonCyan.opacity(0.5), lineWidth: 1)
                                    )
                            )
                            .neonGlow(color: .neonCyan, radius: 8)
                    }
                    .padding(.leading, 20)
                    .padding(.top, 60)

                    Spacer()
                }

                Spacer()
            }
        }
        .onAppear {
            Task {
                await fetchAlbumTracks()
            }
        }
        .sheet(isPresented: $showNowPlaying) {
            NowPlayingView()
        }
    }

    // MARK: - Fetch Album Tracks
    private func fetchAlbumTracks() async {
        isLoadingTracks = true

        do {
            let tracks = try await jellyfinService.getAlbumTracks(albumId: album.id)
            let baseURL = jellyfinService.baseURL
            self.albumTracks = tracks.map { Track(from: $0, baseURL: baseURL) }
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

    // MARK: - Album Hero Section
    private var albumHeroSection: some View {
        VStack(spacing: 0) {
            // Album Artwork
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [
                        Color.neonCyan.opacity(0.6),
                        Color.neonPink.opacity(0.6),
                        Color.neonPurple.opacity(0.7)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 380)

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
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color.neonCyan.opacity(0.8),
                                                    Color.neonPink.opacity(0.8)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 2
                                        )
                                )
                                .neonGlow(color: .neonPink, radius: 20)
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
                        Color.darkBackground.opacity(0.9)
                    ],
                    startPoint: .center,
                    endPoint: .bottom
                )
            )

            // Album Title & Artist
            VStack(spacing: 8) {
                Text(album.name)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .neonGlow(color: .neonCyan, radius: 10)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                Text(album.artistName)
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
                        Color.neonPurple.opacity(0.5)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 260, height: 260)
            .glassEffect(.regular)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.neonCyan.opacity(0.8),
                                Color.neonPink.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
            .neonGlow(color: .neonPink, radius: 20)
            .overlay(
                Image(systemName: "music.note")
                    .font(.system(size: 80))
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
                        .fill(albumTracks.isEmpty ? Color.gray : Color.neonCyan)
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
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                            .glassEffect(.regular)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.neonPurple.opacity(0.5), lineWidth: 1)
                            )
                    )
                    .neonGlow(color: .neonPurple, radius: 8)
            }
            .disabled(albumTracks.isEmpty)

            // Favorite Button
            Button {
                toggleFavorite()
            } label: {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(isFavorite ? .neonPink : .white)
                    .frame(width: 56, height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                            .glassEffect(.regular)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.neonPink.opacity(isFavorite ? 0.8 : 0.5), lineWidth: 1)
                            )
                    )
                    .neonGlow(color: .neonPink, radius: isFavorite ? 12 : 8)
            }

            // Download Button (future feature)
            Button {
                // Offline playback feature - requires download manager
            } label: {
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                            .glassEffect(.regular)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.neonCyan.opacity(0.5), lineWidth: 1)
                            )
                    )
                    .neonGlow(color: .neonCyan, radius: 8)
            }
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
                .foregroundColor(.white)
                .padding(.horizontal, 20)

            if isLoadingTracks {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(.neonCyan)
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
                        .glassEffect(.regular)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.neonCyan.opacity(0.2), lineWidth: 1)
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
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.1))
                .glassEffect(.regular)
        )
        .overlay(
            Capsule()
                .stroke(Color.neonCyan.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Album Track Row Component
struct AlbumTrackRow: View {
    let track: Track
    let trackNumber: Int
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
                // Track number
                Text("\(trackNumber)")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.neonCyan)
                    .frame(width: 28, alignment: .trailing)

                // Track info
                VStack(alignment: .leading, spacing: 4) {
                    Text(track.name)
                        .font(.jellyAmpBody)
                        .foregroundColor(.white)
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
    }
}

// MARK: - Preview
#Preview {
    AlbumDetailView(album: Album.mockAlbums[0])
}
