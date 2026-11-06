import SwiftUI

struct PairingScannerView: View {
    @Localized private var localized
    @State private var ready = false
    @State private var unavailable = false
    let onResult: (String) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if unavailable {
                    ContentUnavailableView {
                        Label(localized("Camera unavailable"), systemImage: "camera")
                    } description: {
                        Text(localized("Allow camera access in Settings to scan the QR code."))
                    } actions: {
                        Button(localized("Open Settings")) {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                } else if ready {
                    PairingCameraPreview(onResult: onResult, onFailure: { unavailable = true })
                        .ignoresSafeArea(edges: .bottom)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle(localized("Scan QR code"))
            .navigationBarTitleDisplayMode(.inline)
            .task {
                let available = await PairingScannerController.requestAvailability()
                guard !Task.isCancelled else { return }
                ready = available
                unavailable = !ready
            }
        }
    }
}

private struct PairingCameraPreview: UIViewControllerRepresentable {
    let onResult: (String) -> Void
    let onFailure: () -> Void

    func makeUIViewController(context: Context) -> PairingScannerController {
        PairingScannerController(onResult: onResult, onFailure: onFailure)
    }

    func updateUIViewController(_ controller: PairingScannerController, context: Context) {}

    static func dismantleUIViewController(_ controller: PairingScannerController, coordinator: ()) {
        controller.stopScanning()
    }
}
