import SwiftUI

struct FastingBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
            RadialGradient(
                colors: [.accentColor.opacity(colorScheme == .dark ? 0.20 : 0.10), .clear],
                center: .init(x: 0.75, y: 0.3), startRadius: 5, endRadius: 430
            )
        }
        .ignoresSafeArea()
    }
}

extension View {
    @ViewBuilder
    func fastingButton(prominent: Bool = false) -> some View {
        if #available(iOS 26, *) {
            if prominent { buttonStyle(.glassProminent) }
            else { buttonStyle(.glass) }
        } else {
            if prominent { buttonStyle(.borderedProminent) }
            else { buttonStyle(.bordered) }
        }
    }
}
