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
    @ObservedObject var themeManager = ThemeManager.shared

    var body: some View {
        VStack(spacing: 0) {
            // Content Area (Tab Views)
            Group {
                switch selectedTab {
                case 0:
                    LibraryView()
                case 1:
                    SearchView()
                case 2:
                    FavoritesView()
                case 3:
                    DownloadsView()
                case 4:
                    SettingsView()
                default:
                    LibraryView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Mini Player (sits above tab bar)
            if playerManager.currentTrack != nil {
                MiniPlayerView(showNowPlaying: $showNowPlaying)
            }

            // Custom Tab Bar (always at bottom)
            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard)
        .fullScreenCover(isPresented: $showNowPlaying) {
            NowPlayingView()
        }
    }
}

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: Int

    var body: some View {
        HStack(spacing: 8) {
            TabBarButton(
                icon: "music.note.list",
                label: "Library",
                isSelected: selectedTab == 0
            ) {
                selectedTab = 0
            }

            TabBarButton(
                icon: "magnifyingglass",
                label: "Search",
                isSelected: selectedTab == 1
            ) {
                selectedTab = 1
            }

            TabBarButton(
                icon: "heart.fill",
                label: "Favorites",
                isSelected: selectedTab == 2
            ) {
                selectedTab = 2
            }

            TabBarButton(
                icon: "arrow.down.circle.fill",
                label: "Downloads",
                isSelected: selectedTab == 3
            ) {
                selectedTab = 3
            }

            TabBarButton(
                icon: "gearshape.fill",
                label: "Settings",
                isSelected: selectedTab == 4
            ) {
                selectedTab = 4
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(
            ZStack {
                // Base glass layer with ultra thin material
                RoundedRectangle(cornerRadius: 28)
                    .fill(.ultraThinMaterial)

                // Dark tinted overlay for depth
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.4),
                                Color.black.opacity(0.5),
                                Color.black.opacity(0.6)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .opacity(0.8)

                // Inner shadow for depth
                RoundedRectangle(cornerRadius: 28)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.5),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
                    .blur(radius: 1)

                // Glass highlight on top edge
                RoundedRectangle(cornerRadius: 28)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.25),
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1.5
                    )

                // Shimmer effect
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.08),
                                Color.clear,
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        )
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
        .shadow(color: Color.black.opacity(0.5), radius: 25, x: 0, y: -15)
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: -5)
    }
}

// MARK: - Tab Bar Button
struct TabBarButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3.weight(.medium))
                    .foregroundColor(isSelected ? .jellyAmpAccent : .white.opacity(0.6))

                Text(label)
                    .font(.caption2.weight(isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .jellyAmpAccent : .white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                // Liquid glass pill for selected state
                Group {
                    if isSelected {
                        ZStack {
                            // Base glass material
                            RoundedRectangle(cornerRadius: 18)
                                .fill(.thinMaterial)

                            // Dark tinted overlay
                            RoundedRectangle(cornerRadius: 18)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.black.opacity(0.5),
                                            Color.black.opacity(0.6)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .opacity(0.85)

                            // Accent glow border
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.jellyAmpAccent.opacity(0.4),
                                            Color.jellyAmpAccent.opacity(0.2)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 1.5
                                )

                            // Glass highlight
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.15),
                                            Color.clear
                                        ],
                                        startPoint: .top,
                                        endPoint: .center
                                    ),
                                    lineWidth: 1
                                )
                        }
                        .shadow(color: Color.jellyAmpAccent.opacity(0.2), radius: 8, x: 0, y: 0)
                    } else {
                        Color.clear
                    }
                }
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSelected)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Static Tab Bar (for detail views)
struct StaticTabBar: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        HStack(spacing: 8) {
            StaticTabButton(icon: "music.note.list", label: "Library") {
                dismiss()
            }

            StaticTabButton(icon: "magnifyingglass", label: "Search") {
                dismiss()
            }

            StaticTabButton(icon: "heart.fill", label: "Favorites") {
                dismiss()
            }

            StaticTabButton(icon: "arrow.down.circle.fill", label: "Downloads") {
                dismiss()
            }

            StaticTabButton(icon: "gearshape.fill", label: "Settings") {
                dismiss()
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(
            ZStack {
                // Base glass layer with ultra thin material
                RoundedRectangle(cornerRadius: 28)
                    .fill(.ultraThinMaterial)

                // Dark tinted overlay for depth
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.4),
                                Color.black.opacity(0.5),
                                Color.black.opacity(0.6)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .opacity(0.8)

                // Inner shadow for depth
                RoundedRectangle(cornerRadius: 28)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.5),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
                    .blur(radius: 1)

                // Glass highlight on top edge
                RoundedRectangle(cornerRadius: 28)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.25),
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1.5
                    )

                // Shimmer effect
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.08),
                                Color.clear,
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        )
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
        .shadow(color: Color.black.opacity(0.5), radius: 25, x: 0, y: -15)
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: -5)
    }
}

// MARK: - Static Tab Button (non-highlighted)
struct StaticTabButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3.weight(.medium))
                    .foregroundColor(.white.opacity(0.6))

                Text(label)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Placeholder Views (to be built later)
struct SearchTabPlaceholder: View {
    var body: some View {
        ZStack {
            Color.darkBackground.ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "magnifyingglass")
                    .font(.title)
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
                    .font(.title)
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
    @ObservedObject var themeManager = ThemeManager.shared

    var body: some View {
        ZStack {
            Color.jellyAmpBackground.ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.title)
                    .foregroundColor(.jellyAmpSuccess)
                    .neonGlow(color: .jellyAmpSuccess, radius: 20)

                Text("Downloads")
                    .font(.jellyAmpTitle)
                    .foregroundColor(Color.jellyAmpText)

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
