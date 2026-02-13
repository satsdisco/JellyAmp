import SwiftUI

struct ArtistCard: View {
    let artist: Artist

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Artist artwork (square with rounded corners — matches PWA)
            if let artworkURL = artist.artworkURL, let url = URL(string: artworkURL) {
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
    }

    private var placeholderArtwork: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.jellyAmpTertiary.opacity(0.5),
                            Color.jellyAmpSecondary.opacity(0.5),
                            Color.jellyAmpAccent.opacity(0.5)
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
                .shadow(color: .black.opacity(0.2), radius: 8, y: 4)

            // Artist icon
            Image(systemName: "music.mic")
                .font(.title)
                .foregroundColor(.white.opacity(0.4))
        }
    }
}
