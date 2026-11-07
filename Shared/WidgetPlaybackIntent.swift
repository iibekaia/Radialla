import AppIntents

struct WidgetPlaybackIntent: AudioPlaybackIntent {
    static let title: LocalizedStringResource = "Radio playback"
    static let openAppWhenRun = false
    static let isDiscoverable = false

    @Parameter(title: "Station ID")
    var stationID: String

    @Parameter(title: "Play")
    var shouldPlay: Bool

    init() {}

    init(stationID: String, shouldPlay: Bool) {
        self.stationID = stationID
        self.shouldPlay = shouldPlay
    }

    @MainActor
    func perform() async throws -> some IntentResult {
#if !RADIALLA_WIDGET
        RadioStore.shared.setLastStationPlayback(shouldPlay, stationID: stationID)
#endif
        return .result()
    }
}
