import SwiftUI

@main
struct RadiallaApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var store = RadioStore.shared
    @StateObject private var savedTracks = SavedTracksStore()

    var body: some Scene {
        WindowGroup {
            ExplorerView().environmentObject(store).environmentObject(savedTracks)
                .onOpenURL { store.handleWidgetURL($0) }
                .onChange(of: scenePhase, initial: true) { _, phase in
                    if phase == .active { store.restorePlaybackOnLaunch() }
                }
        }
    }
}
