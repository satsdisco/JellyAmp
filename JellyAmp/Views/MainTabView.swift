//
//  MainTabView.swift
//  JellyAmp
//
//  Main tab navigation with native TabView and NavigationStack
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showNowPlaying = false
    @ObservedObject var playerManager = PlayerManager.shared
    @ObservedObject var themeManager = ThemeManager.shared
    @Namespace private var playerAnimation

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                NavigationStack {
                    LibraryView()
                }
                .tabItem {
                    Label("Library", systemImage: "music.note.list")
                }
                .tag(0)
                
                NavigationStack {
                    SearchView()
                }
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(1)
                
                NavigationStack {
                    FavoritesView()
                }
                .tabItem {
                    Label("Favorites", systemImage: "heart.fill")
                }
                .tag(2)
                
                NavigationStack {
                    DownloadsView()
                }
                .tabItem {
                    Label("Downloads", systemImage: "arrow.down.circle.fill")
                }
                .tag(3)
                
                NavigationStack {
                    SettingsView()
                }
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(4)
            }
            .tint(.jellyAmpAccent)
            .overlay(alignment: .bottom) {
                // Mini Player floats above tab bar
                if playerManager.currentTrack != nil && !showNowPlaying {
                    MiniPlayerView(showNowPlaying: $showNowPlaying, namespace: playerAnimation)
                        .padding(.horizontal, 8)
                        .padding(.bottom, 56) // Tab bar height + spacing
                }
            }
            
            // Now Playing View as overlay with swipe-to-dismiss
            if showNowPlaying {
                NowPlayingDismissWrapper {
                    showNowPlaying = false
                } content: {
                    NowPlayingView(namespace: playerAnimation, onDismiss: {
                        showNowPlaying = false
                    })
                }
                .transition(.move(edge: .bottom))
                .zIndex(1)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: showNowPlaying)
    }
}

// MARK: - Swipe-to-Dismiss Wrapper
struct NowPlayingDismissWrapper<Content: View>: View {
    let onDismiss: () -> Void
    @ViewBuilder let content: () -> Content
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        content()
            .offset(y: max(0, dragOffset))
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onChanged { value in
                        // Only allow downward drag
                        if value.translation.height > 0 {
                            dragOffset = value.translation.height
                        }
                    }
                    .onEnded { value in
                        if value.translation.height > 150 || value.predictedEndTranslation.height > 300 {
                            // Dismiss
                            onDismiss()
                        }
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            dragOffset = 0
                        }
                    }
            )
            .animation(.interactiveSpring(), value: dragOffset)
    }
}

// MARK: - Preview
#Preview {
    MainTabView()
}