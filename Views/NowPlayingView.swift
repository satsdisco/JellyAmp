//
//  NowPlayingView.swift
//  JellyAmp
//
//  Beautiful Now Playing screen with iOS 26 Liquid Glass + Cypherpunk styling
//

import SwiftUI

struct NowPlayingView: View {
    @State private var currentTrack = Track.mockTrack1
    @State private var isPlaying = false
    @State private var currentTime: Double = 45
    @State private var isShuffle = false
    @State private var repeatMode = 0 // 0: off, 1: all, 2: one

    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            // Background with gradient
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

            // Content
            VStack(spacing: 0) {
                // Top Bar
                topBar

                Spacer()

                // Album Artwork
                artworkSection

                Spacer()

                // Track Info
                trackInfoSection

                // Progress Slider
                progressSection

                // Controls
                controlsSection

                // Bottom Actions
                bottomActionsSection

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text("Now Playing")
                .font(.jellyAmpCaption)
                .foregroundColor(.secondary)

            Spacer()

            Button {
                // More options
            } label: {
                Image(systemName: "ellipsis")
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }
        }
    }

    // MARK: - Artwork Section
    private var artworkSection: some View {
        ZStack {
            // Placeholder artwork with gradient
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.neonCyan.opacity(0.6),
                            Color.neonPink.opacity(0.6),
                            Color.neonPurple.opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 320, height: 320)
                .glassEffect(.regular)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
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
                .neonGlow(color: .neonCyan, radius: 20)

            // Album icon overlay
            Image(systemName: "music.note")
                .font(.title)
                .foregroundColor(.white.opacity(0.3))
        }
    }

    // MARK: - Track Info Section
    private var trackInfoSection: some View {
        VStack(spacing: 8) {
            Text(currentTrack.name)
                .font(.jellyAmpTitle)
                .foregroundColor(.white)
                .neonGlow(color: .neonCyan, radius: 10)

            Text(currentTrack.artistName)
                .font(.jellyAmpHeadline)
                .foregroundColor(.secondary)

            Text(currentTrack.albumName)
                .font(.jellyAmpCaption)
                .foregroundColor(.tertiary)
        }
        .padding(.top, 30)
    }

    // MARK: - Progress Section
    private var progressSection: some View {
        VStack(spacing: 8) {
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track background
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .glassEffect(.regular)

                    // Progress fill
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.neonCyan, Color.neonPink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * (currentTime / currentTrack.duration))
                        .neonGlow(color: .neonCyan, radius: 4)
                }
            }
            .frame(height: 6)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let percent = min(max(0, value.location.x / UIScreen.main.bounds.width * 1.2), 1)
                        currentTime = currentTrack.duration * percent
                    }
            )

            // Time labels
            HStack {
                Text(formatTime(currentTime))
                    .font(.jellyAmpMono)
                    .foregroundColor(.neonCyan)

                Spacer()

                Text(currentTrack.durationFormatted)
                    .font(.jellyAmpMono)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top, 40)
    }

    // MARK: - Controls Section
    private var controlsSection: some View {
        HStack(spacing: 40) {
            // Previous
            Button {
                // Previous track
            } label: {
                Image(systemName: "backward.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            }

            // Play/Pause (prominent)
            Button {
                isPlaying.toggle()
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.neonCyan, Color.neonPink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .neonGlow(color: .neonCyan, radius: 20)

                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.title)
                        .foregroundColor(.black)
                }
            }

            // Next
            Button {
                // Next track
            } label: {
                Image(systemName: "forward.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            }
        }
        .padding(.top, 30)
    }

    // MARK: - Bottom Actions
    private var bottomActionsSection: some View {
        HStack(spacing: 50) {
            // Shuffle
            Button {
                isShuffle.toggle()
            } label: {
                Image(systemName: "shuffle")
                    .font(.title3)
                    .foregroundColor(isShuffle ? .neonCyan : .secondary)
                    .neonGlow(color: .neonCyan, radius: isShuffle ? 6 : 0)
            }

            // Favorite
            Button {
                // Toggle favorite
            } label: {
                Image(systemName: "heart")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }

            // Queue
            Button {
                // Show queue
            } label: {
                Image(systemName: "list.bullet")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }

            // Repeat
            Button {
                repeatMode = (repeatMode + 1) % 3
            } label: {
                Image(systemName: repeatMode == 2 ? "repeat.1" : "repeat")
                    .font(.title3)
                    .foregroundColor(repeatMode > 0 ? .neonCyan : .secondary)
                    .neonGlow(color: .neonCyan, radius: repeatMode > 0 ? 6 : 0)
            }
        }
        .padding(.top, 30)
    }

    // MARK: - Helpers
    private func formatTime(_ time: TimeInterval) -> String {
        // Guard against NaN or infinite values
        guard !time.isNaN && !time.isInfinite && time >= 0 else {
            return "0:00"
        }

        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Preview
#Preview {
    NowPlayingView()
}
