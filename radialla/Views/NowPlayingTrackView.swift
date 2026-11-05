import SwiftUI

struct NowPlayingTrackView: View {
    @Localized private var localized
    @EnvironmentObject private var savedTracks: SavedTracksStore
    @State private var showsSavedConfirmation = false
    let track: NowPlayingTrack
    let stationName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 14) {
                Image(systemName: "music.note").foregroundStyle(Color.radioAccent)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 6) {
                    Text(track.title).font(.headline).lineLimit(1)
                    if let artist = track.artist {
                        Text(artist).font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Button {
                    savedTracks.toggle(track, stationName: stationName)
                    showsSavedConfirmation = savedTracks.contains(track)
                } label: {
                    Image(systemName: savedTracks.contains(track) ? "bookmark.fill" : "bookmark")
                        .frame(width: 44, height: 44)
                        .foregroundStyle(Color.radioAccent)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(localized(savedTracks.contains(track) ? "Remove saved song" : "Save song"))
            }
            YouTubeButton(track: track)
                .padding(.leading, 28)
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Color.primary.opacity(0.08)))
        .alert(localized("Song saved"), isPresented: $showsSavedConfirmation) {
            Button(localized("კარგი"), role: .cancel) { }
        }
    }
}
