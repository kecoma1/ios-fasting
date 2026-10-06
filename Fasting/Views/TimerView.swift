import SwiftUI
import SwiftData

struct TimerView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \FastingSession.startedAt, order: .reverse) private var sessions: [FastingSession]
    @AppStorage("defaultGoalHours") private var goalHours = 16
    @State private var showingSettings = false
    @State private var showingStart = false
    @State private var showingFinish = false
    @State private var showingGoal = false
    @State private var selectedGoal = 16
    @State private var editingSession: FastingSession?
    @State private var errorMessage: String?

    private var activeSessions: [FastingSession] {
        sessions.filter(\.isActive).sorted {
            $0.startedAt == $1.startedAt ? $0.id.uuidString < $1.id.uuidString : $0.startedAt > $1.startedAt
        }
    }
    private var active: FastingSession? { activeSessions.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    Text(active == nil ? "Ready when you are" : "Fast in progress")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.top, 20)
                    TimelineView(.periodic(from: .now, by: 1)) { timeline in
                        TimerRing(
                            elapsed: active?.elapsed(at: timeline.date) ?? 0,
                            progress: active?.progress(at: timeline.date) ?? 0,
                            active: active != nil
                        )
                    }
                    Button {
                        selectedGoal = active?.goalHours ?? goalHours
                        showingGoal = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "scope")
                            Text("Goal · \(DurationText.goal(hours: active?.goalHours ?? goalHours))")
                            Image(systemName: "chevron.down").font(.caption.weight(.semibold))
                        }
                        .padding(.horizontal, 10).padding(.vertical, 6)
                    }
                    .fastingButton()
                    .buttonBorderShape(.capsule)
                    .accessibilityIdentifier("goalButton")
                    if let active {
                        sessionTimes(active)
                    } else {
                        Text("One timer. A little space for yourself.")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                    }
                    if activeSessions.count > 1 {
                        Label("Several devices started a fast. You can finish each one in History.", systemImage: "icloud")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                    Button {
                        if active == nil { showingStart = true }
                        else { showingFinish = true }
                    } label: {
                        Label(active == nil ? "Start Fast" : "Finish Fast", systemImage: active == nil ? "play.fill" : "stop.fill")
                            .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 15)
                            .foregroundStyle(colorScheme == .dark ? Color.black : Color.white)
                    }
                    .fastingButton(prominent: true)
                    .buttonBorderShape(.capsule)
                    .accessibilityIdentifier(active == nil ? "startFastButton" : "finishFastButton")
                    Text(active == nil ? "You can adjust the start time if you already began." : "You can close the app. Your timer keeps going.")
                        .font(.footnote).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 28).padding(.bottom, 30)
                .frame(maxWidth: 500).frame(maxWidth: .infinity)
            }
            .background { FastingBackground() }
            .navigationTitle("Fast")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingSettings = true } label: { Label("Settings", systemImage: "slider.horizontal.3") }
                        .accessibilityIdentifier("settingsButton")
                }
            }
            .sheet(isPresented: $showingSettings) { SettingsView() }
            .sheet(isPresented: $showingStart) { StartFastSheet(goalHours: goalHours) }
            .sheet(isPresented: $showingGoal) { goalSheet }
            .sheet(item: $editingSession) { SessionEditor(session: $0) }
            .confirmationDialog("Finish this fast?", isPresented: $showingFinish, titleVisibility: .visible) {
                Button("Finish and Save") {
                    guard let active else { return }
                    do { try FastingStore(context: context).finish(active) }
                    catch { errorMessage = error.localizedDescription }
                }
                Button("Cancel", role: .cancel) { }
            } message: { Text("It will appear in your history.") }
            .alert("Couldn’t Save", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: { Text(errorMessage ?? "") }
        }
    }

    private func sessionTimes(_ session: FastingSession) -> some View {
        HStack(alignment: .top, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Started").font(.caption).foregroundStyle(.secondary)
                Text(session.startedAt, format: .dateTime.hour().minute()).font(.headline)
                Text(session.startedAt, format: .dateTime.day().month(.abbreviated)).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Text("Goal time").font(.caption).foregroundStyle(.secondary)
                Text(session.targetDate, format: .dateTime.hour().minute()).font(.headline)
                Text(session.targetDate, format: .dateTime.day().month(.abbreviated)).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .background(.background.opacity(0.7), in: RoundedRectangle(cornerRadius: 22))
        .overlay(alignment: .center) {
            Button { editingSession = session } label: { Image(systemName: "pencil").padding(8) }
                .accessibilityLabel("Edit start time")
                .accessibilityIdentifier("editActiveButton")
        }
    }

    private var goalSheet: some View {
        NavigationStack {
            Form {
                Section {
                    GoalDurationPicker(goalHours: $selectedGoal)
                } footer: { Text("Choose the duration that works for you.") }
            }
            .navigationTitle("Fasting Goal").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingGoal = false }.accessibilityIdentifier("cancelGoalButton")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        do {
                            if let active {
                                try FastingStore(context: context).update(active, start: active.startedAt, end: nil, goalHours: selectedGoal)
                            }
                            goalHours = selectedGoal
                            showingGoal = false
                        } catch { errorMessage = error.localizedDescription }
                    }
                    .accessibilityIdentifier("confirmGoalButton")
                }
            }
        }
        .presentationDetents(dynamicTypeSize.isAccessibilitySize ? [.large] : [.medium])
    }
}
