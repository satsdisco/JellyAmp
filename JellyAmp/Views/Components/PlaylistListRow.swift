import SwiftUI

struct PlaylistListRow: View {
    let playlist: Playlist

    var body: some View {
            HStack(spacing: 16) {
                // Playlist artwork (square)
                if let artworkURL = playlist.artworkURL, let url = URL(string: artworkURL) {
                    CachedAsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            placeholderArtwork
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 64, height: 64)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        case .failure:
                            placeholderArtwork
                        @unknown default:
                            placeholderArtwork
                        }
                    }
                    .transaction { $0.animation = nil }
                    .frame(width: 64, height: 64)
                } else {
                    placeholderArtwork
                }

                // Playlist info
                VStack(alignment: .leading, spacing: 8) {
                    // Playlist name - bold and prominent
                    Text(playlist.name)
                        .font(.body.weight(.semibold))
                        .foregroundColor(Color.jellyAmpText)
                        .lineLimit(1)

                    // Track count and date
                    HStack(spacing: 0) {
                        Text("\(playlist.trackCount) track\(playlist.trackCount == 1 ? "" : "s")")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.secondary.opacity(0.8))

                        if let dateCreated = playlist.dateCreated {
                            Text("  •  ")
                                .font(.caption)
                                .foregroundColor(.secondary.opacity(0.5))

                            Text(dateCreated, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary.opacity(0.6))
                        }
                    }
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.neonPink.opacity(0.6))
            }
            .padding(.vertical, 14)
    }

    private var placeholderArtwork: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.neonPink.opacity(0.4),
                            Color.jellyAmpSecondary.opacity(0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 64, height: 64)

            Image(systemName: "music.note.list")
                .font(.title3)
                .foregroundColor(.white.opacity(0.4))
        }
    }
}

