import SwiftUI
import CloudKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("defaultGoalHours") private var goalHours = 16
    @State private var cloudStatus = String(localized: "Checking availability…")

    var body: some View {
        NavigationStack {
            Form {
                Section("Your next fast") {
                    GoalPickerRow(title: "Default goal", goalHours: $goalHours)
                        .accessibilityIdentifier("defaultGoalRow")
                }
                Section {
                    Label("Saved on Your iPhone", systemImage: "iphone")
                    Label(cloudStatus, systemImage: "icloud")
                } header: { Text("Your data") } footer: {
                    Text("Your fasts are saved on this device. With iCloud available, they sync privately between devices using the same Apple Account.")
                }
                Section {
                    Label("No account to create", systemImage: "person.crop.circle.badge.checkmark")
                    Label("No ads or analytics", systemImage: "hand.raised")
                } header: { Text("Simple and private") }
                Section {
                    LabeledContent("App", value: "Fasting")
                    LabeledContent("Version", value: "0.1.0")
                } footer: { Text("Fasting is a temporary name.") }
            }
            .navigationTitle("Settings").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.accessibilityIdentifier("closeSettingsButton")
                }
            }
            .task { await checkCloud() }
        }
    }

    private func checkCloud() async {
        guard Persistence.usesCloud else {
            cloudStatus = String(localized: "iCloud unavailable in this simulator")
            return
        }
        do {
            switch try await CKContainer(identifier: Persistence.cloudContainerID).accountStatus() {
            case .available: cloudStatus = String(localized: "iCloud account available")
            case .noAccount: cloudStatus = String(localized: "Sign in to iCloud in Settings")
            case .restricted: cloudStatus = String(localized: "iCloud is restricted")
            default: cloudStatus = String(localized: "iCloud temporarily unavailable")
            }
        } catch { cloudStatus = String(localized: "iCloud temporarily unavailable") }
    }
}
