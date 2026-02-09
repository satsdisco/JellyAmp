//
//  WatchOnboardingView.swift
//  JellyAmp Watch Watch App
//
//  Onboarding view for Apple Watch when no credentials are available
//

import SwiftUI

struct WatchOnboardingView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "iphone.and.watch")
                .font(.title)
                .foregroundColor(.blue)
            
            Text("Sign In Required")
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Text("Please sign in on your iPhone first, then credentials will sync automatically.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    WatchOnboardingView()
}