//
//  SettingsView.swift
//  JellyAmp
//
//  Settings view with Jellyfin server management and sign out
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var jellyfinService = JellyfinService.shared
    @State private var showSignOutConfirmation = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Dark background
                Color.darkBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header with app icon/logo
                        headerSection

                        // Server Info Section
                        serverInfoSection

                        // Account Section
                        accountSection

                        // Danger Zone
                        signOutSection

                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .confirmationDialog("Sign Out", isPresented: $showSignOutConfirmation) {
            Button("Sign Out", role: .destructive) {
                jellyfinService.signOut()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to sign out? You'll need to reconnect to your Jellyfin server.")
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            // App Icon/Logo Area
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.neonCyan, .neonPink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .blur(radius: 20)

                Image(systemName: "music.note")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
                    .neonGlow(color: .neonCyan, radius: 10)
            }
            .frame(width: 80, height: 80)

            Text("JellyAmp")
                .font(.jellyAmpTitle)
                .foregroundColor(.white)

            Text("Version 1.0")
                .font(.jellyAmpMono)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    // MARK: - Server Info Section

    private var serverInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Server")
                .font(.jellyAmpHeadline)
                .foregroundColor(.neonCyan)

            VStack(alignment: .leading, spacing: 12) {
                // Server URL
                HStack {
                    Image(systemName: "server.rack")
                        .foregroundColor(.neonPurple)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Server URL")
                            .font(.jellyAmpBody)
                            .foregroundColor(.secondary)

                        Text(jellyfinService.baseURL.isEmpty ? "Not configured" : jellyfinService.baseURL)
                            .font(.jellyAmpMono)
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }

                    Spacer()
                }

                Divider()
                    .background(Color.white.opacity(0.1))

                // Connection Status
                HStack {
                    Image(systemName: jellyfinService.isAuthenticated ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(jellyfinService.isAuthenticated ? .neonGreen : .neonPink)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Status")
                            .font(.jellyAmpBody)
                            .foregroundColor(.secondary)

                        Text(jellyfinService.isAuthenticated ? "Connected" : "Disconnected")
                            .font(.jellyAmpMono)
                            .foregroundColor(jellyfinService.isAuthenticated ? .neonGreen : .neonPink)
                    }

                    Spacer()
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.darkMid)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [.neonCyan.opacity(0.3), .neonPurple.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
        }
    }

    // MARK: - Account Section

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Account")
                .font(.jellyAmpHeadline)
                .foregroundColor(.neonCyan)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.neonCyan)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("User")
                            .font(.jellyAmpBody)
                            .foregroundColor(.secondary)

                        Text(jellyfinService.currentUser?.Name ?? "Unknown")
                            .font(.jellyAmpMono)
                            .foregroundColor(.white)
                    }

                    Spacer()
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.darkMid)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [.neonPink.opacity(0.3), .neonPurple.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
        }
    }

    // MARK: - Sign Out Section

    private var signOutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Danger Zone")
                .font(.jellyAmpHeadline)
                .foregroundColor(.neonPink)

            Button {
                showSignOutConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Sign Out")
                        .font(.jellyAmpHeadline)
                    Spacer()
                }
                .foregroundColor(.white)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [.neonPink.opacity(0.2), .red.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    LinearGradient(
                                        colors: [.neonPink, .red],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                )
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
