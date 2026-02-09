//
//  MiniPlayerView.swift
//  JellyAmp
//
//  Polished mini player with ticker-style text and glass effects
//

import SwiftUI

struct MiniPlayerView: View {
    @ObservedObject var playerManager = PlayerManager.shared
    @Binding var showNowPlaying: Bool

    var body: some View {
        if let currentTrack = playerManager.currentTrack {
            miniPlayerButton(for: currentTrack)
        }
    }

    private func miniPlayerButton(for currentTrack: Track) -> some View {
        Button {
            showNowPlaying = true
        } label: {
            miniPlayerContent(for: currentTrack)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Now playing: \(currentTrack.name) by \(currentTrack.artistName)")
        .accessibilityHint("Double tap for full player")
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: playerManager.currentTrack?.id)
    }

    private func miniPlayerContent(for currentTrack: Track) -> some View {
        HStack(spacing: 0) {
            miniPlayerArtwork(for: currentTrack)

            // Track info
            VStack(spacing: 3) {
                Text("\(currentTrack.name) • \(currentTrack.artistName)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)

                Text(currentTrack.albumName)
                    .font(.caption.weight(.medium))
                    .foregroundColor(.white.opacity(0.65))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 12)

            miniPlayerPlayButton
        }
        .frame(height: 64)
        .background(.regularMaterial)
    }

    private func miniPlayerArtwork(for track: Track) -> some View {
        AsyncImage(url: URL(string: track.artworkURL ?? "")) { phase in
            switch phase {
            case .success(let image):
                image.resizable().aspectRatio(contentMode: .fill)
            case .empty, .failure, _:
                ZStack {
                    Rectangle().fill(Color.jellyAmpMidBackground)
                    Image(systemName: "music.note")
                        .font(.body.weight(.medium))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .frame(width: 48, height: 48)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
        .padding(.leading, 12)
    }

    private var miniPlayerPlayButton: some View {
        Button {
            playerManager.togglePlayPause()
        } label: {
            Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                .font(.body.weight(.semibold))
                .foregroundColor(.neonPink)
                .frame(width: 40, height: 40)
                .background(Circle().fill(.ultraThinMaterial))
                .overlay(Circle().stroke(Color.neonPink.opacity(0.3), lineWidth: 1))
        }
        .accessibilityLabel(playerManager.isPlaying ? "Pause" : "Play")
        .padding(.trailing, 12)
    }
}

// MARK: - Ticker Text Component
struct TickerText: View {
    let text: String
    let isPlaying: Bool
    let geometry: GeometryProxy

    @State private var offset: CGFloat = 0
    @State private var textWidth: CGFloat = 0
    @State private var needsScrolling: Bool = false

    var body: some View {
        VStack {
            Spacer()
            HStack(spacing: 0) {
                // First copy of text
                Text(text)
                    .font(.body.weight(.semibold))
                    .foregroundColor(.white)
                    .fixedSize()
                    .background(
                        GeometryReader { textGeometry in
                            Color.clear.onAppear {
                                textWidth = textGeometry.size.width
                            }
                        }
                    )

                // Only show separator and second copy if text needs scrolling
                if needsScrolling {
                    // Separator
                    Text("  •  ")
                        .font(.body.weight(.bold))
                        .foregroundColor(.white.opacity(0.5))

                    // Second copy of text for seamless loop
                    Text(text)
                        .font(.body.weight(.semibold))
                        .foregroundColor(.white)
                        .fixedSize()
                }
            }
            .offset(x: offset)
            Spacer()
        }
        .onAppear {
            startScrolling()
        }
        .onChange(of: text) { _, _ in
            // Reset and restart when text changes
            offset = 0
            needsScrolling = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                startScrolling()
            }
        }
    }

    private func startScrolling() {
        guard textWidth > 0 else { return }

        let totalWidth = textWidth + 30 // Text width + separator width

        // Only scroll if text is wider than available space
        if textWidth > geometry.size.width {
            needsScrolling = true
            withAnimation(.linear(duration: Double(totalWidth) / 40).repeatForever(autoreverses: false)) {
                offset = -totalWidth
            }
        } else {
            needsScrolling = false
            offset = 0
        }
    }
}

// MARK: - Preview
#Preview {
    VStack {
        Spacer()
        MiniPlayerView(showNowPlaying: .constant(false))
    }
    .background(Color.jellyAmpBackground)
}
