import SwiftUI

struct StationFavoriteButton: View {
    @Localized private var localized
    @EnvironmentObject private var store: RadioStore
    let station: Station

    private var isFavorite: Bool { store.favorites.contains(station.id) }

    var body: some View {
        Button { store.toggleFavorite(station) } label: {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.title3)
                .frame(width: 44, height: 44)
                .background(.primary.opacity(0.04), in: Circle())
                .overlay(Circle().strokeBorder(.primary.opacity(0.18)))
        }
        .buttonStyle(.plain)
        .foregroundStyle(isFavorite ? Color.radioAccent : Color.primary)
        .accessibilityLabel(localized(isFavorite ? "ფავორიტებშია" : "ფავორიტებში დამატება"))
    }
}
