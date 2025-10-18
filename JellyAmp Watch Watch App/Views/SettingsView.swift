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

                    HStack {
                        Text("Server")
                        Spacer()
                        Text(serverDomain)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                // Sign out
                Section {
                    Button(role: .destructive) {
                        showSignOutConfirmation = true
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
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
        .navigationTitle("Settings")
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
