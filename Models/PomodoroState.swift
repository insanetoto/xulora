import Foundation
import SwiftData

enum PomodoroPhase: String, Codable {
    case focus, shortBreak, longBreak
}

@Model
final class PomodoroState {
    var id: UUID
    var widgetID: UUID
    var phase: String
    var focusMinutes: Int
    var shortBreakMinutes: Int
    var longBreakMinutes: Int
    var targetEndTime: Date?
    var remainingSecondsAtPause: Int?
    var isPaused: Bool
    var autoStartBreak: Bool
    var updatedAt: Date

    var currentPhase: PomodoroPhase {
        PomodoroPhase(rawValue: phase) ?? .focus
    }

    init(
        id: UUID = UUID(),
        widgetID: UUID,
        phase: PomodoroPhase = .focus,
        focusMinutes: Int = 25,
        shortBreakMinutes: Int = 5,
        longBreakMinutes: Int = 15,
        targetEndTime: Date? = nil,
        remainingSecondsAtPause: Int? = nil,
        isPaused: Bool = true,
        autoStartBreak: Bool = false
    ) {
        self.id = id
        self.widgetID = widgetID
        self.phase = phase.rawValue
        self.focusMinutes = focusMinutes
        self.shortBreakMinutes = shortBreakMinutes
        self.longBreakMinutes = longBreakMinutes
        self.targetEndTime = targetEndTime
        self.remainingSecondsAtPause = remainingSecondsAtPause
        self.isPaused = isPaused
        self.autoStartBreak = autoStartBreak
        self.updatedAt = Date()
    }

    /// Calculate remaining seconds based on absolute target time.
    var remainingSeconds: Int {
        if isPaused, let saved = remainingSecondsAtPause {
            return max(saved, 0)
        }
        guard let target = targetEndTime else {
            return currentPhase == .focus ? focusMinutes * 60 : shortBreakMinutes * 60
        }
        return max(0, Int(target.timeIntervalSinceNow))
    }
}
