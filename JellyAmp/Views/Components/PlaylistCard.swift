import SwiftUI

struct PlaylistCard: View {
    let playlist: Playlist

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Playlist Artwork
            ZStack {
                if let artworkURL = playlist.artworkURL, let url = URL(string: artworkURL) {
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
                    .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                } else {
                    placeholderArtwork
                }
            }

            // Playlist Info
            VStack(alignment: .leading, spacing: 4) {
                Text(playlist.name)
                    .font(.jellyAmpBody)
                    .foregroundColor(Color.jellyAmpText)
                    .lineLimit(1)

                Text("\(playlist.trackCount) track\(playlist.trackCount == 1 ? "" : "s")")
                    .font(.jellyAmpCaption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
    }

    private var placeholderArtwork: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                LinearGradient(
                    colors: [
                        Color.neonPink.opacity(0.5),
                        Color.jellyAmpSecondary.opacity(0.5),
                        Color.neonPurple.opacity(0.5)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .aspectRatio(1, contentMode: .fit)
            .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
            .overlay(
                Image(systemName: "music.note.list")
                    .font(.title)
                    .foregroundColor(.white.opacity(0.4))
            )
    }
}

