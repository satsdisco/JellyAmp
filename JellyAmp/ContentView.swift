//
//  ContentView.swift
//  JellyAmp
//
//  Root view that shows onboarding or main app based on authentication
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var jellyfinService = JellyfinService.shared
    @AppStorage("preferredAppearance") private var preferredAppearance = "always_dark"
    
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
        .preferredColorScheme(colorScheme)
    }
    
    private var colorScheme: ColorScheme? {
        switch preferredAppearance {
        case "system":
            return nil
        case "always_dark":
            return .dark
        default:
            return .dark
        }
    }
}

#Preview {
    ContentView()
}
