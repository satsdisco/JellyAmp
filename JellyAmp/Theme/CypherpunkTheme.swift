//
//  CypherpunkTheme.swift
//  JellyAmp
//
//  Modern theme system with multiple color schemes
//

import SwiftUI
import Combine

// MARK: - Theme Types

enum AppTheme: String, CaseIterable, Identifiable {
    case cypherpunk = "Cypherpunk"
    case sleek = "Sleek"

    var id: String { rawValue }

    var displayName: String {
        rawValue
    }

    var description: String {
        switch self {
        case .cypherpunk:
            return "Neon accents with dark backgrounds"
        case .sleek:
            return "Gold, brass, and deep blue tones"
        }
    }
}

// MARK: - Theme Manager

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "selectedTheme")
        }
    }

    private init() {
        if let savedTheme = UserDefaults.standard.string(forKey: "selectedTheme"),
           let theme = AppTheme(rawValue: savedTheme) {
            currentTheme = theme
        } else {
            currentTheme = .cypherpunk
        }
    }
}

// MARK: - Color Palette
extension Color {
    // Cypherpunk Theme - Neon Accents
    static let neonCyan = Color(red: 0.0, green: 1.0, blue: 1.0)
    static let neonPink = Color(red: 1.0, green: 0.0, blue: 0.43)
    static let neonPurple = Color(red: 0.62, green: 0.0, blue: 1.0)
    static let neonGreen = Color(red: 0.0, green: 1.0, blue: 0.25)
    static let neonOrange = Color(red: 1.0, green: 0.6, blue: 0.0)
    static let neonBlue = Color(red: 0.0, green: 0.4, blue: 1.0)

    // Cypherpunk Theme - Dark Backgrounds
    static let darkBackground = Color(red: 0.05, green: 0.05, blue: 0.08)
    static let darkMid = Color(red: 0.1, green: 0.1, blue: 0.13)
    static let darkElevated = Color(red: 0.15, green: 0.15, blue: 0.18)

    // Bitcoin Theme - Backgrounds
    static let matteBlack = Color(hex: "181818")
    static let steelyGray = Color(hex: "33434b")

    // Bitcoin Theme - Refined Palette (less orange-heavy)
    static let mattaze = Color(hex: "cc6633")           // Rust/terracotta (toned down from bright orange)
    static let deepBlue = Color(hex: "0d579b")          // Deep blue
    static let lightGray = Color(hex: "ececec")         // Light gray text
    static let cyphernyuk = Color(hex: "3d5a5a")        // Dark teal/green
    static let goldBrass = Color(hex: "d5bb73")         // Gold/brass
    static let bronze = Color(hex: "9f8247")            // Bronze/brown
    static let bitcoinOrange = Color(hex: "f7931a")     // Pure bitcoin orange (used sparingly)

    // Semantic Colors (Theme-aware)
    static var jellyAmpAccent: Color {
        switch ThemeManager.shared.currentTheme {
        case .cypherpunk:
            return neonCyan
        case .sleek:
            return goldBrass  // Primary: Gold/brass instead of orange
        }
    }

    static var jellyAmpSecondary: Color {
        switch ThemeManager.shared.currentTheme {
        case .cypherpunk:
            return neonPink
        case .sleek:
            return deepBlue  // Secondary: Deep blue
        }
    }

    static var jellyAmpSuccess: Color {
        switch ThemeManager.shared.currentTheme {
        case .cypherpunk:
            return neonGreen
        case .sleek:
            return cyphernyuk  // Success: Dark teal
        }
    }

    static var jellyAmpWarning: Color {
        switch ThemeManager.shared.currentTheme {
        case .cypherpunk:
            return neonOrange
        case .sleek:
            return mattaze  // Warning: Rust/terracotta
        }
    }

    static var jellyAmpError: Color {
        switch ThemeManager.shared.currentTheme {
        case .cypherpunk:
            return Color.red
        case .sleek:
            return Color.red
        }
    }

    static var jellyAmpBackground: Color {
        switch ThemeManager.shared.currentTheme {
        case .cypherpunk:
            return darkBackground
        case .sleek:
            return matteBlack
        }
    }

    static var jellyAmpMidBackground: Color {
        switch ThemeManager.shared.currentTheme {
        case .cypherpunk:
            return darkMid
        case .sleek:
            return steelyGray
        }
    }

    static var jellyAmpElevated: Color {
        switch ThemeManager.shared.currentTheme {
        case .cypherpunk:
            return darkElevated
        case .sleek:
            return steelyGray.opacity(0.8)
        }
    }

    static var jellyAmpText: Color {
        switch ThemeManager.shared.currentTheme {
        case .cypherpunk:
            return .white
        case .sleek:
            return lightGray
        }
    }

    static var jellyAmpTertiary: Color {
        switch ThemeManager.shared.currentTheme {
        case .cypherpunk:
            return neonPurple
        case .sleek:
            return bronze
        }
    }

    // Helper for hex colors
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Typography
extension Font {
    static let jellyAmpTitle = Font.largeTitle.weight(.bold)
    static let jellyAmpHeadline = Font.title3.weight(.semibold)
    static let jellyAmpBody = Font.body
    static let jellyAmpCaption = Font.caption
    static let jellyAmpMono = Font.system(.caption, design: .monospaced).weight(.medium)
}

// MARK: - Glass Effect Styles
struct GlassCard: ViewModifier {
    var tint: Color = .jellyAmpAccent
    var intensity: Double = 0.3

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [
                                tint.opacity(intensity),
                                tint.opacity(intensity * 0.5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: tint.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

struct NeonGlow: ViewModifier {
    var color: Color
    var radius: CGFloat = 8

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.5), radius: radius * 0.5, x: 0, y: 0)
            .shadow(color: color.opacity(0.25), radius: radius, x: 0, y: 0)
            .shadow(color: color.opacity(0.1), radius: radius * 1.5, x: 0, y: 0)
    }
}

// MARK: - View Extensions
extension View {
    func glassCard(tint: Color = .jellyAmpAccent, intensity: Double = 0.3) -> some View {
        modifier(GlassCard(tint: tint, intensity: intensity))
    }

    func neonGlow(color: Color = .jellyAmpAccent, radius: CGFloat = 8) -> some View {
        modifier(NeonGlow(color: color, radius: radius))
    }
}

// MARK: - Button Styles
struct CypherpunkButtonStyle: ButtonStyle {
    var color: Color = .jellyAmpAccent
    var isProminent: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Group {
                    if isProminent {
                        color.opacity(configuration.isPressed ? 0.6 : 0.8)
                    } else {
                        Color.white.opacity(configuration.isPressed ? 0.05 : 0.1)
                    }
                }
            )
            .foregroundColor(isProminent ? .black : color)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.5), lineWidth: 1)
            )
            .neonGlow(color: color, radius: configuration.isPressed ? 4 : 8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.darkBackground.ignoresSafeArea()

        VStack(spacing: 30) {
            // Glass Card Example
            VStack(spacing: 12) {
                Text("Now Playing")
                    .font(.jellyAmpHeadline)
                    .foregroundColor(.white)

                Text("Synthwave Dreams")
                    .font(.jellyAmpBody)
                    .foregroundColor(.secondary)
            }
            .padding(30)
            .glassCard(tint: .neonCyan)

            // Button Examples
            HStack(spacing: 20) {
                Button("Play") {
                    // Action
                }
                .buttonStyle(CypherpunkButtonStyle(color: .neonCyan, isProminent: true))

                Button("Queue") {
                    // Action
                }
                .buttonStyle(CypherpunkButtonStyle(color: .neonPink))
            }

            // Neon Text
            Text("JellyAmp")
                .font(.jellyAmpTitle)
                .foregroundColor(.neonCyan)
                .neonGlow(color: .neonCyan, radius: 12)
        }
        .padding()
    }
}
