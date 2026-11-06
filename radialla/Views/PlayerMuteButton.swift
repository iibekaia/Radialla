import SwiftUI

struct PlayerMuteButton: View {
    @Localized private var localized
    @EnvironmentObject private var store: RadioStore

    var body: some View {
        Button { store.toggleMute() } label: {
            Image(systemName: store.isMuted ? "speaker.slash.fill" : "speaker.wave.1.fill")
                .font(.title3)
                .frame(width: 44, height: 44)
                .background(.primary.opacity(0.04), in: Circle())
                .overlay(Circle().strokeBorder(.primary.opacity(0.18)))
        }
        .buttonStyle(.plain)
        .disabled(store.isController)
        .opacity(store.isController ? 0.4 : 1)
        .foregroundStyle(store.isMuted ? Color.radioAccent : Color.primary)
        .accessibilityLabel(localized(store.isMuted ? "Unmute" : "Mute"))
    }
}
