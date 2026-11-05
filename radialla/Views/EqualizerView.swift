import SwiftUI

struct EqualizerView: View {
    @Localized private var localized
    let isPlaying: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    private var animates: Bool {
        isPlaying && !reduceMotion && scenePhase == .active
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24, paused: !animates)) { context in
            let time = animates ? context.date.timeIntervalSinceReferenceDate : 0
            HStack(spacing: 2) {
                ForEach(0..<4) { index in
                    Capsule().frame(width: 3, height: barHeight(index: index, time: time))
                }
            }
        }
        .frame(width: 20, height: 22)
        .accessibilityLabel(isPlaying ? localized("რადიო უკრავს") : localized("რადიო შეჩერებულია"))
    }

    private func barHeight(index: Int, time: Double) -> CGFloat {
        guard animates else { return 6 }
        let phase = time * (3.5 + Double(index) * 0.6) + Double(index) * 1.7
        return CGFloat(6 + 16 * abs(sin(phase)))
    }
}
