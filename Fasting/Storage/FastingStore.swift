import Foundation
import SwiftData

enum FastingStoreError: LocalizedError {
    case alreadyActive, futureStart, invalidEnd, invalidGoal

    var errorDescription: String? {
        switch self {
        case .alreadyActive: String(localized: "You already have a fast in progress.")
        case .futureStart: String(localized: "The start must be in the past.")
        case .invalidEnd: String(localized: "The end must be after the start and not in the future.")
        case .invalidGoal: String(localized: "Choose a goal between 1 hour and 365 days.")
        }
    }
}

/// Explicit saves mean the UI only reports success once the session is stored on disk.
@MainActor
struct FastingStore {
    let context: ModelContext

    @discardableResult
    func start(at date: Date = .now, goalHours: Int, now: Date = .now) throws -> FastingSession {
        let existing = try context.fetch(FetchDescriptor<FastingSession>())
        guard !existing.contains(where: \.isActive) else { throw FastingStoreError.alreadyActive }
        try validate(start: date, end: nil, goal: goalHours, now: now)
        let session = FastingSession(startedAt: date, goalHours: goalHours)
        context.insert(session)
        try save()
        return session
    }

    func finish(_ session: FastingSession, at date: Date = .now, now: Date = .now) throws {
        try validate(start: session.startedAt, end: date, goal: session.goalHours, now: now)
        let previousEnd = session.endedAt
        session.endedAt = date
        try save { session.endedAt = previousEnd }
    }

    @discardableResult
    func add(start: Date, end: Date, goalHours: Int, now: Date = .now) throws -> FastingSession {
        try validate(start: start, end: end, goal: goalHours, now: now)
        let session = FastingSession(startedAt: start, endedAt: end, goalHours: goalHours)
        context.insert(session)
        try save()
        return session
    }

    func update(_ session: FastingSession, start: Date, end: Date?, goalHours: Int, now: Date = .now) throws {
        try validate(start: start, end: end, goal: goalHours, now: now)
        let previous = (session.startedAt, session.endedAt, session.goalHours)
        session.startedAt = start
        session.endedAt = end
        session.goalHours = goalHours
        try save {
            session.startedAt = previous.0
            session.endedAt = previous.1
            session.goalHours = previous.2
        }
    }

    func delete(_ session: FastingSession) throws {
        context.delete(session)
        try save()
    }

    private func save(restoring restore: (() -> Void)? = nil) throws {
        do { try context.save() }
        catch {
            context.rollback()
            // SwiftData can leave observed model values at their attempted values after a
            // failed disk save. Restore the UI's live object as well as rolling back the context.
            restore?()
            throw error
        }
    }

    private func validate(start: Date, end: Date?, goal: Int, now: Date) throws {
        guard FastingGoal.allowedHours.contains(goal) else { throw FastingStoreError.invalidGoal }
        guard start <= now else { throw FastingStoreError.futureStart }
        if let end, end < start || end > now { throw FastingStoreError.invalidEnd }
    }
}
