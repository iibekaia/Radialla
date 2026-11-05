import SwiftUI

struct StationRowView: View {
    @Localized private var localized
    @EnvironmentObject private var store: RadioStore
    let station: Station

    var body: some View {
        HStack {
            Button {
                store.play(station)
            } label: {
                HStack {
                    Group {
                        if store.selected?.id == station.id {
                            EqualizerView(isPlaying: store.playing)
                        } else {
                            Image(systemName: "radio")
                        }
                    }
                    .foregroundStyle(Color.radioAccent).frame(width: 40, height: 40)
                    .background(Color.radioAccent.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                    VStack(alignment: .leading) {
                        Text(station.name).font(.subheadline.weight(.medium)).lineLimit(1).foregroundStyle(.primary)
                        HStack(spacing: 6) {
                            Text(station.country).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                            if let frequency = station.frequencyLabel {
                                FrequencyBadge(label: frequency)
                            }
                        }
                    }
                    Spacer()
                }.padding(.vertical, 6).contentShape(Rectangle())
            }.buttonStyle(.plain)
            Button {
                store.toggleFavorite(station)
            } label: {
                Image(systemName: store.favorites.contains(station.id) ? "heart.fill" : "heart")
                    .frame(width: 44, height: 44)
            }.tint(Color.radioAccent).accessibilityLabel(localized("ფავორიტის შეცვლა"))
        }
    }
}
