//
//  ContentView.swift
//  JellyAmp Watch Watch App
//
//  Main tabbed interface for watch app with authentication checking
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var watchJellyfinService = WatchJellyfinService.shared
    @State private var selectedTab = 0

    var body: some View {
        Group {
            if watchJellyfinService.isAuthenticated {
                // User is authenticated - show main app
                TabView(selection: $selectedTab) {
                    NavigationStack {
                        LibraryView()
                    }
                    .tag(0)

                    NowPlayingView()
                        .tag(1)

                    SettingsView()
                        .tag(2)
                }
                .tabViewStyle(.page)
            } else {
                // User not authenticated - show message to sync from iPhone
                WatchOnboardingView()
            }
        }
        .preferredColorScheme(.dark)
        .containerBackground(.black.gradient, for: .tabView)
    }
}

#Preview {
    ContentView()
}
