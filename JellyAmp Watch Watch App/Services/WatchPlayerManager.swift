//
//  WatchPlayerManager.swift
//  JellyAmp Watch
//
//  Audio player for Apple Watch with cellular streaming support
//

import Foundation
import AVFoundation
import MediaPlayer
import Combine
import WatchKit
import WidgetKit

class WatchPlayerManager: NSObject, ObservableObject {
    static let shared = WatchPlayerManager()

    // MARK: - Published Properties
    @Published var currentTrack: WatchTrack?
    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var queue: [WatchTrack] = []
    @Published var currentIndex: Int = 0
    @Published var volume: Float = 1.0

    private var player: AVPlayer?
    private var timeObserver: Any?
    private let jellyfinService = WatchJellyfinService.shared

    // CRITICAL: Extended runtime session for background audio on watchOS
    private var extendedRuntimeSession: WKExtendedRuntimeSession?

    override init() {
        super.init()
        setupAudioSession()
        setupRemoteControls()
        setupNotifications()
    }

    // MARK: - Audio Session

    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            // Configure for background playback on watchOS
            // Note: allowAirPlay is not available on watchOS, only Bluetooth
            try audioSession.setCategory(.playback,
                                       mode: .default,
                                       options: [.allowBluetoothA2DP])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            print("✅ Watch audio session configured for background playback")
        } catch {
            print("❌ Watch audio session failed: \(error)")
        }
    }

    /// Ensures audio session is active before playback (critical for watchOS background audio)
    private func activateAudioSessionIfNeeded() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            if !audioSession.isOtherAudioPlaying {
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            }
        } catch {
            print("⚠️ Failed to activate audio session: \(error)")
        }
    }

    // MARK: - Extended Runtime Session (Critical for watchOS background audio)

    /// Starts extended runtime session for background audio
    /// This is REQUIRED for audio to continue when Watch screen is off
    private func startExtendedRuntimeSession() {
        // Clean up any existing session
        stopExtendedRuntimeSession()

        // Create new session
        extendedRuntimeSession = WKExtendedRuntimeSession()
        extendedRuntimeSession?.delegate = self

        // Start the session
        extendedRuntimeSession?.start()
        print("🔄 Extended runtime session started for background audio")
    }

    /// Stops extended runtime session
    private func stopExtendedRuntimeSession() {
        guard let session = extendedRuntimeSession else { return }
        session.invalidate()
        extendedRuntimeSession = nil
        print("⏹️ Extended runtime session stopped")
    }

    // MARK: - Playback

    func play(tracks: [WatchTrack], startingAt index: Int = 0) {
        guard !tracks.isEmpty, index < tracks.count else { return }

        queue = tracks
        currentIndex = index
        playCurrentTrack()
    }

    func play(_ track: WatchTrack) {
        queue = [track]
        currentIndex = 0
        playCurrentTrack()
    }

    private func playCurrentTrack() {
        guard currentIndex < queue.count else { return }

        let track = queue[currentIndex]
        currentTrack = track
        duration = track.duration
        currentTime = 0

        guard let streamURL = jellyfinService.getStreamingURL(for: track.id) else {
            print("❌ Failed to get streaming URL")
            return
        }

        print("🎵 Playing: \(track.name)")

        // Clean up old player
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
        player?.pause()

        // CRITICAL: Ensure audio session is active before playback (watchOS background audio)
        activateAudioSessionIfNeeded()

        // CRITICAL: Start extended runtime session for background playback
        startExtendedRuntimeSession()

        // Create new player
        let playerItem = AVPlayerItem(url: streamURL)
        player = AVPlayer(playerItem: playerItem)
        player?.automaticallyWaitsToMinimizeStalling = true

        // Setup time observer
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentTime = time.seconds
        }

        // Observe track end
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(trackEnded),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )

        // Apply current volume
        player?.volume = self.volume

        // Start playback
        player?.play()
        isPlaying = true
        updateNowPlayingInfo()
    }

    func togglePlayPause() {
        guard let player = player else { return }

        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            // Ensure audio session is active when resuming (important for watchOS background)
            activateAudioSessionIfNeeded()
            player.play()
            isPlaying = true
        }
        updateNowPlayingInfo()
    }

    func playNext() {
        guard currentIndex < queue.count - 1 else { return }
        currentIndex += 1
        playCurrentTrack()
    }

    func playPrevious() {
        if currentTime > 3.0 {
            seek(to: 0)
        } else if currentIndex > 0 {
            currentIndex -= 1
            playCurrentTrack()
        }
    }

    func setVolume(_ volume: Float) {
        self.volume = max(0, min(1, volume))
        player?.volume = self.volume
    }

    func seek(to time: Double) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cmTime)
        currentTime = time
        updateNowPlayingInfo()
    }

    @objc private func trackEnded() {
        if currentIndex < queue.count - 1 {
            playNext()
        } else {
            isPlaying = false
            stopExtendedRuntimeSession()
        }
    }

    // MARK: - Now Playing

    private func updateNowPlayingInfo() {
        guard let track = currentTrack else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            updateComplicationData(track: nil)
            return
        }

        let info: [String: Any] = [
            MPMediaItemPropertyTitle: track.name,
            MPMediaItemPropertyArtist: track.artist,
            MPMediaItemPropertyAlbumTitle: track.album,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        updateComplicationData(track: track)
    }

    /// Write now-playing data to shared App Group for complications
    private func updateComplicationData(track: WatchTrack?) {
        guard let defaults = UserDefaults(suiteName: "group.jellyampos.Jellywatch.JellyAmp") else { return }

        if let track = track {
            defaults.set(track.name, forKey: "complication_trackName")
            defaults.set(track.artist, forKey: "complication_artistName")
            defaults.set(track.album, forKey: "complication_albumName")
            defaults.set(isPlaying, forKey: "complication_isPlaying")
        } else {
            defaults.removeObject(forKey: "complication_trackName")
            defaults.removeObject(forKey: "complication_artistName")
            defaults.removeObject(forKey: "complication_albumName")
            defaults.set(false, forKey: "complication_isPlaying")
        }

        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Remote Controls

    private func setupRemoteControls() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.player?.play()
            self?.isPlaying = true
            return .success
        }

        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.player?.pause()
            self?.isPlaying = false
            return .success
        }

        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.playNext()
            return .success
        }

        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.playPrevious()
            return .success
        }
    }

    // MARK: - Notifications

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
    }

    @objc private func handleInterruption(notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        if type == .began {
            player?.pause()
            isPlaying = false
        } else if type == .ended {
            // Reactivate audio session after interruption
            activateAudioSessionIfNeeded()

            if let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt,
               AVAudioSession.InterruptionOptions(rawValue: optionsValue).contains(.shouldResume) {
                player?.play()
                isPlaying = true
            }
        }
    }
}

// MARK: - WKExtendedRuntimeSessionDelegate

extension WatchPlayerManager: WKExtendedRuntimeSessionDelegate {
    func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        print("✅ Extended runtime session started successfully")
    }
    
    func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        print("⚠️ Extended runtime session will expire soon")
    }
    
    func extendedRuntimeSession(_ extendedRuntimeSession: WKExtendedRuntimeSession, didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason, error: Error?) {
        print("⏹️ Extended runtime session invalidated: \(reason.rawValue)")
        if let error = error {
            print("   Error: \(error.localizedDescription)")
        }
    }
}
