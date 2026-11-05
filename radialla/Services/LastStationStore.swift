import Foundation

struct LastStationStore {
    private let defaults: UserDefaults
    private let key = "lastPlayedStation.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> Station? {
        guard let data = defaults.data(forKey: key) else { return nil }
        guard let station = try? JSONDecoder().decode(Station.self, from: data),
              !station.id.isEmpty,
              station.streamURL != nil else {
            defaults.removeObject(forKey: key)
            return nil
        }
        return station
    }

    func save(_ station: Station) {
        guard let data = try? JSONEncoder().encode(station) else { return }
        defaults.set(data, forKey: key)
    }
}
