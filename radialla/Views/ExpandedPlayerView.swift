import SwiftUI

struct ExpandedPlayerView: View {
    @EnvironmentObject private var store: RadioStore
    @Environment(\.dismiss) private var dismiss
    let canSkip: Bool

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                if let station = store.selected {
                    VStack(spacing: 12) {
                        StationArtwork(station: station)
                            .aspectRatio(1, contentMode: .fit)
                            .frame(maxWidth: min(240, max(100, geometry.size.width - 128)))
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .id(station.id)
                            .frame(maxWidth: .infinity)
                            .frame(height: min(264, max(100, geometry.size.height - 370)))
                            .overlay(alignment: .topTrailing) { PlayerMuteButton() }
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(station.name).font(.title2.bold())
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.8)
                                HStack(spacing: 8) {
                                    if let frequency = station.frequencyLabel { FrequencyBadge(label: frequency) }
                                    if let language = station.language, !language.isEmpty {
                                        Text(language).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                                    }
                                }
                                PlayerStatusView()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            StationFavoriteButton(station: station)
                        }
                        PlayerTransportControls(canSkip: canSkip, playButtonSize: 64)
                        Group {
                            if let track = store.nowPlayingTrack {
                                NowPlayingTrackView(track: track, stationName: station.name)
                            }
                        }
                        .frame(height: 132, alignment: .top)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
            }
            .background { ExpandedPlayerBackground() }
            .toolbar(.hidden, for: .navigationBar)
        }
        .accessibilityAction(.escape) { dismiss() }
    }
}
