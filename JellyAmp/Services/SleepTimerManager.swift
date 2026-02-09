//
//  SleepTimerManager.swift
//  JellyAmp
//
//  Sleep timer that pauses playback after a set duration
//

import Foundation
import Combine

enum SleepTimerOption: String, CaseIterable, Identifiable {
    case endOfTrack = "End of Track"
    case min15 = "15 Minutes"
    case min30 = "30 Minutes"
    case min45 = "45 Minutes"
    case hr1 = "1 Hour"
    case hr2 = "2 Hours"

    var id: String { rawValue }

    var seconds: TimeInterval? {
        switch self {
        case .endOfTrack: return nil
        case .min15: return 15 * 60
        case .min30: return 30 * 60
        case .min45: return 45 * 60
        case .hr1: return 60 * 60
        case .hr2: return 120 * 60
        }
    }
}

class SleepTimerManager: ObservableObject {
    static let shared = SleepTimerManager()

    @Published var isActive = false
    @Published var remainingTime: TimeInterval = 0
    @Published var selectedOption: SleepTimerOption?

    private var timer: AnyCancellable?
    private var trackChangeCancellable: AnyCancellable?

    private init() {}

    func start(option: SleepTimerOption) {
        cancel()
        selectedOption = option
        isActive = true

        if option == .endOfTrack {
            // Listen for track change
            trackChangeCancellable = PlayerManager.shared.$currentTrack
                .dropFirst() // Skip current value
                .sink { [weak self] _ in
                    self?.expire()
                }
        } else if let seconds = option.seconds {
            remainingTime = seconds
            timer = Timer.publish(every: 1, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] _ in
                    guard let self = self else { return }
                    self.remainingTime -= 1
                    if self.remainingTime <= 0 {
                        self.expire()
                    }
                }
        }
    }

    func cancel() {
        timer?.cancel()
        timer = nil
        trackChangeCancellable?.cancel()
        trackChangeCancellable = nil
        isActive = false
        remainingTime = 0
        selectedOption = nil
    }

    private func expire() {
        PlayerManager.shared.pause()
        cancel()
    }

    var formattedRemaining: String {
        if selectedOption == .endOfTrack { return "End of track" }
        let mins = Int(remainingTime) / 60
        let secs = Int(remainingTime) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
