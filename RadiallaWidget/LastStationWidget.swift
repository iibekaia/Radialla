import SwiftUI
import WidgetKit

@main
struct LastStationWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetStationSnapshot.kind, provider: LastStationTimelineProvider()) { entry in
            LastStationWidgetView(entry: entry)
        }
        .configurationDisplayName("Radialla")
        .description("Quick access to your last radio station.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
