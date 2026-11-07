import SwiftUI
import WidgetKit

struct LastStationWidgetView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let entry: LastStationEntry
    private let accent = Color(red: 241 / 255, green: 90 / 255, blue: 34 / 255)
    private let equalizerBarHeights: [CGFloat] = [8, 17, 11, 14]

    private var equalizer: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(equalizerBarHeights.indices, id: \.self) { index in
                if entry.station?.isPlaying == true {
                    Capsule()
                        .fill(accent)
                        .frame(width: 3, height: equalizerBarHeights[index])
                        .transition(reduceMotion ? .identity : .asymmetric(
                            insertion: .scale(scale: 0.2, anchor: .bottom)
                                .animation(.spring(duration: 0.6, bounce: 0.45)
                                    .delay(Double(index) * 0.1)),
                            removal: .opacity.animation(.easeOut(duration: 0.15))
                        ))
                }
            }
        }
        .frame(width: 18, height: 17, alignment: .bottomTrailing)
        .accessibilityHidden(true)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image("RadioLogo").resizable().scaledToFit()
                    .frame(width: 28, height: 28)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                Text("Radialla").font(.caption.bold())
                Spacer(minLength: 0)
                equalizer
            }
            Spacer(minLength: 0)
            if let station = entry.station {
                if family == .systemMedium {
                    Text("Last played station").font(.caption2).foregroundStyle(.secondary)
                }
                Text(verbatim: station.name).font(.headline)
                    .lineLimit(family == .systemSmall ? 2 : 1).minimumScaleFactor(0.85)
                HStack {
                    Text(verbatim: station.country).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    Spacer(minLength: 4)
                    Button(intent: WidgetPlaybackIntent(stationID: station.stationID, shouldPlay: !station.isPlaying)) {
                        Image(systemName: station.isPlaying ? "pause.fill" : "play.fill")
                            .font(.subheadline.bold())
                            .foregroundStyle(.black)
                            .frame(width: 44, height: 44)
                            .background(accent, in: Circle())
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(station.isPlaying ? "Pause station" : "Play last station"))
                }
            } else {
                Text("Open Radialla to choose a station.").font(.subheadline)
            }
        }
        .containerBackground(.background, for: .widget)
        .environment(\.locale, Locale(identifier: entry.station?.language ?? Locale.current.identifier))
    }
}
