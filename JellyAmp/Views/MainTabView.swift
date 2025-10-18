//
//  MainTabView.swift
//  JellyAmp
//
//  Main tab navigation with Liquid Glass styling
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showNowPlaying = false
    @ObservedObject var playerManager = PlayerManager.shared

    var body: some View {
        VStack(spacing: 0) {
            // Tab View
            TabView(selection: $selectedTab) {
                LibraryView()
                    .tag(0)
                    .tabItem {
                        Label("Library", systemImage: "music.note.list")
                    }

                SearchView()
                    .tag(1)
                    .tabItem {
                        Label("Search", systemImage: "magnifyingglass")
                    }

                FavoritesView()
                    .tag(2)
                    .tabItem {
                        Label("Favorites", systemImage: "heart.fill")
                    }

                DownloadsTabPlaceholder()
                    .tag(3)
                    .tabItem {
                        Label("Downloads", systemImage: "arrow.down.circle.fill")
                    }

                SettingsView()
                    .tag(4)
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
            }
            .tint(.neonCyan)

            // CNN-Style Ticker Mini Player (always visible above tab bar)
            if let currentTrack = playerManager.currentTrack {
                tickerMiniPlayer(track: currentTrack)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .fullScreenCover(isPresented: $showNowPlaying) {
            NowPlayingView()
        }
    }

    // MARK: - CNN-Style Ticker Mini Player
    @ViewBuilder
    private func tickerMiniPlayer(track: Track) -> some View {
        Button {
            showNowPlaying = true
        } label: {
            HStack(spacing: 0) {
                // Animated scrolling text (CNN-style ticker)
                GeometryReader { geometry in
                    ScrollingText(
                        text: "\(track.name) • \(track.artistName) • \(track.albumName)",
                        isPlaying: playerManager.isPlaying,
                        geometry: geometry
                    )
                }
                .frame(height: 32)

                // Play/Pause button (compact)
                Button {
                    playerManager.togglePlayPause()
                } label: {
                    Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 32)
                }
            }
            .foregroundColor(.white)
            .frame(height: 32)
            .background(
                Rectangle()
                    .fill(Color.darkMid)
                    .overlay(
                        // Top gradient line
                        LinearGradient(
                            colors: [
                                Color.neonCyan.opacity(0.5),
                                Color.neonPink.opacity(0.5)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(height: 2),
                        alignment: .top
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Scrolling Text Component (CNN-Style Ticker)
struct ScrollingText: View {
    let text: String
    let isPlaying: Bool
    let geometry: GeometryProxy

    @State private var offset: CGFloat = 0

    var body: some View {
        HStack(spacing: 0) {
            Text(text)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
                .fixedSize()

            Text("  ▸  ")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.neonCyan)

            Text(text)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
                .fixedSize()
        }
        .offset(x: offset)
        .onAppear {
            startScrolling()
        }
        .onChange(of: isPlaying) { _, newValue in
            if newValue {
                startScrolling()
            }
        }
    }

    private func startScrolling() {
        let textWidth = text.widthOfString(usingFont: UIFont.monospacedSystemFont(ofSize: 13, weight: .medium))
        let totalWidth = textWidth + 50 // Add separator width

        withAnimation(.linear(duration: Double(totalWidth) / 30).repeatForever(autoreverses: false)) {
            offset = -totalWidth
        }
    }
}

// Helper extension to calculate text width
extension String {
    func widthOfString(usingFont font: UIFont) -> CGFloat {
        let fontAttributes = [NSAttributedString.Key.font: font]
        let size = self.size(withAttributes: fontAttributes)
        return size.width
    }
}

// MARK: - Placeholder Views (to be built later)
struct SearchTabPlaceholder: View {
    var body: some View {
        ZStack {
            Color.darkBackground.ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 60))
                    .foregroundColor(.neonCyan)
                    .neonGlow(color: .neonCyan, radius: 20)

                Text("Search")
                    .font(.jellyAmpTitle)
                    .foregroundColor(.white)

                Text("Coming soon...")
                    .font(.jellyAmpBody)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct FavoritesTabPlaceholder: View {
    var body: some View {
        ZStack {
            Color.darkBackground.ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.neonPink)
                    .neonGlow(color: .neonPink, radius: 20)

                Text("Favorites")
                    .font(.jellyAmpTitle)
                    .foregroundColor(.white)

                Text("Coming soon...")
                    .font(.jellyAmpBody)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct DownloadsTabPlaceholder: View {
    var body: some View {
        ZStack {
            Color.darkBackground.ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.neonGreen)
                    .neonGlow(color: .neonGreen, radius: 20)

                Text("Downloads")
                    .font(.jellyAmpTitle)
                    .foregroundColor(.white)

                Text("Coming soon...")
                    .font(.jellyAmpBody)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    MainTabView()
}
