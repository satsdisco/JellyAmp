//
//  ContentView.swift
//  JellyAmp Watch Watch App
//
//  Main tabbed interface for watch app
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
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
    }
}

#Preview {
    ContentView()
}
