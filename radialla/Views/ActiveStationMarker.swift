import SwiftUI

struct ActiveStationMarker: View {
    let isPlaying: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    private var animates: Bool { isPlaying && !reduceMotion && scenePhase == .active }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24, paused: !animates)) { context in
            let phase = animates ? context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1.6) / 1.6 : 0
            ZStack {
                Circle().stroke(Color.radioAccent.opacity(0.7 * (1 - phase)), lineWidth: 2)
                    .frame(width: 22 + phase * 24, height: 22 + phase * 24)
                Circle().fill(Color.radioAccent).frame(width: 20, height: 20)
                    .overlay { Circle().stroke(.white, lineWidth: 3) }
                Circle().fill(.white).frame(width: 5, height: 5)
            }.frame(width: 48, height: 48)
        }
    }
}
