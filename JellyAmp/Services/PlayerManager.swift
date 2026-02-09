//
//  PlayerManager.swift
//  JellyAmp
//
//  Audio player management for background playback and Now Playing integration
//  Rebuilt using proven JellyJam approach for reliable background audio
//

import Foundation
import AVFoundation
import MediaPlayer
import Combine
import UIKit
import os.log

/// Manages audio playback with AVPlayer and iOS Now Playing integration
/// Handles background audio, interruptions, and remote controls
class PlayerManager: NSObject, ObservableObject {
    static let shared = PlayerManager()

    private let logger = Logger(subsystem: "com.jellyamp.app", category: "PlayerManager")

    // MARK: - Published Properties
    @Published var currentTrack: Track?
    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var isBuffering = false
    @Published var errorMessage: String?

    // MARK: - Playback Queue
    @Published var queue: [Track] = []
    @Published var currentIndex: Int = 0
    @Published var shuffleEnabled = false
    @Published var repeatMode: RepeatMode = .off
    @Published var recentlyPlayedAlbumIds: [String] = []

    enum RepeatMode {
        case off
        case all
        case one

        var systemImage: String {
            switch self {
            case .off:
                return "repeat"
            case .all:
                return "repeat"
            case .one:
                return "repeat.1"
            }
        }
    }

    // MARK: - Private Properties
    private var player: AVQueuePlayer?
    private var playerItems: [AVPlayerItem] = []
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    private var playerItemCancellables = Set<AnyCancellable>() // Separate for player item observers
    private let jellyfinService = JellyfinService.shared
    private let downloadManager = DownloadManager.shared
    private var originalQueue: [Track] = []
    private var originalIndex: Int = 0
    private var lastValidPlaybackTime: Double = 0.0  // Track last known position to detect unexpected restarts

    // MARK: - Initialization

    override init() {
        super.init()
        recentlyPlayedAlbumIds = UserDefaults.standard.stringArray(forKey: "recentlyPlayedAlbumIds") ?? []
        setupNotifications()
        // Configure audio session immediately when PlayerManager is created
        configureAudioSession()
    }

    // MARK: - Audio Session Configuration

    /// Configures audio session for background playback
    func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()

            // Configure for playback with AirPlay support and background audio
            try audioSession.setCategory(.playback,
                                       mode: .default,
                                       options: [.allowAirPlay,
                                               .allowBluetoothA2DP])

            // Set audio session as active with options
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

            // Configure for remote control
            UIApplication.shared.beginReceivingRemoteControlEvents()

            // Enable remote control events
            setupRemoteControls()

            logger.info("✅ Audio session configured successfully")

        } catch {
            errorMessage = "Audio setup failed: \(error.localizedDescription)"
            logger.error("❌ Failed to setup audio session: \(error.localizedDescription)")
        }
    }

    // MARK: - Playback Control

    /// Plays a single track
    func play(_ track: Track) {
        // Validate track before playing
        guard !track.id.isEmpty else {
            errorMessage = "Invalid track"
            logger.error("Cannot play track with empty ID")
            return
        }

        queue = [track]
        currentIndex = 0
        playCurrentTrack()
    }

    /// Plays a list of tracks starting at index
    func play(tracks: [Track], startingAt index: Int = 0) {
        // Validate input
        guard !tracks.isEmpty else {
            errorMessage = "No tracks to play"
            logger.error("Empty tracks array provided")
            return
        }

        guard index >= 0 && index < tracks.count else {
            errorMessage = "Invalid track position"
            logger.error("Invalid starting index \(index) for \(tracks.count) tracks")
            return
        }

        // Filter out any invalid tracks
        let validTracks = tracks.filter { !$0.id.isEmpty }
        guard !validTracks.isEmpty else {
            errorMessage = "No valid audio tracks"
            logger.error("No valid audio tracks in the provided list")
            return
        }

        originalQueue = validTracks
        originalIndex = min(index, validTracks.count - 1)

        if shuffleEnabled && validTracks.count > 1 {
            // Shuffle the queue but keep the starting track first
            var shuffled = validTracks
            let startingTrack = shuffled.remove(at: originalIndex)
            shuffled.shuffle()
            queue = [startingTrack] + shuffled
            currentIndex = 0
        } else {
            queue = validTracks
            currentIndex = originalIndex
        }

        playCurrentTrack()
    }

    /// Plays/pauses current track
    func togglePlayPause() {
        guard let player = player else {
            return
        }

        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }

        updateNowPlayingInfo()
    }

    /// Resume playback
    func play() {
        guard let player = player else {
            return
        }

        player.play()
        isPlaying = true
        updateNowPlayingInfo()
    }

    /// Pause playback
    func pause() {
        player?.pause()
        isPlaying = false
        updateNowPlayingInfo()
    }

    /// Skips to next track
    func playNext() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        switch repeatMode {
        case .one:
            // Repeat current track
            seek(to: 0)
            player?.play()
            isPlaying = true
        case .all:
            // Go to next track, or loop to beginning
            if currentIndex < queue.count - 1 {
                currentIndex += 1
            } else {
                currentIndex = 0
            }
            // Manually advance and rebuild gapless queue
            player?.pause()
            playCurrentTrack()
        case .off:
            // Normal behavior - stop at end
            guard currentIndex < queue.count - 1 else {
                // End of queue
                isPlaying = false
                return
            }
            currentIndex += 1
            // Manually advance and rebuild gapless queue
            player?.pause()
            playCurrentTrack()
        }
    }

    /// Skips to previous track
    func playPrevious() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        // If more than 3 seconds into track, restart it
        if currentTime > 3 {
            seek(to: 0)
        } else if currentIndex > 0 {
            currentIndex -= 1
            // Rebuild gapless queue from new position
            player?.pause()
            playCurrentTrack()
        } else {
            // At beginning, just restart current track
            seek(to: 0)
        }
    }

    /// Adds a track to the end of the queue
    func addToQueue(track: Track) {
        queue.append(track)
        // If nothing playing, start playing
        if currentTrack == nil {
            currentIndex = queue.count - 1
            playCurrentTrack()
        }
    }

    /// Insert track to play after current track
    func playNext(track: Track) {
        let insertIndex = min(currentIndex + 1, queue.count)
        queue.insert(track, at: insertIndex)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    /// Add track to end of queue
    func playLast(track: Track) {
        queue.append(track)
        if currentTrack == nil {
            currentIndex = queue.count - 1
            playCurrentTrack()
        }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    /// Seeks to specific time
    /// Flag to tell the time observer that a deliberate seek is in progress
    private var isSeeking = false

    func seek(to time: Double) {
        guard let player = player else {
            logger.error("❌ Cannot seek - player is nil")
            return
        }

        guard let currentItem = player.currentItem else {
            logger.error("❌ Cannot seek - no current item")
            return
        }

        // Log seeks to beginning to help debug restarts
        if time == 0 {
            logger.info("🔄 Seeking to beginning of track: \(self.currentTrack?.name ?? "unknown")")
        }

        // Check if current item is ready to seek
        guard currentItem.status == .readyToPlay else {
            logger.warning("⚠️ Cannot seek - item not ready (status: \(currentItem.status.rawValue))")
            return
        }

        // Duration comes from track metadata (set when track starts playing)
        guard duration > 0 else {
            logger.error("❌ Cannot seek - duration is 0 (track metadata issue)")
            return
        }

        // Clamp time to valid range
        let clampedTime = max(0, min(time, duration))
        let cmTime = CMTime(seconds: clampedTime, preferredTimescale: 600)

        logger.info("🔍 Seeking to \(clampedTime)s (duration: \(self.duration)s)")

        // Mark seeking so the time observer doesn't fight us
        isSeeking = true
        // Update currentTime immediately to prevent UI snapping back
        self.currentTime = clampedTime

        // Use small tolerance for reliable backward seeking (zero tolerance fails on some codecs)
        let tolerance = CMTime(seconds: 0.5, preferredTimescale: 600)
        player.seek(to: cmTime, toleranceBefore: tolerance, toleranceAfter: tolerance) { [weak self] completed in
            guard let self = self else { return }
            self.isSeeking = false
            if completed {
                self.logger.info("✅ Seek completed to \(clampedTime)s")
                self.currentTime = clampedTime
                self.updateNowPlayingInfo()
            } else {
                self.logger.error("❌ Seek failed to \(clampedTime)s")
            }
        }
    }

    /// Toggles shuffle mode
    func toggleShuffle() {
        shuffleEnabled.toggle()

        if shuffleEnabled {
            // Enable shuffle - save original order and shuffle
            if originalQueue.isEmpty {
                originalQueue = queue
                originalIndex = currentIndex
            }

            // Shuffle queue keeping current track first
            guard let currentTrack = currentTrack,
                  let currentTrackIndex = queue.firstIndex(where: { $0.id == currentTrack.id }) else { return }

            var newQueue = queue
            newQueue.remove(at: currentTrackIndex)
            newQueue.shuffle()
            queue = [currentTrack] + newQueue
            currentIndex = 0
        } else {
            // Disable shuffle - restore original order
            if !originalQueue.isEmpty {
                queue = originalQueue
                // Find current track in original queue
                if let currentTrack = currentTrack,
                   let index = originalQueue.firstIndex(where: { $0.id == currentTrack.id }) {
                    currentIndex = index
                }
                originalQueue = []
            }
        }
    }

    /// Cycles through repeat modes
    func toggleRepeatMode() {
        switch repeatMode {
        case .off:
            repeatMode = .all
        case .all:
            repeatMode = .one
        case .one:
            repeatMode = .off
        }
    }

    // MARK: - Queue Management

    /// Removes a track from the queue at the specified index
    func removeFromQueue(at index: Int) {
        guard index >= 0 && index < queue.count else { return }

        // If removing current track, skip to next
        if index == currentIndex {
            if currentIndex < queue.count - 1 {
                // Skip to next without playing current again
                queue.remove(at: index)
                playCurrentTrack()
            } else if currentIndex > 0 {
                // Last track - go to previous
                queue.remove(at: index)
                currentIndex -= 1
                playCurrentTrack()
            } else {
                // Only track in queue
                queue.remove(at: index)
                currentTrack = nil
                player?.pause()
                isPlaying = false
                cleanupPlayer()
            }
        } else if index < currentIndex {
            // Removing track before current - adjust index
            queue.remove(at: index)
            currentIndex -= 1
            // Rebuild gapless queue to reflect changes
            if isPlaying {
                setupGaplessQueue(startingAt: currentIndex)
                player?.play()
            }
        } else {
            // Removing track after current - just remove
            queue.remove(at: index)
            // If it's in the preloaded buffer, rebuild gapless queue
            let bufferEnd = currentIndex + playerItems.count
            if index < bufferEnd && isPlaying {
                setupGaplessQueue(startingAt: currentIndex)
                player?.play()
            }
        }
    }

    /// Moves a track in the queue from one index to another
    func moveInQueue(from source: Int, to destination: Int) {
        guard source >= 0 && source < queue.count,
              destination >= 0 && destination <= queue.count else { return }

        // Don't move to the same position
        guard source != destination else { return }

        let track = queue[source]
        queue.remove(at: source)

        // Adjust for removal
        let insertIndex = source < destination ? destination - 1 : destination
        queue.insert(track, at: insertIndex)

        // Update current index if needed
        if source == currentIndex {
            // Moving current track
            currentIndex = insertIndex
        } else if source < currentIndex && insertIndex >= currentIndex {
            // Moved a track from before to after current
            currentIndex -= 1
        } else if source > currentIndex && insertIndex <= currentIndex {
            // Moved a track from after to before current
            currentIndex += 1
        }

        // If we're currently playing, we need to sync the AVQueuePlayer with the new order
        // BUT we cannot restart the current track
        if isPlaying && player != nil {
            // Remove all preloaded items (keep only the currently playing one)
            while playerItems.count > 1 {
                playerItems.removeLast()
                // Remove from AVQueuePlayer (can't remove specific items, so we rely on them being at the end)
            }

            // Now preload the next tracks based on the NEW queue order
            for offset in 1...2 {
                let nextIndex = currentIndex + offset
                guard nextIndex < queue.count else { break }

                let nextTrack = queue[nextIndex]
                guard let streamURL = jellyfinService.getStreamingURL(for: nextTrack.id) else {
                    logger.error("❌ Failed to preload track at index \(nextIndex): \(nextTrack.name)")
                    continue
                }

                let playerItem = AVPlayerItem(url: streamURL)
                playerItem.canUseNetworkResourcesForLiveStreamingWhilePaused = true
                playerItem.preferredForwardBufferDuration = 60.0  // Large buffer for stability
                // Note: No bitrate limit - using direct file streaming

                player?.insert(playerItem, after: nil)
                playerItems.append(playerItem)
                logger.info("✅ Reloaded track \(offset) after reorder: \(nextTrack.name)")
            }
        }

        updateNowPlayingInfo()
    }

    /// Clears the entire queue
    func clearQueue() {
        queue.removeAll()
        currentIndex = 0
        currentTrack = nil
        player?.pause()
        isPlaying = false
        cleanupPlayer()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    /// Jump to track at index in queue
    func jumpToTrack(at index: Int) {
        guard index >= 0 && index < queue.count else { return }
        currentIndex = index
        playCurrentTrack()
    }

    // MARK: - Private Playback Methods

    private func playCurrentTrack() {
        guard currentIndex >= 0 && currentIndex < queue.count else {
            logger.error("Invalid queue index: \(self.currentIndex) (queue size: \(self.queue.count))")
            errorMessage = "Invalid track position"
            return
        }

        let track = queue[currentIndex]

        // Validate track data
        guard !track.id.isEmpty else {
            logger.error("Track has empty ID")
            errorMessage = "Invalid track data"
            playNext()
            return
        }

        currentTrack = track
        trackRecentPlay()

        // Set duration from track metadata (Jellyfin API provides this)
        // Don't rely on stream duration as HTTP transcoded streams report isIndefinite
        duration = track.duration
        currentTime = 0
        logger.info("📏 Set duration from track metadata: \(track.duration)s for '\(track.name)'")

        // Clear any previous error
        errorMessage = nil

        // Clean up previous player
        cleanupPlayer()

        // Setup AVQueuePlayer with current + next 2 tracks for gapless playback
        setupGaplessQueue(startingAt: currentIndex)

        // Ensure audio session is properly configured and active before playing
        do {
            let audioSession = AVAudioSession.sharedInstance()

            // Check if we need to reconfigure the audio session
            if audioSession.category != .playback {
                try audioSession.setCategory(.playback,
                                           mode: .default,
                                           options: [.allowAirPlay,
                                                   .allowBluetoothA2DP])
            }

            // Activate audio session
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

            logger.info("✅ Audio session activated for playback")
        } catch {
            errorMessage = "Failed to configure audio: \(error.localizedDescription)"
            logger.error("Failed to activate audio session: \(error)")

            // Clean up on failure
            cleanupPlayer()
            return
        }

        // Ensure remote controls are set up
        setupRemoteControls()

        // Start playback
        player?.play()
        isPlaying = true

        // Update Now Playing
        updateNowPlayingInfo()

        logger.info("▶️ Started playing: \(track.name)")
    }

    // MARK: - Gapless Playback Setup

    /// Setup AVQueuePlayer for gapless playback
    private func setupGaplessQueue(startingAt index: Int) {
        // Clear old player items
        playerItems.removeAll()

        // Create player items for current + next 2 tracks (3 total for gapless playback)
        let tracksToLoad = Array(queue[index...].prefix(3))
        logger.info("🎵 Setting up gapless queue starting at index \(index)")

        for (offset, track) in tracksToLoad.enumerated() {
            // Check if track is downloaded for offline playback
            let playbackURL: URL?
            let isOffline: Bool

            if let localURL = downloadManager.getLocalURL(for: track.id) {
                playbackURL = localURL
                isOffline = true
                logger.info("  [\(offset)] Using offline file: \(track.name)")
            } else {
                let qualityRaw = UserDefaults.standard.string(forKey: "streamingQuality") ?? "medium"
                let quality = StreamingQuality(rawValue: qualityRaw) ?? .medium
                if quality == .original {
                    playbackURL = jellyfinService.getDownloadURL(for: track.id)
                } else {
                    playbackURL = jellyfinService.getStreamingURL(for: track.id, bitrate: quality.bitrate)
                }
                isOffline = false
                logger.info("  [\(offset)] Streaming (\(qualityRaw)): \(track.name)")
            }

            guard let url = playbackURL else {
                logger.error("❌ Failed to get playback URL for track at index \(index + offset): \(track.name)")
                continue
            }

            let playerItem = AVPlayerItem(url: url)

            // Configure for reliable playback
            if !isOffline {
                // Streaming configuration
                playerItem.canUseNetworkResourcesForLiveStreamingWhilePaused = true
                playerItem.preferredForwardBufferDuration = 60.0  // Large buffer for stability
                playerItem.preferredPeakBitRate = 128000  // Match our max streaming bitrate
            }

            playerItems.append(playerItem)
        }

        // Create AVQueuePlayer with preloaded items
        player = AVQueuePlayer(items: playerItems)
        player?.automaticallyWaitsToMinimizeStalling = true
        player?.volume = 1.0

        // Setup observers for all items
        setupPlayerObservers()

        logger.info("✅ Gapless queue setup complete with \(self.playerItems.count) tracks loaded")
    }

    /// Handle track finishing in gapless mode
    private func handleTrackFinishedGapless(_ notification: Notification) {
        // Verify this is one of our player items
        guard let finishedItem = notification.object as? AVPlayerItem else {
            return
        }

        // CRITICAL: Only process if this is the FIRST item in our queue
        // By the time this notification fires, AVQueuePlayer has already advanced to the next item
        // So we check if the finished item WAS the first item (the one that should have been playing)
        guard let firstItem = playerItems.first, finishedItem == firstItem else {
            // This is either a preloaded item finishing early (shouldn't happen) or an old item
            logger.info("⏭️ Non-first item finished, ignoring (not our current track)")
            return
        }

        // Additional safety: only process if we're actually in a playing state
        guard isPlaying || player?.rate != 0 else {
            logger.info("⏭️ Track finished but not playing, ignoring")
            return
        }

        // CRITICAL FIX: Verify we're actually near the end of the track
        // Sometimes AVPlayerItemDidPlayToEndTime fires incorrectly mid-song
        guard let currentTrack = currentTrack else {
            logger.warning("⚠️ Track finished but currentTrack is nil, ignoring")
            return
        }

        let timeRemaining = currentTrack.duration - self.currentTime
        if timeRemaining > 5.0 {
            // We're more than 5 seconds from the end - this is a false notification
            logger.warning("⚠️ IGNORING false 'track finished' notification - still \(timeRemaining)s remaining in '\(currentTrack.name)'")
            logger.warning("   Current time: \(self.currentTime)s, Duration: \(currentTrack.duration)s")
            return
        }

        logger.info("✅ Current track finished playing: \(currentTrack.name) (time: \(self.currentTime)s, duration: \(currentTrack.duration)s)")

        guard repeatMode != .one else {
            // Repeat current track
            seek(to: 0)
            player?.play()
            isPlaying = true
            return
        }

        // Move to next track in queue
        if !playerItems.isEmpty {
            playerItems.removeFirst()
        }

        // Update current index and track
        switch repeatMode {
        case .off:
            guard currentIndex < queue.count - 1 else {
                // End of queue
                isPlaying = false
                return
            }
            currentIndex += 1
        case .all:
            // Loop to beginning if at end
            if currentIndex < queue.count - 1 {
                currentIndex += 1
            } else {
                currentIndex = 0
                // Reload queue from beginning for repeat all
                setupGaplessQueue(startingAt: 0)
                player?.play()
                isPlaying = true
                updateNowPlayingInfo()
                return
            }
        case .one:
            // Already handled above
            break
        }

        // Update current track and metadata
        if currentIndex < queue.count {
            let newTrack = queue[currentIndex]
            let previousTrack = currentTrack
            self.currentTrack = newTrack

            // Set duration from track metadata (not from stream)
            // The time observer will update currentTime automatically from the player
            duration = newTrack.duration
            logger.info("📏 Track changed: '\(previousTrack.name)' → '\(newTrack.name)' (index: \(self.currentIndex), duration: \(newTrack.duration)s)")
        } else {
            logger.error("❌ currentIndex \(self.currentIndex) out of bounds for queue size \(self.queue.count)")
        }

        // Preload next track if available (maintain 3-track buffer)
        let nextIndex = currentIndex + playerItems.count
        logger.info("🔄 Preload check: currentIndex=\(self.currentIndex), playerItems.count=\(self.playerItems.count), nextIndex=\(nextIndex), queue.count=\(self.queue.count)")

        if nextIndex < queue.count {
            let nextTrack = queue[nextIndex]

            guard let streamURL = jellyfinService.getStreamingURL(for: nextTrack.id) else {
                logger.error("❌ Failed to preload next track: \(nextTrack.name)")
                updateNowPlayingInfo()
                return
            }

            let playerItem = AVPlayerItem(url: streamURL)
            playerItem.canUseNetworkResourcesForLiveStreamingWhilePaused = true
            playerItem.preferredForwardBufferDuration = 60.0  // Large buffer for stability
            playerItem.preferredPeakBitRate = 128000  // Match our max streaming bitrate

            player?.insert(playerItem, after: nil)
            playerItems.append(playerItem)

            logger.info("✅ Preloaded next track: \(nextTrack.name) at index \(nextIndex)")
        }

        updateNowPlayingInfo()
    }

    private func setupPlayerObservers() {
        guard let player = player else {
            logger.error("Player is nil in setupPlayerObservers")
            errorMessage = "Failed to setup player"
            return
        }

        // Clear only player item observers (not notification observers)
        playerItemCancellables.removeAll()

        // Observe playback time - tracks current item automatically
        let interval = CMTime(seconds: 0.5, preferredTimescale: 1000)
        var lastValidTime: Double = 0.0
        var lastTrackedTrackId: String? = nil

        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            guard time.isValid && time.isNumeric else { return }

            // Don't update time during an active seek — let the seek completion handle it
            guard !self.isSeeking else { return }

            let newTime = time.seconds

            // CRITICAL: Reset time tracking when track changes
            // This prevents false "restart" detection when AVQueuePlayer advances to next track
            if let currentTrackId = self.currentTrack?.id, currentTrackId != lastTrackedTrackId {
                self.logger.info("🔄 Track changed in time observer, resetting time tracking (was: \(lastTrackedTrackId ?? "nil"), now: \(currentTrackId))")
                lastValidTime = 0.0
                lastTrackedTrackId = currentTrackId
            }

            // Detect unexpected restarts WITHIN THE SAME TRACK
            // If time jumps backward by more than 10 seconds AND we've been playing for a while,
            // this is likely a stream restart (not a user seek, which sets isSeeking=true)
            if newTime < lastValidTime - 10.0 && lastValidTime > 30.0 && lastTrackedTrackId == self.currentTrack?.id {
                self.logger.error("🚨 UNEXPECTED RESTART DETECTED: Time jumped from \(lastValidTime)s to \(newTime)s")
                self.logger.error("   Track: '\(self.currentTrack?.name ?? "unknown")'")
                self.logger.error("   This indicates the AVPlayer stream restarted on its own")

                // Attempt recovery: seek back to where we were
                if self.isPlaying {
                    self.logger.info("🔧 Attempting to recover playback position...")
                    self.seek(to: lastValidTime)
                }
            }

            // Update current time from player
            self.currentTime = newTime
            lastValidTime = newTime

            // Ensure duration matches current track (safeguard against race conditions)
            if let currentTrack = self.currentTrack, self.duration != currentTrack.duration {
                self.duration = currentTrack.duration
                self.logger.info("📏 Duration sync: Updated to \(currentTrack.duration)s for '\(currentTrack.name)'")
            }

            // Duration comes from Track metadata, not from stream
            // HTTP transcoded streams report isIndefinite, so we use Jellyfin API metadata
        }

        // Observe ALL player items in the queue
        for (index, playerItem) in playerItems.enumerated() {
            // Observe status
            playerItem.publisher(for: \.status)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] status in
                    guard let self = self else { return }

                    switch status {
                    case .readyToPlay:
                        if playerItem == self.player?.currentItem {
                            self.logger.info("✅ Player item ready to play (duration from track metadata: \(self.duration)s)")
                            self.isBuffering = false
                        } else {
                            self.logger.info("✅ Preloaded item \(index) ready")
                        }
                    case .failed:
                        let error = playerItem.error ?? NSError(domain: "PlayerManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown playback error"])
                        self.logger.error("❌ Player item \(index) failed: \(error.localizedDescription)")
                        if playerItem == self.player?.currentItem {
                            self.handlePlaybackError(error)
                        }
                    case .unknown:
                        break
                    @unknown default:
                        break
                    }
                }
                .store(in: &playerItemCancellables)

            // Observe buffering for current item
            playerItem.publisher(for: \.isPlaybackBufferEmpty)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] isEmpty in
                    guard let self = self else { return }
                    // Only update buffering state if this is the current item
                    if playerItem == self.player?.currentItem {
                        self.isBuffering = isEmpty
                        if isEmpty {
                            self.logger.warning("⏸️ Buffer empty - playback may stall")
                        }
                    }
                }
                .store(in: &playerItemCancellables)

            // Observe likely to keep up
            playerItem.publisher(for: \.isPlaybackLikelyToKeepUp)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] isLikely in
                    guard let self = self else { return }
                    if playerItem == self.player?.currentItem {
                        if isLikely && self.isBuffering {
                            self.logger.info("▶️ Buffer recovered - playback can resume")
                            self.isBuffering = false
                        }
                    }
                }
                .store(in: &playerItemCancellables)

            // Observe playback stalls
            playerItem.publisher(for: \.isPlaybackBufferFull)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] isFull in
                    guard let self = self else { return }
                    if playerItem == self.player?.currentItem && isFull {
                        self.logger.info("📦 Playback buffer is full - good streaming health")
                    }
                }
                .store(in: &playerItemCancellables)
        }
    }

    private func cleanupPlayer() {
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }

        player?.pause()
        player = nil
        playerItemCancellables.removeAll()
    }

    // MARK: - Now Playing & Remote Controls

    private func setupRemoteControls() {
        let commandCenter = MPRemoteCommandCenter.shared()

        // Remove any existing targets first
        commandCenter.playCommand.removeTarget(nil)
        commandCenter.pauseCommand.removeTarget(nil)
        commandCenter.togglePlayPauseCommand.removeTarget(nil)
        commandCenter.nextTrackCommand.removeTarget(nil)
        commandCenter.previousTrackCommand.removeTarget(nil)
        commandCenter.changePlaybackPositionCommand.removeTarget(nil)

        // Enable commands
        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.isEnabled = true

        // Play/Pause
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.play()
            return .success
        }

        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }

        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.togglePlayPause()
            return .success
        }

        // Skip controls
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.playNext()
            return .success
        }

        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.playPrevious()
            return .success
        }

        // Seek controls
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            if let positionEvent = event as? MPChangePlaybackPositionCommandEvent {
                self?.seek(to: positionEvent.positionTime)
                return .success
            }
            return .commandFailed
        }

        // Skip forward/backward 15s (lock screen & Control Center)
        commandCenter.skipForwardCommand.removeTarget(nil)
        commandCenter.skipBackwardCommand.removeTarget(nil)
        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.skipForwardCommand.preferredIntervals = [15]
        commandCenter.skipBackwardCommand.preferredIntervals = [15]

        commandCenter.skipForwardCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            self.seek(to: min(self.duration, self.currentTime + 15))
            return .success
        }

        commandCenter.skipBackwardCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            self.seek(to: max(0, self.currentTime - 15))
            return .success
        }
    }

    func updateNowPlayingInfo() {
        guard let track = currentTrack else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }

        var info = [String: Any]()
        info[MPMediaItemPropertyTitle] = track.name
        info[MPMediaItemPropertyArtist] = track.artistName
        info[MPMediaItemPropertyAlbumTitle] = track.albumName
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        info[MPMediaItemPropertyPlaybackDuration] = duration > 0 ? duration : 0
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0

        // Add media type
        info[MPMediaItemPropertyMediaType] = MPMediaType.music.rawValue

        // Set Now Playing info immediately
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info

        logger.info("🎵 Now Playing updated: \(track.name)")

        // Add artwork if available
        if let artworkURL = track.artworkURL,
           let url = URL(string: artworkURL) {
            Task {
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    if let image = UIImage(data: data) {
                        let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }

                        await MainActor.run {
                            if var currentInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo,
                               currentInfo[MPMediaItemPropertyTitle] as? String == track.name {
                                currentInfo[MPMediaItemPropertyArtwork] = artwork
                                MPNowPlayingInfoCenter.default().nowPlayingInfo = currentInfo
                            }
                        }
                    }
                } catch {
                    logger.error("Failed to load artwork: \(error)")
                }
            }
        }
    }

    // MARK: - Error Handling

    private func handlePlaybackError(_ error: Error?) {
        let errorDescription = error?.localizedDescription ?? "Playback failed"
        errorMessage = errorDescription
        isPlaying = false

        logger.error("Playback Error: \(errorDescription)")
        if let error = error {
            logger.error("Error details: \(error)")
        }

        // Retry logic for network errors
        if let nsError = error as NSError? {
            switch nsError.code {
            case -1004, -1009: // Cannot connect to host, no internet
                logger.info("Network error detected, will retry in 2 seconds")
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                    self?.playCurrentTrack()
                }
            default:
                break
            }
        }
    }

    // MARK: - Recently Played Tracking

    private func trackRecentPlay() {
        guard let track = currentTrack, let albumId = track.albumId, !albumId.isEmpty else { return }
        recentlyPlayedAlbumIds.removeAll { $0 == albumId }
        recentlyPlayedAlbumIds.insert(albumId, at: 0)
        if recentlyPlayedAlbumIds.count > 20 {
            recentlyPlayedAlbumIds = Array(recentlyPlayedAlbumIds.prefix(20))
        }
        UserDefaults.standard.set(recentlyPlayedAlbumIds, forKey: "recentlyPlayedAlbumIds")
    }

    // MARK: - Notifications

    private func setupNotifications() {
        // CRITICAL: Track endings for gapless playback
        // This observer is set up ONCE and persists for the lifetime of PlayerManager
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)
            .sink { [weak self] notification in
                self?.handleTrackFinishedGapless(notification)
            }
            .store(in: &cancellables)

        // Audio interruption handling
        NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)
            .sink { [weak self] notification in
                guard let info = notification.userInfo,
                      let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
                      let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

                switch type {
                case .began:
                    self?.player?.pause()
                    self?.isPlaying = false
                case .ended:
                    // Re-activate audio session and resume playback
                    do {
                        try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
                        if let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt,
                           AVAudioSession.InterruptionOptions(rawValue: optionsValue).contains(.shouldResume) {
                            self?.player?.play()
                            self?.isPlaying = true
                        }
                    } catch {
                        self?.logger.error("Failed to reactivate audio session: \(error)")
                    }
                @unknown default:
                    break
                }
            }
            .store(in: &cancellables)

        // Route change handling (e.g., headphones disconnected)
        NotificationCenter.default.publisher(for: AVAudioSession.routeChangeNotification)
            .sink { [weak self] notification in
                guard let info = notification.userInfo,
                      let reasonValue = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
                      let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }

                switch reason {
                case .oldDeviceUnavailable:
                    // Headphones were unplugged, pause playback
                    self?.player?.pause()
                    self?.isPlaying = false
                case .categoryChange:
                    // Re-configure audio session if category changed
                    self?.configureAudioSession()
                default:
                    break
                }
            }
            .store(in: &cancellables)

        // App lifecycle notifications
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                // App is going to background - ensure playback continues
                self?.updateNowPlayingInfo()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                guard let self = self else { return }
                // App entered background - ensure audio session is still active
                do {
                    try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
                    self.updateNowPlayingInfo()
                    self.logger.info("🔵 Maintained audio session in background")
                } catch {
                    self.logger.error("Failed to maintain audio session in background: \(error)")
                }
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                // App returning to foreground - reactivate audio session
                do {
                    try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
                } catch {
                    self?.logger.error("Failed to reactivate audio session: \(error)")
                }
            }
            .store(in: &cancellables)
    }
}
