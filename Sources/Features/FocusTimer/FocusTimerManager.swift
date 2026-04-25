import Foundation
import UserNotifications
import AppKit

// MARK: - Phase

public enum FocusPhase: Equatable {
    case work
    case shortBreak
    case longBreak

    public var duration: TimeInterval {
        switch self {
        case .work:       return 25 * 60
        case .shortBreak: return  5 * 60
        case .longBreak:  return 15 * 60
        }
    }

    public var label: String {
        switch self {
        case .work:       return "Focus"
        case .shortBreak: return "Short Break"
        case .longBreak:  return "Long Break"
        }
    }
}

// MARK: - Manager

@MainActor
public final class FocusTimerManager: ObservableObject {

    public static let shared = FocusTimerManager()

    @Published public var phase:            FocusPhase   = .work
    @Published public var timeRemaining:    TimeInterval = FocusPhase.work.duration
    @Published public var cyclesCompleted:  Int          = 0
    @Published public var isRunning:        Bool         = false

    private let cyclesPerSet = 4
    private var timer: Timer?

    private init() {
        requestNotificationPermission()
    }

    // MARK: - Controls

    public func start() {
        guard !isRunning else { return }
        isRunning = true
        scheduleTick()
    }

    public func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    public func reset() {
        pause()
        timeRemaining = phase.duration
    }

    public func resetAll() {
        pause()
        phase           = .work
        timeRemaining   = FocusPhase.work.duration
        cyclesCompleted = 0
    }

    // MARK: - Tick

    private func scheduleTick() {
        let t = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.tick() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func tick() {
        guard isRunning else { return }
        if timeRemaining > 1 {
            timeRemaining -= 1
        } else {
            timeRemaining = 0
            completePhase()
        }
    }

    // MARK: - Phase completion

    private func completePhase() {
        pause()
        playSound()

        switch phase {
        case .work:
            cyclesCompleted += 1
            let nextPhase: FocusPhase = (cyclesCompleted % cyclesPerSet == 0) ? .longBreak : .shortBreak
            notify(completed: phase, next: nextPhase)
            transition(to: nextPhase)

        case .shortBreak, .longBreak:
            notify(completed: phase, next: .work)
            transition(to: .work)
        }
    }

    private func transition(to next: FocusPhase) {
        phase         = next
        timeRemaining = next.duration
    }

    // MARK: - Sound

    private func playSound() {
        NSSound(named: "Tink")?.play()
    }

    // MARK: - Notifications

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func notify(completed: FocusPhase, next: FocusPhase) {
        let content        = UNMutableNotificationContent()
        content.title      = "\(completed.label) complete"
        content.body       = "Time for \(next.label.lowercased())."
        content.sound      = .default

        let req = UNNotificationRequest(
            identifier: "focus.phase.\(UUID().uuidString)",
            content:    content,
            trigger:    nil
        )
        UNUserNotificationCenter.current().add(req)
    }
}
