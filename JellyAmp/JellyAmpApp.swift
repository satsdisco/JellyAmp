//
//  JellyAmpApp.swift
//  JellyAmp
//
//  Created by Grafton on 10/17/25.
//

import SwiftUI
import AVFoundation

@main
struct JellyAmpApp: App {
    @Environment(\.scenePhase) private var scenePhase

    // Initialize Watch Connectivity
    private let watchConnectivity = PhoneConnectivityManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleScenePhaseChange(oldPhase: oldPhase, newPhase: newPhase)
        }
    }

    /// Handle scene phase changes to maintain background audio
    private func handleScenePhaseChange(oldPhase: ScenePhase, newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            // App became active (foreground)
            print("🟢 App became active")

        case .inactive:
            // App is transitioning (e.g., control center, notification)
            print("🟡 App became inactive")

        case .background:
            // App went to background - CRITICAL for background audio
            print("🔵 App entered background - Audio should continue playing")

            // Ensure audio session remains active
            do {
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setActive(true)
                print("✅ Audio session kept active in background")
            } catch let error as NSError {
                print("❌ Failed to keep audio session active in background: \(error.localizedDescription) (code: \(error.code))")
            }

        @unknown default:
            break
        }
    }
}
