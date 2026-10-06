import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            TimerView()
                .tabItem { Label("Fast", systemImage: "timer") }
                .accessibilityIdentifier("timerTab")
            HistoryView()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
                .accessibilityIdentifier("historyTab")
        }
    }
}
