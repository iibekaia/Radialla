# Country-capital map fallback

`StationMapLocation.swift` bundles offline display locations, separate from the station's original `geo_lat` / `geo_long`. Country codes are preferred; exact English country names support records persisted before country codes were decoded. Unknown countries and territories without capitals remain in the list and have no marker.

Base capital data: [Stefie/geojson-world](https://github.com/Stefie/geojson-world/blob/master/capitals.geojson), credited there to GeoNames/Geognos. The source's degree/minute notation was converted to decimal degrees. Added missing inhabited territories and updated locations including Tbilisi, Gitega, Nay Pyi Taw, Dodoma, Sri Jayawardenepura Kotte and Ngerulmud. These are approximate city locations, not broadcaster addresses. Multiple-capital countries use one administrative capital.

References for changed capitals: [Burundi government](https://primature.gov.bi/presentation-generale/), [Myanmar government](https://myanmar.gov.mm/-/nay-pyi-daw?redirect=%2Fabout-myanmar), [Dodoma Capital City Act](https://oagmis.oag.go.tz/portal/acts/52).

Standalone regression check (macOS, Xcode selected):

```sh
xcrun swiftc -module-cache-path /tmp/radialla-map-modules radialla/Models/Station.swift radialla/Models/StationCluster.swift radialla/Services/StationMapLocation.swift radialla/Services/StationMapIndex.swift tests/map-locations/main.swift -o /tmp/radialla-map-check
/tmp/radialla-map-check
```

Covers coordinate preservation, capital fallback, invalid coordinates, lowercase codes, old saved records, unknown countries, viewport filtering, favorites, clustering and Codable persistence. Physical-device map rendering and actual audio playback require a separate check.
