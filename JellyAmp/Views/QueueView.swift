//
//  QueueView.swift
//  JellyAmp
//
//  Queue management view with reordering and deletion - Cypherpunk theme
//

import SwiftUI

struct QueueView: View {
    @ObservedObject var playerManager = PlayerManager.shared
    @ObservedObject var themeManager = ThemeManager.shared
    @Environment(\.dismiss) var dismiss

    @State private var editMode: EditMode = .inactive

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

            VStack(spacing: 0) {
                // Header
                queueHeader

                // Queue List
                if playerManager.queue.isEmpty {
                    emptyQueueView
                } else {
                    List {
                        ForEach(Array(playerManager.queue.enumerated()), id: \.element.id) { index, track in
                            QueueTrackRow(
                                track: track,
                                index: index,
                                isCurrentTrack: index == playerManager.currentIndex,
                                onTap: {
                                    // Jump to this track
                                    playerManager.jumpToTrack(at: index)
                                },
                                onDelete: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        playerManager.removeFromQueue(at: index)
                                    }
                                }
                            )
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("\(track.name) by \(track.artistName)\(index == playerManager.currentIndex ? " - Currently playing" : "")")
                            .accessibilityHint("Double tap to play track")
                            .accessibilityAddTraits(.isButton)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                        }
                        .onMove { source, destination in
                            guard let sourceIndex = source.first else { return }
                            withAnimation {
                                playerManager.moveInQueue(from: sourceIndex, to: destination)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .environment(\.editMode, .constant(.active))
                }
            }

            // Close Button (floating)
            VStack {
                HStack {
                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundColor(Color.jellyAmpText)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(Color.jellyAmpMidBackground)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.jellyAmpSecondary.opacity(0.5), lineWidth: 1)
                                    )
                            )
                            .neonGlow(color: .jellyAmpSecondary, radius: 8)
                    }
                    .accessibilityLabel("Close queue")
                    .padding(.trailing, 20)
                    .padding(.top, 60)
                }

                Spacer()
            }
        }
        .environment(\.editMode, $editMode)
    }

    // MARK: - Header
    private var queueHeader: some View {
        VStack(spacing: 16) {
            // Title
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Up Next")
                        .font(.title.weight(.bold))
                        .foregroundColor(Color.jellyAmpText)
                        .neonGlow(color: .jellyAmpAccent, radius: 12)

                    Text("\(playerManager.queue.count) track\(playerManager.queue.count == 1 ? "" : "s")")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.secondary)
                }
                .padding(.leading, 20)

                Spacer()
            }

            // Action Buttons
            HStack(spacing: 12) {
                // Edit/Done Button
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        editMode = editMode == .active ? .inactive : .active
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: editMode == .active ? "checkmark" : "slider.horizontal.3")
                            .font(.subheadline.weight(.semibold))
                        Text(editMode == .active ? "Done" : "Edit")
                            .font(.subheadline.weight(.bold))
                    }
                    .foregroundColor(.neonCyan)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.jellyAmpAccent.opacity(0.15))
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.jellyAmpAccent.opacity(0.3), lineWidth: 1)
                    )
                }

                // Clear Queue Button
                if !playerManager.queue.isEmpty {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            playerManager.clearQueue()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "trash")
                                .font(.subheadline.weight(.semibold))
                            Text("Clear")
                                .font(.subheadline.weight(.bold))
                        }
                        .foregroundColor(.neonPink)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color.jellyAmpSecondary.opacity(0.15))
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.jellyAmpSecondary.opacity(0.3), lineWidth: 1)
                        )
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 100)
        .padding(.bottom, 20)
    }

    // MARK: - Empty State
    private var emptyQueueView: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note.list")
                .font(.title)
                .foregroundColor(.neonCyan.opacity(0.5))

            Text("Queue is Empty")
                .font(.title3.weight(.bold))
                .foregroundColor(Color.jellyAmpText)

            Text("Play some music to see it here")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Queue Track Row
struct QueueTrackRow: View {
    let track: Track
    let index: Int
    let isCurrentTrack: Bool
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: 16) {
                // Now Playing Indicator
                if isCurrentTrack {
                    Image(systemName: "waveform")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.neonCyan)
                        .frame(width: 28)
                } else {
                    Text("\(index + 1)")
                        .font(.body.weight(.medium))
                        .foregroundColor(.secondary)
                        .frame(width: 28)
                }

                // Track Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(track.name)
                        .font(.body.weight(isCurrentTrack ? .bold : .semibold))
                        .foregroundColor(isCurrentTrack ? .neonCyan : .white)
                        .lineLimit(1)

                    Text(track.artistName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                // Delete Button
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.neonPink.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isCurrentTrack ? Color.jellyAmpAccent.opacity(0.1) : Color.jellyAmpMidBackground.opacity(0.3))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isCurrentTrack ? Color.jellyAmpAccent.opacity(0.4) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
#Preview {
    QueueView()
}
