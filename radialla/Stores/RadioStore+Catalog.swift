import Foundation

extension RadioStore {
    func load() async {
        guard !backgroundLoading else { return }
        backgroundLoading = true
        loading = stations.isEmpty
        defer {
            backgroundLoading = false
            loading = false
        }

        if !restoredCatalog {
            restoredCatalog = true
            if let cached = await catalogService.restore() {
                mergeStations(cached.stations)
                if Date().timeIntervalSince(cached.date) < 6 * 60 * 60 {
                    catalogOffset = cached.offset
                    catalogComplete = cached.complete
                }
                loading = false
            }
        }
        if catalogComplete { return }

        do {
            if stations.isEmpty {
                for _ in 0..<10 {
                    if priorityCountry != nil { break }
                    try await Task.sleep(for: .milliseconds(150))
                }
            }
            if let priorityCountry { await prioritizeCountry(priorityCountry) }
            let pageSize = 500
            while !catalogComplete {
                try Task.checkCancellation()
                let page = try await catalogService.page(offset: catalogOffset, limit: pageSize)
                try Task.checkCancellation()
                mergeStations(page)
                loading = false
                catalogOffset += page.count
                catalogComplete = page.count < pageSize
                catalogMessage =
                    catalogComplete
                    ? RadioMessage("კატალოგი ჩაიტვირთა: %@ სადგური", String(stations.count))
                    : RadioMessage("იტვირთება კატალოგი: %@ სადგური…", String(stations.count))
                if catalogComplete || catalogOffset % 2000 == 0 { await saveCatalog() }
                if !catalogComplete { try await Task.sleep(for: .milliseconds(350)) }
            }
        } catch {
            await saveCatalog()
            guard !Task.isCancelled else { return }
            catalogMessage = RadioMessage(
                "Catalog loading stopped. Loaded stations remain available.")
        }
    }

    func prioritizeCountry(_ country: String) async {
        priorityCountry = country
        guard !completedCountries.contains(country), countryRequestInProgress != country else { return }
        countryRequestInProgress = country
        defer { if countryRequestInProgress == country { countryRequestInProgress = nil } }
        do {
            var offset = 0
            let pageSize = 200
            while true {
                try Task.checkCancellation()
                let page = try await catalogService.page(offset: offset, limit: pageSize, country: country)
                try Task.checkCancellation()
                mergeStations(page)
                if !page.isEmpty { loading = false }
                offset += page.count
                if page.count < pageSize { break }
            }
            completedCountries.insert(country)
            await saveCatalog()
        } catch {
            return
        }
    }

    private func mergeStations(_ page: [Station]) {
        var merged = stations
        var changed = false
        for station in page {
            if let index = stationIndices[station.id] {
                guard merged[index] != station else { continue }
                merged[index] = station
            } else {
                stationIndices[station.id] = merged.count
                merged.append(station)
            }
            changed = true
        }
        if changed {
            stations = merged
            catalogRevision += 1
        }
    }

    private func saveCatalog() async {
        await catalogService.save(
            .init(
                stations: stations, offset: catalogOffset,
                complete: catalogComplete, date: Date()))
    }
}
