//
//  NowPlayingView.swift
//  JellyAmp
//
//  Beautiful Now Playing screen with iOS 26 Liquid Glass + Cypherpunk styling
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
    @ObservedObject var sleepTimer = SleepTimerManager.shared
    var namespace: Namespace.ID

    var body: some View {
        ZStack {
            // Background with dynamic dominant color
            LinearGradient(
                colors: [
                    (dominantColor ?? Color.jellyAmpMidBackground).opacity(0.6),
                    Color.jellyAmpBackground,
                    Color.jellyAmpBackground
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.8), value: dominantColor != nil)
            .matchedGeometryEffect(id: "playerBg", in: namespace)

            // Content
            VStack(spacing: 0) {
                // Top Bar
                topBar

                Spacer()

                // Album Artwork
                artworkSection

                Spacer()

                // Track Info
                trackInfoSection

                // Progress Slider
                progressSection

                // Controls
                controlsSection

                // Bottom Actions
                bottomActionsSection

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)
            .padding(.bottom, 40)
        }
        .onChange(of: playerManager.currentTrack) { _, newTrack in
            // Update favorite status when track changes
            isFavorite = newTrack?.isFavorite ?? false
            // Extract dominant color
            extractDominantColor(for: newTrack)
        }
        .onAppear {
            // Set initial favorite status
            isFavorite = playerManager.currentTrack?.isFavorite ?? false
            extractDominantColor(for: playerManager.currentTrack)
        }
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.title3)
                    .foregroundColor(Color.jellyAmpText)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Close now playing")

            Spacer()

            Text("Now Playing")
                .font(.jellyAmpCaption)
                .foregroundColor(.secondary)

            Spacer()

            // AirPlay Button
            AirPlayButton()
                .frame(width: 44, height: 44)

            // Queue Button
            Button {
                showQueue = true
            } label: {
                Image(systemName: "list.bullet")
                    .font(.title3)
                    .foregroundColor(Color.jellyAmpText)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("View queue")
        }
        .sheet(isPresented: $showQueue) {
            QueueView()
        }
    }

    // MARK: - Artwork Section
    private var artworkSection: some View {
        ZStack {
            if let track = playerManager.currentTrack,
               let artworkURLString = track.artworkURL,
               let artworkURL = URL(string: artworkURLString) {
                CachedAsyncImage(url: artworkURL) { phase in
                    switch phase {
                    case .empty:
                        placeholderArtwork
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 320, height: 320)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.jellyAmpAccent.opacity(0.8),
                                                Color.jellyAmpSecondary.opacity(0.8)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 3
                                    )
                            )
                            .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                    case .failure:
                        placeholderArtwork
                    @unknown default:
                        placeholderArtwork
                    }
                }
                .frame(width: 320, height: 320)
                .matchedGeometryEffect(id: "albumArt", in: namespace)
            } else {
                placeholderArtwork
                    .matchedGeometryEffect(id: "albumArt", in: namespace)
            }
        }
    }

    private var placeholderArtwork: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.jellyAmpAccent.opacity(0.6),
                            Color.jellyAmpSecondary.opacity(0.6),
                            Color.neonPurple.opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 320, height: 320)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.jellyAmpAccent.opacity(0.8),
                                    Color.jellyAmpSecondary.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: .black.opacity(0.2), radius: 8, y: 4)

            // Album icon overlay
            Image(systemName: "music.note")
                .font(.title)
                .foregroundColor(.white.opacity(0.3))
        }
    }

    // MARK: - Track Info Section
    private var trackInfoSection: some View {
        VStack(spacing: 8) {
            if let track = playerManager.currentTrack {
                Text(track.name)
                    .font(.jellyAmpTitle)
                    .foregroundColor(Color.jellyAmpText)

                Text(track.artistName)
                    .font(.jellyAmpHeadline)
                    .foregroundColor(.secondary)

                Text(track.albumName)
                    .font(.jellyAmpCaption)
                    .foregroundColor(.gray)
            } else {
                Text("No Track Playing")
                    .font(.jellyAmpTitle)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top, 30)
    }

    // MARK: - Progress Section
    private var progressSection: some View {
        VStack(spacing: 8) {
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track background
                    Capsule()
                        .fill(Color.white.opacity(0.1))

                    // Progress fill
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.jellyAmpAccent, Color.jellyAmpSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress)
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isDraggingSlider = true
                            let percent = min(max(0, value.location.x / geometry.size.width), 1)
                            sliderValue = percent * playerManager.duration
                        }
                        .onEnded { _ in
                            playerManager.seek(to: sliderValue)
                            isDraggingSlider = false
                        }
                )
                .accessibilityElement()
                .accessibilityLabel("Track progress")
                .accessibilityValue("\(formatTime(isDraggingSlider ? sliderValue : playerManager.currentTime)) of \(formatTime(playerManager.duration))")
                .accessibilityAdjustableAction { direction in
                    let step = playerManager.duration * 0.05 // 5% of total duration
                    let currentTime = isDraggingSlider ? sliderValue : playerManager.currentTime
                    let newTime = direction == .increment ? 
                        min(currentTime + step, playerManager.duration) : 
                        max(currentTime - step, 0)
                    playerManager.seek(to: newTime)
                }
            }
            .frame(height: 6)

            // Time labels
            HStack {
                Text(formatTime(isDraggingSlider ? sliderValue : playerManager.currentTime))
                    .font(.jellyAmpMono)
                    .foregroundColor(.neonCyan)

                Spacer()

                Text(formatTime(playerManager.duration))
                    .font(.jellyAmpMono)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top, 40)
    }

    var progress: Double {
        guard playerManager.duration > 0 else { return 0 }
        let time = isDraggingSlider ? sliderValue : playerManager.currentTime
        return min(max(time / playerManager.duration, 0), 1)
    }

    // MARK: - Controls Section
    private var controlsSection: some View {
        HStack(spacing: 40) {
            // Previous
            Button {
                playerManager.playPrevious()
            } label: {
                Image(systemName: "backward.fill")
                    .font(.title2)
                    .foregroundColor(Color.jellyAmpText)
            }
            .accessibilityLabel("Previous track")

            // Play/Pause (prominent)
            Button {
                playerManager.togglePlayPause()
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.jellyAmpAccent, Color.jellyAmpSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .neonGlow(color: .neonCyan, radius: 8)

                    Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title)
                        .foregroundColor(.black)
                }
            }
            .accessibilityLabel(playerManager.isPlaying ? "Pause" : "Play")

            // Next
            Button {
                playerManager.playNext()
            } label: {
                Image(systemName: "forward.fill")
                    .font(.title2)
                    .foregroundColor(Color.jellyAmpText)
            }
            .accessibilityLabel("Next track")
        }
        .padding(.top, 30)
    }

    // MARK: - Bottom Actions
    private var bottomActionsSection: some View {
        HStack(spacing: 50) {
            // Shuffle
            Button {
                playerManager.toggleShuffle()
            } label: {
                Image(systemName: "shuffle")
                    .font(.title3)
                    .foregroundColor(playerManager.shuffleEnabled ? .neonCyan : .secondary)
                    .neonGlow(color: .neonCyan, radius: playerManager.shuffleEnabled ? 6 : 0)
            }
            .accessibilityLabel("Shuffle")
            .accessibilityValue(playerManager.shuffleEnabled ? "On" : "Off")

            // Favorite
            Button {
                toggleFavorite()
            } label: {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .font(.title3)
                    .foregroundColor(isFavorite ? .neonPink : .white)
                    .neonGlow(color: .neonPink, radius: isFavorite ? 6 : 0)
            }
            .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")

            // Sleep Timer
            Button {
                showSleepTimer = true
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "moon.zzz")
                        .font(.title3)
                        .foregroundColor(sleepTimer.isActive ? .jellyAmpAccent : .secondary)
                        .neonGlow(color: .neonCyan, radius: sleepTimer.isActive ? 6 : 0)

                    if sleepTimer.isActive {
                        Circle()
                            .fill(Color.jellyAmpAccent)
                            .frame(width: 8, height: 8)
                            .offset(x: 4, y: -4)
                    }
                }
            }
            .accessibilityLabel("Sleep timer")
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

            // Repeat
            Button {
                playerManager.toggleRepeatMode()
            } label: {
                Image(systemName: repeatIcon)
                    .font(.title3)
                    .foregroundColor(playerManager.repeatMode != .off ? .neonCyan : .secondary)
                    .neonGlow(color: .neonCyan, radius: playerManager.repeatMode != .off ? 6 : 0)
            }
            .accessibilityLabel("Repeat")
            .accessibilityValue(playerManager.repeatMode == .off ? "Off" : playerManager.repeatMode == .all ? "All" : "One")
        }
        .padding(.top, 30)
    }

    var repeatIcon: String {
        switch playerManager.repeatMode {
        case .off:
            return "repeat"
        case .all:
            return "repeat"
        case .one:
            return "repeat.1"
        }
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
            // Try to get from image cache first
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
        // Guard against NaN or infinite values
        guard !time.isNaN && !time.isInfinite && time >= 0 else {
            return "0:00"
        }

        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func toggleFavorite() {
        guard let currentTrack = playerManager.currentTrack else { return }

        // Optimistic UI update
        withAnimation(.spring(response: 0.3)) {
            isFavorite.toggle()
        }

        // Call API in background
        Task {
            do {
                if isFavorite {
                    try await jellyfinService.markFavorite(itemId: currentTrack.id)
                } else {
                    try await jellyfinService.unmarkFavorite(itemId: currentTrack.id)
                }

                // Update the track in the queue
                let currentIndex = playerManager.currentIndex
                if currentIndex < playerManager.queue.count {
                    playerManager.queue[currentIndex].isFavorite = isFavorite
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
}

// MARK: - AirPlay Button
struct AirPlayButton: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let routePickerView = AVRoutePickerView()
        routePickerView.backgroundColor = .clear
        routePickerView.activeTintColor = UIColor(Color.jellyAmpAccent)
        routePickerView.tintColor = UIColor(.white)

        // Make the button larger and centered
        routePickerView.prioritizesVideoDevices = false

        return routePickerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // No updates needed
    }
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
