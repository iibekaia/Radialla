import SwiftUI

struct SavedTracksView: View {
    @Localized private var localized
    @EnvironmentObject private var savedTracks: SavedTracksStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            ForEach(savedTracks.tracks) { saved in
                VStack(alignment: .leading, spacing: 6) {
                    Text(saved.track.title).font(.headline)
                    if let artist = saved.track.artist {
                        Text(artist).font(.subheadline).foregroundStyle(.secondary)
                    }
                    Text(saved.stationName).font(.caption).foregroundStyle(.secondary)
                    YouTubeButton(track: saved.track)
                        .padding(.top, 4)
                }
                .padding(.vertical, 6)
            }
            .onDelete { savedTracks.remove(at: $0) }
        }
        .overlay {
            if savedTracks.tracks.isEmpty {
                ContentUnavailableView(localized("No saved songs yet"), systemImage: "bookmark",
                    description: Text(localized("Save a song from the expanded player.")))
            }
        }
        .tint(Color.radioAccent)
        .accessibilityAction(.escape) { dismiss() }
    }
}
