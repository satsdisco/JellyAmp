//
//  ArtistDetailView.swift
//  JellyAmp Watch
//
//  Artist detail with albums, songs, and year filtering
//

import SwiftUI

struct ArtistDetailView: View {
    let artist: WatchArtist

    @ObservedObject var jellyfinService = WatchJellyfinService.shared
    @ObservedObject var playerManager = WatchPlayerManager.shared

    @State private var albums: [WatchAlbum] = []
    @State private var tracks: [WatchTrack] = []
    @State private var isLoading = true
    @State private var isLoadingTracks = false
    @State private var errorMessage: String?
    @State private var selectedTab = 0
    @State private var uniqueYears: [Int] = []
    @State private var selectedYear: Int? = nil

    private let tabs = [(label: "Albums", icon: "square.stack"), (label: "Songs", icon: "music.note"), (label: "Years", icon: "calendar")]

    var body: some View {
        VStack(spacing: 0) {
            // Compact tab selector
            if !albums.isEmpty || !tracks.isEmpty {
                HStack(spacing: 6) {
                    ForEach(0..<tabs.count, id: \.self) { index in
                        Button(action: {
                            selectedTab = index
                        }) {
                            VStack(spacing: 2) {
                                Image(systemName: tabs[index].icon)
                                    .font(.subheadline)
                                    .foregroundColor(selectedTab == index ? .cyan : .secondary)

                                Text(tabs[index].label)
                                    .font(.caption2.weight(selectedTab == index ? .medium : .regular))
                                    .foregroundColor(selectedTab == index ? .cyan : .secondary)
                            }
                            .frame(minWidth: 50)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedTab == index ? Color.cyan.opacity(0.2) : Color.gray.opacity(0.2))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(selectedTab == index ? Color.cyan : Color.clear, lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }

            // Content
            if isLoading {
                Spacer()
                ProgressView("Loading...")
                Spacer()
            } else if let error = errorMessage {
                Spacer()
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
                Spacer()
            } else if selectedTab == 0 {
                // Albums list with year filter
                if albums.isEmpty {
                    Spacer()
                    Text("No albums found")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                } else {
                    let filteredAlbums = selectedYear != nil ? albums.filter { $0.year == selectedYear } : albums

                    if !filteredAlbums.isEmpty {
                        List {
                            // Year filter indicator
                            if let year = selectedYear {
                                HStack {
                                    Text("Year: \(String(year))")
                                        .font(.caption.weight(.medium))
                                        .foregroundColor(.pink)

                                    Spacer()

                                    Button(action: {
                                        selectedYear = nil
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .padding(.vertical, 6)
                            }

                            ForEach(filteredAlbums) { album in
                                NavigationLink(destination: AlbumDetailView(album: album)) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(album.name)
                                            .font(.headline)
                                            .lineLimit(1)

                                        if let year = album.year {
                                            Text(String(year))
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                        .listStyle(PlainListStyle())
                    } else if let year = selectedYear {
                        Spacer()
                        Text("No albums for \(String(year))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            } else if selectedTab == 1 {
                // All songs list
                if isLoadingTracks {
                    Spacer()
                    ProgressView("Loading tracks...")
                    Spacer()
                } else if !tracks.isEmpty {
                    List {
                        // Play all button
                        Button(action: {
                            playerManager.play(tracks: tracks)
                        }) {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(Color.cyan.opacity(0.2))
                                        .frame(width: 32, height: 32)

                                    Image(systemName: "play.fill")
                                        .font(.subheadline)
                                        .foregroundColor(.cyan)
                                }

                                Text("Play All")
                                    .font(.subheadline.weight(.medium))

                                Spacer()

                                Text("\(tracks.count) tracks")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(PlainButtonStyle())

                        // Track list
                        ForEach(Array(tracks.enumerated()), id: \.element.id) { index, track in
                            Button(action: {
                                playerManager.play(tracks: tracks, startingAt: index)
                            }) {
                                HStack {
                                    Text("\(index + 1)")
                                        .font(.caption.weight(.medium))
                                        .foregroundColor(.cyan)
                                        .frame(width: 25, alignment: .trailing)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(track.name)
                                            .font(.subheadline.weight(.medium))
                                            .lineLimit(1)

                                        Text(track.album)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }

                                    Spacer()
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .listStyle(PlainListStyle())
                } else {
                    Spacer()
                    Text("No tracks available")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else if selectedTab == 2 {
                // Years view
                if uniqueYears.isEmpty {
                    Spacer()
                    Text("No year information")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            // All Years button
                            Button(action: {
                                selectedYear = nil
                                selectedTab = 0
                            }) {
                                HStack {
                                    Image(systemName: "calendar.badge.clock")
                                        .font(.subheadline)
                                        .foregroundColor(.pink)
                                    Text("All Years")
                                        .font(.subheadline.weight(.medium))
                                    Spacer()
                                    Text("\(albums.count)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(selectedYear == nil ? Color.pink.opacity(0.2) : Color.gray.opacity(0.2))
                                )
                            }
                            .buttonStyle(PlainButtonStyle())

                            // Individual years (descending order - newest first)
                            ForEach(uniqueYears.sorted(by: >), id: \.self) { year in
                                Button(action: {
                                    selectedYear = year
                                    selectedTab = 0
                                }) {
                                    HStack {
                                        Image(systemName: "calendar")
                                            .font(.caption)
                                            .foregroundColor(.pink.opacity(0.7))
                                        Text(String(year))
                                            .font(.subheadline.weight(.medium))
                                        Spacer()
                                        let albumCount = albums.filter { $0.year == year }.count
                                        Text("\(albumCount)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedYear == year ? Color.pink.opacity(0.2) : Color.gray.opacity(0.2))
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 8)
                    }
                }
            }
        }
        .navigationTitle(artist.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadArtistContent()
        }
        .onChange(of: selectedTab) { _ in
            if selectedTab == 1 && tracks.isEmpty && !isLoadingTracks {
                Task {
                    await loadTracks()
                }
            }
        }
    }

    private func loadArtistContent() async {
        // Load albums first
        await loadAlbums()
    }

    private func loadAlbums() async {
        do {
            albums = try await jellyfinService.fetchAlbums(artistId: artist.id)
            isLoading = false

            // Extract unique years
            uniqueYears = Array(Set(albums.compactMap { $0.year })).sorted(by: >)
        } catch {
            errorMessage = userFriendlyError(error)
            isLoading = false
        }
    }

    private func loadTracks() async {
        isLoadingTracks = true

        do {
            tracks = try await jellyfinService.fetchArtistTracks(artistId: artist.id)
            isLoadingTracks = false
        } catch {
            if errorMessage == nil {
                errorMessage = userFriendlyError(error)
            }
            isLoadingTracks = false
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
            return "Failed to load: \(error.localizedDescription)"
        }
    }
}
