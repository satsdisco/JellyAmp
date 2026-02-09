//
//  NowPlayingView.swift
//  JellyAmp Watch
//
//  Now Playing screen with playback controls for Apple Watch
//

import SwiftUI

struct NowPlayingView: View {
    @ObservedObject var playerManager = WatchPlayerManager.shared
    @ObservedObject var jellyfinService = WatchJellyfinService.shared
    @State private var isFavorite = false
    @State private var crownVolume: Double = 1.0
    @State private var showVolumeIndicator = false

    var body: some View {
        VStack(spacing: 6) {
            // Track info
            if let track = playerManager.currentTrack {
                trackInfo(track)
            } else {
                placeholderView
            }

            // Progress
            if playerManager.duration > 0 {
                progressView
            }

            // Playback controls
            controlsView
        }
        .overlay(alignment: .top) {
            if showVolumeIndicator {
                HStack(spacing: 6) {
                    Image(systemName: crownVolume == 0 ? "speaker.slash.fill" : crownVolume < 0.5 ? "speaker.wave.1.fill" : "speaker.wave.2.fill")
                        .font(.caption2)
                        .foregroundColor(.cyan)
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.2))
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.cyan, .pink],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * crownVolume)
                        }
                    }
                    .frame(height: 4)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.black.opacity(0.8))
                .cornerRadius(8)
                .padding(.top, 4)
                .transition(.opacity)
            }
        }
        .padding(.vertical, 4)
        .focusable(true)
        .digitalCrownRotation($crownVolume, from: 0.0, through: 1.0, by: 0.05, sensitivity: .medium)
        .onChange(of: crownVolume) { _, newValue in
            playerManager.setVolume(Float(newValue))
            withAnimation(.easeIn(duration: 0.15)) {
                showVolumeIndicator = true
            }
            // Hide after delay
            Task {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                withAnimation(.easeOut(duration: 0.3)) {
                    showVolumeIndicator = false
                }
            }
        }
        .onAppear {
            crownVolume = Double(playerManager.volume)
            syncFavoriteState()
        }
        .onChange(of: playerManager.currentTrack?.id) { _, _ in
            syncFavoriteState()
        }
        .containerBackground(.black.gradient, for: .navigation)
    }

    // MARK: - Track Info

    private func trackInfo(_ track: WatchTrack) -> some View {
        VStack(spacing: 3) {
            // Album artwork with favorite button
            ZStack(alignment: .topTrailing) {
                AlbumArtworkView(
                    albumId: track.albumId,
                    baseURL: jellyfinService.baseURL,
                    size: 85
                )
                .frame(width: 85, height: 85)
                .cornerRadius(8)

                // Favorite button
                Button {
                    toggleFavorite(track: track)
                } label: {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.subheadline)
                        .foregroundColor(.pink)
                        .padding(6)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.6))
                                .frame(width: 26, height: 26)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
                .offset(x: 4, y: -4)
            }

            // Track name
            Text(track.name)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .multilineTextAlignment(.center)

            // Artist
            Text(track.artist)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Placeholder

    private var placeholderView: some View {
        VStack(spacing: 12) {
            Image(systemName: "music.note.list")
                .font(.title)
                .foregroundColor(.secondary)

            Text("Nothing Playing")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Play music on your iPhone")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 20)
    }

    // MARK: - Progress

    private var progressView: some View {
        VStack(spacing: 1) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    Capsule()
                        .fill(Color.white.opacity(0.2))

                    // Progress
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.cyan, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress)
                }
            }
            .frame(height: 2.5)

            // Time labels
            HStack {
                Text(formatTime(playerManager.currentTime))
                    .font(.caption2)
                    .monospacedDigit()
                    .foregroundColor(.cyan)

                Spacer()

                Text(formatTime(playerManager.duration))
                    .font(.caption2)
                    .monospacedDigit()
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 6)
    }

    private var progress: Double {
        guard playerManager.duration > 0 else { return 0 }
        return min(max(playerManager.currentTime / playerManager.duration, 0), 1)
    }

    // MARK: - Controls

    private var controlsView: some View {
        HStack(spacing: 24) {
            // Previous
            Button {
                playerManager.playPrevious()
            } label: {
                Image(systemName: "backward.fill")
                    .font(.title3)
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Previous track")

            // Play/Pause - Large tap target for running
            Button {
                playerManager.togglePlayPause()
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.cyan, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)

                    Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title3)
                        .foregroundColor(.black)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(playerManager.isPlaying ? "Pause" : "Play")

            // Next
            Button {
                playerManager.playNext()
            } label: {
                Image(systemName: "forward.fill")
                    .font(.title3)
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Next track")
        }
        .foregroundColor(.white)
        .padding(.vertical, 2)
    }

    // MARK: - Queue Info

    private var queueInfo: some View {
        HStack(spacing: 6) {
            Image(systemName: "music.note.list")
                .font(.caption2)
            Text("\(playerManager.queue.count) tracks in queue")
                .font(.caption2)
        }
        .foregroundColor(.secondary)
    }

    // MARK: - Helpers

    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func syncFavoriteState() {
        guard let track = playerManager.currentTrack else {
            isFavorite = false
            return
        }
        isFavorite = track.isFavorite
    }

    private func toggleFavorite(track: WatchTrack) {
        Task {
            do {
                // Optimistically update UI
                isFavorite.toggle()

                // Update on server
                if isFavorite {
                    try await jellyfinService.markFavorite(itemId: track.id)
                } else {
                    try await jellyfinService.unmarkFavorite(itemId: track.id)
                }

                print("✅ Favorite toggled: \(track.name) - isFavorite: \(isFavorite)")
            } catch {
                // Revert on failure
                isFavorite.toggle()
                print("❌ Failed to toggle favorite: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    NowPlayingView()
}
