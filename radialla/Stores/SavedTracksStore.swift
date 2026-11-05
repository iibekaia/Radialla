import Foundation
import Combine

@MainActor
final class SavedTracksStore: ObservableObject {
    @Published private(set) var tracks: [SavedTrack]
    private let defaults: UserDefaults
    private let key = "savedTracks.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        tracks = defaults.data(forKey: key)
            .flatMap { try? JSONDecoder().decode([SavedTrack].self, from: $0) } ?? []
    }

    func contains(_ track: NowPlayingTrack) -> Bool {
        tracks.contains { $0.track.storageKey == track.storageKey }
    }

    func toggle(_ track: NowPlayingTrack, stationName: String) {
        if contains(track) {
            tracks.removeAll { $0.track.storageKey == track.storageKey }
        } else {
            tracks.insert(SavedTrack(id: UUID(), track: track, stationName: stationName, savedAt: Date()), at: 0)
        }
        persist()
    }

    func remove(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) where tracks.indices.contains(index) { tracks.remove(at: index) }
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(tracks) else { return }
        defaults.set(data, forKey: key)
    }
}
