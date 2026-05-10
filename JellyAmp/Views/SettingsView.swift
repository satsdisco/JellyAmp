//
//  SettingsView.swift
//  JellyAmp
//
//  Settings view with Jellyfin server management and sign out
//

import SwiftUI

struct AppVersionInfo {
    let version: String
    let build: String

    var displayText: String {
        "Version \(version) (\(build))"
    }

    static func from(infoDictionary: [String: Any]?) -> AppVersionInfo {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String
        let build = infoDictionary?["CFBundleVersion"] as? String

        return AppVersionInfo(
            version: version?.isEmpty == false ? version! : "?",
            build: build?.isEmpty == false ? build! : "?"
        )
    }
}

enum StreamingQuality: String, CaseIterable, Identifiable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case original = "original"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .original: return "Original"
        }
    }

    var description: String {
        switch self {
        case .low: return "96 kbps — saves data"
        case .medium: return "192 kbps — balanced"
        case .high: return "320 kbps — high quality"
        case .original: return "Direct stream — best quality, more data"
        }
    }

    var bitrate: Int {
        switch self {
        case .low: return 96
        case .medium: return 192
        case .high: return 320
        case .original: return 0
        }
    }
}

struct SettingsView: View {
    @ObservedObject var jellyfinService = JellyfinService.shared
    @State private var showSignOutConfirmation = false
    @AppStorage("preferredAppearance") private var preferredAppearance = "always_dark"
    @AppStorage("streamingQuality") private var selectedQualityRaw = StreamingQuality.medium.rawValue

    private var selectedQuality: StreamingQuality {
        get { StreamingQuality(rawValue: selectedQualityRaw) ?? .medium }
    }
    private func setSelectedQuality(_ quality: StreamingQuality) {
        selectedQualityRaw = quality.rawValue
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Dark background
                Color.jellyAmpBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header with app icon/logo
                        headerSection

                        // Appearance
                        appearanceSection

                        // Streaming Quality
                        streamingQualitySection

                        // Server Info Section
                        serverInfoSection

                        // Danger Zone
                        signOutSection

                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .confirmationDialog("Sign Out", isPresented: $showSignOutConfirmation) {
            Button("Sign Out", role: .destructive) {
                jellyfinService.signOut()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to sign out? You'll need to reconnect to your Jellyfin server.")
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            // App Icon
            Image("AppIcon_Display")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: Color.jellyAmpAccent.opacity(0.3), radius: 10, y: 4)

            Text("JellyAmp")
                .font(.jellyAmpTitle)
                .foregroundColor(Color.jellyAmpText)

            Text(AppVersionInfo.from(infoDictionary: Bundle.main.infoDictionary).displayText)
                .font(.jellyAmpMono)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    // MARK: - Appearance Section

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Appearance")
                .font(.jellyAmpHeadline)
                .foregroundColor(.jellyAmpAccent)

            Text("Choose whether JellyAmp always uses its dark stage-friendly look or follows your system setting.")
                .font(.jellyAmpCaption)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                ForEach(["always_dark", "system"], id: \.self) { appearance in
                    Button {
                        preferredAppearance = appearance
                    } label: {
                        HStack {
                            Image(systemName: appearanceIcon(for: appearance))
                                .font(.title3)
                                .foregroundColor(.jellyAmpText)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(appearanceTitle(for: appearance))
                                    .font(.jellyAmpBody)
                                    .foregroundColor(.jellyAmpText)

                                Text(appearanceDescription(for: appearance))
                                    .font(.jellyAmpCaption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if preferredAppearance == appearance {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.jellyAmpAccent)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(preferredAppearance == appearance ? Color.jellyAmpMidBackground : Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            preferredAppearance == appearance ?
                                            Color.jellyAmpAccent.opacity(0.5) :
                                            Color.white.opacity(0.1),
                                            lineWidth: 1
                                        )
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(appearanceTitle(for: appearance))
                    .accessibilityHint(appearanceDescription(for: appearance))
                    .accessibilityAddTraits(preferredAppearance == appearance ? .isSelected : [])
                }
            }
        }
    }

    // Helper functions for appearance setting
    private func appearanceIcon(for appearance: String) -> String {
        switch appearance {
        case "always_dark":
            return "moon.fill"
        case "system":
            return "circle.lefthalf.filled"
        default:
            return "moon.fill"
        }
    }
    
    private func appearanceTitle(for appearance: String) -> String {
        switch appearance {
        case "always_dark":
            return "Always Dark"
        case "system":
            return "System"
        default:
            return "Always Dark"
        }
    }
    
    private func appearanceDescription(for appearance: String) -> String {
        switch appearance {
        case "always_dark":
            return "Force dark mode for optimal cypherpunk aesthetic"
        case "system":
            return "Follow system light/dark mode setting"
        default:
            return "Force dark mode for optimal cypherpunk aesthetic"
        }
    }

    // MARK: - Streaming Quality Section
    private var streamingQualitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Streaming")
                .font(.jellyAmpHeadline)
                .foregroundColor(.jellyAmpAccent)

            VStack(spacing: 8) {
                ForEach(StreamingQuality.allCases) { quality in
                    Button {
                        setSelectedQuality(quality)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(quality.displayName)
                                    .font(.jellyAmpBody)
                                    .foregroundColor(Color.jellyAmpText)
                                Text(quality.description)
                                    .font(.jellyAmpCaption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if selectedQuality == quality {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.jellyAmpAccent)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedQuality == quality ? Color.jellyAmpMidBackground : Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedQuality == quality ? Color.jellyAmpAccent.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Server Info Section

    private var serverInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Server")
                .font(.jellyAmpHeadline)
                .foregroundColor(.jellyAmpAccent)

            VStack(alignment: .leading, spacing: 12) {
                // Server URL
                HStack {
                    Image(systemName: "server.rack")
                        .foregroundColor(.jellyAmpTertiary)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Server URL")
                            .font(.jellyAmpBody)
                            .foregroundColor(.secondary)

                        Text(jellyfinService.baseURL.isEmpty ? "Not configured" : jellyfinService.baseURL)
                            .font(.jellyAmpMono)
                            .foregroundColor(Color.jellyAmpText)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }

                    Spacer()
                }

                Divider()
                    .background(Color.white.opacity(0.1))

                // Connection Status
                HStack {
                    Image(systemName: jellyfinService.isAuthenticated ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(jellyfinService.isAuthenticated ? .jellyAmpSuccess : .jellyAmpSecondary)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Status")
                            .font(.jellyAmpBody)
                            .foregroundColor(.secondary)

                        Text(jellyfinService.isAuthenticated ? "Connected" : "Disconnected")
                            .font(.jellyAmpMono)
                            .foregroundColor(jellyfinService.isAuthenticated ? .jellyAmpSuccess : .jellyAmpSecondary)
                    }

                    Spacer()
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.jellyAmpMidBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.jellyAmpAccent.opacity(0.3), Color.jellyAmpTertiary.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
        }
    }

    // MARK: - Sign Out Section

    private var signOutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Danger Zone")
                .font(.jellyAmpHeadline)
                .foregroundColor(.red)

            Button {
                showSignOutConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Sign Out")
                        .font(.jellyAmpHeadline)
                    Spacer()
                }
                .foregroundColor(Color.jellyAmpText)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [.red.opacity(0.2), .red.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    LinearGradient(
                                        colors: [.red.opacity(0.8), .red.opacity(0.5)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                )
            }
            .accessibilityLabel("Sign out of account")
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
