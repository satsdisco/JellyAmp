//
//  NowPlayingView.swift
//  JellyAmp
//
//  Now Playing screen — redesigned to match PWA layout
//

import SwiftUI
import AVKit

struct NowPlayingView: View {
    @ObservedObject var playerManager = PlayerManager.shared
    @ObservedObject var jellyfinService = JellyfinService.shared
    @ObservedObject var themeManager = ThemeManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var isDraggingSlider = false
    @State private var sliderValue: Double = 0
    @State private var showQueue = false
    @State private var isFavorite = false
    @State private var showSleepTimer = false
    @State private var dominantColor: Color?
    @State private var artworkImage: Image?
    @ObservedObject var sleepTimer = SleepTimerManager.shared
    @State private var dragOffset: CGFloat = 0
    var namespace: Namespace.ID
    var onDismiss: (() -> Void)?

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background: blurred album art (PWA style)
                backgroundLayer

                // Content in ScrollView for safety
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Top Bar
                        topBar
                            .padding(.top, 8)

                        // Album Artwork — responsive
                        artworkSection(screenWidth: geo.size.width, screenHeight: geo.size.height)
                            .padding(.top, 16)

                        // Track Info + Favorite
                        trackInfoSection
                            .padding(.top, 20)

                        // Progress Slider
                        progressSection
                            .padding(.top, 24)

                        // Controls (PWA layout: shuffle | prev | play | next | repeat)
                        controlsSection
                            .padding(.top, 20)

                        // Secondary actions
                        secondaryActionsSection
                            .padding(.top, 16)

                        // Up Next preview
                        upNextSection
                            .padding(.top, 24)

                        // Bottom padding
                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .offset(y: max(0, dragOffset))
        .opacity(1.0 - Double(max(0, dragOffset)) / 500.0)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.height > 0 {
                        dragOffset = value.translation.height
                    }
                }
                .onEnded { value in
                    if value.translation.height > 150 || value.velocity.height > 500 {
                        if let onDismiss = onDismiss {
                            onDismiss()
                        } else {
                            dismiss()
                        }
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            dragOffset = 0
                        }
                    }
                }
        )
        .onChange(of: playerManager.currentTrack) { _, newTrack in
            isFavorite = newTrack?.isFavorite ?? false
            extractDominantColor(for: newTrack)
        }
        .onAppear {
            isFavorite = playerManager.currentTrack?.isFavorite ?? false
            extractDominantColor(for: playerManager.currentTrack)
        }
    }

    // MARK: - Background (blurred album art like PWA)
    private var backgroundLayer: some View {
        ZStack {
            Color.jellyAmpBackground
                .ignoresSafeArea()

            // Blurred album art background
            if let track = playerManager.currentTrack,
               let artworkURLString = track.artworkURL,
               let artworkURL = URL(string: artworkURLString) {
                CachedAsyncImage(url: artworkURL) { phase in
                    if case .success(let image) = phase {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .blur(radius: 80)
                            .scaleEffect(1.3)
                            .saturation(1.5)
                            .opacity(0.35)
                    }
                }
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.8), value: track.id)
            }

            // Gradient overlay for readability
            LinearGradient(
                colors: [
                    Color.jellyAmpBackground.opacity(0.5),
                    Color.jellyAmpBackground.opacity(0.7),
                    Color.jellyAmpBackground.opacity(0.9)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Dominant color tint
            if let dominantColor = dominantColor {
                dominantColor
                    .opacity(0.15)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.8), value: dominantColor != nil)
            }
        }
        .matchedGeometryEffect(id: "playerBg", in: namespace)
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            Button {
                if let onDismiss = onDismiss {
                    onDismiss()
                } else {
                    dismiss()
                }
            } label: {
                Image(systemName: "chevron.down")
                    .font(.body.weight(.medium))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Close now playing")

            Spacer()

            Text("Now Playing")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .textCase(.uppercase)
                .tracking(1.5)
                .foregroundColor(.white.opacity(0.4))

            Spacer()

            // AirPlay Button
            AirPlayButton()
                .frame(width: 44, height: 44)

            // Queue Button
            Button {
                showQueue = true
            } label: {
                Image(systemName: "list.bullet")
                    .font(.body.weight(.medium))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("View queue")
        }
        .sheet(isPresented: $showQueue) {
            QueueView()
        }
    }

    // MARK: - Artwork Section (responsive)
    private func artworkSection(screenWidth: CGFloat, screenHeight: CGFloat) -> some View {
        let artSize = min(screenWidth * 0.65, 320.0)

        return ZStack {
            if let track = playerManager.currentTrack,
               let artworkURLString = track.artworkURL,
               let artworkURL = URL(string: artworkURLString) {
                CachedAsyncImage(url: artworkURL) { phase in
                    switch phase {
                    case .empty:
                        placeholderArtwork(size: artSize)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: artSize, height: artSize)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.5), radius: 20, y: 10)
                    case .failure:
                        placeholderArtwork(size: artSize)
                    @unknown default:
                        placeholderArtwork(size: artSize)
                    }
                }
                .frame(width: artSize, height: artSize)
                .matchedGeometryEffect(id: "albumArt", in: namespace)
            } else {
                placeholderArtwork(size: artSize)
                    .matchedGeometryEffect(id: "albumArt", in: namespace)
            }
        }
    }

    private func placeholderArtwork(size: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.jellyAmpMidBackground)
                .frame(width: size, height: size)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.5), radius: 20, y: 10)

            Image(systemName: "music.note")
                .font(.largeTitle)
                .foregroundColor(.white.opacity(0.2))
        }
    }

    // MARK: - Track Info Section (with inline favorite — matches PWA)
    private var trackInfoSection: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                if let track = playerManager.currentTrack {
                    Text(track.name)
                        .font(.title3.weight(.bold))
                        .foregroundColor(Color.jellyAmpText)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)

                    Button {
                        navigateToArtist(track: track)
                    } label: {
                        Text(track.artistName)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                    }

                    Button {
                        navigateToAlbum(track: track)
                    } label: {
                        Text(track.albumName)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.35))
                    }
                } else {
                    Text("No Track Playing")
                        .font(.title3.weight(.bold))
                        .foregroundColor(.jellyAmpTextSecondary)
                }
            }

            Spacer()

            // Inline favorite button (PWA style)
            Button {
                toggleFavorite()
            } label: {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .font(.title3)
                    .foregroundColor(isFavorite ? .neonPink : .white.opacity(0.3))
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
        }
    }

    // MARK: - Progress Section
    private var progressSection: some View {
        VStack(spacing: 8) {
            Slider(
                value: Binding(
                    get: { isDraggingSlider ? sliderValue : playerManager.currentTime },
                    set: { newValue in
                        isDraggingSlider = true
                        sliderValue = newValue
                    }
                ),
                in: 0...max(playerManager.duration, 1),
                onEditingChanged: { editing in
                    if !editing {
                        playerManager.seek(to: sliderValue)
                        isDraggingSlider = false
                    }
                }
            )
            .tint(Color.jellyAmpAccent)
            .accessibilityLabel("Track progress")

            HStack {
                Text(formatTime(isDraggingSlider ? sliderValue : playerManager.currentTime))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
                Spacer()
                Text(formatTime(playerManager.duration))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
    }

    // MARK: - Controls (PWA layout: shuffle | prev | play | next | repeat)
    private var controlsSection: some View {
        HStack(spacing: 0) {
            // Shuffle
            Button {
                playerManager.toggleShuffle()
            } label: {
                Image(systemName: "shuffle")
                    .font(.body)
                    .foregroundColor(playerManager.shuffleEnabled ? .neonCyan : .white.opacity(0.4))
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Shuffle")

            Spacer()

            // Previous
            Button {
                playerManager.playPrevious()
            } label: {
                Image(systemName: "backward.fill")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Previous track")

            Spacer()

            // Play/Pause — white circle (PWA style)
            Button {
                playerManager.togglePlayPause()
            } label: {
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: 68, height: 68)
                        .shadow(color: .white.opacity(0.15), radius: 20)

                    Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title2)
                        .foregroundColor(.black)
                        .offset(x: playerManager.isPlaying ? 0 : 2)
                }
            }
            .accessibilityLabel(playerManager.isPlaying ? "Pause" : "Play")

            Spacer()

            // Next
            Button {
                playerManager.playNext()
            } label: {
                Image(systemName: "forward.fill")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Next track")

            Spacer()

            // Repeat
            Button {
                playerManager.toggleRepeatMode()
            } label: {
                Image(systemName: repeatIcon)
                    .font(.body)
                    .foregroundColor(playerManager.repeatMode != .off ? .neonCyan : .white.opacity(0.4))
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Repeat")
        }
    }

    var repeatIcon: String {
        switch playerManager.repeatMode {
        case .off: return "repeat"
        case .all: return "repeat"
        case .one: return "repeat.1"
        }
    }

    // MARK: - Secondary Actions (sleep timer)
    private var secondaryActionsSection: some View {
        HStack(spacing: 16) {
            // Sleep Timer
            Button {
                showSleepTimer = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "moon.zzz")
                        .font(.caption)
                    if sleepTimer.isActive {
                        Text(sleepTimer.formattedRemaining)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                    }
                }
                .foregroundColor(sleepTimer.isActive ? .jellyAmpAccent : .white.opacity(0.4))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(sleepTimer.isActive ? Color.jellyAmpAccent.opacity(0.15) : Color.white.opacity(0.1))
                )
                .overlay(
                    Capsule()
                        .stroke(sleepTimer.isActive ? Color.jellyAmpAccent.opacity(0.3) : Color.clear, lineWidth: 1)
                )
            }
            .confirmationDialog("Sleep Timer", isPresented: $showSleepTimer, titleVisibility: .visible) {
                ForEach(SleepTimerOption.allCases) { option in
                    Button(option.rawValue) {
                        sleepTimer.start(option: option)
                    }
                }
                if sleepTimer.isActive {
                    Button("Cancel Timer", role: .destructive) {
                        sleepTimer.cancel()
                    }
                }
            } message: {
                if sleepTimer.isActive {
                    Text("Timer active: \(sleepTimer.formattedRemaining)")
                } else {
                    Text("Pause playback after...")
                }
            }
        }
    }

    // MARK: - Up Next Section
    private var upNextSection: some View {
        Group {
            if playerManager.currentIndex < playerManager.queue.count - 1 {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Up Next")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .textCase(.uppercase)
                        .tracking(1.2)
                        .foregroundColor(.white.opacity(0.3))
                        .padding(.horizontal, 4)

                    ForEach(nextTracks, id: \.id) { track in
                        HStack(spacing: 12) {
                            CachedAsyncImage(url: URL(string: track.artworkURL ?? "")) { phase in
                                switch phase {
                                case .success(let image):
                                    image.resizable().aspectRatio(contentMode: .fill)
                                default:
                                    Rectangle().fill(Color.jellyAmpMidBackground)
                                        .overlay(Image(systemName: "music.note").font(.caption).foregroundColor(.white.opacity(0.3)))
                                }
                            }
                            .frame(width: 40, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(track.name)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.white.opacity(0.7))
                                    .lineLimit(1)
                                Text(track.artistName)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.35))
                                    .lineLimit(1)
                            }

                            Spacer()

                            Text(track.durationFormatted)
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundColor(.white.opacity(0.3))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                    }
                }
            }
        }
    }

    private var nextTracks: [Track] {
        let startIdx = playerManager.currentIndex + 1
        let endIdx = min(startIdx + 2, playerManager.queue.count)
        guard startIdx < playerManager.queue.count else { return [] }
        return Array(playerManager.queue[startIdx..<endIdx])
    }

    // MARK: - Dominant Color Extraction
    private func extractDominantColor(for track: Track?) {
        guard let track = track,
              let urlString = track.artworkURL,
              let url = URL(string: urlString) else {
            dominantColor = nil
            return
        }

        Task {
            if let cachedImage = await ImageCache.shared.cachedImage(for: url) {
                let color = await DominantColorExtractor.shared.dominantColor(from: cachedImage, trackId: track.id)
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.8)) {
                        dominantColor = color
                    }
                }
            } else if let img = try? await ImageCache.shared.loadImage(from: url) {
                let color = await DominantColorExtractor.shared.dominantColor(from: img, trackId: track.id)
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.8)) {
                        dominantColor = color
                    }
                }
            }
        }
    }

    // MARK: - Helpers
    private func formatTime(_ time: TimeInterval) -> String {
        guard !time.isNaN && !time.isInfinite && time >= 0 else { return "0:00" }
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func navigateToArtist(track: Track) {
        let artist = Artist(
            id: track.artistId ?? "",
            name: track.artistName,
            bio: nil,
            albumCount: 0,
            artworkURL: nil
        )
        guard !artist.id.isEmpty else { return }
        NavigationCoordinator.shared.pendingArtistNavigation = artist
        if let onDismiss = onDismiss { onDismiss() } else { dismiss() }
    }

    private func navigateToAlbum(track: Track) {
        guard let albumId = track.albumId else { return }
        let album = Album(
            id: albumId,
            name: track.albumName,
            artistName: track.artistName,
            artistId: track.artistId,
            year: track.productionYear,
            artworkURL: track.artworkURL
        )
        NavigationCoordinator.shared.pendingAlbumNavigation = album
        if let onDismiss = onDismiss { onDismiss() } else { dismiss() }
    }

    private func toggleFavorite() {
        guard let currentTrack = playerManager.currentTrack else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        withAnimation(.spring(response: 0.3)) {
            isFavorite.toggle()
        }

        Task {
            do {
                if isFavorite {
                    try await jellyfinService.markFavorite(itemId: currentTrack.id)
                } else {
                    try await jellyfinService.unmarkFavorite(itemId: currentTrack.id)
                }
                let currentIndex = playerManager.currentIndex
                if currentIndex < playerManager.queue.count {
                    playerManager.queue[currentIndex].isFavorite = isFavorite
                }
            } catch {
                await MainActor.run {
                    withAnimation(.spring(response: 0.3)) {
                        isFavorite.toggle()
                    }
                }
            }
        }
    }
}

// MARK: - AirPlay Button
struct AirPlayButton: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let routePickerView = AVRoutePickerView()
        routePickerView.backgroundColor = .clear
        routePickerView.activeTintColor = UIColor(Color.jellyAmpAccent)
        routePickerView.tintColor = UIColor(.white.opacity(0.6))
        routePickerView.prioritizesVideoDevices = false
        return routePickerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

// MARK: - Preview
#Preview {
    struct PreviewWrapper: View {
        @Namespace private var namespace
        var body: some View {
            NowPlayingView(namespace: namespace)
        }
    }
    return PreviewWrapper()
}
