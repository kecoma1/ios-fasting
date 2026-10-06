import Foundation
import SwiftData

/// Each saved entry is an event so offline devices can merge without a singleton constraint.
@Model
final class MealEntry {
    var id: UUID = UUID()
    var eatenAt: Date = Date.now
    var recordedAt: Date = Date.now

    init(id: UUID = UUID(), eatenAt: Date = .now, recordedAt: Date = .now) {
        self.id = id
        self.eatenAt = eatenAt
        self.recordedAt = recordedAt
    }

    func elapsed(at date: Date) -> TimeInterval {
        max(0, date.timeIntervalSince(eatenAt))
    }

    /// The newest action wins, including a correction to an earlier meal time.
    static func latest(in entries: [MealEntry]) -> MealEntry? {
        entries.max {
            $0.recordedAt == $1.recordedAt ? $0.id.uuidString < $1.id.uuidString : $0.recordedAt < $1.recordedAt
        }
    }
}
