import SwiftUI

struct AlbumCard: View {
    let album: Album

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Album Artwork
            ZStack {
                if let artworkURL = album.artworkURL, let url = URL(string: artworkURL) {
                    CachedAsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            placeholderArtwork
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(1, contentMode: .fill)
                                .frame(maxWidth: .infinity)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        case .failure:
                            placeholderArtwork
                        @unknown default:
                            placeholderArtwork
                        }
                    }
                    .transaction { $0.animation = nil }
                    .aspectRatio(1, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                } else {
                    placeholderArtwork
                }
            }

            // Album Info
            VStack(alignment: .leading, spacing: 4) {
                Text(album.name)
                    .font(.jellyAmpBody)
                    .foregroundColor(Color.jellyAmpText)
                    .lineLimit(1)

                Text(album.artistName)
                    .font(.jellyAmpCaption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                if let showDate = ShowDateParser.parse(album.name) {
                    Text(ShowDateParser.format(showDate))
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.neonCyan.opacity(0.6))
                } else if let year = album.year {
                    Text(String(year))
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.neonCyan.opacity(0.6))
                }
            }
        }
        .contentShape(Rectangle())
    }

    private var placeholderArtwork: some View {
        let hue = AlbumPlaceholderHelper.hue(for: album.name)
        let hue2 = (hue + 40.0).truncatingRemainder(dividingBy: 360.0)

        return RoundedRectangle(cornerRadius: 12)
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
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
            .overlay(
                VStack(spacing: 4) {
                    Text(album.name)
                        .font(.system(.caption, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    Text(album.artistName)
                        .font(.system(.caption2))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(1)
                }
                .padding(8)
            )
    }
}
