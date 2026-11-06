import SwiftUI

struct DevicePairingView: View {
    @Localized private var localized
    @ObservedObject var pairing: DevicePairingService
    @State private var showingScanner = false
    @State private var scannedPayload: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(localized("Control web playback and the map from this device. Audio plays on the web."))
                    Text(localized("Both devices need an internet connection. Use the same Radialla server."))
                        .font(.footnote).foregroundStyle(.secondary)
                }
                if pairing.paired {
                    Section {
                        Label(localized(pairing.connected ? "Connected" : "Reconnecting…"),
                              systemImage: pairing.connected ? "checkmark.circle" : "wifi.slash")
                        Text("\(localized("Paired devices")): \(pairing.members)")
                        Button(localized("Disconnect this device"), role: .destructive) {
                            Task { await pairing.disconnect() }
                        }
                    }
                } else {
                    Section {
                        Button { showingScanner = true } label: {
                            Label(localized("Scan QR code"), systemImage: "qrcode.viewfinder")
                        }
                    }
                }
                if pairing.busy { ProgressView() }
                if !pairing.messageKey.isEmpty {
                    Text(localized(pairing.messageKey)).foregroundStyle(.secondary)
                }
            }
            .disabled(pairing.busy)
            .sheet(isPresented: $showingScanner, onDismiss: {
                if let payload = scannedPayload {
                    scannedPayload = nil
                    Task { await pairing.joinQRCode(payload) }
                }
            }) {
                PairingScannerView { payload in
                    scannedPayload = payload
                    showingScanner = false
                }
            }
            .navigationTitle(localized("Device pairing"))
        }
    }
}
