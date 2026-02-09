//
//  LibraryView.swift
//  JellyAmp Watch
//
//  Browse music library on Apple Watch
//

import SwiftUI

struct LibraryView: View {
    @ObservedObject var jellyfinService = WatchJellyfinService.shared
    @State private var artists: [WatchArtist] = []
    @State private var albums: [WatchAlbum] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedTab = 0

    private let tabs = ["Artists", "Albums"]

    var body: some View {
        VStack(spacing: 0) {
            if !jellyfinService.isAuthenticated {
                notAuthenticatedView
            } else {
                // Tab selector
                if !artists.isEmpty || !albums.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(0..<tabs.count, id: \.self) { index in
                            Button(action: {
                                selectedTab = index
                            }) {
                                Text(tabs[index])
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(selectedTab == index ? Color.cyan.opacity(0.2) : Color.gray.opacity(0.2))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 4)
                                                    .stroke(selectedTab == index ? Color.cyan : Color.clear, lineWidth: 1)
                                            )
                                    )
                                    .foregroundColor(selectedTab == index ? .cyan : .secondary)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.top, 4)
                }

                // Content
                if isLoading {
                    Spacer()
                    ProgressView("Loading...")
                    Spacer()
                } else if let error = errorMessage {
                    errorView(error)
                } else if selectedTab == 0 {
                    if artists.isEmpty {
                        emptyView(type: "Artists")
                    } else {
                        artistsList
                    }
                } else {
                    if albums.isEmpty {
                        emptyView(type: "Albums")
                    } else {
                        albumsList
                    }
                }
            }
        }
        .navigationTitle("Library")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadLibrary()
        }
        .onChange(of: selectedTab) {
            if selectedTab == 1 && albums.isEmpty {
                Task {
                    await loadAlbums()
                }
            }
        }
    }

    // MARK: - Artists List

    private var artistsList: some View {
        List(artists) { artist in
            NavigationLink(destination: ArtistDetailView(artist: artist)) {
                HStack {
                    Image(systemName: "music.mic")
                        .font(.body)
                        .foregroundColor(.cyan)
                        .frame(width: 30)

                    Text(artist.name)
                        .font(.headline)
                        .lineLimit(1)
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(PlainListStyle())
    }

    // MARK: - Albums List

    private var albumsList: some View {
        List(albums) { album in
            NavigationLink(destination: AlbumDetailView(album: album)) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(album.name)
                        .font(.headline)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Text(album.artist)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if let year = album.year {
                            Text("•")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(String(year))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .lineLimit(1)
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(PlainListStyle())
    }

    // MARK: - Empty/Error States

    private var notAuthenticatedView: some View {
        VStack(spacing: 12) {
            Image(systemName: "music.note.list")
                .font(.largeTitle)
                .foregroundColor(.secondary)

            Text("Not Signed In")
                .font(.headline)

            Text("Sign in from iPhone or Settings")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private func emptyView(type: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "music.note")
                .font(.largeTitle)
                .foregroundColor(.secondary)

            Text("No \(type)")
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
                Task { await loadLibrary() }
            }
        }
        .padding()
    }

    // MARK: - Data Loading

    private func loadLibrary() async {
        guard jellyfinService.isAuthenticated else { return }

        isLoading = true
        errorMessage = nil

        do {
            artists = try await jellyfinService.fetchArtists()
            isLoading = false
        } catch {
            errorMessage = userFriendlyError(error)
            isLoading = false
        }
    }

    private func loadAlbums() async {
        do {
            albums = try await jellyfinService.fetchAlbums()
        } catch {
            errorMessage = userFriendlyError(error)
        }
    }

    private func userFriendlyError(_ error: Error) -> String {
        // Convert technical errors to user-friendly messages
        let nsError = error as NSError

        switch nsError.code {
        case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
            return "No internet. Check connection."
        case NSURLErrorTimedOut:
            return "Request timed out. Try again."
        case NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost:
            return "Cannot connect to server."
        case NSURLErrorUserAuthenticationRequired, 401:
            return "Authentication failed."
        default:
            return error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        LibraryView()
    }
}
