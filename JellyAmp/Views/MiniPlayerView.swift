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
            Button {
                showNowPlaying = true
            } label: {
                HStack(spacing: 0) {
                    // Album artwork (small)
                    AsyncImage(url: URL(string: currentTrack.artworkURL ?? "")) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .empty, .failure, _:
                            ZStack {
                                Rectangle()
                                    .fill(.thinMaterial)

                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.neonPink.opacity(0.2),
                                                Color.neonPurple.opacity(0.2)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )

                                Image(systemName: "music.note")
                                    .font(.body.weight(.medium))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                    }
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.2),
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                    .padding(.leading, 12)

                    // Track info with two lines
                    VStack(spacing: 3) {
                        // Song Title • Artist (top line)
                        Text("\(currentTrack.name) • \(currentTrack.artistName)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity)

                        // Album Name (bottom line, centered)
                        Text(currentTrack.albumName)
                            .font(.caption.weight(.medium))
                            .foregroundColor(.white.opacity(0.65))
                            .lineLimit(1)
                            .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 12)

                    // Play/Pause button
                    Button {
                        playerManager.togglePlayPause()
                    } label: {
                        ZStack {
                            // Glass button background
                            Circle()
                                .fill(.thinMaterial)
                                .frame(width: 40, height: 40)

                            Circle()
                                .fill(Color.neonPink.opacity(0.15))
                                .frame(width: 40, height: 40)

                            // Border glow
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.neonPink.opacity(0.5),
                                            Color.neonPink.opacity(0.2)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                                .frame(width: 40, height: 40)

                            Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                                .font(.body.weight(.semibold))
                                .foregroundColor(.neonPink)
                        }
                        .shadow(color: Color.neonPink.opacity(0.3), radius: 8, x: 0, y: 0)
                    }
                    .accessibilityLabel(playerManager.isPlaying ? "Pause" : "Play")
                    .padding(.trailing, 12)
                }
                .frame(height: 64)
                .background(
                    ZStack {
                        // Base glass layer with ultra thin material
                        Rectangle()
                            .fill(.ultraThinMaterial)

                        // Dark tinted overlay for depth
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.black.opacity(0.45),
                                        Color.black.opacity(0.55),
                                        Color.black.opacity(0.65)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .opacity(0.8)

                        // Inner shadow for depth
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.black.opacity(0.3),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: 4)
                            .frame(maxHeight: .infinity, alignment: .top)
                            .blur(radius: 2)

                        // Glass highlight on top edge
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.15),
                                        Color.white.opacity(0.05),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: 1.5)
                            .frame(maxHeight: .infinity, alignment: .top)

                        // Shimmer effect
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.06),
                                        Color.clear,
                                        Color.white.opacity(0.04)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                )
                .overlay(
                    // Subtle bottom divider
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 0.5)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                )
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Now playing: \(currentTrack.name) by \(currentTrack.artistName)")
            .accessibilityHint("Double tap for full player")
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: playerManager.currentTrack?.id)
        }
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
