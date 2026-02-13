import SwiftUI

struct AlbumListRow: View {
    let album: Album

    var body: some View {
            HStack(spacing: 16) {
                // Album artwork (square, larger and properly centered)
                if let artworkURL = album.artworkURL, let url = URL(string: artworkURL) {
                    CachedAsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            placeholderArtwork
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .shadow(color: Color.jellyAmpAccent.opacity(0.2), radius: 8, x: 0, y: 4)
                        case .failure:
                            placeholderArtwork
                        @unknown default:
                            placeholderArtwork
                        }
                    }
                    .transaction { $0.animation = nil }
                    .frame(width: 80, height: 80)
                } else {
                    placeholderArtwork
                }

                // Album info
                VStack(alignment: .leading, spacing: 6) {
                    // Album name - bold and prominent
                    Text(album.name)
                        .font(.headline.weight(.bold))
                        .foregroundColor(Color.jellyAmpText)
                        .lineLimit(2)

                    // Artist name - secondary
                    Text(album.artistName)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    // Year and track count - clear and separated
                    HStack(spacing: 8) {
                        if let showDate = ShowDateParser.parse(album.name) {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .font(.caption2)
                                    .foregroundColor(.neonCyan)
                                Text(ShowDateParser.format(showDate))
                                    .font(.subheadline.weight(.bold))
                                    .foregroundColor(.neonCyan)
                            }
                        } else if let year = album.year {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .font(.caption2)
                                    .foregroundColor(.neonCyan)
                                Text(String(year))
                                    .font(.subheadline.weight(.bold))
                                    .foregroundColor(.neonCyan)
                            }
                        }

                        if let trackCount = album.trackCount {
                            HStack(spacing: 4) {
                                Image(systemName: "music.note.list")
                                    .font(.caption2)
                                    .foregroundColor(.neonPink.opacity(0.8))
                                Text("\(trackCount)")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.neonCyan.opacity(0.6))
            }
            .padding(.vertical, 12)
    }

    private var placeholderArtwork: some View {
        let hue = AlbumPlaceholderHelper.hue(for: album.name)
        let hue2 = (hue + 40.0).truncatingRemainder(dividingBy: 360.0)

        return ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hue: hue / 360.0, saturation: 0.45, brightness: 0.25),
                            Color(hue: hue2 / 360.0, saturation: 0.55, brightness: 0.18)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)

            Text(AlbumPlaceholderHelper.hue(for: album.name) > 0 ? String(album.name.prefix(1)).uppercased() : "♪")
                .font(.system(.title2, weight: .bold))
                .foregroundColor(.white.opacity(0.6))
        }
    }
}

