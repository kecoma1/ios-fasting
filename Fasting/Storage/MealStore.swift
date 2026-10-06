import Foundation
import SwiftData

enum MealStoreError: LocalizedError {
    case futureMeal

    var errorDescription: String? {
        String(localized: "Choose a meal time that is not in the future.")
    }
}

@MainActor
struct MealStore {
    let context: ModelContext

    @discardableResult
    func record(at date: Date, now: Date = .now) throws -> MealEntry {
        guard date <= now else { throw MealStoreError.futureMeal }
        // Keep an uncommitted insertion out of the context observed by the counter.
        // The short-lived context is discarded entirely if its disk save fails.
        let transaction = ModelContext(context.container)
        transaction.autosaveEnabled = false
        let entry = MealEntry(eatenAt: date, recordedAt: now)
        transaction.insert(entry)
        do { try transaction.save() }
        catch {
            transaction.rollback()
            throw error
        }
        return entry
    }
}
