import SwiftUI
import SwiftData

struct SessionEditor: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let session: FastingSession?
    @State private var start: Date
    @State private var end: Date
    @State private var goal: Int
    @State private var errorMessage: String?
    @State private var showingDelete = false
    @State private var showingFinish = false

    init(session: FastingSession? = nil) {
        self.session = session
        _start = State(initialValue: session?.startedAt ?? Date.now.addingTimeInterval(-16 * 3_600))
        _end = State(initialValue: session?.endedAt ?? .now)
        _goal = State(initialValue: session?.goalHours ?? 16)
    }

    private var active: Bool { session?.isActive == true }
    private var valid: Bool { start <= .now && (active || (end >= start && end <= .now)) }

    var body: some View {
        NavigationStack {
            Form {
                if !active {
                    Section {
                        VStack(spacing: 8) {
                            Image(systemName: "moon.fill").font(.title).foregroundStyle(Color.accentColor)
                            Text(DurationText.compact(max(0, end.timeIntervalSince(start))))
                                .font(.largeTitle.weight(.light)).monospacedDigit()
                            Text("Time fasting").font(.subheadline).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                    }
                }
                Section("Times") {
                    DatePicker("Start", selection: $start, in: ...Date.now)
                        .accessibilityIdentifier("editorStartDate")
                    if !active {
                        DatePicker("End", selection: $end, in: ...Date.now)
                            .accessibilityIdentifier("editorEndDate")
                    }
                    GoalPickerRow(title: "Goal", goalHours: $goal)
                        .accessibilityIdentifier("sessionGoalRow")
                }
                if !valid { Text("The end must be after the start and not in the future.").foregroundStyle(.red) }
                if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
                if active {
                    Section { Button("Finish Fast") { showingFinish = true } }
                }
                if session != nil {
                    Section { Button("Delete Fast", role: .destructive) { showingDelete = true }.accessibilityIdentifier("deleteFastButton") }
                }
            }
            .navigationTitle(session == nil ? "Add a Past Fast" : "Edit Fast")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save).disabled(!valid).accessibilityIdentifier("saveSessionButton")
                }
            }
            .confirmationDialog("Delete this fast?", isPresented: $showingDelete, titleVisibility: .visible) {
                Button("Delete Fast", role: .destructive) {
                    guard let session else { return }
                    perform { try FastingStore(context: context).delete(session) }
                }
            } message: { Text("This also deletes it from your devices using iCloud.") }
            .confirmationDialog("Finish this fast?", isPresented: $showingFinish, titleVisibility: .visible) {
                Button("Finish and Save") {
                    guard let session else { return }
                    perform { try FastingStore(context: context).update(session, start: start, end: .now, goalHours: goal) }
                }
            }
        }
    }

    private func save() {
        perform {
            let store = FastingStore(context: context)
            if let session { try store.update(session, start: start, end: active ? nil : end, goalHours: goal) }
            else { try store.add(start: start, end: end, goalHours: goal) }
        }
    }

    private func perform(_ operation: () throws -> Void) {
        do { try operation(); dismiss() }
        catch { errorMessage = error.localizedDescription }
    }
}
