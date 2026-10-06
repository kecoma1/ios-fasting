import SwiftUI

struct TimerRing: View {
    let elapsed: TimeInterval
    let progress: Double
    let active: Bool
    @ScaledMetric(relativeTo: .largeTitle) private var clockSize: CGFloat = 46

    var body: some View {
        ZStack {
            Circle().stroke(.primary.opacity(0.055), lineWidth: 12)
            Circle()
                .trim(from: 0, to: active ? max(0.004, progress) : 1)
                .stroke(
                    AngularGradient(colors: [.accentColor.opacity(active ? 0.4 : 0.12), .accentColor], center: .center),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            Circle().stroke(.primary.opacity(0.12), style: StrokeStyle(lineWidth: 3, dash: [1, 12]))
                .padding(21)
            VStack(spacing: 12) {
                Image(systemName: active ? (progress >= 1 ? "checkmark" : "hourglass") : "moon")
                    .font(.title2.weight(.light))
                    .foregroundStyle(Color.accentColor)
                    .accessibilityHidden(true)
                Text(DurationText.clock(elapsed))
                    .font(.system(size: min(clockSize, 66), weight: .light, design: .rounded))
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .accessibilityLabel("Elapsed time")
                    .accessibilityValue(DurationText.accessible(elapsed))
                    .accessibilityIdentifier("elapsedTime")
                Text(active ? (progress >= 1 ? "Goal reached" : "Time fasting") : "Your next fast")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(40)
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: 320)
        .padding(6)
    }
}
