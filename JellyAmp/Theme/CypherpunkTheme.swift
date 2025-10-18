//
//  CypherpunkTheme.swift
//  JellyAmp
//
//  Modern Cypherpunk theme with iOS 26 Liquid Glass integration
//

import SwiftUI

// MARK: - Color Palette
extension Color {
    // Neon Accents (Cypherpunk Identity)
    static let neonCyan = Color(red: 0.0, green: 1.0, blue: 1.0)
    static let neonPink = Color(red: 1.0, green: 0.0, blue: 0.43)
    static let neonPurple = Color(red: 0.62, green: 0.0, blue: 1.0)
    static let neonGreen = Color(red: 0.0, green: 1.0, blue: 0.25)
    static let neonOrange = Color(red: 1.0, green: 0.6, blue: 0.0)
    static let neonBlue = Color(red: 0.0, green: 0.4, blue: 1.0)

    // Dark Backgrounds (Base)
    static let darkBackground = Color(red: 0.05, green: 0.05, blue: 0.08)
    static let darkMid = Color(red: 0.1, green: 0.1, blue: 0.13)
    static let darkElevated = Color(red: 0.15, green: 0.15, blue: 0.18)

    // Semantic Colors
    static let jellyAmpAccent = neonCyan
    static let jellyAmpSecondary = neonPink
    static let jellyAmpSuccess = neonGreen
    static let jellyAmpWarning = neonOrange
    static let jellyAmpError = Color.red
}

// MARK: - Typography
extension Font {
    static let jellyAmpTitle = Font.system(size: 32, weight: .bold, design: .rounded)
    static let jellyAmpHeadline = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let jellyAmpBody = Font.system(size: 16, weight: .regular, design: .default)
    static let jellyAmpCaption = Font.system(size: 13, weight: .regular, design: .default)
    static let jellyAmpMono = Font.system(size: 14, weight: .medium, design: .monospaced)
}

// MARK: - Glass Effect Styles
struct GlassCard: ViewModifier {
    var tint: Color = .jellyAmpAccent
    var intensity: Double = 0.3

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .glassEffect(.regular) // iOS 26 Liquid Glass
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
            .glassEffect(.regular)
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
