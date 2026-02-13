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
    @ObservedObject var themeManager = ThemeManager.shared
    @Environment(\.dismiss) var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass

    @State private var albums: [Album] = []
    @State private var isLoadingAlbums = true
    // Navigation handled by NavigationStack
    @State private var viewMode: ArtistViewMode = .allAlbums
    @State private var selectedYear: Int?
    @State private var isShuffling = false
    @State private var showNowPlaying = false
    @State private var isFavorite: Bool
    @Namespace private var playerAnimation

    init(artist: Artist) {
        self.artist = artist
        _isFavorite = State(initialValue: artist.isFavorite)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main Content
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

                ScrollView {
                    VStack(spacing: 0) {
                        // Hero Header with Artist Image (extends behind status bar)
                        artistHeaderSection
                            .padding(.top, -60) // Pull up behind status bar

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

                // Navigation handled by NavigationStack
            }

        }
        .ignoresSafeArea(.keyboard)
        .onAppear {
            Task {
                await fetchArtistAlbums()
            }
        }
        .navigationDestination(for: Album.self) { album in
            AlbumDetailView(album: album)
        }
        .fullScreenCover(isPresented: $showNowPlaying) {
            NowPlayingView(namespace: playerAnimation)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(.ultraThinMaterial, in: Circle())
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
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

    // MARK: - Toggle Favorite
    private func toggleFavorite() {
        // Optimistic UI update
        withAnimation(.spring(response: 0.3)) {
            isFavorite.toggle()
        }

        // Call API in background
        Task {
            do {
                if isFavorite {
                    try await jellyfinService.markFavorite(itemId: artist.id)
                } else {
                    try await jellyfinService.unmarkFavorite(itemId: artist.id)
                }
            } catch {
                // Revert on failure
                await MainActor.run {
                    withAnimation(.spring(response: 0.3)) {
                        isFavorite.toggle()
                    }
                }
                print("Error toggling favorite: \(error)")
            }
        }
    }

    // MARK: - Artist Header Section
    private var artistHeaderSection: some View {
        VStack(spacing: 0) {
            // Large artist artwork/gradient
            ZStack {
                if let artworkURL = artist.artworkURL, let url = URL(string: artworkURL) {
                    GeometryReader { geo in
                        CachedAsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                placeholderArtistHeader
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: geo.size.width, height: 280)
                                    .clipped()
                            case .failure:
                                placeholderArtistHeader
                            @unknown default:
                                placeholderArtistHeader
                            }
                        }
                    }
                    .frame(height: 280)
                    .clipped()
                } else {
                    placeholderArtistHeader
                }
            }
            .frame(height: 280)
            .clipped()
            .overlay(
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.jellyAmpBackground.opacity(0.8)
                    ],
                    startPoint: .center,
                    endPoint: .bottom
                )
            )

            // Artist Name & Stats
            VStack(spacing: 20) {
                Text(artist.name)
                    .font(.title.weight(.bold))
                    .foregroundColor(Color.jellyAmpText)
                    .multilineTextAlignment(.center)
                    .neonGlow(color: .jellyAmpAccent, radius: 6)
                    .padding(.top, -40)
                    .padding(.horizontal, 20)

                // Action Buttons
                HStack(spacing: 12) {
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
                                    .font(.headline.weight(.semibold))
                            }
                            Text(isShuffling ? "LOADING..." : "SHUFFLE")
                                .font(.body.weight(.bold))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.jellyAmpAccent, Color.jellyAmpTertiary],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                        .neonGlow(color: .jellyAmpAccent, radius: 6)
                    }
                    .disabled(isShuffling)
                    .accessibilityLabel("Shuffle all songs by artist")

                    // Favorite Button
                    Button {
                        toggleFavorite()
                    } label: {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .font(.title3.weight(.semibold))
                            .foregroundColor(isFavorite ? .neonPink : .white)
                            .frame(width: 56, height: 56)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(
                                        Circle()
                                            .stroke(Color.jellyAmpSecondary.opacity(isFavorite ? 0.8 : 0.5), lineWidth: 1)
                                    )
                            )
                            .neonGlow(color: .jellyAmpSecondary, radius: isFavorite ? 6 : 4)
                    }
                    .accessibilityLabel(isFavorite ? "Remove artist from favorites" : "Add artist to favorites")
                }

                if artist.albumCount > 0 {
                    HStack(spacing: 8) {
                        Image(systemName: "music.note.list")
                            .font(.caption)
                            .foregroundColor(.neonCyan)
                        Text("\(artist.albumCount) album\(artist.albumCount == 1 ? "" : "s")")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.jellyAmpTextSecondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.jellyAmpAccent.opacity(0.3), lineWidth: 1)
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
                    .font(.headline.weight(.semibold))
                    .foregroundColor(Color.jellyAmpText)
            }

            Text(bio)
                .font(.subheadline)
                .foregroundColor(.jellyAmpTextSecondary)
                .lineSpacing(8)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.jellyAmpAccent.opacity(0.2), lineWidth: 1)
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
                    Color.jellyAmpAccent.opacity(0.6),
                    Color.jellyAmpSecondary.opacity(0.6),
                    Color.jellyAmpTertiary.opacity(0.7)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 280)

            // Artist icon overlay
            Image(systemName: "person.circle.fill")
                .font(.largeTitle)
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
                        .font(.title3.weight(.bold))
                        .foregroundColor(Color.jellyAmpText)

                    if !albums.isEmpty {
                        Text("\(albums.count) album\(albums.count == 1 ? "" : "s")")
                            .font(.jellyAmpCaption)
                            .foregroundColor(.jellyAmpTextSecondary)
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
                                .font(.body.weight(.semibold))
                                .foregroundColor(viewMode == .allAlbums ? .black : .neonCyan)
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .fill(viewMode == .allAlbums ? Color.jellyAmpAccent : Color.white.opacity(0.1))
                                )
                                .overlay(
                                    Circle()
                                        .stroke(Color.jellyAmpAccent.opacity(0.5), lineWidth: 1)
                                )
                        }

                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                viewMode = .byYear
                            }
                        } label: {
                            Image(systemName: "calendar")
                                .font(.body.weight(.semibold))
                                .foregroundColor(viewMode == .byYear ? .black : .neonPink)
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .fill(viewMode == .byYear ? Color.jellyAmpSecondary : Color.white.opacity(0.1))
                                )
                                .overlay(
                                    Circle()
                                        .stroke(Color.jellyAmpSecondary.opacity(0.5), lineWidth: 1)
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
                            .tint(.jellyAmpAccent)
                        Text("Loading albums...")
                            .font(.jellyAmpCaption)
                            .foregroundColor(.jellyAmpTextSecondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 40)
            } else if albums.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "music.note.list")
                            .font(.title)
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("No albums found")
                            .font(.jellyAmpBody)
                            .foregroundColor(.jellyAmpTextSecondary)
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
                NavigationLink(value: album) {
                    AlbumListRow(album: album)
                }
                .background(Color.jellyAmpMidBackground.opacity(0.3))
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
                    onAlbumTap: { _ in
                        // Navigation now handled by NavigationLink
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
                .font(.system(.title3, design: .monospaced).weight(.bold))
                .foregroundColor(.neonCyan)

            Text(label)
                .font(.jellyAmpCaption)
                .foregroundColor(.jellyAmpTextSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.1))
        )
        .overlay(
            Capsule()
                .stroke(Color.jellyAmpAccent.opacity(0.3), lineWidth: 1)
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
                        .font(.title.weight(.bold))
                        .foregroundColor(Color.jellyAmpText)

                    Spacer()

                    // Album count badge
                    HStack(spacing: 8) {
                        Text("\(albums.count)")
                            .font(.headline.weight(.bold))
                            .foregroundColor(.neonCyan)
                        Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.right.circle.fill")
                            .font(.title3.weight(.semibold))
                            .foregroundColor(.neonCyan)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.jellyAmpAccent.opacity(0.15))
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
                                    Color.jellyAmpAccent.opacity(0.3),
                                    Color.jellyAmpSecondary.opacity(0.2)
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
                        NavigationLink(value: album) {
                            AlbumListRow(album: album)
                        }
                        .background(Color.jellyAmpMidBackground.opacity(0.2))
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
