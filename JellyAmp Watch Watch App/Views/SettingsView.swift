//
//  SettingsView.swift
//  JellyAmp Watch
//
//  Settings and account management
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var jellyfinService = WatchJellyfinService.shared
    @State private var showSignOutConfirmation = false

    var body: some View {
        List {
            if jellyfinService.isAuthenticated {
                // Account section
                Section("Account") {
                    HStack {
                        Text("User")
                        Spacer()
                        Text(jellyfinService.userName)
                            .foregroundColor(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Current user: \(jellyfinService.userName)")

                    HStack {
                        Text("Server")
                        Spacer()
                        Text(serverDomain)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Connected to server: \(serverDomain)")
                }

                // Sign out
                Section {
                    Button(role: .destructive) {
                        showSignOutConfirmation = true
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                    .accessibilityLabel("Sign out of current account")
                    .accessibilityHint("Double tap to sign out, requires confirmation")
                }
            } else {
                // Not authenticated
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.badge.exclamationmark")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)

                        Text("Not Signed In")
                            .font(.headline)

                        Text("Sign in from your iPhone to sync your Jellyfin account")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            }

            // App info
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0")
                        .foregroundColor(.secondary)
                }
            }
        }
        .focusable(true) // Enable Digital Crown scrolling
        .navigationTitle("Settings")
        .containerBackground(.black.gradient, for: .navigation)
        .confirmationDialog("Sign Out", isPresented: $showSignOutConfirmation) {
            Button("Sign Out", role: .destructive) {
                jellyfinService.signOut()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure? You'll need to re-sync from your iPhone.")
        }
    }

    private var serverDomain: String {
        guard let url = URL(string: jellyfinService.baseURL) else {
            return jellyfinService.baseURL
        }
        return url.host ?? jellyfinService.baseURL
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
