import SwiftUI

struct MiniPlayerView: View {
    @Localized private var localized
    @EnvironmentObject private var store: RadioStore
    @Binding var showsPlayer: Bool
    let canSkip: Bool

    var body: some View {
        if let selected = store.selected {
            HStack {
                Button {
                    showsPlayer = true
                } label: {
                    HStack {
                        StationArtwork(station: selected).frame(width: 40, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(selected.name).font(.subheadline.bold()).lineLimit(1)
                            PlayerStatusView()
                            if let frequency = selected.frequencyLabel {
                                FrequencyBadge(label: frequency)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(localized("დიდი პლეერის გახსნა"))
                PlayerTransportControls(canSkip: canSkip)
            }
            .padding(12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22))
            .accessibilityAction(named: Text(localized("დიდი პლეერის გახსნა"))) { showsPlayer = true }
            .padding(.horizontal, 10).padding(.vertical, 8)
        }
    }
}
