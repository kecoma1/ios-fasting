import SwiftUI
import SwiftData

struct StartFastSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let goalHours: Int
    @State private var startDate = Date.now
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Start", selection: $startDate, in: ...Date.now)
                        .accessibilityIdentifier("startDatePicker")
                    LabeledContent("Goal", value: "\(goalHours) h")
                } footer: { Text("Already fasting? Set the time you started.") }
                Section {
                    Button("Start Now") {
                        do {
                            try FastingStore(context: context).start(at: startDate, goalHours: goalHours)
                            dismiss()
                        } catch { errorMessage = error.localizedDescription }
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier("confirmStartButton")
                }
                if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
            }
            .navigationTitle("Start Fast").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
        .presentationDetents(dynamicTypeSize.isAccessibilitySize ? [.large] : [.medium, .large])
    }
}
