import Foundation

enum FastingGoal {
    // This bounds the duration editor, not elapsed time: an active fast never stops at its goal.
    static let maximumDays = 365
    static let allowedHours = 1...(maximumDays * 24)
}
