import SwiftUI

private struct StationListOverflowKey: PreferenceKey {
    static var defaultValue = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = nextValue()
    }
}

struct StationListView: View {
    @Localized private var localized
    @EnvironmentObject private var store: RadioStore
    @State private var hasMoreStationsBelow = false
    @Binding var listHeight: CGFloat
    @Binding var isResizing: Bool
    let maximumHeight: CGFloat
    let onResizeEnded: () -> Void
    let visibleStations: [Station]
    let onlyFavorites: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ListResizeHandle(
                height: $listHeight, isResizing: $isResizing,
                maximumHeight: maximumHeight, onResizeEnded: onResizeEnded)
            HStack {
                Text(onlyFavorites ? localized("ფავორიტები") : localized("სადგურები ამ არეში")).font(.headline)
                Spacer()
                if store.loading { ProgressView().controlSize(.small) }
                Text(localized("%@ სადგური", String(describing: visibleStations.count))).font(
                    .caption.monospacedDigit()
                )
                .foregroundStyle(Color.radioAccent).padding(.horizontal, 10).padding(.vertical, 5)
                .background(Color.radioAccent.opacity(0.1), in: Capsule())
            }
            if store.playing {
                LiveBadge()
            } else {
                Text(store.status).font(.caption2).foregroundStyle(.secondary).lineLimit(2)
            }
            ScrollView {
                LazyVStack {
                    ForEach(visibleStations) { station in
                        StationRowView(station: station)
                    }
                    if visibleStations.isEmpty && !store.loading {
                        Text(localized("სადგურები ვერ მოიძებნა — შეცვალე რუკის არე")).font(.caption).padding()
                    }
                }
                .padding(.trailing, 8)
                .background {
                    GeometryReader { geometry in
                        Color.clear.preference(
                            key: StationListOverflowKey.self,
                            value: geometry.frame(in: .named("stationList")).maxY > listHeight + 1)
                    }
                }
            }
            .coordinateSpace(name: "stationList")
            .scrollIndicators(.visible)
            .scrollIndicatorsFlash(trigger: visibleStations.count)
            .frame(height: min(listHeight, maximumHeight))
            .onPreferenceChange(StationListOverflowKey.self) {
                guard !isResizing else { return }
                hasMoreStationsBelow = $0
            }
            .overlay(alignment: .bottom) {
                if hasMoreStationsBelow {
                    LinearGradient(
                        colors: [.clear, Color.radioSurface],
                        startPoint: .top, endPoint: .bottom
                    )
                    .frame(height: 20).allowsHitTesting(false)
                    .accessibilityHidden(true)
                }
            }
            Label(localized("ქვემოთ კიდევ არის — ჩამოსქროლე"), systemImage: "chevron.down")
                .font(.caption).foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .opacity(hasMoreStationsBelow ? 1 : 0)
                .accessibilityHidden(!hasMoreStationsBelow)
        }.padding(.horizontal, 18).background(Color.radioSurface, in: RoundedRectangle(cornerRadius: 28))
            .padding(.horizontal, 10)
    }
}
