import SwiftUI

struct ArtistListRow: View {
    let artist: Artist

    var body: some View {
            HStack(spacing: 16) {
                // Artist artwork (circular with photo if available)
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
                                .clipShape(Circle())
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
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.jellyAmpTertiary.opacity(0.5),
                            Color.jellyAmpSecondary.opacity(0.5)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 64, height: 64)

            Image(systemName: "person.circle.fill")
                .font(.title2)
                .foregroundColor(.white.opacity(0.4))
        }
    }
}

