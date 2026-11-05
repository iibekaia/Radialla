import WidgetKit

enum WidgetStationBridge {
    static func update(_ station: Station) {
        let snapshot = WidgetStationSnapshot(stationID: station.id, name: station.name,
                                             country: station.country, language: InterfaceLanguage.current)
        if snapshot.save() {
            WidgetCenter.shared.reloadTimelines(ofKind: WidgetStationSnapshot.kind)
        }
    }
}
