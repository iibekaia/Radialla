import SwiftUI

struct LiveBadge: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    private var animates: Bool { !reduceMotion && scenePhase == .active }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 15, paused: !animates)) { context in
            let phase = context.date.timeIntervalSinceReferenceDate * .pi * 1.25
            let opacity = animates ? 0.55 + 0.45 * (sin(phase) + 1) / 2 : 1
            HStack(spacing: 6) {
                Circle()
                    .frame(width: 6, height: 6)
                    .opacity(opacity)
                Text(verbatim: "LIVE")
                    .font(.caption2.weight(.bold))
                    .tracking(1)
            }
            .foregroundStyle(Color.red)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.red.opacity(0.08), in: Capsule())
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("LIVE")
    }
}
