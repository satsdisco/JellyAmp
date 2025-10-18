//
//  OnboardingView.swift
//  JellyAmp
//
//  Onboarding flow coordinator - iOS 26 Liquid Glass + Cypherpunk
//

import SwiftUI

struct OnboardingView: View {
    @ObservedObject var jellyfinService = JellyfinService.shared
    @State private var currentStep: OnboardingStep = .serverSetup

    enum OnboardingStep {
        case serverSetup
        case quickConnect
    }

    var body: some View {
        ZStack {
            switch currentStep {
            case .serverSetup:
                ServerSetupView {
                    withAnimation(.spring(response: 0.4)) {
                        currentStep = .quickConnect
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

            case .quickConnect:
                QuickConnectView {
                    // Authentication successful - JellyfinService updates isAuthenticated
                    // ContentView will automatically switch to MainTabView
                } onBack: {
                    withAnimation(.spring(response: 0.4)) {
                        currentStep = .serverSetup
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Preview
#Preview {
    OnboardingView()
}
