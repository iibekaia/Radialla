import SwiftUI
import MapKit

struct StationMapView: View {
    @Localized private var localized
    @State private var currentCamera: MapCamera?
    @State private var zoomButtonWasUsed = false
    @EnvironmentObject private var store: RadioStore
    @ObservedObject var location: LocationController
    @Binding var camera: MapCameraPosition
    @Binding var mapLayer: String
    @Binding var onlyFavorites: Bool
    let region: MKCoordinateRegion?
    let mapClusters: [StationCluster]
    let mapStyle: MapStyle
    let showsControls: Bool
    let onRegionChange: (MKCoordinateRegion, Bool) -> Void
    var body: some View {
            Map(position: $camera, interactionModes: mapLayer == "terrain" ? .all : [.pan, .zoom]) {
                if let selected = store.selected, let coordinate = selected.coordinate,
                   !onlyFavorites || store.favorites.contains(selected.id) {
                    Annotation(selected.name, coordinate: coordinate) {
                        ActiveStationMarker(isPlaying: store.playing && (region?.span.latitudeDelta ?? 150) < 40)
                            .accessibilityLabel(selected.name)
                    }.annotationTitles(.hidden)
                }
                ForEach(mapClusters) { cluster in
                    Annotation(localized("%@ რადიოსადგური", String(describing: cluster.stations.count)), coordinate: cluster.coordinate) {
                        Button {
                            if cluster.stations.count == 1, let station = cluster.stations.first {
                                store.play(station)
                            } else {
                                let span = region?.span ?? MKCoordinateSpan(latitudeDelta: 150, longitudeDelta: 360)
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    camera = .region(MKCoordinateRegion(center: cluster.coordinate,
                                        span: MKCoordinateSpan(latitudeDelta: max(0.005, span.latitudeDelta / 3),
                                                               longitudeDelta: max(0.005, span.longitudeDelta / 3))))
                                }
                            }
                        } label: {
                            ZStack {
                                Circle().fill(Color.radioAccent.opacity(0.16)).frame(width: 30, height: 30)
                                if cluster.stations.count > 1 {
                                    Text("\(cluster.stations.count)").font(.caption.bold().monospacedDigit())
                                        .foregroundStyle(.black).padding(8)
                                        .background(Color.radioAccent, in: Circle())
                                } else {
                                    Circle().fill(cluster.stations.first?.id == store.selected?.id ? Color.white : Color.radioAccent)
                                        .frame(width: 13, height: 13)
                                }
                            }
                        }.buttonStyle(.plain)
                            .allowsHitTesting((region?.span.latitudeDelta ?? 150) < 60)
                            .accessibilityLabel(cluster.stations.count == 1 ? cluster.stations[0].name : localized("%@ რადიოსადგური — მიახლოება", String(describing: cluster.stations.count)))
                    }.annotationTitles(.hidden)
                }
            }
            .mapStyle(mapStyle)
            .overlay(alignment: .bottomLeading) {
                MapFavoritesButton(onlyFavorites: $onlyFavorites)
                    .padding(16)
                    .opacity(showsControls ? 1 : 0)
                    .allowsHitTesting(showsControls)
                    .accessibilityHidden(!showsControls)
                    .animation(.easeInOut(duration: 0.15), value: showsControls)
            }
            .overlay(alignment: .topTrailing) {
                Menu {
                    Picker(localized("რუკის ფენა"), selection: $mapLayer) {
                        Text(localized("მარტივი")).tag("standard")
                        Text(localized("სატელიტური")).tag("satellite")
                        Text(localized("რელიეფი · 3D")).tag("terrain")
                    }
                } label: {
                    Image(systemName: "square.3.layers.3d")
                        .font(.title3).frame(width: 48, height: 48)
                        .background(.regularMaterial, in: Circle())
                }
                .accessibilityLabel(localized("რუკის ფენის შეცვლა"))
                .padding(12)
                .opacity(showsControls ? 1 : 0)
                .allowsHitTesting(showsControls)
                .accessibilityHidden(!showsControls)
                .animation(.easeInOut(duration: 0.15), value: showsControls)
            }
            .overlay(alignment: .top) {
                if store.backgroundLoading {
                    HStack(spacing: 10) {
                        ProgressView().controlSize(.small)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(localized("რადიოები იტვირთება…")).font(.caption.weight(.semibold))
                            Text(store.stations.isEmpty ? localized("ვამზადებთ რუკას") : localized("%@ სადგური უკვე ხელმისაწვდომია", String(describing: store.stations.count)))
                                .font(.caption2).foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                    .padding(.horizontal, 14).padding(.vertical, 11)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding(12)
                    .padding(.trailing, 60)
                    .allowsHitTesting(false)
                    .accessibilityElement(children: .combine)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                VStack(spacing: 10) {
                MapZoomControls(zoomIn: { zoom(by: 0.5) }, zoomOut: { zoom(by: 2) })
                Button { location.locate() } label: {
                    Image(systemName: "location.fill").font(.title3)
                        .frame(width: 48, height: 48)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .accessibilityLabel(localized("ჩემს მდებარეობაზე მიახლოება"))
                }
                .padding(16)
                .opacity(showsControls ? 1 : 0)
                .allowsHitTesting(showsControls)
                .accessibilityHidden(!showsControls)
                .animation(.easeInOut(duration: 0.15), value: showsControls)
            }
            .onMapCameraChange(frequency: .onEnd) { context in
                currentCamera = context.camera
                let userMovedMap = camera.positionedByUser || zoomButtonWasUsed
                zoomButtonWasUsed = false
                onRegionChange(context.region, userMovedMap)
            }
            .frame(maxHeight: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .padding(.horizontal, 10)
    }

    private func zoom(by factor: Double) {
        guard var target = currentCamera ?? camera.camera else { return }
        target.distance = min(40_000_000, max(150, target.distance * factor))
        zoomButtonWasUsed = true
        currentCamera = target
        camera = .camera(target)
    }
}
