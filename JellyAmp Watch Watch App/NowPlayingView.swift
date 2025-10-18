//
//  NowPlayingView.swift
//  JellyAmp Watch
//
//  Now Playing screen with playback controls for Apple Watch
//

import SwiftUI

struct NowPlayingView: View {
    @ObservedObject var playerManager = WatchPlayerManager.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
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

                // Queue info
                if playerManager.queue.count > 0 {
                    queueInfo
                }
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Track Info

    private func trackInfo(_ track: WatchTrack) -> some View {
        VStack(spacing: 4) {
            // Album art placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Color.cyan.opacity(0.3), Color.pink.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 120)

                Image(systemName: "music.note")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 4)

            // Track name
            Text(track.name)
                .font(.headline)
                .fontWeight(.bold)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            // Artist
            Text(track.artist)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)

            // Album
            Text(track.album)
                .font(.caption2)
                .foregroundColor(.secondary.opacity(0.7))
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Placeholder

    private var placeholderView: some View {
        VStack(spacing: 12) {
            Image(systemName: "music.note.list")
                .font(.system(size: 40))
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
        VStack(spacing: 4) {
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
            .frame(height: 4)

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
        .padding(.horizontal, 8)
    }

    private var progress: Double {
        guard playerManager.duration > 0 else { return 0 }
        return min(max(playerManager.currentTime / playerManager.duration, 0), 1)
    }

    // MARK: - Controls

    private var controlsView: some View {
        HStack(spacing: 16) {
            // Previous
            Button {
                playerManager.playPrevious()
            } label: {
                Image(systemName: "backward.fill")
                    .font(.title3)
            }
            .buttonStyle(.plain)

            // Play/Pause
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
                        .frame(width: 50, height: 50)

                    Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title3)
                        .foregroundColor(.black)
                }
            }
            .buttonStyle(.plain)

            // Next
            Button {
                playerManager.playNext()
            } label: {
                Image(systemName: "forward.fill")
                    .font(.title3)
            }
            .buttonStyle(.plain)
        }
        .foregroundColor(.white)
        .padding(.vertical, 8)
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

    // MARK: - Helper

    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    NowPlayingView()
}
