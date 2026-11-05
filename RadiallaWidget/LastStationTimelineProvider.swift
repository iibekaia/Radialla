import WidgetKit

struct LastStationEntry: TimelineEntry {
    let date: Date
    let station: WidgetStationSnapshot?
}

struct LastStationTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> LastStationEntry {
        LastStationEntry(date: Date(), station: WidgetStationSnapshot(
            stationID: "preview", name: "Radialla Radio", country: "", language: "en"))
    }

    func getSnapshot(in context: Context, completion: @escaping (LastStationEntry) -> Void) {
        completion(LastStationEntry(date: Date(), station: WidgetStationSnapshot.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LastStationEntry>) -> Void) {
        let entry = LastStationEntry(date: Date(), station: WidgetStationSnapshot.load())
        completion(Timeline(entries: [entry], policy: .never))
    }
}
