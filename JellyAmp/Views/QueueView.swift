//
//  QueueView.swift
//  JellyAmp
//
//  Queue management view with reordering and deletion - Cypherpunk theme
//

import SwiftUI

struct QueueView: View {
    @ObservedObject var playerManager = PlayerManager.shared
    @Environment(\.dismiss) var dismiss

    @State private var editMode: EditMode = .inactive

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color.darkBackground,
                    Color.darkMid,
                    Color.darkBackground
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
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(Color.darkMid)
                                    .glassEffect(.regular)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.neonPink.opacity(0.5), lineWidth: 1)
                                    )
                            )
                            .neonGlow(color: .neonPink, radius: 8)
                    }
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
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .neonGlow(color: .neonCyan, radius: 12)

                    Text("\(playerManager.queue.count) track\(playerManager.queue.count == 1 ? "" : "s")")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
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
                            .font(.system(size: 14, weight: .semibold))
                        Text(editMode == .active ? "Done" : "Edit")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.neonCyan)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.neonCyan.opacity(0.15))
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.neonCyan.opacity(0.3), lineWidth: 1)
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
                                .font(.system(size: 14, weight: .semibold))
                            Text("Clear")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.neonPink)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color.neonPink.opacity(0.15))
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.neonPink.opacity(0.3), lineWidth: 1)
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
                .font(.system(size: 64))
                .foregroundColor(.neonCyan.opacity(0.5))

            Text("Queue is Empty")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("Play some music to see it here")
                .font(.system(size: 16))
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

    @State private var isPressed = false

    var body: some View {
        Button {
            isPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
                onTap()
            }
        } label: {
            HStack(spacing: 16) {
                // Now Playing Indicator
                if isCurrentTrack {
                    Image(systemName: "waveform")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.neonCyan)
                        .frame(width: 28)
                } else {
                    Text("\(index + 1)")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .frame(width: 28)
                }

                // Track Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(track.name)
                        .font(.system(size: 17, weight: isCurrentTrack ? .bold : .semibold))
                        .foregroundColor(isCurrentTrack ? .neonCyan : .white)
                        .lineLimit(1)

                    Text(track.artistName)
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                // Delete Button
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.neonPink.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isCurrentTrack ? Color.neonCyan.opacity(0.1) : Color.darkMid.opacity(isPressed ? 0.5 : 0.3))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isCurrentTrack ? Color.neonCyan.opacity(0.4) : Color.clear, lineWidth: 1)
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
