import SwiftUI

/// Waveform-style progress bar that replaces the standard slider.
/// Generates pseudo-random bars from track ID for consistent appearance.
struct WaveformView: View {
    let currentTime: Double
    let duration: Double
    let trackId: String
    let onSeek: (Double) -> Void

    var barCount: Int = 60

    @State private var isDragging = false
    @State private var dragTime: Double = 0

    private var progress: Double {
        guard duration > 0 else { return 0 }
        let time = isDragging ? dragTime : currentTime
        return min(max(time / duration, 0), 1)
    }

    private var bars: [CGFloat] {
        generateBars(for: trackId, count: barCount)
    }

    var body: some View {
        GeometryReader { geo in
            HStack(alignment: .center, spacing: 1.5) {
                ForEach(0..<bars.count, id: \.self) { index in
                    let barProgress = Double(index) / Double(bars.count)
                    let isPlayed = barProgress <= progress

                    RoundedRectangle(cornerRadius: 1)
                        .fill(isPlayed ? Color.neonCyan : Color.white.opacity(0.12))
                        .frame(height: geo.size.height * bars[index])
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isDragging = true
                        let pct = min(max(value.location.x / geo.size.width, 0), 1)
                        dragTime = pct * duration
                    }
                    .onEnded { value in
                        let pct = min(max(value.location.x / geo.size.width, 0), 1)
                        onSeek(pct * duration)
                        isDragging = false
                    }
            )
        }
    }

    // MARK: - Bar Generation (seeded pseudo-random, matches PWA)

    private func generateBars(for id: String, count: Int) -> [CGFloat] {
        var seed = hashString(id)
        var bars: [CGFloat] = []

        for i in 0..<count {
            seed = (seed &* 9301 &+ 49297) % 233280
            let raw = CGFloat(seed) / 233280.0
            let baseHeight = 0.3 + raw * 0.7

            let smoothingFactor: CGFloat = 0.15
            let prevHeight = i > 0 ? bars[i - 1] : baseHeight
            let height = prevHeight * smoothingFactor + baseHeight * (1 - smoothingFactor)
            bars.append(min(max(height, 0.2), 1.0))
        }
        return bars
    }

    private func hashString(_ str: String) -> Int {
        var hash = 0
        for char in str.unicodeScalars {
            hash = ((hash &<< 5) &- hash) &+ Int(char.value)
        }
        return abs(hash)
    }
}
