import Foundation

extension RadioStore {
    func handleWidgetURL(_ url: URL) {
        guard url.scheme?.lowercased() == "radialla", ["play-last", "pause-last"].contains(url.host ?? ""),
              url.path.isEmpty || url.path == "/",
              let station = LastStationStore().load() else { return }
        if url.host == "pause-last" {
            if selected?.id == station.id { pause() }
            return
        }
        if selected?.id == station.id {
            if !playbackRequested { resume() }
        } else {
            play(station, showPlayer: false)
        }
    }

    func refreshLastStationWidget() {
        if let station = LastStationStore().load() {
            WidgetStationBridge.update(station, playing: playing && selected?.id == station.id)
        }
    }
}
