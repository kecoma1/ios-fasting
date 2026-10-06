import SwiftUI

/// Store whole hours as before, while letting people select days and remaining hours.
struct GoalDurationPicker: View {
    @Binding var goalHours: Int
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var dayValue: Int { goalHours / 24 }
    private var hourRange: ClosedRange<Int> {
        dayValue == FastingGoal.maximumDays ? 0...0 : (dayValue == 0 ? 1...23 : 0...23)
    }
    private var days: Binding<Int> {
        Binding(get: { dayValue }, set: { value in
            goalHours = min(FastingGoal.allowedHours.upperBound, max(1, value * 24 + goalHours % 24))
        })
    }
    private var hours: Binding<Int> {
        Binding(get: { goalHours % 24 }, set: { value in
            goalHours = max(1, dayValue * 24 + value)
        })
    }

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(spacing: 12) { dayPicker; hourPicker }
        } else {
            HStack(spacing: 12) { dayPicker; hourPicker }
        }
    }

    private var dayPicker: some View {
        VStack(spacing: 0) {
            Text("Days").font(.subheadline).foregroundStyle(.secondary)
            Picker("Days", selection: days) {
                ForEach(0...FastingGoal.maximumDays, id: \.self) { Text("\($0) d").tag($0) }
            }
            .pickerStyle(.wheel).labelsHidden()
            .frame(minWidth: dynamicTypeSize.isAccessibilitySize ? 180 : 90, maxWidth: .infinity, minHeight: 150, maxHeight: 150)
            .clipped()
            .accessibilityIdentifier("goalDaysWheel")
        }
    }

    private var hourPicker: some View {
        VStack(spacing: 0) {
            Text("Hours").font(.subheadline).foregroundStyle(.secondary)
            Picker("Hours", selection: hours) {
                ForEach(hourRange, id: \.self) { Text("\($0) h").tag($0) }
            }
            .pickerStyle(.wheel).labelsHidden()
            .frame(minWidth: dynamicTypeSize.isAccessibilitySize ? 180 : 90, maxWidth: .infinity, minHeight: 150, maxHeight: 150)
            .clipped()
            .accessibilityIdentifier("goalHoursWheel")
            // Recreate the native wheel when zero hours becomes a valid choice.
            .id(hourRange)
        }
    }
}

/// Keep the compact settings/editor row; the duration has its own cancellable sheet.
struct GoalPickerRow: View {
    let title: LocalizedStringKey
    @Binding var goalHours: Int
    @State private var draft = 16
    @State private var showingPicker = false

    var body: some View {
        Button {
            draft = goalHours
            showingPicker = true
        } label: {
            LabeledContent {
                HStack(spacing: 6) {
                    Text(DurationText.goal(hours: goalHours))
                    Image(systemName: "chevron.up.chevron.down").font(.caption2)
                }
            } label: { Text(title).foregroundStyle(.primary) }
        }
        .sheet(isPresented: $showingPicker) {
            NavigationStack {
                Form {
                    Section { GoalDurationPicker(goalHours: $draft) }
                    footer: { Text("Choose the duration that works for you.") }
                }
                .navigationTitle("Fasting Goal").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showingPicker = false }
                            .accessibilityIdentifier("cancelGoalButton")
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { goalHours = draft; showingPicker = false }
                            .accessibilityIdentifier("confirmGoalButton")
                    }
                }
            }
        }
    }
}
