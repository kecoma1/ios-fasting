import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \FastingSession.startedAt, order: .reverse) private var sessions: [FastingSession]
    @State private var showingNew = false
    @State private var selected: FastingSession?

    private var completed: [FastingSession] { sessions.filter { !$0.isActive } }
    private var active: [FastingSession] { sessions.filter(\.isActive) }
    private var months: [Date] {
        Set(completed.map { month(of: $0.startedAt) }).sorted(by: >)
    }
    private func month(of date: Date) -> Date {
        Calendar.current.dateInterval(of: .month, for: date)?.start ?? date
    }

    var body: some View {
        NavigationStack {
            List {
                if !completed.isEmpty {
                    Section {
                        statistics
                            .listRowBackground(Color.clear).listRowInsets(EdgeInsets())
                    }
                }
                if !active.isEmpty {
                    Section("In progress") {
                        ForEach(active) { session in
                            Button { selected = session } label: { SessionRow(session: session) }
                                .buttonStyle(.plain)
                        }
                    }
                }
                if completed.isEmpty {
                    ContentUnavailableView {
                        Label("Your Fasts, in One Place", systemImage: "clock.arrow.circlepath")
                    } description: {
                        Text("Finished fasts will appear here. You can also add one you forgot to record.")
                    } actions: {
                        Button("Add a Past Fast") { showingNew = true }
                            .fastingButton().accessibilityIdentifier("emptyAddFastButton")
                    }
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(months, id: \.self) { month in
                        Section {
                            ForEach(completed.filter { self.month(of: $0.startedAt) == month }) { session in
                                Button { selected = session } label: { SessionRow(session: session) }
                                    .buttonStyle(.plain)
                                    .accessibilityIdentifier("historySessionRow")
                            }
                        } header: { Text(month, format: .dateTime.month(.wide).year()) }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background { FastingBackground() }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingNew = true } label: { Label("Add a Past Fast", systemImage: "plus") }
                        .accessibilityIdentifier("addPastFastButton")
                }
            }
            .sheet(isPresented: $showingNew) { SessionEditor() }
            .sheet(item: $selected) { SessionEditor(session: $0) }
        }
    }

    private var statistics: some View {
        let stats = FastingStatistics(sessions: completed)
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            statistic("Fasts", value: "\(stats.count)", symbol: "checkmark.circle")
            statistic("Total time", value: DurationText.compact(stats.total), symbol: "hourglass")
            statistic("Average", value: DurationText.compact(stats.average), symbol: "chart.bar")
            statistic("Longest", value: DurationText.compact(stats.longest), symbol: "flag")
        }
        .padding(.vertical, 4)
    }

    private func statistic(_ title: LocalizedStringKey, value: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: symbol).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title3.weight(.semibold)).minimumScaleFactor(0.7).lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(18)
        .background(.background.opacity(0.75), in: RoundedRectangle(cornerRadius: 22))
        .accessibilityElement(children: .combine)
    }
}

private struct SessionRow: View {
    let session: FastingSession

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: session.isActive ? "hourglass" : "moon.fill")
                .font(.title3).foregroundStyle(Color.accentColor)
                .frame(width: 42, height: 42)
                .background(Color.accentColor.opacity(0.09), in: RoundedRectangle(cornerRadius: 14))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 5) {
                Text(session.startedAt, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated))
                    .font(.subheadline.weight(.semibold))
                Text("Goal · \(session.goalHours) h").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 5) {
                Text(DurationText.compact(session.duration)).font(.subheadline.weight(.semibold))
                if session.reachedGoal {
                    Label("Completed", systemImage: "checkmark").font(.caption).foregroundStyle(Color.accentColor)
                } else if session.isActive {
                    Text("In progress").font(.caption).foregroundStyle(.secondary)
                }
            }
            Image(systemName: "chevron.right").font(.caption2.weight(.semibold)).foregroundStyle(.tertiary)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}
