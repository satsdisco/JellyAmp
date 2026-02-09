//
//  QuickConnectView.swift
//  JellyAmp
//
//  Quick Connect authentication screen - iOS 26 Liquid Glass + Cypherpunk
//

import SwiftUI

struct QuickConnectView: View {
    @ObservedObject var jellyfinService = JellyfinService.shared
    @ObservedObject var themeManager = ThemeManager.shared
    @State private var quickConnectCode = ""
    @State private var quickConnectSecret = ""
    @State private var isLoading = true
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var isPolling = false
    @State private var pollingTask: Task<Void, Never>?

    let onSuccess: () -> Void
    let onBack: () -> Void

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color.jellyAmpBackground,
                    Color.jellyAmpMidBackground,
                    Color.jellyAmpBackground
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            if isLoading {
                loadingView
            } else {
                mainContent
            }

            // Back Button
            VStack {
                HStack {
                    Button {
                        pollingTask?.cancel()
                        onBack()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundColor(Color.jellyAmpText)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(Color.jellyAmpMidBackground)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.jellyAmpAccent.opacity(0.5), lineWidth: 1)
                                    )
                            )
                            .neonGlow(color: .jellyAmpAccent, radius: 8)
                    }
                    .padding(.leading, 20)
                    .padding(.top, 60)

                    Spacer()
                }

                Spacer()
            }
        }
        .onAppear {
            Task {
                await initiateQuickConnect()
            }
        }
        .onDisappear {
            pollingTask?.cancel()
        }
        .alert("Authentication Error", isPresented: $showError) {
            Button("Try Again", role: .cancel) {
                Task {
                    await initiateQuickConnect()
                }
            }
            Button("Go Back") {
                pollingTask?.cancel()
                onBack()
            }
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .tint(.jellyAmpAccent)
                .scaleEffect(1.5)

            Text("Initiating Quick Connect...")
                .font(.jellyAmpBody)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Main Content
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 120)

                // Icon
                iconSection

                // Title
                titleSection

                // Code Display
                codeDisplay

                // Instructions
                instructionsSection

                // Status
                statusSection

                Spacer()
            }
            .padding(.horizontal, 30)
        }
    }

    // MARK: - Icon Section
    private var iconSection: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.jellyAmpTertiary.opacity(0.3),
                            Color.jellyAmpSecondary.opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 100)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.jellyAmpTertiary.opacity(0.8),
                                    Color.jellyAmpSecondary.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .neonGlow(color: .jellyAmpTertiary, radius: 20)

            Image(systemName: "qrcode")
                .font(.title)
                .foregroundColor(Color.jellyAmpText)
        }
        .padding(.bottom, 30)
    }

    // MARK: - Title Section
    private var titleSection: some View {
        VStack(spacing: 12) {
            Text("Quick Connect")
                .font(.title2.weight(.bold))
                .foregroundColor(Color.jellyAmpText)
                .neonGlow(color: .jellyAmpSecondary, radius: 10)

            Text("Enter this code on your Jellyfin server")
                .font(.jellyAmpBody)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 40)
    }

    // MARK: - Code Display
    private var codeDisplay: some View {
        VStack(spacing: 16) {
            // Code
            Text(quickConnectCode)
                .font(.system(.title, design: .monospaced).weight(.bold))
                .foregroundColor(.neonCyan)
                .tracking(8)
                .neonGlow(color: .jellyAmpAccent, radius: 15)
                .padding(.vertical, 30)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.jellyAmpAccent.opacity(0.6),
                                            Color.jellyAmpTertiary.opacity(0.6)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                )

            // Copy Button
            Button {
                UIPasteboard.general.string = quickConnectCode
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                    Text("Copy Code")
                        .font(.jellyAmpCaption)
                }
                .foregroundColor(.neonPurple)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                )
                .overlay(
                    Capsule()
                        .stroke(Color.jellyAmpTertiary.opacity(0.4), lineWidth: 1)
                )
            }
        }
        .padding(.bottom, 40)
    }

    // MARK: - Instructions Section
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            instructionStep(number: "1", text: "Open your Jellyfin server in a web browser")
            instructionStep(number: "2", text: "Go to Settings → Quick Connect")
            instructionStep(number: "3", text: "Enter the code shown above")
            instructionStep(number: "4", text: "Wait for authentication to complete")
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.jellyAmpSecondary.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.bottom, 30)
    }

    private func instructionStep(number: String, text: String) -> some View {
        HStack(spacing: 16) {
            Text(number)
                .font(.system(.headline, design: .monospaced).weight(.bold))
                .foregroundColor(.neonPink)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(Color.jellyAmpSecondary.opacity(0.2))
                )

            Text(text)
                .font(.subheadline)
                .foregroundColor(Color.jellyAmpText)
        }
    }

    // MARK: - Status Section
    private var statusSection: some View {
        HStack(spacing: 12) {
            ProgressView()
                .tint(.jellyAmpAccent)
                .scaleEffect(0.8)

            Text(isPolling ? "Waiting for authentication..." : "Checking status...")
                .font(.jellyAmpCaption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.05))
        )
    }

    // MARK: - Quick Connect Logic
    private func initiateQuickConnect() async {
        isLoading = true

        do {
            let result = try await jellyfinService.initiateQuickConnect()
            quickConnectCode = result.code
            quickConnectSecret = result.secret

            isLoading = false

            // Start polling
            startPolling()
        } catch {
            errorMessage = "Failed to initiate Quick Connect.\n\nError: \(error.localizedDescription)"
            showError = true
            isLoading = false
        }
    }

    private func startPolling() {
        isPolling = true

        pollingTask = Task {
            // Poll every 2 seconds for up to 5 minutes
            for _ in 0..<150 {
                // Check if cancelled
                if Task.isCancelled {
                    return
                }

                do {
                    let authenticated = try await jellyfinService.pollQuickConnect(secret: quickConnectSecret)

                    if authenticated {
                        // Success!
                        await MainActor.run {
                            onSuccess()
                        }
                        return
                    }
                } catch {
                    // Continue polling even on error (user might not have approved yet)
                    print("Polling error: \(error)")
                }

                // Wait 2 seconds before next poll
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }

            // Timeout after 5 minutes
            await MainActor.run {
                errorMessage = "Authentication timed out. Please try again."
                showError = true
                isPolling = false
            }
        }
    }
}

// MARK: - Preview
#Preview {
    QuickConnectView {
        print("Success!")
    } onBack: {
        print("Back")
    }
}
