import SwiftUI
import SwiftData

@main
struct FastingApp: App {
    @State private var container: ModelContainer?
    @State private var errorMessage: String?

    var body: some Scene {
        WindowGroup {
            Group {
                if let container {
                    RootView().modelContainer(container)
                } else if let errorMessage {
                    ContentUnavailableView {
                        Label("Couldn’t Open Your Fasts", systemImage: "externaldrive.badge.exclamationmark")
                    } description: {
                        Text("Your saved data has been kept. Try opening it again.")
                        Text(errorMessage).font(.caption)
                    } actions: {
                        Button("Try Again", action: load).buttonStyle(.borderedProminent)
                    }
                } else {
                    ProgressView().task { load() }
                }
            }
            .tint(.accentColor)
        }
    }

    private func load() {
        do {
            container = try Persistence.makeContainer()
            errorMessage = nil
        } catch {
            // Never erase a failed store or silently switch to an empty in-memory database.
            errorMessage = error.localizedDescription
        }
    }
}
