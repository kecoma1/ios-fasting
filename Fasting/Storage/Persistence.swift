import Foundation
import SwiftData
#if DEBUG
import CoreData
import _SwiftData_CoreData
#endif

enum Persistence {
    static let cloudContainerID = "iCloud.com.rento.fasting"

    static var usesCloud: Bool {
        #if targetEnvironment(simulator)
        false
        #else
        true
        #endif
    }

    @MainActor
    static func makeContainer() throws -> ModelContainer {
        let directory = try FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true
        ).appendingPathComponent("Fasting", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var url = directory.appendingPathComponent("Fasting.store")
        var cloud = usesCloud
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        // UI tests get their own persistent store; they never reset the user's database.
        if let index = arguments.firstIndex(of: "-UITestStore"), arguments.indices.contains(index + 1),
           let id = UUID(uuidString: arguments[index + 1]) {
            url = directory.appendingPathComponent("test-\(id.uuidString).store")
            cloud = false
        }
        if arguments.contains("-InitializeCloudKitSchema") {
            try initializeCloudSchema()
        }
        #endif
        let schema = Schema([FastingSession.self, MealEntry.self])
        let configuration = ModelConfiguration(
            "Fasting", schema: schema, url: url,
            cloudKitDatabase: cloud ? .private(cloudContainerID) : .none
        )
        let container = try ModelContainer(for: schema, configurations: [configuration])
        container.mainContext.autosaveEnabled = false
        #if DEBUG
        if !cloud, url.lastPathComponent.hasPrefix("test-"), arguments.contains("-DemoMealData"),
           try container.mainContext.fetchCount(FetchDescriptor<MealEntry>()) == 0 {
            let elapsed: TimeInterval = arguments.contains("-DemoMealMultiDay") ? 273_900 : 45_780
            try MealStore(context: container.mainContext).record(at: Date.now.addingTimeInterval(-elapsed))
        }
        if !cloud, url.lastPathComponent.hasPrefix("test-"), arguments.contains("-DemoData"),
           try container.mainContext.fetchCount(FetchDescriptor<FastingSession>()) == 0 {
            let now = Date.now
            for (index, hours) in [16, 14, 18].enumerated() {
                let end = Calendar.current.date(byAdding: .day, value: -(index + 2), to: now) ?? now
                container.mainContext.insert(FastingSession(
                    startedAt: end.addingTimeInterval(-TimeInterval(hours) * 3_600),
                    endedAt: end, goalHours: 16
                ))
            }
            let multiDay = arguments.contains("-DemoMultiDay")
            let hours = multiDay ? 76 : 12
            let minutes = multiDay ? 5 : 43
            let elapsed = TimeInterval(hours * 3_600 + minutes * 60)
            container.mainContext.insert(FastingSession(
                startedAt: now.addingTimeInterval(-elapsed), goalHours: multiDay ? 72 : 16
            ))
            try container.mainContext.save()
        }
        #endif
        return container
    }

    #if DEBUG
    /// Use a disposable store and unload it before SwiftData opens the real database.
    private static func initializeCloudSchema() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("schema-\(UUID()).store")
        defer {
            for suffix in ["", "-wal", "-shm"] {
                try? FileManager.default.removeItem(atPath: url.path + suffix)
            }
        }
        try autoreleasepool {
            guard let model = NSManagedObjectModel.makeManagedObjectModel(for: [FastingSession.self, MealEntry.self]) else {
                throw CocoaError(.persistentStoreInvalidType)
            }
            let description = NSPersistentStoreDescription(url: url)
            description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: cloudContainerID)
            description.shouldAddStoreAsynchronously = false
            let container = NSPersistentCloudKitContainer(name: "Fasting", managedObjectModel: model)
            container.persistentStoreDescriptions = [description]
            var loadError: Error?
            container.loadPersistentStores { _, error in loadError = error }
            if let loadError { throw loadError }
            try container.initializeCloudKitSchema()
            if let store = container.persistentStoreCoordinator.persistentStores.first {
                try container.persistentStoreCoordinator.remove(store)
            }
        }
    }
    #endif
}
