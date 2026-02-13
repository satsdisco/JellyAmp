//
//  PlaceholderHelper.swift
//  JellyAmp
//
//  Deterministic color generation for missing artwork — matches PWA approach.
//  Each album/artist gets a unique, consistent color based on its name.
//

import SwiftUI

/// Generates deterministic hues from names (matches PWA AlbumPlaceholder.tsx / ArtistPlaceholder.tsx)
enum AlbumPlaceholderHelper {
    /// Hash a name to a hue (0-360), offset by 180 from artists (matches PWA)
    static func hue(for name: String) -> Double {
        var hash = 0
        for char in name.unicodeScalars {
            hash = Int(char.value) &+ ((hash << 5) &- hash)
        }
        return Double(((hash % 360) + 360) % 360 + 180).truncatingRemainder(dividingBy: 360)
    }
}

enum ArtistPlaceholderHelper {
    /// Hash a name to a hue (0-360)
    static func hue(for name: String) -> Double {
        var hash = 0
        for char in name.unicodeScalars {
            hash = Int(char.value) &+ ((hash << 5) &- hash)
        }
        return Double(((hash % 360) + 360) % 360)
    }

    /// Get initials from artist name (max 2 characters)
    static func initials(for name: String) -> String {
        let words = name.split(separator: " ")
        if words.count >= 2 {
            return String(words[0].prefix(1) + words[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}
