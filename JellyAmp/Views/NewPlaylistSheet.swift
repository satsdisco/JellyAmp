//
//  NewPlaylistSheet.swift
//  JellyAmp
//
//  Sheet for creating a new playlist with name input
//

import SwiftUI

struct NewPlaylistSheet: View {
    @ObservedObject var jellyfinService = JellyfinService.shared
    @Environment(\.dismiss) var dismiss
    @State private var playlistName = ""
    @State private var isCreating = false
    @State private var errorMessage: String?

    let onPlaylistCreated: (String) -> Void  // Callback with new playlist ID

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
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

                VStack(spacing: 32) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.neonPink.opacity(0.3),
                                        Color.neonPurple.opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)

                        Image(systemName: "music.note.list")
                            .font(.title)
                            .foregroundColor(.neonPink)
                    }
                    .neonGlow(color: .neonPink, radius: 20)
                    .padding(.top, 20)

                    // Title
                    VStack(spacing: 8) {
                        Text("New Playlist")
                            .font(.title2.weight(.bold))
                            .foregroundColor(Color.jellyAmpText)
                            .neonGlow(color: .neonPink, radius: 8)

                        Text("Create a playlist to organize your music")
                            .font(.jellyAmpBody)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }

                    // Name Input
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Playlist Name")
                            .font(.jellyAmpCaption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)

                        TextField("My Awesome Playlist", text: $playlistName)
                            .font(.jellyAmpBody)
                            .foregroundColor(Color.jellyAmpText)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.neonPink.opacity(0.4), lineWidth: 1)
                                    )
                            )
                            .tint(.neonPink)
                            .submitLabel(.done)
                            .onSubmit {
                                if !playlistName.trimmingCharacters(in: .whitespaces).isEmpty {
                                    createPlaylist()
                                }
                            }
                    }
                    .padding(.horizontal, 20)

                    // Error message
                    if let error = errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.jellyAmpCaption)
                                .foregroundColor(.red)
                        }
                        .padding(.horizontal, 20)
                    }

                    Spacer()

                    // Create Button
                    Button {
                        createPlaylist()
                    } label: {
                        HStack(spacing: 12) {
                            if isCreating {
                                ProgressView()
                                    .tint(.black)
                                    .scaleEffect(0.9)
                            } else {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                            }
                            Text(isCreating ? "Creating..." : "Create Playlist")
                                .font(.jellyAmpBody)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    playlistName.trimmingCharacters(in: .whitespaces).isEmpty
                                    ? Color.gray
                                    : Color.neonPink
                                )
                        )
                        .neonGlow(
                            color: playlistName.trimmingCharacters(in: .whitespaces).isEmpty ? .clear : .neonPink,
                            radius: 12
                        )
                    }
                    .disabled(playlistName.trimmingCharacters(in: .whitespaces).isEmpty || isCreating)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.neonPink)
                    .disabled(isCreating)
                }
            }
        }
    }

    // MARK: - Create Playlist
    private func createPlaylist() {
        let trimmedName = playlistName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        isCreating = true
        errorMessage = nil

        Task {
            do {
                // Create empty playlist
                let playlistId = try await jellyfinService.createPlaylist(name: trimmedName, trackIds: [])

                await MainActor.run {
                    isCreating = false
                    onPlaylistCreated(playlistId)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isCreating = false
                    errorMessage = "Failed to create playlist. Please try again."
                    print("Error creating playlist: \(error)")
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    NewPlaylistSheet { playlistId in
        print("Created playlist: \(playlistId)")
    }
}
