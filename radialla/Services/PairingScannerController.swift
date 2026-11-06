import UIKit
import AVFoundation
import VisionKit

/// VisionKit owns camera capture and stops it when this controller leaves the screen.
final class PairingScannerController: UIViewController, DataScannerViewControllerDelegate {
    private let scanner = DataScannerViewController(
        recognizedDataTypes: [.barcode(symbologies: [.qr])],
        qualityLevel: .balanced, recognizesMultipleItems: false,
        isHighFrameRateTrackingEnabled: false, isPinchToZoomEnabled: true,
        isGuidanceEnabled: true, isHighlightingEnabled: true)
    static func requestAvailability() async -> Bool {
        guard DataScannerViewController.isSupported else { return false }
        let allowed = await AVCaptureDevice.requestAccess(for: .video)
        return allowed && DataScannerViewController.isAvailable
    }

    var onResult: ((String) -> Void)?
    var onFailure: (() -> Void)?
    private var delivered = false

    init(onResult: @escaping (String) -> Void, onFailure: @escaping () -> Void) {
        self.onResult = onResult
        self.onFailure = onFailure
        super.init(nibName: nil, bundle: nil)
        scanner.delegate = self
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        addChild(scanner)
        scanner.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scanner.view)
        NSLayoutConstraint.activate([
            scanner.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scanner.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scanner.view.topAnchor.constraint(equalTo: view.topAnchor),
            scanner.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        scanner.didMove(toParent: self)
    }

    func stopScanning() { scanner.stopScanning() }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        do { try scanner.startScanning() } catch { onFailure?() }
    }

    override func viewWillDisappear(_ animated: Bool) {
        stopScanning()
        super.viewWillDisappear(animated)
    }

    func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
        guard !delivered else { return }
        for item in addedItems {
            if case .barcode(let barcode) = item, let text = barcode.payloadStringValue {
                delivered = true
                stopScanning()
                onResult?(text)
                return
            }
        }
    }

    func dataScanner(_ dataScanner: DataScannerViewController, becameUnavailableWithError error: DataScannerViewController.ScanningUnavailable) {
        stopScanning()
        onFailure?()
    }
}
