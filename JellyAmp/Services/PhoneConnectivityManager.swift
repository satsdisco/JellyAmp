//
//  PhoneConnectivityManager.swift
//  JellyAmp
//
//  Manages communication with Apple Watch
//  Sends playback state updates and handles remote control commands from watch
//

import Foundation
import WatchConnectivity
import Combine

/// Manages WatchConnectivity session for iPhone app
class PhoneConnectivityManager: NSObject, ObservableObject {
    static let shared = PhoneConnectivityManager()

    private var session: WCSession?
    private var cancellables = Set<AnyCancellable>()
    private let playerManager = PlayerManager.shared

    override init() {
        super.init()

        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }

        // Observe player state changes and send to watch
        setupPlayerObservers()
    }

    // MARK: - Setup Observers

    private func setupPlayerObservers() {
        // Observe authentication changes and sync to watch
        JellyfinService.shared.$isAuthenticated
            .sink { [weak self] isAuth in
                if isAuth {
                    self?.syncCredentialsToWatch()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Sync Credentials to Watch

    func syncCredentialsToWatch() {
        guard let session = session, session.activationState == .activated else {
            return
        }

        let jellyfin = JellyfinService.shared

        guard jellyfin.isAuthenticated,
              let accessToken = KeychainService.shared.getAccessToken(),
              let userId = UserDefaults.standard.string(forKey: "jellyfinUserId") else {
            print("⚠️ Cannot sync - not authenticated")
            return
        }

        let context: [String: Any] = [
            "baseURL": jellyfin.baseURL,
            "accessToken": accessToken,
            "userId": userId,
            "userName": jellyfin.currentUser?.Name ?? "User"
        ]

        // Send as application context (persistent)
        do {
            try session.updateApplicationContext(context)
            print("✅ Synced credentials to watch")
        } catch {
            print("❌ Failed to sync credentials: \(error)")
        }
    }
}

// MARK: - WCSessionDelegate

extension PhoneConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("❌ Phone session activation failed: \(error.localizedDescription)")
        } else {
            print("✅ Phone session activated")
            // Sync credentials to watch
            syncCredentialsToWatch()
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        print("📱 Session became inactive")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        print("📱 Session deactivated")
        // Reactivate for new watch
        session.activate()
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        print("📱 Watch reachable: \(session.isReachable)")
        if session.isReachable {
            syncCredentialsToWatch()
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        if let action = message["action"] as? String, action == "requestCredentials" {
            // Watch is requesting credentials
            handleCredentialsRequest(replyHandler: replyHandler)
            return
        }

        replyHandler([:])
    }

    // MARK: - Handle Credentials Request

    private func handleCredentialsRequest(replyHandler: @escaping ([String: Any]) -> Void) {
        let jellyfin = JellyfinService.shared

        guard jellyfin.isAuthenticated,
              let accessToken = KeychainService.shared.getAccessToken(),
              let userId = UserDefaults.standard.string(forKey: "jellyfinUserId") else {
            print("⚠️ Cannot provide credentials - not authenticated")
            replyHandler([:])
            return
        }

        let credentials: [String: Any] = [
            "baseURL": jellyfin.baseURL,
            "accessToken": accessToken,
            "userId": userId,
            "userName": jellyfin.currentUser?.Name ?? "User"
        ]

        print("✅ Sending credentials to watch")
        replyHandler(credentials)
    }
}
