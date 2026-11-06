import Foundation

enum StationDeduplicator {
    private struct Key: Hashable {
        let name: String
        let country: String
    }

    // Keep catalog IDs intact for playback, saved favorites and cache restoration.
    // Select one visible representative for repeated directory registrations.
    static func unique(_ stations: [Station], favorites: Set<String>) -> [Station] {
        var result: [Station] = []
        var indices: [Key: Int] = [:]
        for station in stations {
            let name = normalized(station.name)
            let code = normalized(station.countrycode ?? "")
            let country = code.isEmpty ? normalized(station.country) : code
            // Missing identity information is insufficient evidence of a duplicate.
            guard !name.isEmpty, !country.isEmpty else {
                result.append(station)
                continue
            }
            let key = Key(name: name, country: country)
            if let index = indices[key] {
                let existing = result[index]
                if (favorites.contains(station.id) && !favorites.contains(existing.id))
                    || (favorites.contains(station.id) == favorites.contains(existing.id)
                        && existing.streamURL == nil && station.streamURL != nil) {
                    result[index] = station
                }
            } else {
                indices[key] = result.count
                result.append(station)
            }
        }
        return result
    }

    private static func normalized(_ text: String) -> String {
        text.lowercased().split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
    }
}
