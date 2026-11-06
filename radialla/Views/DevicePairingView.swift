import SwiftUI

struct DevicePairingView: View {
    @Localized private var localized
    @ObservedObject var pairing: DevicePairingService
    @Environment(\.dismiss) private var dismiss
    @State private var enteredCode = ""
    @State private var showingScanner = false
    @State private var scannedPayload: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(localized("Starting playback here pauses your other paired devices, and vice versa."))
                    Text(localized("Both devices need an internet connection. Use the same Radialla server."))
                        .font(.footnote).foregroundStyle(.secondary)
                }
                if pairing.paired {
                    Section {
                        Label(localized(pairing.connected ? "Connected" : "Reconnecting…"),
                              systemImage: pairing.connected ? "checkmark.circle" : "wifi.slash")
                        Text("\(localized("Paired devices")): \(pairing.members)")
                        Button(localized("Generate pairing code")) { Task { await pairing.createCode() } }
                        if !pairing.code.isEmpty, let expiry = pairing.codeExpiresAt {
                            TimelineView(.periodic(from: .now, by: 1)) { context in
                                if context.date < expiry {
                                    Text(pairing.code).font(.title.monospaced()).textSelection(.enabled)
                                    Text(localized("Enter this code on your other device. It expires in 5 minutes."))
                                } else {
                                    Text(localized("Code expired. Generate a new one."))
                                }
                            }
                        }
                        Button(localized("Disconnect this device"), role: .destructive) {
                            Task { await pairing.disconnect() }
                        }
                    }
                } else {
                    Section {
                        Button(localized("Generate pairing code")) { Task { await pairing.createCode() } }
                    }
                    Section {
                        Button { showingScanner = true } label: {
                            Label(localized("Scan QR code"), systemImage: "qrcode.viewfinder")
                        }
                    }
                    Section(localized("Or enter a code from the web")) {
                        TextField(localized("8-digit code"), text: $enteredCode)
                            .keyboardType(.numberPad).textContentType(.oneTimeCode)
                            .onChange(of: enteredCode) { _, value in
                                enteredCode = String(value.filter { $0.isASCII && $0.isNumber }.prefix(8))
                            }
                        Button(localized("Pair device")) { Task { await pairing.join(enteredCode) } }
                            .disabled(enteredCode.count != 8)
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
            .toolbar { Button(localized("Done")) { dismiss() } }
        }
    }
}
