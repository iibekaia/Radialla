import SwiftUI

@main
struct RadiallaApp: App {
    @StateObject private var store = RadioStore()
    @StateObject private var savedTracks = SavedTracksStore()

    var body: some Scene {
        WindowGroup {
            ExplorerView().environmentObject(store).environmentObject(savedTracks)
                .onOpenURL { store.handleWidgetURL($0) }
        }
    }
}
