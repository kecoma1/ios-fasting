import XCTest
import SwiftData

@MainActor
final class MealStoreTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func container(url: URL? = nil, allowsSave: Bool = true, legacy: Bool = false) throws -> ModelContainer {
        let schema = legacy ? Schema([FastingSession.self]) : Schema([FastingSession.self, MealEntry.self])
        let config: ModelConfiguration
        if let url {
            config = ModelConfiguration("Fasting", schema: schema, url: url, allowsSave: allowsSave, cloudKitDatabase: .none)
        } else {
            config = ModelConfiguration("Fasting", schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        }
        let db = try ModelContainer(for: schema, configurations: [config])
        db.mainContext.autosaveEnabled = false
        return db
    }

    func testMealAndActiveFastPersistIndependentlyAcrossReopening() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("meals.store")
        let eatenAt = now.addingTimeInterval(-273_900) // 3 days, 4 hours, 5 minutes.
        try autoreleasepool {
            let db = try container(url: url)
            try FastingStore(context: db.mainContext).start(at: now.addingTimeInterval(-18 * 3_600), goalHours: 16, now: now)
            try MealStore(context: db.mainContext).record(at: eatenAt, now: now)
        }
        let db = try container(url: url)
        let meal = try XCTUnwrap(MealEntry.latest(in: db.mainContext.fetch(FetchDescriptor<MealEntry>())))
        XCTAssertEqual(meal.eatenAt, eatenAt)
        XCTAssertEqual(meal.elapsed(at: now.addingTimeInterval(3_600)), 277_500)
        XCTAssertEqual(DurationText.compact(meal.elapsed(at: now)), "3 d 4 h 5 min")
        let fast = try XCTUnwrap(db.mainContext.fetch(FetchDescriptor<FastingSession>()).first)
        XCTAssertTrue(fast.isActive)
        XCTAssertEqual(fast.elapsed(at: now), 18 * 3_600)
        XCTAssertEqual(fast.goalHours, 16)
    }

    func testNewRecordResetsCounterAndCorrectionCanMoveMealTimeEarlier() throws {
        let db = try container()
        let store = MealStore(context: db.mainContext)
        try store.record(at: now.addingTimeInterval(-10 * 3_600), now: now)
        let later = now.addingTimeInterval(60)
        let justAte = try store.record(at: later, now: later)
        XCTAssertEqual(justAte.elapsed(at: later), 0)
        XCTAssertEqual(MealEntry.latest(in: try db.mainContext.fetch(FetchDescriptor<MealEntry>()))?.id, justAte.id)

        let correctedDate = now.addingTimeInterval(-12 * 3_600)
        let corrected = try store.record(at: correctedDate, now: later.addingTimeInterval(60))
        let latest = try XCTUnwrap(MealEntry.latest(in: db.mainContext.fetch(FetchDescriptor<MealEntry>())))
        XCTAssertEqual(latest.id, corrected.id)
        XCTAssertEqual(latest.eatenAt, correctedDate)
        XCTAssertEqual(latest.elapsed(at: now), 12 * 3_600)
    }

    func testFutureMealIsRejectedWithoutReplacingPreviousRecord() throws {
        let db = try container()
        let store = MealStore(context: db.mainContext)
        let original = try store.record(at: now.addingTimeInterval(-3_600), now: now)
        XCTAssertThrowsError(try store.record(at: now.addingTimeInterval(1), now: now))
        let meals = try db.mainContext.fetch(FetchDescriptor<MealEntry>())
        XCTAssertEqual(meals.count, 1)
        XCTAssertEqual(MealEntry.latest(in: meals)?.id, original.id)
        XCTAssertEqual(original.elapsed(at: now), 3_600)
    }

    func testFailedSaveKeepsPreviousMealAndDoesNotLeavePhantomRecord() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("readonly.store")
        let originalDate = now.addingTimeInterval(-8 * 3_600)
        try autoreleasepool {
            let db = try container(url: url)
            try MealStore(context: db.mainContext).record(at: originalDate, now: now)
        }
        let db = try container(url: url, allowsSave: false)
        XCTAssertThrowsError(try MealStore(context: db.mainContext).record(at: now, now: now.addingTimeInterval(60)))
        let meals = try db.mainContext.fetch(FetchDescriptor<MealEntry>())
        XCTAssertEqual(meals.count, 1)
        XCTAssertEqual(MealEntry.latest(in: meals)?.eatenAt, originalDate)
        XCTAssertThrowsError(try MealStore(context: db.mainContext).record(at: now, now: now.addingTimeInterval(120)))
        let retried = try db.mainContext.fetch(FetchDescriptor<MealEntry>())
        XCTAssertEqual(retried.count, 1)
        XCTAssertEqual(MealEntry.latest(in: retried)?.eatenAt, originalDate)
    }

    func testAddingMealModelPreservesOriginalFastingDatabase() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("upgrade.store")
        try autoreleasepool {
            let db = try container(url: url, legacy: true)
            let store = FastingStore(context: db.mainContext)
            try store.add(start: now.addingTimeInterval(-273_900), end: now, goalHours: 72, now: now)
            try store.start(at: now.addingTimeInterval(-16 * 3_600), goalHours: 24, now: now)
        }
        try autoreleasepool {
            let upgraded = try container(url: url)
            let sessions = try upgraded.mainContext.fetch(FetchDescriptor<FastingSession>())
            XCTAssertEqual(sessions.count, 2)
            XCTAssertEqual(sessions.filter(\.isActive).first?.goalHours, 24)
            XCTAssertEqual(FastingStatistics(sessions: sessions).total, 273_900)
            XCTAssertEqual(try upgraded.mainContext.fetchCount(FetchDescriptor<MealEntry>()), 0)
            try MealStore(context: upgraded.mainContext).record(at: now.addingTimeInterval(-3_600), now: now)
        }
        let reopened = try container(url: url)
        XCTAssertEqual(try reopened.mainContext.fetchCount(FetchDescriptor<FastingSession>()), 2)
        XCTAssertEqual(try reopened.mainContext.fetchCount(FetchDescriptor<MealEntry>()), 1)
    }

    func testMergedEntriesResolveTiesConsistentlyAndClockCannotGoNegative() throws {
        let low = MealEntry(id: try XCTUnwrap(UUID(uuidString: "00000000-0000-0000-0000-000000000001")),
                            eatenAt: now.addingTimeInterval(-10 * 3_600), recordedAt: now)
        let high = MealEntry(id: try XCTUnwrap(UUID(uuidString: "00000000-0000-0000-0000-000000000002")),
                             eatenAt: now.addingTimeInterval(-3_600), recordedAt: now)
        XCTAssertEqual(MealEntry.latest(in: [low, high])?.id, high.id)
        XCTAssertEqual(MealEntry.latest(in: [high, low])?.id, high.id)
        XCTAssertEqual(high.elapsed(at: now.addingTimeInterval(-7_200)), 0)
        XCTAssertNil(MealEntry.latest(in: []))
    }
}
