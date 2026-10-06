import SwiftUI
import SwiftData

struct LastMealView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \MealEntry.recordedAt, order: .reverse) private var entries: [MealEntry]
    @State private var showingTime = false
    @State private var selectedDate = Date.now
    @State private var errorMessage: String?

    private var latest: MealEntry? { MealEntry.latest(in: entries) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    Text(latest == nil ? "When did you last eat?" : "Since your last meal")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.top, 20)
                    TimelineView(.periodic(from: .now, by: 1)) { timeline in
                        MealClock(elapsed: latest?.elapsed(at: timeline.date))
                    }
                    if let latest {
                        VStack(spacing: 8) {
                            Text("Last meal").font(.caption).foregroundStyle(.secondary)
                            Text(latest.eatenAt, format: .dateTime.day().month(.abbreviated).year().hour().minute())
                                .font(.headline)
                                .multilineTextAlignment(.center)
                                .accessibilityIdentifier("lastMealDate")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(20)
                        .background(.background.opacity(0.7), in: RoundedRectangle(cornerRadius: 22))
                    } else {
                        Text("Log a meal to start your counter.")
                            .font(.subheadline).foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .accessibilityIdentifier("emptyMealMessage")
                    }
                    Button {
                        let now = Date.now
                        record(at: now, now: now)
                    } label: {
                        Label("Just Ate", systemImage: "fork.knife")
                            .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 15)
                            .foregroundStyle(colorScheme == .dark ? Color.black : Color.white)
                    }
                    .fastingButton(prominent: true)
                    .buttonBorderShape(.capsule)
                    .accessibilityIdentifier("recordMealNowButton")
                    Button {
                        errorMessage = nil
                        selectedDate = min(latest?.eatenAt ?? .now, .now)
                        showingTime = true
                    } label: {
                        Label(latest == nil ? "Choose Time" : "Change Time", systemImage: "calendar.badge.clock")
                    }
                    .fastingButton()
                    .buttonBorderShape(.capsule)
                    .accessibilityIdentifier("chooseMealTimeButton")
                    Text("You can close the app. Your meal counter keeps going.")
                        .font(.footnote).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 28).padding(.bottom, 30)
                .frame(maxWidth: 500).frame(maxWidth: .infinity)
            }
            .background { FastingBackground() }
            .navigationTitle("Last Meal")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingTime) { timeSheet }
            .alert("Couldn’t Save", isPresented: Binding(get: { errorMessage != nil && !showingTime }, set: { if !$0 { errorMessage = nil } })) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: { Text(errorMessage ?? "") }
        }
    }

    private var timeSheet: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Meal time", selection: $selectedDate, in: ...Date.now)
                        .accessibilityIdentifier("mealTimePicker")
                } footer: { Text("Choose when you finished your last meal.") }
                if let errorMessage {
                    Text(errorMessage).foregroundStyle(.red).accessibilityIdentifier("mealSaveError")
                }
            }
            .navigationTitle("Meal Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingTime = false }
                        .accessibilityIdentifier("cancelMealTimeButton")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { record(at: selectedDate, now: .now) }
                        .disabled(selectedDate > .now)
                        .accessibilityIdentifier("confirmMealTimeButton")
                }
            }
        }
    }

    private func record(at date: Date, now: Date) {
        errorMessage = nil
        do {
            try MealStore(context: context).record(at: date, now: now)
            showingTime = false
        } catch { errorMessage = error.localizedDescription }
    }
}

private struct MealClock: View {
    let elapsed: TimeInterval?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .largeTitle) private var clockSize: CGFloat = 46

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            clockContent
                .padding(24).frame(maxWidth: .infinity)
                .background(.background.opacity(0.7), in: RoundedRectangle(cornerRadius: 28))
                .overlay {
                    RoundedRectangle(cornerRadius: 28).stroke(Color.accentColor.opacity(0.4), lineWidth: 2)
                }
        } else {
            ZStack {
                Circle().stroke(Color.accentColor.opacity(elapsed == nil ? 0.15 : 0.4), lineWidth: 12)
                Circle().stroke(.primary.opacity(0.12), style: StrokeStyle(lineWidth: 3, dash: [1, 12]))
                    .padding(21)
                clockContent.padding(40)
            }
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: 320).padding(6)
        }
    }

    private var clockContent: some View {
        VStack(spacing: 12) {
            Image(systemName: "fork.knife")
                .font(.title2.weight(.light)).foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)
            if let elapsed, DurationText.days(elapsed) > 0 {
                Text("\(DurationText.days(elapsed)) d")
                    .font(.title3.weight(.medium)).monospacedDigit()
                    .foregroundStyle(Color.accentColor)
                    .accessibilityHidden(true)
            }
            Text(elapsed.map(DurationText.clock) ?? "—")
                .font(.system(size: min(clockSize, 66), weight: .light, design: .rounded))
                .monospacedDigit().minimumScaleFactor(0.5).lineLimit(1)
                .accessibilityLabel("Time since last meal")
                .accessibilityValue(elapsed.map(DurationText.accessible) ?? String(localized: "No meal recorded"))
                .accessibilityIdentifier("mealElapsedTime")
            Text(elapsed == nil ? "No meal recorded" : "Time since last meal")
                .font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
