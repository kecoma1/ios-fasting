import XCTest
import SwiftData
import CoreData
import _SwiftData_CoreData

@MainActor
final class FastingStoreTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func container(url: URL? = nil, allowsSave: Bool = true) throws -> ModelContainer {
        let schema = Schema([FastingSession.self])
        let config: ModelConfiguration
        if let url { config = ModelConfiguration(schema: schema, url: url, allowsSave: allowsSave, cloudKitDatabase: .none) }
        else { config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none) }
        let container = try ModelContainer(for: schema, configurations: [config])
        container.mainContext.autosaveEnabled = false
        return container
    }

    func testActiveFastSurvivesReopeningDiskStore() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("test.store")
        let start = now.addingTimeInterval(-5 * 3_600)
        try autoreleasepool {
            let db = try container(url: url)
            try FastingStore(context: db.mainContext).start(at: start, goalHours: 16, now: now)
        }
        let reopened = try container(url: url)
        let sessions = try reopened.mainContext.fetch(FetchDescriptor<FastingSession>())
        XCTAssertEqual(sessions.count, 1)
        XCTAssertTrue(sessions[0].isActive)
        XCTAssertEqual(sessions[0].elapsed(at: now), 5 * 3_600)
        XCTAssertEqual(sessions[0].goalHours, 16)
    }

    func testSecondActiveFastIsRejected() throws {
        let db = try container()
        let store = FastingStore(context: db.mainContext)
        try store.start(at: now, goalHours: 16, now: now)
        XCTAssertThrowsError(try store.start(at: now, goalHours: 14, now: now))
        XCTAssertEqual(try db.mainContext.fetchCount(FetchDescriptor<FastingSession>()), 1)
    }

    func testFinishingFreezesDurationAndAllowsNextFast() throws {
        let db = try container()
        let store = FastingStore(context: db.mainContext)
        let session = try store.start(at: now.addingTimeInterval(-18 * 3_600), goalHours: 16, now: now)
        try store.finish(session, at: now, now: now)
        XCTAssertFalse(session.isActive)
        XCTAssertTrue(session.reachedGoal)
        XCTAssertEqual(session.elapsed(at: now.addingTimeInterval(3_600)), 18 * 3_600)
        try store.start(at: now, goalHours: 14, now: now)
        XCTAssertEqual(try db.mainContext.fetchCount(FetchDescriptor<FastingSession>()), 2)
    }

    func testInvalidDatesAndGoalsNeverWriteRecords() throws {
        let db = try container()
        let store = FastingStore(context: db.mainContext)
        XCTAssertThrowsError(try store.start(at: now.addingTimeInterval(60), goalHours: 16, now: now))
        XCTAssertThrowsError(try store.add(start: now, end: now.addingTimeInterval(-60), goalHours: 16, now: now))
        XCTAssertThrowsError(try store.add(start: now, end: now.addingTimeInterval(60), goalHours: 16, now: now))
        XCTAssertThrowsError(try store.start(at: now, goalHours: 0, now: now))
        XCTAssertThrowsError(try store.start(at: now, goalHours: 8_761, now: now))
        XCTAssertEqual(try db.mainContext.fetchCount(FetchDescriptor<FastingSession>()), 0)
    }

    func testInvalidEditPreservesOriginalRecord() throws {
        let db = try container()
        let store = FastingStore(context: db.mainContext)
        let start = now.addingTimeInterval(-16 * 3_600)
        let session = try store.add(start: start, end: now, goalHours: 16, now: now)
        XCTAssertThrowsError(try store.update(session, start: now, end: start, goalHours: 12, now: now))
        XCTAssertEqual(session.startedAt, start)
        XCTAssertEqual(session.endedAt, now)
        XCTAssertEqual(session.goalHours, 16)
    }

    func testEditAndDeleteArePersisted() throws {
        let db = try container()
        let store = FastingStore(context: db.mainContext)
        let session = try store.add(start: now.addingTimeInterval(-16 * 3_600), end: now, goalHours: 16, now: now)
        let newStart = now.addingTimeInterval(-14 * 3_600)
        try store.update(session, start: newStart, end: now, goalHours: 12, now: now)
        let fetched = try ModelContext(db).fetch(FetchDescriptor<FastingSession>())
        XCTAssertEqual(fetched[0].startedAt, newStart)
        XCTAssertEqual(fetched[0].goalHours, 12)
        try store.delete(session)
        XCTAssertEqual(try ModelContext(db).fetchCount(FetchDescriptor<FastingSession>()), 0)
    }

    func testFailedSaveRollsBackEditedDatesAndGoal() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("readonly.store")
        let start = now.addingTimeInterval(-16 * 3_600)
        try autoreleasepool {
            let db = try container(url: url)
            try FastingStore(context: db.mainContext).add(start: start, end: now, goalHours: 16, now: now)
        }
        let db = try container(url: url, allowsSave: false)
        let session = try XCTUnwrap(db.mainContext.fetch(FetchDescriptor<FastingSession>()).first)
        XCTAssertThrowsError(try FastingStore(context: db.mainContext).update(
            session, start: now.addingTimeInterval(-12 * 3_600), end: now, goalHours: 12, now: now
        ))
        XCTAssertEqual(session.startedAt, start)
        XCTAssertEqual(session.goalHours, 16)
        XCTAssertEqual(session.endedAt, now)
    }

    func testStatisticsIgnoreActiveSessions() throws {
        let sessions = [
            FastingSession(startedAt: now.addingTimeInterval(-12 * 3_600), endedAt: now, goalHours: 16),
            FastingSession(startedAt: now.addingTimeInterval(-18 * 3_600), endedAt: now, goalHours: 16),
            FastingSession(startedAt: now.addingTimeInterval(-50 * 3_600))
        ]
        let stats = FastingStatistics(sessions: sessions)
        XCTAssertEqual(stats.count, 2)
        XCTAssertEqual(stats.total, 30 * 3_600)
        XCTAssertEqual(stats.average, 15 * 3_600)
        XCTAssertEqual(stats.longest, 18 * 3_600)
    }

    func testEmptyStatisticsAndDayAwareDurations() {
        let multiDayDuration: TimeInterval = 273_906 // 3 days, 4 hours, 5 minutes, 6 seconds.
        let stats = FastingStatistics(sessions: [])
        XCTAssertEqual(stats.average, 0)
        XCTAssertEqual(stats.longest, 0)
        XCTAssertEqual(DurationText.days(25 * 3_600 + 61), 1)
        XCTAssertEqual(DurationText.clock(25 * 3_600 + 61), "01:01:01")
        XCTAssertEqual(DurationText.days(multiDayDuration), 3)
        XCTAssertEqual(DurationText.clock(multiDayDuration), "04:05:06")
        XCTAssertEqual(DurationText.clock(86_399), "23:59:59")
        XCTAssertEqual(DurationText.clock(86_400), "00:00:00")
        XCTAssertEqual(DurationText.clock(-10), "00:00:00")
        XCTAssertEqual(DurationText.compact(16 * 3_600 + 30 * 60), "16 h 30 min")
        XCTAssertEqual(DurationText.compact(3 * 86_400), "3 d")
        XCTAssertEqual(DurationText.compact(multiDayDuration), "3 d 4 h 5 min")
        XCTAssertEqual(DurationText.goal(hours: 16), "16 h")
        XCTAssertEqual(DurationText.goal(hours: 72), "3 d")
        XCTAssertEqual(DurationText.goal(hours: 73), "3 d 1 h")
        XCTAssertEqual(DurationText.goal(hours: 360), "15 d")
    }

    func testThreeDayFastPersistsAndKeepsCountingAfterItsGoal() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("multiday.store")
        let duration: TimeInterval = 273_900 // 3 days, 4 hours, 5 minutes.
        let start = now.addingTimeInterval(-duration)
        try autoreleasepool {
            let db = try container(url: url)
            try FastingStore(context: db.mainContext).start(at: start, goalHours: 72, now: now)
        }
        try autoreleasepool {
            let db = try container(url: url)
            let session = try XCTUnwrap(db.mainContext.fetch(FetchDescriptor<FastingSession>()).first)
            XCTAssertEqual(session.goalHours, 72)
            XCTAssertEqual(session.targetDate, start.addingTimeInterval(72 * 3_600))
            XCTAssertTrue(session.isActive)
            XCTAssertEqual(session.progress(at: now), 1)
            XCTAssertEqual(session.elapsed(at: now.addingTimeInterval(3_600)), duration + 3_600)
            try FastingStore(context: db.mainContext).finish(session, at: now, now: now)
        }
        let db = try container(url: url)
        let session = try XCTUnwrap(db.mainContext.fetch(FetchDescriptor<FastingSession>()).first)
        XCTAssertFalse(session.isActive)
        XCTAssertTrue(session.reachedGoal)
        XCTAssertEqual(session.elapsed(at: now.addingTimeInterval(86_400)), duration)
        XCTAssertEqual(DurationText.compact(session.duration), "3 d 4 h 5 min")
        XCTAssertEqual(FastingStatistics(sessions: [session]).longest, duration)
    }

    func testExtendedGoalsAndPastFastsAreStoredInWholeHours() throws {
        let db = try container()
        let store = FastingStore(context: db.mainContext)
        for hours in [49, 72, 360, 8_760] {
            let session = try store.add(start: now.addingTimeInterval(-TimeInterval(hours) * 3_600),
                                        end: now, goalHours: hours, now: now)
            XCTAssertEqual(session.goalHours, hours)
            XCTAssertEqual(session.duration, TimeInterval(hours) * 3_600)
            XCTAssertEqual(session.targetDate, now)
            XCTAssertTrue(session.reachedGoal)
        }
        XCTAssertEqual(try ModelContext(db).fetchCount(FetchDescriptor<FastingSession>()), 4)
    }

    func testClockChangesAndGoalClamp() {
        let session = FastingSession(startedAt: now, goalHours: 16)
        XCTAssertEqual(session.elapsed(at: now.addingTimeInterval(-60)), 0)
        XCTAssertEqual(session.progress(at: now.addingTimeInterval(8 * 3_600)), 0.5)
        XCTAssertEqual(session.progress(at: now.addingTimeInterval(20 * 3_600)), 1)
    }

    func testMilestonesUnlockAtTheirBoundaryAndAccumulateAcrossDays() {
        XCTAssertTrue(FastingMilestone.reached(after: -60).isEmpty)
        XCTAssertTrue(FastingMilestone.reached(after: 0).isEmpty)
        for (index, milestone) in FastingMilestone.allCases.enumerated() {
            let previous = Array(FastingMilestone.allCases.prefix(index))
            XCTAssertEqual(FastingMilestone.reached(after: milestone.threshold - 1), previous)
            XCTAssertEqual(FastingMilestone.reached(after: milestone.threshold), previous + [milestone])
        }
        XCTAssertEqual(FastingMilestone.reached(after: 15 * 86_400), FastingMilestone.allCases)
    }

    func testMilestonesFollowPersistedAndEditedStartWithoutExtraStoredState() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: directory.path) }
        let url = directory.appendingPathComponent("milestones.store")
        try autoreleasepool {
            let db = try container(url: url)
            let session = try FastingStore(context: db.mainContext).start(
                at: now.addingTimeInterval(-18 * 3_600), goalHours: 72, now: now)
            XCTAssertEqual(FastingMilestone.reached(after: session.elapsed(at: now)), [.reserves, .fatFuel, .ketones])
        }
        let db = try container(url: url)
        let session = try XCTUnwrap(db.mainContext.fetch(FetchDescriptor<FastingSession>()).first)
        XCTAssertEqual(FastingMilestone.reached(after: session.elapsed(at: now)), [.reserves, .fatFuel, .ketones])
        try FastingStore(context: db.mainContext).update(session, start: now.addingTimeInterval(-10 * 3_600),
                                                       end: nil, goalHours: 72, now: now)
        XCTAssertEqual(FastingMilestone.reached(after: session.elapsed(at: now)), [.reserves])
    }

    func testFinishedMilestonesFreezeAndNewFastStartsWithoutBadges() throws {
        let db = try container()
        let store = FastingStore(context: db.mainContext)
        let previous = try store.start(at: now.addingTimeInterval(-25 * 3_600), goalHours: 16, now: now)
        try store.finish(previous, at: now, now: now)
        let frozen = FastingMilestone.reached(after: previous.elapsed(at: now))
        XCTAssertEqual(frozen, [.reserves, .fatFuel, .ketones, .oneDay])
        XCTAssertEqual(FastingMilestone.reached(after: previous.elapsed(at: now.addingTimeInterval(7 * 86_400))), frozen)
        let next = try store.start(at: now, goalHours: 16, now: now)
        XCTAssertTrue(FastingMilestone.reached(after: next.elapsed(at: now)).isEmpty)
    }

    func testSchemaIsCompatibleWithCloudKit() throws {
        let model = try XCTUnwrap(NSManagedObjectModel.makeManagedObjectModel(for: [FastingSession.self, MealEntry.self]))
        for entity in model.entities {
            XCTAssertTrue(entity.uniquenessConstraints.isEmpty)
            for attribute in entity.attributesByName.values {
                XCTAssertTrue(attribute.isOptional || attribute.defaultValue != nil,
                              "\(attribute.name) needs a default or an optional value for CloudKit.")
            }
            for relationship in entity.relationshipsByName.values {
                XCTAssertTrue(relationship.isOptional)
            }
        }
    }
}
