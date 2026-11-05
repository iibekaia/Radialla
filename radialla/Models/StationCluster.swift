import Foundation
import CoreLocation

struct StationCluster: Identifiable {
    let id: String
    let stations: [Station]
    var coordinate: CLLocationCoordinate2D {
        let coordinates = stations.compactMap(\.coordinate)
        guard !coordinates.isEmpty else { return CLLocationCoordinate2D(latitude: 0, longitude: 0) }
        let latitude = coordinates.reduce(0) { $0 + $1.latitude } / Double(coordinates.count)
        let sine = coordinates.reduce(0) { $0 + sin($1.longitude * .pi / 180) }
        let cosine = coordinates.reduce(0) { $0 + cos($1.longitude * .pi / 180) }
        return CLLocationCoordinate2D(latitude: latitude, longitude: atan2(sine, cosine) * 180 / .pi)
    }
}
