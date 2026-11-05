import CoreLocation
import UIKit
import Combine

@MainActor
final class SpeedVolumeController: NSObject, @preconcurrency CLLocationManagerDelegate {
    var onVolumeChange: ((Float) -> Void)?
    private let manager = CLLocationManager()
    private let policy = SpeedVolumePolicy()
    private var wantsUpdates = false
    private var lastSample: Date?
    private var target: Float = 1
    private var gain: Float = 1
    private var timer: Timer?
    private var foregroundObserver: AnyCancellable?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        manager.distanceFilter = 10
        manager.activityType = .automotiveNavigation
        manager.showsBackgroundLocationIndicator = true
        foregroundObserver = NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in self?.startIfAuthorized() }
            }
    }

    func setActive(_ active: Bool) {
        guard wantsUpdates != active else { return }
        wantsUpdates = active
        if active {
            if manager.authorizationStatus == .notDetermined {
                manager.requestWhenInUseAuthorization()
            }
            startIfAuthorized()
        } else {
            manager.stopUpdatingLocation()
            manager.allowsBackgroundLocationUpdates = false
            reset()
        }
        startTimer()
    }

    private func startIfAuthorized() {
        guard wantsUpdates,
              manager.authorizationStatus == .authorizedAlways || manager.authorizationStatus == .authorizedWhenInUse,
              UIApplication.shared.applicationState == .active else { return }
        manager.allowsBackgroundLocationUpdates = true
        manager.startUpdatingLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .denied || manager.authorizationStatus == .restricted {
            manager.stopUpdatingLocation()
            reset()
        } else {
            startIfAuthorized()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard wantsUpdates, let location = locations.last,
              location.timestamp > (lastSample ?? .distantPast),
              abs(location.timestamp.timeIntervalSinceNow) <= 5,
              location.horizontalAccuracy >= 0, location.horizontalAccuracy <= 50,
              location.speed.isFinite, location.speed >= 0,
              location.speedAccuracy >= 0, location.speedAccuracy <= 3 else { return }
        lastSample = location.timestamp
        target = policy.gain(for: location.speed * 3.6)
        startTimer()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        reset()
    }

    private func reset() {
        lastSample = nil
        target = 1
    }

    private func startTimer() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.tick() }
        }
    }

    private func tick() {
        if let lastSample, Date().timeIntervalSince(lastSample) > 10 { reset() }
        let difference = target - gain
        if abs(difference) > 0.0001 {
            gain += min(0.01, max(-0.01, difference))
            onVolumeChange?(gain)
        }
        if target == 1 && abs(target - gain) < 0.001 {
            timer?.invalidate()
            timer = nil
        }
    }

    deinit { timer?.invalidate() }
}
