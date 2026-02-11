//
//  OnboardingView.swift
//  JellyAmp
//
//  Onboarding flow coordinator
//

import SwiftUI

struct OnboardingView: View {
    @ObservedObject var jellyfinService = JellyfinService.shared
    @State private var currentStep: OnboardingStep = .serverSetup

    enum OnboardingStep {
        case serverSetup
        case authChoice
        case quickConnect
        case passwordLogin
    }

    var body: some View {
        ZStack {
            switch currentStep {
            case .serverSetup:
                ServerSetupView {
                    withAnimation(.spring(response: 0.4)) {
                        currentStep = .authChoice
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

            case .authChoice:
                AuthChoiceView(
                    onQuickConnect: {
                        withAnimation(.spring(response: 0.4)) {
                            currentStep = .quickConnect
                        }
                    },
                    onPasswordLogin: {
                        withAnimation(.spring(response: 0.4)) {
                            currentStep = .passwordLogin
                        }
                    },
                    onBack: {
                        withAnimation(.spring(response: 0.4)) {
                            currentStep = .serverSetup
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

            case .quickConnect:
                QuickConnectView {
                    // Success
                } onBack: {
                    withAnimation(.spring(response: 0.4)) {
                        currentStep = .authChoice
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

            case .passwordLogin:
                PasswordLoginView {
                    // Success — JellyfinService updates isAuthenticated
                } onBack: {
                    withAnimation(.spring(response: 0.4)) {
                        currentStep = .authChoice
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

#Preview {
    OnboardingView()
}
