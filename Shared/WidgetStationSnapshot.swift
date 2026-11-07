import Foundation

struct WidgetStationSnapshot: Codable, Equatable, Sendable {
    static let groupIdentifier = "group.ge.globeradio.app"
    static let kind = "RadiallaLastStation"
    static let storageKey = "widgetLastStation.v1"

    let stationID: String
    let name: String
    let country: String
    let language: String
    // Optional so snapshots saved by earlier versions still decode.
    var playing: Bool? = nil

    var isPlaying: Bool { playing == true }

    static var sharedDefaults: UserDefaults? {
        guard FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupIdentifier) != nil else {
            return nil
        }
        return UserDefaults(suiteName: groupIdentifier)
    }

    static func load(from defaults: UserDefaults? = sharedDefaults) -> WidgetStationSnapshot? {
        guard let data = defaults?.data(forKey: storageKey),
              let snapshot = try? JSONDecoder().decode(Self.self, from: data),
              !snapshot.stationID.isEmpty, !snapshot.name.isEmpty else { return nil }
        return snapshot
    }

    @discardableResult
    func save(to defaults: UserDefaults? = sharedDefaults) -> Bool {
        guard let defaults, Self.load(from: defaults) != self,
              let data = try? JSONEncoder().encode(self) else { return false }
        defaults.set(data, forKey: Self.storageKey)
        return true
    }
}
