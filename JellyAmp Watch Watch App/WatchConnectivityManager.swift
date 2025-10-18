//
//  WatchConnectivityManager.swift
//  JellyAmp Watch
//
//  Syncs authentication and favorites between iPhone and Apple Watch
//

import Foundation
import WatchConnectivity
import Combine

/// Manages WatchConnectivity session for watch app - syncs credentials and favorites
class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()

    @Published var isPhoneReachable = false

    private var session: WCSession?
    private let jellyfinService = WatchJellyfinService.shared

    override init() {
        super.init()

        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }

    // MARK: - Request Credentials

    func requestCredentials() {
        guard let session = session, session.isReachable else {
            print("⚠️ Phone not reachable - cannot sync credentials")
            return
        }

        let message: [String: Any] = ["action": "requestCredentials"]
        session.sendMessage(message, replyHandler: { reply in
            self.handleCredentialsReply(reply)
        }) { error in
            print("❌ Failed to request credentials: \(error.localizedDescription)")
        }
    }

    private func handleCredentialsReply(_ reply: [String: Any]) {
        guard let baseURL = reply["baseURL"] as? String,
              let accessToken = reply["accessToken"] as? String,
              let userId = reply["userId"] as? String,
              let userName = reply["userName"] as? String else {
            print("⚠️ Invalid credentials response")
            return
        }

        DispatchQueue.main.async {
            self.jellyfinService.setCredentials(
                baseURL: baseURL,
                accessToken: accessToken,
                userId: userId,
                userName: userName
            )
            print("✅ Synced credentials from iPhone")
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("❌ Watch session activation failed: \(error.localizedDescription)")
        } else {
            print("✅ Watch session activated")
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isPhoneReachable = session.isReachable
            print("📱 Phone reachable: \(session.isReachable)")
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        DispatchQueue.main.async {
            self.syncFromContext(applicationContext)
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        if let action = message["action"] as? String, action == "requestCredentials" {
            // This shouldn't happen on watch, but handle gracefully
            replyHandler([:])
            return
        }

        DispatchQueue.main.async {
            self.syncFromContext(message)
        }
    }

    private func syncFromContext(_ context: [String: Any]) {
        // Sync credentials if provided
        if let baseURL = context["baseURL"] as? String,
           let accessToken = context["accessToken"] as? String,
           let userId = context["userId"] as? String,
           let userName = context["userName"] as? String {
            jellyfinService.setCredentials(
                baseURL: baseURL,
                accessToken: accessToken,
                userId: userId,
                userName: userName
            )
            print("✅ Auto-synced credentials from iPhone")
        }

        // TODO: Sync favorites, play history, etc.
    }
}
