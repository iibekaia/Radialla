import SwiftUI
import WidgetKit

struct LastStationWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: LastStationEntry
    private let accent = Color(red: 241 / 255, green: 90 / 255, blue: 34 / 255)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image("RadioLogo").resizable().scaledToFit()
                    .frame(width: 28, height: 28)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                Text("Radialla").font(.caption.bold())
                Spacer(minLength: 0)
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
                    Image(systemName: "play.fill")
                        .font(.caption.bold()).foregroundStyle(.black)
                        .frame(width: 32, height: 32)
                        .background(accent, in: Circle())
                        .accessibilityLabel(Text("Play last station"))
                }
            } else {
                Text("Open Radialla to choose a station.").font(.subheadline)
            }
        }
        .containerBackground(.background, for: .widget)
        .widgetURL(WidgetStationSnapshot.playbackURL)
        .environment(\.locale, Locale(identifier: entry.station?.language ?? Locale.current.identifier))
    }
}
