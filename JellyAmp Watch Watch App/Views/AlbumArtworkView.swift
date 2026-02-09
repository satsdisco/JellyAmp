//
//  AlbumArtworkView.swift
//  JellyAmp Watch
//
//  Album artwork component with async loading
//

import SwiftUI

struct AlbumArtworkView: View {
    let albumId: String
    let baseURL: String
    let size: CGFloat

    @State private var image: UIImage?
    @State private var isLoading = false

    var body: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                // Placeholder gradient
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [Color.cyan.opacity(0.3), Color.pink.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "music.note")
                        .font(.title)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .accessibilityLabel("Album artwork")
        .accessibilityHidden(image == nil) // Hide placeholder from VoiceOver
        .task {
            await loadArtwork()
        }
    }

    private func loadArtwork() async {
        guard !albumId.isEmpty, !baseURL.isEmpty else { return }

        isLoading = true
        defer { isLoading = false }

        // Build artwork URL
        let cleanBaseURL = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedBaseURL = cleanBaseURL.hasSuffix("/") ? String(cleanBaseURL.dropLast()) : cleanBaseURL

        guard let url = URL(string: "\(normalizedBaseURL)/Items/\(albumId)/Images/Primary?maxWidth=\(Int(size * 2))&quality=80") else {
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let loadedImage = UIImage(data: data) {
                await MainActor.run {
                    self.image = loadedImage
                }
            }
        } catch {
            // Failed to load artwork, keep placeholder
        }
    }
}
