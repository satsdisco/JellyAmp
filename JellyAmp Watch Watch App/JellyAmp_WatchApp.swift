//
//  JellyAmp_WatchApp.swift
//  JellyAmp Watch Watch App
//
//  Created by Grafton on 10/17/25.
//

import SwiftUI

@main
struct JellyAmp_Watch_Watch_AppApp: App {
    // Initialize Watch Connectivity
    private let watchConnectivity = WatchConnectivityManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
