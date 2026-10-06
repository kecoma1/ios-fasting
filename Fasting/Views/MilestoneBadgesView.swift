import SwiftUI

struct MilestoneBadgesView: View {
    let elapsed: TimeInterval
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showingGuide = false
    @State private var selectedMilestone: FastingMilestone?

    private var reached: [FastingMilestone] { FastingMilestone.reached(after: elapsed) }
    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: dynamicTypeSize.isAccessibilitySize ? 260 : 145), spacing: 10)]
    }

    var body: some View {
        VStack(spacing: 10) {
            if !reached.isEmpty {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(reached) { milestone in
                        Button {
                            selectedMilestone = milestone
                            showingGuide = true
                        } label: {
                            HStack(spacing: 9) {
                                Image(systemName: milestone.symbol)
                                    .font(.title3.weight(.medium))
                                    .foregroundStyle(Color.accentColor)
                                    .frame(width: 24)
                                    .accessibilityHidden(true)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(milestone.title).font(.caption.weight(.semibold))
                                        .foregroundStyle(.primary)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Text(milestone.timeLabel).font(.caption2).monospacedDigit()
                                        .foregroundStyle(.secondary)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 12).padding(.vertical, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .fastingButton()
                        .buttonBorderShape(.roundedRectangle(radius: 18))
                        .accessibilityIdentifier("milestone-\(milestone.id)")
                        .accessibilityHint("Learn about this time checkpoint")
                        .transition(.opacity)
                    }
                }
            }
            Button {
                selectedMilestone = nil
                showingGuide = true
            } label: {
                Label(reached.isEmpty ? "About milestones" : "Approximate stages · times vary", systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 5)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("milestoneGuideButton")
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: reached)
        .sheet(isPresented: $showingGuide) {
            MilestoneGuideView(elapsed: elapsed, selected: selectedMilestone)
        }
    }
}

private struct MilestoneGuideView: View {
    let elapsed: TimeInterval
    let selected: FastingMilestone?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Badges mark time since your fast began. Metabolic changes are gradual and depend on your meals, activity and health; the app does not measure them or confirm ketosis.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                if let selected {
                    Section {
                        milestoneRow(selected)
                    }
                }
                Section("All milestones") {
                    ForEach(FastingMilestone.allCases.filter { $0 != selected }) { milestone in
                        milestoneRow(milestone)
                    }
                }
                Section {
                    Link("Metabolic switching · scientific review", destination: URL(string: "https://pmc.ncbi.nlm.nih.gov/articles/PMC5783752/")!)
                    Link("Fasting metabolism · human study", destination: URL(string: "https://doi.org/10.1172/jci.insight.127737")!)
                } header: {
                    Text("Sources")
                } footer: {
                    Text("The 8-, 12- and 16-hour checkpoints are approximate educational references. The 24-, 48- and 72-hour badges record elapsed time. None of these badges recommends a fasting duration.")
                }
            }
            .navigationTitle("Fasting milestones")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.accessibilityIdentifier("closeMilestoneGuideButton")
                }
            }
        }
    }

    private func milestoneRow(_ milestone: FastingMilestone) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Label(milestone.title, systemImage: milestone.symbol).font(.headline)
                Spacer(minLength: 10)
                Text(milestone.timeLabel).font(.subheadline).monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Text(milestone.explanation).font(.subheadline).foregroundStyle(.secondary)
            if elapsed >= milestone.threshold {
                Label("Time checkpoint reached", systemImage: "checkmark.circle.fill")
                    .font(.caption).foregroundStyle(Color.accentColor)
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }
}
