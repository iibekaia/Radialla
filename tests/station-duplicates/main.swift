import Foundation

func station(_ id: String, _ name: String, _ country: String = "GE", stream: String = "https://example.com/live") -> Station {
    Station(stationuuid: id, name: name, countrycode: country, country: country,
            favicon: nil, language: nil, url_resolved: stream, geo_lat: nil, geo_long: nil)
}
let first = station("first", "Radio One")
let duplicate = station("duplicate", "  RADIO   One \n")
let otherCountry = station("other-country", "Radio One", "US")
let otherChannel = station("other-channel", "Radio One Jazz")
let entries = [first, duplicate, otherCountry, otherChannel]
assert(StationDeduplicator.unique(entries, favorites: []).map(\.id) == ["first", "other-country", "other-channel"])
assert(StationDeduplicator.unique(entries, favorites: [duplicate.id]).first == duplicate)
assert(StationDeduplicator.unique([duplicate, first], favorites: [duplicate.id]).first == duplicate)
let broken = station("broken", "Radio One", stream: "")
assert(StationDeduplicator.unique([broken, first], favorites: []).first == first)
let unnamed = station("unnamed", "")
assert(StationDeduplicator.unique([unnamed, first], favorites: []).count == 2)
let unknown = station("unknown", "Radio One", "")
assert(StationDeduplicator.unique([unknown, first], favorites: []).count == 2)
assert(StationDeduplicator.unique(entries, favorites: []).map(\.id)
       == StationDeduplicator.unique(entries + entries, favorites: []).map(\.id))
print("PASS: duplicate names, whitespace/case, countries, distinct channels, favorites, playable streams, missing identity, repeated pages")
