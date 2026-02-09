//
//  DominantColorExtractor.swift
//  JellyAmp
//
//  Extracts average/dominant color from album artwork
//

import UIKit
import SwiftUI

actor DominantColorExtractor {
    static let shared = DominantColorExtractor()

    private var cache: [String: Color] = [:]

    func dominantColor(from image: UIImage, trackId: String) -> Color {
        if let cached = cache[trackId] { return cached }

        let color = extractAverage(from: image)
        cache[trackId] = color
        return color
    }

    private func extractAverage(from image: UIImage) -> Color {
        guard let cgImage = image.cgImage else { return .jellyAmpAccent }

        let size = 10
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var pixelData = [UInt8](repeating: 0, count: size * size * 4)

        guard let context = CGContext(
            data: &pixelData,
            width: size,
            height: size,
            bitsPerComponent: 8,
            bytesPerRow: size * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return .jellyAmpAccent }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: size, height: size))

        var totalR: Double = 0, totalG: Double = 0, totalB: Double = 0
        let count = Double(size * size)

        for i in stride(from: 0, to: pixelData.count, by: 4) {
            totalR += Double(pixelData[i])
            totalG += Double(pixelData[i + 1])
            totalB += Double(pixelData[i + 2])
        }

        let r = totalR / count / 255.0
        let g = totalG / count / 255.0
        let b = totalB / count / 255.0

        // Boost saturation slightly so it's visible against dark bg
        return Color(red: min(r * 1.2, 1.0), green: min(g * 1.2, 1.0), blue: min(b * 1.2, 1.0))
    }
}
