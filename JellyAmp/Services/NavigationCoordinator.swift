//
//  NavigationCoordinator.swift
//  JellyAmp
//
//  Coordinates navigation between overlay views (NowPlaying) and the tab/navigation stack
//

import SwiftUI
import Combine

class NavigationCoordinator: ObservableObject {
    static let shared = NavigationCoordinator()

    /// Set this to navigate to an artist after dismissing NowPlaying
    @Published var pendingArtistNavigation: Artist?

    /// Set this to navigate to an album after dismissing NowPlaying
    @Published var pendingAlbumNavigation: Album?
}
