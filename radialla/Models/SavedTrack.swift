import Foundation

struct SavedTrack: Codable, Identifiable {
    let id: UUID
    let track: NowPlayingTrack
    let stationName: String
    let savedAt: Date
}
