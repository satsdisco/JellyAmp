//
//  ContentView.swift
//  JellyAmp
//
//  Root view that shows onboarding or main app based on authentication
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var jellyfinService = JellyfinService.shared

    var body: some View {
        Group {
            if jellyfinService.isAuthenticated {
                // User is authenticated - show main app
                MainTabView()
            } else {
                // User not authenticated - show onboarding
                OnboardingView()
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
