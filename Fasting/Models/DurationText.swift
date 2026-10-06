import Foundation

enum DurationText {
    static func days(_ duration: TimeInterval) -> Int {
        Int(max(0, duration) / 86_400)
    }

    static func clock(_ duration: TimeInterval) -> String {
        let seconds = Int(max(0, duration).rounded(.down))
        return String(format: "%02d:%02d:%02d", (seconds / 3_600) % 24, (seconds % 3_600) / 60, seconds % 60)
    }

    static func goal(hours: Int) -> String {
        let days = max(0, hours) / 24
        let remainingHours = max(0, hours) % 24
        if days == 0 { return String(localized: "\(remainingHours) h") }
        if remainingHours == 0 { return String(localized: "\(days) d") }
        return String(localized: "\(days) d \(remainingHours) h")
    }

    static func compact(_ duration: TimeInterval) -> String {
        let minutes = Int(max(0, duration) / 60)
        let days = minutes / 1_440
        let hours = (minutes / 60) % 24
        let remainingMinutes = minutes % 60
        if days == 0 { return String(localized: "\(hours) h \(remainingMinutes) min") }
        if hours == 0 && remainingMinutes == 0 { return String(localized: "\(days) d") }
        if remainingMinutes == 0 { return String(localized: "\(days) d \(hours) h") }
        return String(localized: "\(days) d \(hours) h \(remainingMinutes) min")
    }

    static func accessible(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute, .second]
        formatter.unitsStyle = .full
        return formatter.string(from: max(0, duration)) ?? compact(duration)
    }
}
