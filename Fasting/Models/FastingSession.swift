import Foundation
import SwiftData

/// Defaults and the absence of uniqueness constraints keep this schema CloudKit compatible.
@Model
final class FastingSession {
    var id: UUID = UUID()
    var startedAt: Date = Date.now
    var endedAt: Date?
    var goalHours: Int = 16

    init(id: UUID = UUID(), startedAt: Date = .now, endedAt: Date? = nil, goalHours: Int = 16) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.goalHours = goalHours
    }

    var isActive: Bool { endedAt == nil }
    var targetDate: Date { startedAt.addingTimeInterval(TimeInterval(goalHours) * 3_600) }
    var duration: TimeInterval { elapsed(at: endedAt ?? .now) }
    var reachedGoal: Bool { !isActive && duration >= TimeInterval(goalHours) * 3_600 }

    func elapsed(at date: Date) -> TimeInterval {
        max(0, (endedAt ?? date).timeIntervalSince(startedAt))
    }

    func progress(at date: Date) -> Double {
        min(1, elapsed(at: date) / max(1, TimeInterval(goalHours) * 3_600))
    }
}

struct FastingStatistics {
    let count: Int
    let total: TimeInterval
    let average: TimeInterval
    let longest: TimeInterval

    init(sessions: [FastingSession]) {
        let durations = sessions.filter { !$0.isActive }.map(\.duration)
        count = durations.count
        total = durations.reduce(0, +)
        average = durations.isEmpty ? 0 : total / Double(durations.count)
        longest = durations.max() ?? 0
    }
}
