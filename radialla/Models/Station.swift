import Foundation
import CoreLocation

struct Station: Codable, Equatable, Identifiable, Sendable {
    let stationuuid: String
    let name: String
    let countrycode: String?
    let country: String
    let favicon: String?
    let language: String?
    var streamURL: URL? {
        guard let url = URL(string: url_resolved),
              ["http", "https"].contains(url.scheme?.lowercased() ?? ""),
              let host = url.host, !host.isEmpty else { return nil }
        return url
    }
    var logoURL: URL? {
        guard let favicon, let url = URL(string: favicon),
              url.scheme?.lowercased() == "https", let host = url.host, !host.isEmpty else { return nil }
        return url
    }
    let url_resolved: String
    let geo_lat: Double?
    let geo_long: Double?
    var id: String { stationuuid }
    var frequencyLabel: String? {
        for (patternIndex, expression) in Self.frequencyExpressions.enumerated() {
            guard !name.isEmpty else { continue }
            for match in expression.matches(in: name, range: NSRange(name.startIndex..., in: name)) {
                guard let range = Range(match.range(at: 1), in: name) else { continue }
                let value = String(name[range]).replacingOccurrences(of: ",", with: ".")
                guard let frequency = Double(value), (65...108).contains(frequency) else { continue }
                return patternIndex < 2 ? "\(value) FM" : value
            }
        }
        return nil
    }

    private static let frequencyExpressions: [NSRegularExpression] = {
        [
            #"(?i)\b(\d{2,3}(?:[.,]\d{1,2})?)\s*(?:FM|MHz)\b"#,
            #"(?i)\bFM\s*(\d{2,3}(?:[.,]\d{1,2})?)\b"#,
            #"(?<![\d.,])(\d{2,3}[.,]\d{1,2})(?![\d.,])"#
        ].compactMap { try? NSRegularExpression(pattern: $0) }
    }()
    var mapCoordinate: CLLocationCoordinate2D? { StationMapLocation.coordinate(for: self) }

    var coordinate: CLLocationCoordinate2D? {
        guard let latitude = geo_lat, let longitude = geo_long,
              (-90...90).contains(latitude), (-180...180).contains(longitude) else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
