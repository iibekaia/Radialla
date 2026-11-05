import Foundation

extension RadioStore {
    func handleWidgetURL(_ url: URL) {
        guard url.scheme?.lowercased() == "radialla", url.host == "play-last",
              url.path.isEmpty || url.path == "/",
              let station = LastStationStore().load() else { return }
        if selected?.id == station.id {
            if !playbackRequested { resume() }
        } else {
            play(station, showPlayer: false)
        }
    }

    func refreshLastStationWidget() {
        if let station = LastStationStore().load() { WidgetStationBridge.update(station) }
    }
}
