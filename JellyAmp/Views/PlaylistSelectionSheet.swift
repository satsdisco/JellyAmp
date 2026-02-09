//
//  PlaylistSelectionSheet.swift
//  JellyAmp
//
//  Sheet for selecting a playlist to add tracks to
//

import SwiftUI

struct PlaylistSelectionSheet: View {
    @ObservedObject var jellyfinService = JellyfinService.shared
    @Environment(\.dismiss) var dismiss
    @State private var playlists: [Playlist] = []
    @State private var isLoading = true
    @State private var isAdding = false
    @State private var selectedPlaylistId: String?
    @State private var errorMessage: String?

    let trackIds: [String]  // Track IDs to add
    let onTracksAdded: () -> Void  // Callback when tracks are added

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

                VStack(spacing: 0) {
                    if isLoading {
                        // Loading state
                        VStack(spacing: 16) {
                            ProgressView()
                                .tint(.neonPink)
                                .scaleEffect(1.5)
                            Text("Loading playlists...")
                                .font(.jellyAmpBody)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if playlists.isEmpty {
                        // Empty state
                        VStack(spacing: 20) {
                            Image(systemName: "music.note.list")
                                .font(.title)
                                .foregroundColor(.secondary.opacity(0.5))

                            Text("No Playlists")
                                .font(.jellyAmpTitle)
                                .foregroundColor(Color.jellyAmpText)

                            Text("Create a playlist first to add tracks to it")
                                .font(.jellyAmpBody)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        // Playlist list
                        ScrollView {
                            VStack(spacing: 12) {
                                Text("Select a playlist")
                                    .font(.jellyAmpCaption)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 20)
                                    .padding(.top, 16)

                                VStack(spacing: 1) {
                                    ForEach(playlists) { playlist in
                                        PlaylistSelectionRow(
                                            playlist: playlist,
                                            isAdding: isAdding && selectedPlaylistId == playlist.id
                                        ) {
                                            addToPlaylist(playlistId: playlist.id)
                                        }
                                    }
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.jellyAmpMidBackground)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.neonPink.opacity(0.2), lineWidth: 1)
                                )
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
                                    .padding(.top, 8)
                                }

                                // Bottom padding
                                Color.clear.frame(height: 20)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add to Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.neonPink)
                    .disabled(isAdding)
                }
            }
        }
        .onAppear {
            Task {
                await fetchPlaylists()
            }
        }
    }

    // MARK: - Fetch Playlists
    private func fetchPlaylists() async {
        isLoading = true

        do {
            let fetchedPlaylists = try await jellyfinService.fetchPlaylists()
            let baseURL = jellyfinService.baseURL
            let playlistModels = fetchedPlaylists.map { Playlist(from: $0, baseURL: baseURL) }

            await MainActor.run {
                self.playlists = playlistModels
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = "Failed to load playlists"
                print("Error fetching playlists: \(error)")
            }
        }
    }

    // MARK: - Add to Playlist
    private func addToPlaylist(playlistId: String) {
        guard !isAdding else { return }

        selectedPlaylistId = playlistId
        isAdding = true
        errorMessage = nil

        Task {
            do {
                try await jellyfinService.addToPlaylist(playlistId: playlistId, trackIds: trackIds)

                await MainActor.run {
                    isAdding = false
                    onTracksAdded()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isAdding = false
                    selectedPlaylistId = nil
                    errorMessage = "Failed to add tracks. Please try again."
                    print("Error adding to playlist: \(error)")
                }
            }
        }
    }
}

// MARK: - Playlist Selection Row
struct PlaylistSelectionRow: View {
    let playlist: Playlist
    let isAdding: Bool
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 16) {
                // Playlist icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.neonPink.opacity(0.4),
                                    Color.neonPurple.opacity(0.4)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)

                    Image(systemName: "music.note.list")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.6))
                }

                // Playlist info
                VStack(alignment: .leading, spacing: 4) {
                    Text(playlist.name)
                        .font(.jellyAmpBody)
                        .foregroundColor(Color.jellyAmpText)
                        .lineLimit(1)

                    Text("\(playlist.trackCount) track\(playlist.trackCount == 1 ? "" : "s")")
                        .font(.jellyAmpCaption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Add button / Loading indicator
                if isAdding {
                    ProgressView()
                        .tint(.neonPink)
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.neonPink)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.jellyAmpMidBackground)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isAdding)
    }
}

// MARK: - Preview
#Preview {
    PlaylistSelectionSheet(trackIds: ["1", "2", "3"]) {
        print("Tracks added!")
    }
}
