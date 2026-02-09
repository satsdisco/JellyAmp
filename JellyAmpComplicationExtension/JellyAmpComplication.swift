//
//  JellyAmpComplication.swift
//  JellyAmpComplicationExtension
//
//  watchOS complications for JellyAmp
//

import WidgetKit
import SwiftUI

// MARK: - Shared Data

struct NowPlayingData {
    let trackName: String
    let artistName: String
    let albumName: String
    let isPlaying: Bool
    
    static let placeholder = NowPlayingData(
        trackName: "JellyAmp",
        artistName: "Music Player",
        albumName: "",
        isPlaying: false
    )
    
    static func load() -> NowPlayingData {
        guard let defaults = UserDefaults(suiteName: "group.jellyampos.Jellywatch.JellyAmp") else {
            return .placeholder
        }
        
        let track = defaults.string(forKey: "complication_trackName") ?? ""
        let artist = defaults.string(forKey: "complication_artistName") ?? ""
        let album = defaults.string(forKey: "complication_albumName") ?? ""
        let playing = defaults.bool(forKey: "complication_isPlaying")
        
        if track.isEmpty {
            return .placeholder
        }
        
        return NowPlayingData(
            trackName: track,
            artistName: artist,
            albumName: album,
            isPlaying: playing
        )
    }
}

// MARK: - Timeline Entry

struct NowPlayingEntry: TimelineEntry {
    let date: Date
    let data: NowPlayingData
}

// MARK: - Timeline Provider

struct NowPlayingProvider: TimelineProvider {
    func placeholder(in context: Context) -> NowPlayingEntry {
        NowPlayingEntry(date: .now, data: .placeholder)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (NowPlayingEntry) -> Void) {
        completion(NowPlayingEntry(date: .now, data: NowPlayingData.load()))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<NowPlayingEntry>) -> Void) {
        let entry = NowPlayingEntry(date: .now, data: NowPlayingData.load())
        // Refresh every 5 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: .now)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Complication Views

struct NowPlayingComplicationView: View {
    @Environment(\.widgetFamily) var family
    let entry: NowPlayingEntry
    
    var body: some View {
        switch family {
        case .accessoryCircular:
            circularView
        case .accessoryRectangular:
            rectangularView
        case .accessoryCorner:
            cornerView
        case .accessoryInline:
            inlineView
        default:
            circularView
        }
    }
    
    // Circular: play/pause icon with ring
    private var circularView: some View {
        ZStack {
            AccessoryWidgetBackground()
            
            if entry.data.trackName == "JellyAmp" {
                Image(systemName: "waveform")
                    .font(.title3)
                    .foregroundColor(.cyan)
            } else {
                Image(systemName: entry.data.isPlaying ? "waveform" : "pause.fill")
                    .font(.title3)
                    .foregroundColor(.cyan)
            }
        }
    }
    
    // Rectangular: track name + artist
    private var rectangularView: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: entry.data.isPlaying ? "waveform" : "music.note")
                    .font(.caption2)
                    .foregroundColor(.cyan)
                
                Text("JellyAmp")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(entry.data.trackName)
                .font(.headline)
                .lineLimit(1)
            
            Text(entry.data.artistName)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // Corner: small icon
    private var cornerView: some View {
        Image(systemName: "waveform")
            .font(.title3)
            .foregroundColor(.cyan)
            .widgetLabel {
                Text(entry.data.trackName == "JellyAmp" ? "JellyAmp" : entry.data.trackName)
            }
    }
    
    // Inline: text only
    private var inlineView: some View {
        HStack(spacing: 4) {
            Image(systemName: "waveform")
            if entry.data.trackName == "JellyAmp" {
                Text("JellyAmp")
            } else {
                Text("\(entry.data.trackName) — \(entry.data.artistName)")
            }
        }
    }
}

// MARK: - Widget

@main
struct JellyAmpComplicationWidget: Widget {
    let kind = "JellyAmpNowPlaying"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NowPlayingProvider()) { entry in
            NowPlayingComplicationView(entry: entry)
                .containerBackground(.black, for: .widget)
        }
        .configurationDisplayName("Now Playing")
        .description("Shows what's playing on JellyAmp")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryCorner,
            .accessoryInline
        ])
    }
}

// MARK: - Preview

#Preview(as: .accessoryRectangular) {
    JellyAmpComplicationWidget()
} timeline: {
    NowPlayingEntry(date: .now, data: .placeholder)
    NowPlayingEntry(date: .now, data: NowPlayingData(
        trackName: "Dark Star",
        artistName: "Grateful Dead",
        albumName: "Live/Dead",
        isPlaying: true
    ))
}
