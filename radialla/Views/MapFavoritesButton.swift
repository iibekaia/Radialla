import SwiftUI

struct MapFavoritesButton: View {
    @Localized private var localized
    @Binding var onlyFavorites: Bool

    var body: some View {
        Button { onlyFavorites.toggle() } label: {
            Image(systemName: onlyFavorites ? "heart.fill" : "heart")
                .font(.title3)
                .foregroundStyle(onlyFavorites ? Color.radioAccent : Color.primary)
                .frame(width: 48, height: 48)
                .background(.regularMaterial, in: Circle())
                .overlay {
                    Circle().strokeBorder(Color.radioAccent.opacity(onlyFavorites ? 0.5 : 0), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(localized("ფავორიტები"))
        .accessibilityAddTraits(onlyFavorites ? .isSelected : [])
    }
}
