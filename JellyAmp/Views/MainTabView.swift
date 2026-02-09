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
            
            // Now Playing View as overlay for hero animation
            if showNowPlaying {
                NowPlayingView(namespace: playerAnimation)
                    .transition(.move(edge: .bottom))
                    .zIndex(1)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: showNowPlaying)
    }
}

// MARK: - Preview
#Preview {
    MainTabView()
}