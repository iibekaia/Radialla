import Foundation

struct PairingCommand: Encodable {
    let type: String
    var stationId: String? = nil
    var latitude: Double? = nil
    var longitude: Double? = nil
    var zoom: Double? = nil

    static func viewport(latitude: Double, longitude: Double, longitudeDelta: Double) -> Self {
        // MapKit span to the web map's Web Mercator zoom convention.
        Self(type: "viewport", latitude: min(85, max(-85, latitude)),
             longitude: min(180, max(-180, longitude)),
             zoom: min(18, max(2, log2(360 / max(0.000001, longitudeDelta)))))
    }
}
