import SwiftUI

struct ExplorerMenu: View {
    @Localized private var localized
    @EnvironmentObject private var savedTracks: SavedTracksStore
    let close: () -> Void
    @State private var showsSavedTracks = false
    @State private var showsDevicePairing = false
    @EnvironmentObject private var store: RadioStore

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image("RadioLogo").resizable().scaledToFit()
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                Text("Radialla").font(.title2.bold())
                Spacer()
                Button(action: close) {
                    Image(systemName: "xmark").frame(width: 44, height: 44)
                }
                .accessibilityLabel(localized("Close menu"))
            }
            .padding(20)
            .simultaneousGesture(DragGesture(minimumDistance: 20).onEnded { value in
                if value.translation.height < -60,
                   abs(value.translation.height) > abs(value.translation.width) {
                    close()
                }
            })
            Divider()
            ScrollView {
                VStack(spacing: 20) {
                    Button { showsSavedTracks = true } label: {
                        HStack(spacing: 12) {
                            Label(localized("Saved songs"), systemImage: "bookmark")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            MenuCountBadge(count: savedTracks.tracks.count)
                        }
                        .frame(minHeight: 44)
                    }
                    .accessibilityLabel(localized("Saved songs"))
                    .accessibilityValue(Text(savedTracks.tracks.count, format: .number))
                    Divider()
                    Button { showsDevicePairing = true } label: {
                        Label(localized("Device pairing"), systemImage: "link")
                            .frame(maxWidth: .infinity, alignment: .leading).frame(minHeight: 44)
                    }
                    Divider()
                    InterfaceLanguagePicker()
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(minHeight: 44)
                }
                .padding(24)
            }
        }
        .buttonStyle(.plain)
        .tint(Color.radioAccent)
        .sheet(isPresented: $showsDevicePairing) {
            DevicePairingView(pairing: store.devicePairing).modifier(RadioSheetStyle())
        }
        .sheet(isPresented: $showsSavedTracks) {
            SavedTracksView()
                .modifier(RadioSheetStyle())
        }
    }
}
