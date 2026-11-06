import MapKit

enum StationMapIndex {
    static func focusRegion(for station: Station?) -> MKCoordinateRegion? {
        guard let coordinate = station?.mapCoordinate else { return nil }
        return MKCoordinateRegion(center: coordinate,
                                  span: MKCoordinateSpan(latitudeDelta: 0.25, longitudeDelta: 0.25))
    }

    static func contains(_ coordinate: CLLocationCoordinate2D, in region: MKCoordinateRegion) -> Bool {
        let longitudeDistance = abs((coordinate.longitude - region.center.longitude + 540)
            .truncatingRemainder(dividingBy: 360) - 180)
        return abs(coordinate.latitude - region.center.latitude) <= region.span.latitudeDelta / 2
            && longitudeDistance <= min(180, region.span.longitudeDelta / 2)
    }

    static func visibleStations(_ stations: [Station], favorites: Set<String>, onlyFavorites: Bool,
                                region: MKCoordinateRegion?) -> [Station] {
        let visible = stations.filter { station in
            guard !onlyFavorites || favorites.contains(station.id) else { return false }
            guard let region else { return true }
            guard let coordinate = station.mapCoordinate else { return false }
            return contains(coordinate, in: region)
        }
        return StationDeduplicator.unique(visible, favorites: favorites)
    }

    static func clusters(_ stations: [Station], region: MKCoordinateRegion?) -> [StationCluster] {
        let broadView = (region?.span.latitudeDelta ?? 150) > 40
        let divisions = broadView ? 6.0 : 12.0
        let latitudeStep = max(0.002, (region?.span.latitudeDelta ?? 150) / divisions)
        let longitudeStep = max(0.002, (region?.span.longitudeDelta ?? 360) / divisions)
        var groups: [String: [Station]] = [:]
        for station in stations {
            guard let coordinate = station.mapCoordinate else { continue }
            let latitudeCell = Int(floor((coordinate.latitude + 90) / latitudeStep))
            let longitudeCell = Int(floor((coordinate.longitude + 180) / longitudeStep))
            groups["\(latitudeCell):\(longitudeCell)", default: []].append(station)
        }
        return groups.map { StationCluster(id: $0.key, stations: $0.value) }.sorted { $0.id < $1.id }
    }
}
