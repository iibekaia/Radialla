import SwiftUI

struct PlayerStatusView: View {
    @EnvironmentObject private var store: RadioStore

    var body: some View {
        if !store.playing || store.isMuted {
            Text(store.playbackStatus)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
    }
}
