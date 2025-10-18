//
//  SafeDecoding.swift
//  JellyAmp
//
//  Utilities for safer JSON decoding
//

import Foundation

/// Custom decoder that handles type mismatches gracefully
extension JSONDecoder {
    static let jellyfin: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()

            // Try string first
            if let dateString = try? container.decode(String.self) {
                // Try ISO8601 format
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let date = formatter.date(from: dateString) {
                    return date
                }

                // Try without fractional seconds
                formatter.formatOptions = [.withInternetDateTime]
                if let date = formatter.date(from: dateString) {
                    return date
                }

                // Return distant past if parsing fails
                return Date.distantPast
            }

            // Try as TimeInterval
            if let timestamp = try? container.decode(Double.self) {
                return Date(timeIntervalSince1970: timestamp)
            }

            // Default to distant past
            return Date.distantPast
        }
        return decoder
    }()
}

/// Safe decoding wrapper for Jellyfin responses
struct SafeJellyfinDecoder {
    static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try JSONDecoder.jellyfin.decode(type, from: data)
        } catch DecodingError.typeMismatch(let type, let context) {
            print("❌ Type mismatch: expected \(type) at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
            print("Debug: \(context.debugDescription)")

            // Log specific field that failed
            if let lastKey = context.codingPath.last {
                print("Failed field: \(lastKey.stringValue)")
            }

            throw DecodingError.typeMismatch(type, context)
        } catch DecodingError.keyNotFound(let key, let context) {
            print("❌ Key not found: \(key.stringValue) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
            throw DecodingError.keyNotFound(key, context)
        } catch DecodingError.valueNotFound(let type, let context) {
            print("❌ Value not found: \(type) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
            throw DecodingError.valueNotFound(type, context)
        } catch {
            print("❌ Decoding error: \(error)")
            throw error
        }
    }
}
