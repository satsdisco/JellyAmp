import SwiftUI

struct ArtistListRow: View {
    let artist: Artist

    var body: some View {
        HStack(spacing: 16) {
            // Artist artwork (square with rounded corners — matches PWA)
            if let artworkURL = artist.artworkURL, let url = URL(string: artworkURL) {
                CachedAsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        placeholderArtistArt
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 64, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .shadow(color: Color.jellyAmpTertiary.opacity(0.5), radius: 8, x: 0, y: 4)
                    case .failure:
                        placeholderArtistArt
                    @unknown default:
                        placeholderArtistArt
                    }
                }
                .transaction { $0.animation = nil }
                .frame(width: 64, height: 64)
            } else {
                placeholderArtistArt
            }

            // Artist info
            VStack(alignment: .leading, spacing: 4) {
                Text(artist.name)
                    .font(.body.weight(.semibold))
                    .foregroundColor(Color.jellyAmpText)
                    .lineLimit(1)
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundColor(.neonPurple.opacity(0.6))
        }
        .padding(.vertical, 14)
    }

    private var placeholderArtistArt: some View {
        let hue = ArtistPlaceholderHelper.hue(for: artist.name)
        let hue2 = (hue + 30.0).truncatingRemainder(dividingBy: 360.0)

        return ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hue: hue / 360.0, saturation: 0.4, brightness: 0.28),
                            Color(hue: hue2 / 360.0, saturation: 0.5, brightness: 0.18)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 64, height: 64)

            Text(ArtistPlaceholderHelper.initials(for: artist.name))
                .font(.system(.body, weight: .bold))
                .foregroundColor(.white.opacity(0.6))
        }
    }
}
