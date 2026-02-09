//
//  CachedAsyncImage.swift
//  JellyAmp
//
//  Drop-in replacement for AsyncImage with memory + disk caching
//

import SwiftUI

struct CachedAsyncImage<Content: View>: View {
    let url: URL?
    let content: (AsyncImagePhase) -> Content

    @State private var phase: AsyncImagePhase = .empty
    @State private var wasCacheHit = false

    init(url: URL?, @ViewBuilder content: @escaping (AsyncImagePhase) -> Content) {
        self.url = url
        self.content = content
    }

    var body: some View {
        content(phase)
            .opacity(phase.image != nil ? 1 : 1)
            .animation(wasCacheHit ? nil : .easeIn(duration: 0.2), value: phase.image != nil)
            .task(id: url) {
                await loadImage()
            }
    }

    private func loadImage() async {
        guard let url = url else {
            phase = .empty
            return
        }

        // Check cache synchronously first
        if let cached = await ImageCache.shared.cachedImage(for: url) {
            wasCacheHit = true
            phase = .success(Image(uiImage: cached))
            return
        }

        // Network fetch
        wasCacheHit = false
        do {
            let img = try await ImageCache.shared.loadImage(from: url)
            phase = .success(Image(uiImage: img))
        } catch {
            phase = .failure(error)
        }
    }
}

// Convenience: match the AsyncImage(url:) { phase in ... } pattern
extension AsyncImagePhase {
    var image: Image? {
        if case .success(let img) = self { return img }
        return nil
    }
}
