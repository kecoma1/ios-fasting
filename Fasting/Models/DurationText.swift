import Foundation

enum DurationText {
    static func clock(_ duration: TimeInterval) -> String {
        let seconds = Int(max(0, duration).rounded(.down))
        return String(format: "%02d:%02d:%02d", seconds / 3_600, (seconds % 3_600) / 60, seconds % 60)
    }

    static func compact(_ duration: TimeInterval) -> String {
        let minutes = Int(max(0, duration) / 60)
        return "\(minutes / 60) h \(minutes % 60) min"
    }

    static func accessible(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .full
        return formatter.string(from: max(0, duration)) ?? clock(duration)
    }
}
