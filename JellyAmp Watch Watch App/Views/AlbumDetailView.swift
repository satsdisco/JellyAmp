//
//  AlbumDetailView.swift
//  JellyAmp Watch
//
//  Album track list with play controls
//

import SwiftUI

struct AlbumDetailView: View {
    let album: WatchAlbum

    @ObservedObject var jellyfinService = WatchJellyfinService.shared
    @ObservedObject var playerManager = WatchPlayerManager.shared

    @State private var tracks: [WatchTrack] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading tracks...")
            } else if let error = errorMessage {
                errorView(error)
            } else if tracks.isEmpty {
                emptyView
            } else {
                tracksList
            }
        }
        .navigationTitle(album.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadTracks()
        }
    }

    // MARK: - Tracks List

    private var tracksList: some View {
        List {
            // Play All button
            Button {
                playerManager.play(tracks: tracks)
            } label: {
                Label("Play All", systemImage: "play.fill")
                    .foregroundColor(.cyan)
                    .fontWeight(.semibold)
            }

            // Track list
            ForEach(Array(tracks.enumerated()), id: \.element.id) { index, track in
                Button {
                    playerManager.play(tracks: tracks, startingAt: index)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(track.name)
                            .font(.headline)
                            .lineLimit(1)
                            .foregroundColor(.primary)

                        Text(track.artist)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    // MARK: - Empty/Error States

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "music.note")
                .font(.largeTitle)
                .foregroundColor(.secondary)

            Text("No Tracks")
                .font(.headline)
        }
        .padding()
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.red)

            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Retry") {
                Task { await loadTracks() }
            }
        }
        .padding()
    }

    // MARK: - Data Loading

    private func loadTracks() async {
        isLoading = true
        errorMessage = nil

        do {
            tracks = try await jellyfinService.fetchAlbumTracks(albumId: album.id)
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}
