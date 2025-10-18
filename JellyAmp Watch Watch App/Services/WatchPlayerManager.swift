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

class WatchPlayerManager: NSObject, ObservableObject {
    static let shared = WatchPlayerManager()

    // MARK: - Published Properties
    @Published var currentTrack: WatchTrack?
    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var queue: [WatchTrack] = []
    @Published var currentIndex: Int = 0

    private var player: AVPlayer?
    private var timeObserver: Any?
    private let jellyfinService = WatchJellyfinService.shared

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
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
            print("✅ Watch audio session configured")
        } catch {
            print("❌ Watch audio session failed: \(error)")
        }
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
        }
    }

    // MARK: - Now Playing

    private func updateNowPlayingInfo() {
        guard let track = currentTrack else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
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
            if let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt,
               AVAudioSession.InterruptionOptions(rawValue: optionsValue).contains(.shouldResume) {
                player?.play()
                isPlaying = true
            }
        }
    }
}
