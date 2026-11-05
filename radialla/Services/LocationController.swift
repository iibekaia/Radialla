import Foundation
import Combine
import CoreLocation
import MapKit

@MainActor
final class LocationController: NSObject, ObservableObject, @preconcurrency CLLocationManagerDelegate {
    @Published var coordinate: CLLocationCoordinate2D?
    @Published private(set) var mapFocusCoordinate: CLLocationCoordinate2D?
    @Published private(set) var countryCode: String?
    @Published var errorMessage: String?
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var geocodeGeneration = 0
    private var geocodeTask: Task<Void, Never>?
    private var reportsLocationErrors = false
    private var shouldFocusOnNextLocation = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func locate(reportErrors: Bool = true, focusMap: Bool = true) {
        reportsLocationErrors = reportErrors
        errorMessage = nil
        if focusMap { shouldFocusOnNextLocation = true }
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .denied, .restricted:
            if reportErrors { errorMessage = localized("მდებარეობის ნებართვა გამორთულია. ჩართე iPhone-ის Settings-ში radialla-სთვის.") }
        @unknown default:
            break
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        } else {
            coordinate = nil
            countryCode = nil
            geocodeGeneration += 1
            geocodeTask?.cancel()
            geocoder.cancelGeocode()
            UserDefaults.standard.set("en", forKey: "interfaceLanguage")
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last, location.horizontalAccuracy >= 0,
              CLLocationCoordinate2DIsValid(location.coordinate) else { return }
        coordinate = location.coordinate
        errorMessage = nil
        if shouldFocusOnNextLocation {
            shouldFocusOnNextLocation = false
            mapFocusCoordinate = location.coordinate
        }
        geocodeGeneration += 1
        let generation = geocodeGeneration
        geocodeTask?.cancel()
        geocoder.cancelGeocode()
        if #available(iOS 26.0, *) {
            geocodeTask = Task { @MainActor [weak self] in
                guard let request = MKReverseGeocodingRequest(location: location) else {
                    self?.applyCountry(nil, generation: generation)
                    return
                }
                do {
                    let items = try await request.mapItems
                    guard !Task.isCancelled else { return }
                    self?.applyCountry(items.first?.addressRepresentations?.region?.identifier, generation: generation)
                } catch {
                    guard !Task.isCancelled else { return }
                    self?.applyCountry(nil, generation: generation)
                }
            }
            return
        }
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            DispatchQueue.main.async {
                guard let self, self.geocodeGeneration == generation else { return }
                self.applyCountry(placemarks?.first?.isoCountryCode, generation: generation)
            }
        }
    }

    private func applyCountry(_ country: String?, generation: Int) {
        guard geocodeGeneration == generation else { return }
        countryCode = country
        let languages = ["GE": "ka", "RU": "ru", "UA": "uk", "CN": "zh-Hans", "KR": "ko", "AM": "hy", "TR": "tr"]
        UserDefaults.standard.set(languages[country ?? ""] ?? "en", forKey: "interfaceLanguage")
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        geocodeGeneration += 1
        geocodeTask?.cancel()
        geocoder.cancelGeocode()
        if countryCode == nil { UserDefaults.standard.set("en", forKey: "interfaceLanguage") }
        if reportsLocationErrors {
            errorMessage = localized("მდებარეობა ვერ განისაზღვრა. შეამოწმე Location Services და სცადე თავიდან.")
        }
    }
}
