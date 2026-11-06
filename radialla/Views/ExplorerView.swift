import MapKit
import SwiftUI

struct ExplorerView: View {
    @Localized private var localized
    @State private var themeDate = Date()
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var location = LocationController()
    @EnvironmentObject private var store: RadioStore
    @State private var camera: MapCameraPosition = .camera(
        MapCamera(centerCoordinate: CLLocationCoordinate2D(latitude: 30, longitude: 35), distance: 25_000_000))
    @State private var region: MKCoordinateRegion?
    @State private var onlyFavorites = false
    @State private var mapClusters: [StationCluster] = []
    @State private var showsPlayer = false
    @State private var showsMenu = false
    @State private var listHeight: CGFloat = 155
    @State private var isResizingList = false
    @State private var visibleStations: [Station] = []
    @State private var awaitingMapAutoplay = false
    @State private var hasRequestedInitialLocation = false

    @AppStorage("mapLayer") private var mapLayer = "standard"
    @AppStorage("interfaceLanguage") private var interfaceLanguage = "en"
    @AppStorage("manualLanguage") private var manualLanguage = "auto"

    private var effectiveLanguage: String {
        manualLanguage == "auto" ? interfaceLanguage : manualLanguage
    }

    private var mapStyle: MapStyle {
        switch mapLayer {
        case "satellite": return .imagery(elevation: .flat)
        case "terrain": return .hybrid(elevation: .realistic, pointsOfInterest: .excludingAll, showsTraffic: false)
        default:
            return .standard(elevation: .flat, emphasis: .muted, pointsOfInterest: .excludingAll, showsTraffic: false)
        }
    }

    private var theme: ColorScheme {
        ThemeResolver.colorScheme(at: themeDate, coordinate: location.coordinate)
    }

    private func refreshMapClusters() {
        guard !isResizingList else { return }
        visibleStations = StationMapIndex.visibleStations(
            store.stations, favorites: store.favorites,
            onlyFavorites: onlyFavorites, region: onlyFavorites ? nil : region)
        let mapStations =
            onlyFavorites
            ? StationMapIndex.visibleStations(
                visibleStations, favorites: store.favorites, onlyFavorites: false, region: region)
            : visibleStations
        mapClusters = StationMapIndex.clusters(mapStations, region: region)
    }

    private var content: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                ExplorerHeader(showsMenu: $showsMenu)
                StationMapView(
                    location: location, camera: $camera, mapLayer: $mapLayer, onlyFavorites: $onlyFavorites,
                    region: region, mapClusters: mapClusters, mapStyle: mapStyle,
                    showsControls: !isResizingList && listHeight <= 155.5
                ) { newRegion, userMovedMap in
                    guard !isResizingList else { return }
                    region = newRegion
                    refreshMapClusters()
                    if store.isController {
                        awaitingMapAutoplay = false
                        store.devicePairing.send(.viewport(latitude: newRegion.center.latitude,
                            longitude: newRegion.center.longitude,
                            longitudeDelta: newRegion.span.longitudeDelta))
                    } else if userMovedMap {
                        awaitingMapAutoplay = true
                        playFirstVisibleStationIfNeeded()
                    }
                }
                StationListView(
                    listHeight: $listHeight, isResizing: $isResizingList,
                    maximumHeight: max(155, geometry.size.height - 420),
                    onResizeEnded: refreshMapClusters,
                    visibleStations: visibleStations, onlyFavorites: onlyFavorites)
                MiniPlayerView(showsPlayer: $showsPlayer, canSkip: visibleStations.count > 1)

            }
        }
    }

    private func playFirstVisibleStationIfNeeded() {
        guard !store.isController, awaitingMapAutoplay, let station = visibleStations.first else { return }
        awaitingMapAutoplay = false
        store.setStationQueue(visibleStations)
        guard station.id != store.selected?.id || !store.playing else { return }
        store.play(station, showPlayer: false)
    }

    private var styledContent: some View {
        content
            .allowsHitTesting(!showsMenu)
            .accessibilityHidden(showsMenu)
            .background(Color.radioBackground)
            .overlay { ExplorerDrawer(isPresented: $showsMenu) }
            .tint(Color.radioAccent)
            .preferredColorScheme(theme)
            .environment(\.locale, Locale(identifier: effectiveLanguage))
            .sheet(isPresented: $showsPlayer) {
                ExpandedPlayerView(canSkip: visibleStations.count > 1)
                    .environmentObject(store)
                    .preferredColorScheme(theme)
                    .modifier(RadioSheetStyle())
            }
            .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { themeDate = $0 }
            .onReceive(location.$mapFocusCoordinate) { coordinate in
                guard let coordinate else { return }
                withAnimation(.easeInOut(duration: 0.8)) {
                    camera = .region(
                        MKCoordinateRegion(
                            center: coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.25, longitudeDelta: 0.25)))
                }
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    themeDate = Date()
                    location.locate(reportErrors: false, focusMap: false)
                }
            }
            .alert(
                localized("მდებარეობა"),
                isPresented: Binding(
                    get: { location.errorMessage != nil },
                    set: { if !$0 { location.errorMessage = nil } }
                )
            ) {
                Button(localized("კარგი"), role: .cancel) { location.errorMessage = nil }
            } message: {
                Text(location.errorMessage ?? "")
            }
    }

    var body: some View {
        styledContent
            .onChange(of: store.playerPresentationID) { _, _ in showsPlayer = true }
            .onChange(of: store.selected?.id) { _, _ in
                awaitingMapAutoplay = false
            }
            .onChange(of: store.catalogRevision) { _, _ in refreshMapClusters() }
            .onChange(of: effectiveLanguage) { _, _ in store.refreshLastStationWidget() }
            .task(id: location.countryCode) {
                guard let country = location.countryCode else { return }
                await store.prioritizeCountry(country)
            }
            .onChange(of: onlyFavorites) { _, enabled in
                awaitingMapAutoplay = false
                refreshMapClusters()
                guard enabled, let stationRegion = StationMapIndex.focusRegion(for: visibleStations.first) else {
                    return
                }
                withAnimation(.easeInOut(duration: 0.8)) {
                    camera = .region(stationRegion)
                }
            }
            .onChange(of: store.favorites) { _, _ in refreshMapClusters() }
            .onChange(of: visibleStations.map(\.id), initial: true) { _, _ in
                store.setStationQueue(visibleStations)
                playFirstVisibleStationIfNeeded()
                if !store.isController, store.selected == nil, let firstStation = visibleStations.first {
                    store.play(firstStation, showPlayer: false)
                }
            }
            .task {
                if !hasRequestedInitialLocation {
                    hasRequestedInitialLocation = true
                    let stationRegion = StationMapIndex.focusRegion(for: store.selected)
                    if let stationRegion {
                        awaitingMapAutoplay = false
                        region = stationRegion
                        camera = .region(stationRegion)
                        refreshMapClusters()
                    }
                    location.locate(reportErrors: false, focusMap: stationRegion == nil)
                }
                await store.load()
            }
    }
}
