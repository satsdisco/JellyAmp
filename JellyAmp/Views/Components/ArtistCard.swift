import SwiftUI

struct ArtistCard: View {
    let artist: Artist
    @State private var wikiImageURL: String?

    private var effectiveArtworkURL: String? {
        artist.artworkURL ?? wikiImageURL
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Artist artwork (square with rounded corners — matches PWA)
            if let artworkURL = effectiveArtworkURL, let url = URL(string: artworkURL) {
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
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                    case .failure:
                        placeholderArtwork
                    @unknown default:
                        placeholderArtwork
                    }
                }
                .transaction { $0.animation = nil }
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: .infinity)
            } else {
                placeholderArtwork
            }

            // Artist info
            VStack(alignment: .leading, spacing: 4) {
                Text(artist.name)
                    .font(.jellyAmpBody)
                    .foregroundColor(Color.jellyAmpText)
                    .lineLimit(1)
            }
        }
        .task {
            if artist.artworkURL == nil {
                wikiImageURL = await ArtistImageService.shared.getImageURL(for: artist.name)
            }
        }
    }

    private var placeholderArtwork: some View {
        let hue = ArtistPlaceholderHelper.hue(for: artist.name)
        let hue2 = (hue + 30.0).truncatingRemainder(dividingBy: 360.0)

        return ZStack {
            RoundedRectangle(cornerRadius: 12)
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
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )

            Text(ArtistPlaceholderHelper.initials(for: artist.name))
                .font(.system(.title, weight: .bold))
                .foregroundColor(.white.opacity(0.6))
        }
    }
}
