import Foundation

/// Time checkpoints, not measurements of the user's metabolism.
/// The early checkpoints introduce overlapping processes, not exact biological deadlines.
enum FastingMilestone: String, CaseIterable, Identifiable {
    case reserves, fatFuel, ketones, oneDay, twoDays, threeDays

    var id: String { rawValue }

    var hours: Int {
        switch self {
        case .reserves: 8
        case .fatFuel: 12
        case .ketones: 16
        case .oneDay: 24
        case .twoDays: 48
        case .threeDays: 72
        }
    }

    var threshold: TimeInterval { TimeInterval(hours) * 3_600 }
    var isMetabolicReference: Bool { hours < 24 }

    var title: String {
        switch self {
        case .reserves: String(localized: "Energy reserves")
        case .fatFuel: String(localized: "Fat as fuel")
        case .ketones: String(localized: "Ketone transition")
        case .oneDay: String(localized: "One day")
        case .twoDays: String(localized: "Two days")
        case .threeDays: String(localized: "Three days")
        }
    }

    var symbol: String {
        switch self {
        case .reserves: "battery.75percent"
        case .fatFuel: "flame"
        case .ketones: "drop"
        case .oneDay: "sun.max"
        case .twoDays: "moon.stars"
        case .threeDays: "calendar"
        }
    }

    var timeLabel: String {
        let duration = DurationText.goal(hours: hours)
        return isMetabolicReference ? String(localized: "≈ \(duration)") : duration
    }

    var explanation: String {
        switch self {
        case .reserves:
            String(localized: "Between meals, the liver helps supply glucose from stored glycogen. The 8-hour badge is a time checkpoint for learning about this process; it does not measure your reserves or mean they are depleted.")
        case .fatFuel:
            String(localized: "As fasting continues, stored fat can provide a growing share of energy. This is a gradual shift, influenced by your previous meals and activity. The 12-hour badge does not detect fat burning.")
        case .ketones:
            String(localized: "The liver can produce more ketones as fuel during fasting. The metabolic transition is often described over roughly 12–36 hours and varies between people. The 16-hour badge is an educational reference; it does not confirm ketosis.")
        case .oneDay:
            String(localized: "24 hours have elapsed since your saved start time. This badge records time, without making a claim about a new biological stage or a health benefit.")
        case .twoDays:
            String(localized: "48 hours have elapsed since your saved start time. Earlier badges stay visible. This is a duration checkpoint, not a recommendation to extend your fast.")
        case .threeDays:
            String(localized: "72 hours have elapsed since your saved start time. Your timer can keep counting, and all reached badges remain visible until you finish this fast. This checkpoint does not indicate additional health benefits.")
        }
    }

    static func reached(after elapsed: TimeInterval) -> [Self] {
        allCases.filter { elapsed >= $0.threshold }
    }
}
