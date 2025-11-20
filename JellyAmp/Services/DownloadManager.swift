//
//  DownloadManager.swift
//  JellyAmp
//
//  Manages offline downloads for tracks and albums
//  Stores audio files locally for offline playback
//

import Foundation
import Combine
import os.log
import UserNotifications
import UIKit

/// Download state for a track
enum DownloadState: Equatable {
    case notDownloaded
    case downloading(progress: Double)
    case downloaded
    case failed(error: String)

    var isDownloaded: Bool {
        if case .downloaded = self {
            return true
        }
        return false
    }
}

/// Metadata for a downloaded track
struct DownloadedTrack: Codable {
    let trackId: String
    let fileName: String
    let fileSize: Int64
    let downloadDate: Date
    let trackName: String
    let artistName: String
    let albumName: String
    let duration: TimeInterval?
    let albumId: String

    // Track organization metadata
    let trackNumber: Int?
    let discNumber: Int?
    let artistId: String?
    let productionYear: Int?
    let artworkURL: String? // For caching album artwork

    /// Convert to Track for playback
    func toTrack() -> Track {
        return Track(
            id: trackId,
            name: trackName,
            artistName: artistName,
            albumName: albumName,
            duration: duration ?? 0,
            artworkURL: nil, // Local files don't need artwork URL
            isFavorite: false, // Can implement favorites for downloads later
            indexNumber: trackNumber,
            parentIndexNumber: discNumber,
            albumId: albumId,
            artistId: artistId,
            productionYear: productionYear
        )
    }
}

/// Represents a downloaded album with all its tracks
struct DownloadedAlbum: Identifiable {
    let albumId: String
    let albumName: String
    let artistName: String
    let artistId: String?
    let productionYear: Int?
    let tracks: [DownloadedTrack]

    var id: String { albumId }

    var trackCount: Int { tracks.count }

    var totalSize: Int64 {
        tracks.reduce(0) { $0 + $1.fileSize }
    }

    var totalDuration: TimeInterval {
        tracks.compactMap { $0.duration }.reduce(0, +)
    }

    var formattedDuration: String {
        let totalSeconds = Int(totalDuration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

/// Manages downloading and storing music files for offline playback
class DownloadManager: NSObject, ObservableObject {
    static let shared = DownloadManager()

    private let logger = Logger(subsystem: "com.jellyamp.app", category: "DownloadManager")

    // MARK: - Published Properties
    @Published var downloadStates: [String: DownloadState] = [:] // trackId -> state
    @Published var downloadedTracks: [DownloadedTrack] = []
    @Published var totalStorageUsed: Int64 = 0
    @Published var activeDownloads: Int = 0 // Number of currently downloading tracks

    // MARK: - Computed Properties for Organization

    /// Downloaded tracks grouped by album, sorted by track order
    var downloadedAlbums: [DownloadedAlbum] {
        let grouped = Dictionary(grouping: downloadedTracks) { $0.albumId }

        return grouped.map { albumId, tracks in
            let sortedTracks = tracks.sorted { track1, track2 in
                // Sort by disc number first, then track number
                let disc1 = track1.discNumber ?? 1
                let disc2 = track2.discNumber ?? 1

                if disc1 != disc2 {
                    return disc1 < disc2
                }

                let track1Num = track1.trackNumber ?? 0
                let track2Num = track2.trackNumber ?? 0
                return track1Num < track2Num
            }

            // Use metadata from first track for album info
            let firstTrack = sortedTracks.first!
            return DownloadedAlbum(
                albumId: albumId,
                albumName: firstTrack.albumName,
                artistName: firstTrack.artistName,
                artistId: firstTrack.artistId,
                productionYear: firstTrack.productionYear,
                tracks: sortedTracks
            )
        }.sorted { album1, album2 in
            // Sort albums by year (newest first), then name
            if let year1 = album1.productionYear, let year2 = album2.productionYear, year1 != year2 {
                return year1 > year2
            }
            return album1.albumName < album2.albumName
        }
    }

    /// Total number of downloaded albums
    var downloadedAlbumCount: Int {
        Set(downloadedTracks.map { $0.albumId }).count
    }

    // MARK: - Helper Methods

    /// Get download progress for a specific album (0.0 to 1.0)
    func getAlbumDownloadProgress(trackIds: [String]) -> Double {
        guard !trackIds.isEmpty else { return 0.0 }

        var totalProgress = 0.0
        for trackId in trackIds {
            if let state = downloadStates[trackId] {
                switch state {
                case .downloaded:
                    totalProgress += 1.0
                case .downloading(let progress):
                    totalProgress += progress
                case .notDownloaded, .failed:
                    totalProgress += 0.0
                }
            }
        }

        return totalProgress / Double(trackIds.count)
    }

    /// Check if an album is fully downloaded
    func isAlbumDownloaded(trackIds: [String]) -> Bool {
        guard !trackIds.isEmpty else { return false }
        return trackIds.allSatisfy { isDownloaded(trackId: $0) }
    }

    /// Check if an album is currently downloading
    func isAlbumDownloading(trackIds: [String]) -> Bool {
        return trackIds.contains { trackId in
            if case .downloading = downloadStates[trackId] {
                return true
            }
            return false
        }
    }

    // MARK: - Private Properties
    private let fileManager = FileManager.default
    private var downloadTasks: [String: URLSessionDownloadTask] = [:] // trackId -> task
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "com.jellyamp.downloads")
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    private let jellyfinService = JellyfinService.shared

    // Storage keys
    private let downloadedTracksKey = "downloadedTracks"

    // MARK: - Initialization

    override init() {
        super.init()
        loadDownloadedTracks()
        calculateStorageUsed()
    }

    // MARK: - Download Directory

    /// Returns the downloads directory, creating it if needed
    private var downloadsDirectory: URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let downloadsPath = documentsPath.appendingPathComponent("Downloads", isDirectory: true)

        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: downloadsPath.path) {
            try? fileManager.createDirectory(at: downloadsPath, withIntermediateDirectories: true)
        }

        return downloadsPath
    }

    /// Returns the artwork cache directory, creating it if needed
    private var artworkCacheDirectory: URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let artworkPath = documentsPath.appendingPathComponent("AlbumArtwork", isDirectory: true)

        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: artworkPath.path) {
            try? fileManager.createDirectory(at: artworkPath, withIntermediateDirectories: true)
        }

        return artworkPath
    }

    // Store track metadata temporarily for downloads in progress
    private var pendingDownloads: [String: Track] = [:] // trackId -> Track

    // Track which albums are being downloaded to send completion notifications
    private var downloadingAlbums: [String: Set<String>] = [:] // albumId -> Set of trackIds

    // MARK: - Download Operations

    /// Download a single track
    func downloadTrack(_ track: Track) {
        guard downloadStates[track.id] != .downloaded else {
            logger.info("Track already downloaded: \(track.name)")
            return
        }

        guard downloadStates[track.id] != .downloading(progress: 0) else {
            logger.info("Track already downloading: \(track.name)")
            return
        }

        // Get download URL from Jellyfin (direct file, not transcoded)
        guard let downloadURL = jellyfinService.getDownloadURL(for: track.id) else {
            logger.error("Failed to get download URL for track: \(track.name)")
            downloadStates[track.id] = .failed(error: "Could not get download URL")
            return
        }

        logger.info("Starting download: \(track.name)")

        DispatchQueue.main.async {
            self.downloadStates[track.id] = .downloading(progress: 0)
            self.activeDownloads += 1
        }

        // Store track metadata for when download completes
        pendingDownloads[track.id] = track

        let task = urlSession.downloadTask(with: downloadURL)
        task.taskDescription = track.id // Store track ID in task for later reference
        downloadTasks[track.id] = task
        task.resume()
    }

    /// Download all tracks in an album
    func downloadAlbum(tracks: [Track]) {
        logger.info("Starting album download: \(tracks.count) tracks")

        // Download artwork for the album (use first track's artwork)
        if let firstTrack = tracks.first, let albumId = firstTrack.albumId {
            // Track this album download for completion notification
            let trackIds = Set(tracks.map { $0.id })
            downloadingAlbums[albumId] = trackIds

            Task {
                await cacheArtwork(for: albumId, from: firstTrack.artworkURL)
            }
        }

        // Download all tracks
        for track in tracks {
            downloadTrack(track)
        }
    }

    /// Delete a downloaded track
    func deleteDownload(trackId: String) {
        // Cancel active download if any
        if let task = downloadTasks[trackId] {
            task.cancel()
            downloadTasks.removeValue(forKey: trackId)
        }

        // Clean up pending downloads
        pendingDownloads.removeValue(forKey: trackId)

        // Find downloaded track metadata
        guard let downloadedTrack = downloadedTracks.first(where: { $0.trackId == trackId }) else {
            logger.warning("No downloaded track found for ID: \(trackId)")
            downloadStates[trackId] = .notDownloaded
            return
        }

        // Delete file
        let fileURL = downloadsDirectory.appendingPathComponent(downloadedTrack.fileName)
        try? fileManager.removeItem(at: fileURL)

        // Remove from metadata
        downloadedTracks.removeAll { $0.trackId == trackId }
        downloadStates[trackId] = .notDownloaded

        saveDownloadedTracks()
        calculateStorageUsed()

        logger.info("Deleted download: \(downloadedTrack.trackName)")
    }

    /// Delete all downloads
    func deleteAllDownloads() {
        logger.info("Deleting all downloads")

        // Cancel all active downloads
        for (_, task) in downloadTasks {
            task.cancel()
        }
        downloadTasks.removeAll()

        // Clear pending downloads
        pendingDownloads.removeAll()

        // Get all unique album IDs for artwork cleanup
        let albumIds = Set(downloadedTracks.map { $0.albumId })

        // Delete all files
        for downloadedTrack in downloadedTracks {
            let fileURL = downloadsDirectory.appendingPathComponent(downloadedTrack.fileName)
            try? fileManager.removeItem(at: fileURL)
        }

        // Delete all cached artwork
        for albumId in albumIds {
            deleteCachedArtwork(for: albumId)
        }

        // Clear metadata
        downloadedTracks.removeAll()
        downloadStates.removeAll()

        saveDownloadedTracks()
        calculateStorageUsed()
    }

    // MARK: - Playback Support

    /// Get local file URL for a track if downloaded, nil otherwise
    func getLocalURL(for trackId: String) -> URL? {
        guard let downloadedTrack = downloadedTracks.first(where: { $0.trackId == trackId }) else {
            return nil
        }

        let fileURL = downloadsDirectory.appendingPathComponent(downloadedTrack.fileName)

        // Verify file still exists
        guard fileManager.fileExists(atPath: fileURL.path) else {
            logger.warning("Downloaded file missing for track: \(trackId)")
            // Clean up metadata
            downloadedTracks.removeAll { $0.trackId == trackId }
            downloadStates[trackId] = .notDownloaded
            saveDownloadedTracks()
            return nil
        }

        return fileURL
    }

    /// Check if a track is downloaded
    func isDownloaded(trackId: String) -> Bool {
        return downloadStates[trackId]?.isDownloaded ?? false
    }

    // MARK: - Metadata Persistence

    private func loadDownloadedTracks() {
        guard let data = UserDefaults.standard.data(forKey: downloadedTracksKey),
              let tracks = try? JSONDecoder().decode([DownloadedTrack].self, from: data) else {
            return
        }

        downloadedTracks = tracks

        // Set download states
        for track in tracks {
            downloadStates[track.trackId] = .downloaded
        }

        logger.info("Loaded \(tracks.count) downloaded tracks")
    }

    private func saveDownloadedTracks() {
        guard let data = try? JSONEncoder().encode(downloadedTracks) else {
            logger.error("Failed to encode downloaded tracks")
            return
        }

        UserDefaults.standard.set(data, forKey: downloadedTracksKey)
    }

    private func calculateStorageUsed() {
        var total: Int64 = 0

        for downloadedTrack in downloadedTracks {
            total += downloadedTrack.fileSize
        }

        DispatchQueue.main.async {
            self.totalStorageUsed = total
        }
    }

    // MARK: - Helper

    func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    // MARK: - Artwork Caching

    /// Download and cache album artwork
    func cacheArtwork(for albumId: String, from urlString: String?) async {
        guard let urlString = urlString, let url = URL(string: urlString) else {
            logger.warning("No artwork URL provided for album: \(albumId)")
            return
        }

        let artworkFileName = "\(albumId).jpg"
        let artworkPath = artworkCacheDirectory.appendingPathComponent(artworkFileName)

        // Skip if already cached
        if fileManager.fileExists(atPath: artworkPath.path) {
            logger.info("Artwork already cached for album: \(albumId)")
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)

            // Verify it's valid image data
            guard let _ = UIImage(data: data) else {
                logger.error("Invalid image data for album: \(albumId)")
                return
            }

            try data.write(to: artworkPath)
            logger.info("✅ Cached artwork for album: \(albumId) (\(self.formatBytes(Int64(data.count))))")
        } catch {
            logger.error("Failed to cache artwork for album \(albumId): \(error.localizedDescription)")
        }
    }

    /// Get cached artwork URL for an album
    func getCachedArtworkURL(for albumId: String) -> URL? {
        let artworkFileName = "\(albumId).jpg"
        let artworkPath = artworkCacheDirectory.appendingPathComponent(artworkFileName)

        guard fileManager.fileExists(atPath: artworkPath.path) else {
            return nil
        }

        return artworkPath
    }

    /// Delete cached artwork for an album
    func deleteCachedArtwork(for albumId: String) {
        let artworkFileName = "\(albumId).jpg"
        let artworkPath = artworkCacheDirectory.appendingPathComponent(artworkFileName)

        try? fileManager.removeItem(at: artworkPath)
        logger.info("Deleted cached artwork for album: \(albumId)")
    }

    // MARK: - Album Completion Tracking

    /// Check if an album download is complete and send notification
    private func checkAlbumCompletion(trackId: String, albumId: String) {
        guard var pendingTracks = downloadingAlbums[albumId] else {
            return // Not tracking this album
        }

        // Remove this track from pending
        pendingTracks.remove(trackId)

        if pendingTracks.isEmpty {
            // Album complete!
            downloadingAlbums.removeValue(forKey: albumId)

            // Get album info from downloaded tracks
            if let albumTracks = downloadedTracks.filter({ $0.albumId == albumId }).first {
                // Haptic feedback for completion
                DispatchQueue.main.async {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }

                sendAlbumCompleteNotification(
                    albumName: albumTracks.albumName,
                    artistName: albumTracks.artistName,
                    trackCount: downloadedTracks.filter({ $0.albumId == albumId }).count
                )
            }
        } else {
            // Update remaining tracks
            downloadingAlbums[albumId] = pendingTracks
        }
    }

    /// Send local notification for album download completion
    private func sendAlbumCompleteNotification(albumName: String, artistName: String, trackCount: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Download Complete"
        content.body = "\(albumName) by \(artistName) (\(trackCount) tracks)"
        content.sound = .default
        content.categoryIdentifier = "DOWNLOAD_COMPLETE"

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Deliver immediately
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                self.logger.error("Failed to send notification: \(error.localizedDescription)")
            } else {
                self.logger.info("✅ Sent album completion notification: \(albumName)")
            }
        }
    }
}

// MARK: - URLSessionDownloadDelegate

extension DownloadManager: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let trackId = downloadTask.taskDescription else {
            logger.error("Download task missing track ID")
            return
        }

        logger.info("Download completed for track: \(trackId)")

        // Get file extension from response or default to mp3
        let fileExtension = downloadTask.response?.suggestedFilename?.split(separator: ".").last.map(String.init) ?? "mp3"
        let fileName = "\(trackId).\(fileExtension)"
        let destinationURL = downloadsDirectory.appendingPathComponent(fileName)

        do {
            // Remove existing file if present
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }

            // Move downloaded file to permanent location
            try fileManager.moveItem(at: location, to: destinationURL)

            // Get file size
            let attributes = try fileManager.attributesOfItem(atPath: destinationURL.path)
            let fileSize = attributes[.size] as? Int64 ?? 0

            // Get track metadata from pending downloads
            guard let track = pendingDownloads[trackId] else {
                logger.error("❌ No track metadata found for download: \(trackId)")
                return
            }

            guard let albumId = track.albumId else {
                logger.error("❌ Cannot download track without albumId: \(track.name)")
                return
            }

            let downloadedTrack = DownloadedTrack(
                trackId: trackId,
                fileName: fileName,
                fileSize: fileSize,
                downloadDate: Date(),
                trackName: track.name,
                artistName: track.artistName,
                albumName: track.albumName,
                duration: track.duration,
                albumId: albumId,
                trackNumber: track.indexNumber,
                discNumber: track.parentIndexNumber,
                artistId: track.artistId,
                productionYear: track.productionYear,
                artworkURL: track.artworkURL
            )

            // Clean up pending downloads
            pendingDownloads.removeValue(forKey: trackId)

            DispatchQueue.main.async {
                self.downloadedTracks.append(downloadedTrack)
                self.downloadStates[trackId] = .downloaded
                self.downloadTasks.removeValue(forKey: trackId)
                self.activeDownloads = max(0, self.activeDownloads - 1)
                self.saveDownloadedTracks()
                self.calculateStorageUsed()

                // Post notification for download completion
                NotificationCenter.default.post(
                    name: NSNotification.Name("TrackDownloadCompleted"),
                    object: nil,
                    userInfo: ["trackName": downloadedTrack.trackName, "albumName": downloadedTrack.albumName]
                )

                // Check if album is complete and send notification
                self.checkAlbumCompletion(trackId: trackId, albumId: albumId)
            }

            logger.info("✅ Successfully saved download: \(fileName) (\(self.formatBytes(fileSize)))")

        } catch {
            logger.error("❌ Failed to save download: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.downloadStates[trackId] = .failed(error: error.localizedDescription)
                self.downloadTasks.removeValue(forKey: trackId)
            }
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let trackId = downloadTask.taskDescription else { return }

        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)

        DispatchQueue.main.async {
            self.downloadStates[trackId] = .downloading(progress: progress)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error = error,
              let trackId = task.taskDescription else { return }

        logger.error("Download failed for track \(trackId): \(error.localizedDescription)")

        // Clean up pending downloads
        pendingDownloads.removeValue(forKey: trackId)

        DispatchQueue.main.async {
            self.downloadStates[trackId] = .failed(error: error.localizedDescription)
            self.downloadTasks.removeValue(forKey: trackId)
            self.activeDownloads = max(0, self.activeDownloads - 1)

            // Post notification for download failure
            NotificationCenter.default.post(
                name: NSNotification.Name("TrackDownloadFailed"),
                object: nil,
                userInfo: ["trackId": trackId, "error": error.localizedDescription]
            )
        }
    }
}
