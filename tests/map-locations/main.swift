import Foundation
import MapKit

func station(_ code: String?, country: String = "Georgia", lat: Double? = nil, lon: Double? = nil) throws -> Station {
    var data: [String: Any] = ["stationuuid": UUID().uuidString, "name": "Radio", "country": country, "url_resolved": "https://example.com/live"]
    data["countrycode"] = code
    data["geo_lat"] = lat
    data["geo_long"] = lon
    return try JSONDecoder().decode(Station.self, from: JSONSerialization.data(withJSONObject: data))
}
let fallback = try station("ge")
assert(fallback.coordinate == nil)
assert(abs(fallback.mapCoordinate!.latitude - 41.7151) < 0.001)
let exact = try station("GE", lat: 42, lon: 43)
assert(exact.mapCoordinate!.latitude == 42)
let invalid = try station("GE", lat: 100, lon: 200)
assert(invalid.mapCoordinate!.latitude == fallback.mapCoordinate!.latitude)
let legacy = try station(nil)
assert(legacy.mapCoordinate!.longitude == fallback.mapCoordinate!.longitude)
let unknown = try station("XX", country: "Unknown")
assert(unknown.mapCoordinate == nil)
let region = StationMapIndex.focusRegion(for: fallback)!
assert(StationMapIndex.visibleStations([fallback, unknown, exact], favorites: [], onlyFavorites: false, region: region) == [fallback])
let abroad = try station("US", country: "United States")
assert(StationMapIndex.visibleStations([fallback, abroad, unknown, exact], favorites: [], onlyFavorites: false, region: region) == [fallback])
assert(StationMapIndex.visibleStations([unknown], favorites: [], onlyFavorites: false, region: region).isEmpty)
assert(StationMapIndex.visibleStations([unknown], favorites: [unknown.id], onlyFavorites: true, region: region).isEmpty)
// The global favorites list intentionally has no viewport restriction.
assert(StationMapIndex.visibleStations([unknown], favorites: [unknown.id], onlyFavorites: true, region: nil) == [unknown])
let abroadRegion = StationMapIndex.focusRegion(for: abroad)!
assert(StationMapIndex.visibleStations([fallback, abroad, unknown, exact], favorites: [], onlyFavorites: false, region: abroadRegion) == [abroad])
assert(StationMapIndex.visibleStations([fallback, unknown], favorites: [fallback.id], onlyFavorites: true, region: region) == [fallback])
let clusters = StationMapIndex.clusters([fallback, unknown], region: region)
assert(clusters.count == 1)
assert(abs(clusters[0].coordinate.latitude - 41.7151) < 0.001)
let encoded = try JSONEncoder().encode(fallback)
let restored = try JSONDecoder().decode(Station.self, from: encoded)
assert(restored.coordinate == nil && restored.countrycode == "ge")
print("PASS: exact/invalid/missing coordinates, lowercase code, legacy names, unknown country, viewport, favorites, clusters and cache round trip")
