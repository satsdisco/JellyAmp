//
//  AuthChoiceView.swift
//  JellyAmp
//
//  Choose authentication method: Quick Connect or Username/Password
//

import SwiftUI

struct AuthChoiceView: View {
    @ObservedObject var jellyfinService = JellyfinService.shared
    @State private var isQuickConnectAvailable = false
    @State private var isChecking = true

    let onQuickConnect: () -> Void
    let onPasswordLogin: () -> Void
    let onBack: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.jellyAmpBackground,
                    Color.jellyAmpMidBackground,
                    Color.jellyAmpBackground
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack {
                // Back button
                HStack {
                    Button {
                        onBack()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(.body)
                        .foregroundColor(Color.jellyAmpText)
                        .padding(12)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                        )
                    }
                    .accessibilityLabel("Go back to server setup")
                    .padding(.leading, 20)
                    .padding(.top, 60)
                    Spacer()
                }

                Spacer()

                VStack(spacing: 40) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.jellyAmpAccent.opacity(0.3),
                                        Color.jellyAmpSecondary.opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)

                        Image(systemName: "person.badge.key.fill")
                            .font(.title)
                            .foregroundColor(Color.jellyAmpText)
                    }

                    VStack(spacing: 12) {
                        Text("Sign In")
                            .font(.title2.weight(.bold))
                            .foregroundColor(Color.jellyAmpText)

                        Text("Choose how to authenticate")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }

                    VStack(spacing: 16) {
                        // Username & Password button (always available)
                        Button(action: onPasswordLogin) {
                            HStack(spacing: 16) {
                                Image(systemName: "person.fill")
                                    .font(.title3)
                                    .frame(width: 24)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Username & Password")
                                        .font(.body.weight(.semibold))
                                    Text("Sign in with your Jellyfin credentials")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .foregroundColor(Color.jellyAmpText)
                            .padding(20)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.jellyAmpAccent.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                        .accessibilityLabel("Sign in with username and password")

                        // Quick Connect button
                        Button(action: onQuickConnect) {
                            HStack(spacing: 16) {
                                Image(systemName: "qrcode")
                                    .font(.title3)
                                    .frame(width: 24)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Quick Connect")
                                        .font(.body.weight(.semibold))
                                    Text(isChecking ? "Checking availability..." : (isQuickConnectAvailable ? "Available on this server" : "Not available on this server"))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                if isChecking {
                                    ProgressView()
                                        .tint(.secondary)
                                        .scaleEffect(0.7)
                                } else {
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .foregroundColor(isQuickConnectAvailable || isChecking ? Color.jellyAmpText : .secondary)
                            .padding(20)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.jellyAmpTertiary.opacity(0.2), lineWidth: 1)
                                    )
                            )
                        }
                        .disabled(!isQuickConnectAvailable || isChecking)
                        .accessibilityLabel("Sign in with Quick Connect")
                    }
                    .padding(.horizontal, 30)
                }

                Spacer()
            }
        }
        .task {
            // Check Quick Connect availability in background
            do {
                isQuickConnectAvailable = try await jellyfinService.checkQuickConnect()
            } catch {
                isQuickConnectAvailable = false
            }
            isChecking = false
        }
    }
}

#Preview {
    AuthChoiceView(onQuickConnect: {}, onPasswordLogin: {}, onBack: {})
}
