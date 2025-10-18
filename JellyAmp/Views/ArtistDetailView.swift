//
//  ArtistDetailView.swift
//  JellyAmp
//
//  Artist detail page with discography - iOS 26 Liquid Glass + Cypherpunk
//

import SwiftUI

// MARK: - View Mode Enum
enum ArtistViewMode {
    case allAlbums
    case byYear
}

struct ArtistDetailView: View {
    let artist: Artist
    @ObservedObject var jellyfinService = JellyfinService.shared
    @ObservedObject var playerManager = PlayerManager.shared
    @Environment(\.dismiss) var dismiss

    @State private var albums: [Album] = []
    @State private var isLoadingAlbums = true
    @State private var selectedAlbum: Album?
    @State private var viewMode: ArtistViewMode = .allAlbums
    @State private var selectedYear: Int?
    @State private var isShuffling = false

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color.darkBackground,
                    Color.darkMid,
                    Color.darkBackground
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Hero Header with Artist Image
                    artistHeaderSection

                    // Bio Section
                    if let bio = artist.bio {
                        bioSection(bio: bio)
                    }

                    // Albums Section
                    albumsSection

                    // Bottom padding for mini player
                    Color.clear.frame(height: 100)
                }
            }

            // Back Button (floating)
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(Color.darkMid)
                                    .glassEffect(.regular)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.neonCyan.opacity(0.5), lineWidth: 1)
                                    )
                            )
                            .neonGlow(color: .neonCyan, radius: 8)
                    }
                    .padding(.leading, 20)
                    .padding(.top, 60)

                    Spacer()
                }

                Spacer()
            }
        }
        .onAppear {
            Task {
                await fetchArtistAlbums()
            }
        }
        .sheet(item: $selectedAlbum) { album in
            AlbumDetailView(album: album)
        }
    }

    // MARK: - Fetch Artist Data
    private func fetchArtistAlbums() async {
        isLoadingAlbums = true

        do {
            // Fetch albums for this artist
            let items = try await jellyfinService.fetchMusicItems(
                includeItemTypes: "MusicAlbum",
                artistIds: artist.id
            )

            let baseURL = jellyfinService.baseURL
            self.albums = items.map { Album(from: $0, baseURL: baseURL) }
            isLoadingAlbums = false
        } catch {
            print("Error fetching artist albums: \(error)")
            isLoadingAlbums = false
        }
    }

    // MARK: - Artist Header Section
    private var artistHeaderSection: some View {
        VStack(spacing: 0) {
            // Large artist artwork/gradient
            ZStack {
                if let artworkURL = artist.artworkURL, let url = URL(string: artworkURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            placeholderArtistHeader
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 320)
                                .clipped()
                        case .failure:
                            placeholderArtistHeader
                        @unknown default:
                            placeholderArtistHeader
                        }
                    }
                    .frame(height: 320)
                } else {
                    placeholderArtistHeader
                }
            }
            .overlay(
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.darkBackground.opacity(0.8)
                    ],
                    startPoint: .center,
                    endPoint: .bottom
                )
            )

            // Artist Name & Stats
            VStack(spacing: 20) {
                Text(artist.name)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .neonGlow(color: .neonCyan, radius: 12)
                    .padding(.top, -40)
                    .padding(.horizontal, 20)

                // Shuffle Button
                Button {
                    shuffleArtist()
                } label: {
                    HStack(spacing: 10) {
                        if isShuffling {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                .scaleEffect(0.9)
                        } else {
                            Image(systemName: "shuffle")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        Text(isShuffling ? "LOADING..." : "SHUFFLE")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.neonCyan, Color.neonPurple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .neonGlow(color: .neonCyan, radius: 12)
                }
                .disabled(isShuffling)

                if artist.albumCount > 0 {
                    HStack(spacing: 8) {
                        Image(systemName: "music.note.list")
                            .font(.caption)
                            .foregroundColor(.neonCyan)
                        Text("\(artist.albumCount) album\(artist.albumCount == 1 ? "" : "s")")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                            .glassEffect(.regular)
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.neonCyan.opacity(0.3), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
    }

    // MARK: - Bio Section
    private func bioSection(bio: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .font(.caption)
                    .foregroundColor(.neonCyan)
                Text("About")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }

            Text(bio)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .lineSpacing(8)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .glassEffect(.regular)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.neonCyan.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 30)
    }

    private var placeholderArtistHeader: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color.neonCyan.opacity(0.6),
                    Color.neonPink.opacity(0.6),
                    Color.neonPurple.opacity(0.7)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 320)

            // Artist icon overlay
            Image(systemName: "person.circle.fill")
                .font(.system(size: 120))
                .foregroundColor(.white.opacity(0.3))
        }
    }

    // MARK: - Albums Section
    private var albumsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Section Header with View Toggle
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Discography")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    if !albums.isEmpty {
                        Text("\(albums.count) album\(albums.count == 1 ? "" : "s")")
                            .font(.jellyAmpCaption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // View Mode Toggle
                if !albums.isEmpty {
                    HStack(spacing: 8) {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                viewMode = .allAlbums
                            }
                        } label: {
                            Image(systemName: "list.bullet")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(viewMode == .allAlbums ? .black : .neonCyan)
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .fill(viewMode == .allAlbums ? Color.neonCyan : Color.white.opacity(0.1))
                                        .glassEffect(.regular)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(Color.neonCyan.opacity(0.5), lineWidth: 1)
                                )
                        }

                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                viewMode = .byYear
                            }
                        } label: {
                            Image(systemName: "calendar")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(viewMode == .byYear ? .black : .neonPink)
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .fill(viewMode == .byYear ? Color.neonPink : Color.white.opacity(0.1))
                                        .glassEffect(.regular)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(Color.neonPink.opacity(0.5), lineWidth: 1)
                                )
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)

            if isLoadingAlbums {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        ProgressView()
                            .tint(.neonCyan)
                        Text("Loading albums...")
                            .font(.jellyAmpCaption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 40)
            } else if albums.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("No albums found")
                            .font(.jellyAmpBody)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 40)
            } else {
                // Switch between view modes
                if viewMode == .allAlbums {
                    allAlbumsView
                } else {
                    byYearView
                }
            }
        }
        .padding(.bottom, 30)
    }

    // MARK: - All Albums View
    private var allAlbumsView: some View {
        VStack(spacing: 0) {
            ForEach(albums.sorted(by: { ($0.year ?? 0) > ($1.year ?? 0) })) { album in
                AlbumListRow(album: album) {
                    selectedAlbum = album
                }
                .background(Color.darkMid.opacity(0.3))
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.98)))
    }

    // MARK: - By Year View
    private var byYearView: some View {
        VStack(spacing: 12) {
            ForEach(albumsByYear.keys.sorted(by: >), id: \.self) { year in
                YearSection(
                    year: year,
                    albums: albumsByYear[year] ?? [],
                    isExpanded: selectedYear == year,
                    onYearTap: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            selectedYear = (selectedYear == year) ? nil : year
                        }
                    },
                    onAlbumTap: { album in
                        selectedAlbum = album
                    }
                )
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.98)))
    }

    // MARK: - Computed Properties
    private var albumsByYear: [Int: [Album]] {
        Dictionary(grouping: albums) { album in
            album.year ?? 0
        }
    }

    // MARK: - Actions
    private func shuffleArtist() {
        guard !isShuffling else { return }

        isShuffling = true

        // Get tracks from albums (limit to prevent overwhelming server)
        Task {
            var allTracks: [Track] = []
            let maxTracks = 200 // Conservative limit
            let maxAlbums = 15 // Limit number of albums to fetch from

            // Shuffle albums first to get variety
            let shuffledAlbums = Array(albums.shuffled().prefix(maxAlbums))

            // Fetch tracks from albums until we hit the limit
            for album in shuffledAlbums {
                guard allTracks.count < maxTracks else { break }

                do {
                    let items = try await jellyfinService.fetchTracks(parentId: album.id)
                    let baseURL = jellyfinService.baseURL
                    let tracks = items.map { Track(from: $0, baseURL: baseURL) }
                    allTracks.append(contentsOf: tracks)
                } catch {
                    print("Error fetching tracks for album \(album.name): \(error)")
                    // Continue to next album instead of failing entirely
                    continue
                }

                // Delay to prevent overwhelming the server
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }

            // Shuffle and play
            await MainActor.run {
                isShuffling = false
                if !allTracks.isEmpty {
                    playerManager.play(tracks: allTracks.shuffled())
                } else {
                    print("No tracks found to shuffle")
                }
            }
        }
    }
}

// MARK: - Stat Badge Component
struct StatBadge: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundColor(.neonCyan)

            Text(label)
                .font(.jellyAmpCaption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.1))
                .glassEffect(.regular)
        )
        .overlay(
            Capsule()
                .stroke(Color.neonCyan.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Year Section Component
struct YearSection: View {
    let year: Int
    let albums: [Album]
    let isExpanded: Bool
    let onYearTap: () -> Void
    let onAlbumTap: (Album) -> Void

    private var yearString: String {
        year == 0 ? "Unknown" : String(year)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Year Header Button
            Button {
                onYearTap()
            } label: {
                HStack(alignment: .center) {
                    // Year Text
                    Text(yearString)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Spacer()

                    // Album count badge
                    HStack(spacing: 8) {
                        Text("\(albums.count)")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.neonCyan)
                        Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.right.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.neonCyan)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.neonCyan.opacity(0.15))
                    )
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .contentShape(Rectangle())
            }
            .overlay(
                // Bottom border only
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.neonCyan.opacity(0.3),
                                    Color.neonPink.opacity(0.2)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 1)
                }
            )

            // Expanded Album List
            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(albums.sorted(by: { ($0.year ?? 0) > ($1.year ?? 0) })) { album in
                        AlbumListRow(album: album) {
                            onAlbumTap(album)
                        }
                        .background(Color.darkMid.opacity(0.2))
                    }
                }
                .padding(.top, 8)
                .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .top)))
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ArtistDetailView(artist: Artist.mockArtists[0])
}
