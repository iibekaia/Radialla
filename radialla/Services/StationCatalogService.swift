import Foundation

actor StationCatalogService {
    struct Snapshot: Codable, Sendable {
        let stations: [Station]
        let offset: Int
        let complete: Bool
        let date: Date
    }

    private let session = URLSession(configuration: .default)
    private var cacheURL: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("radialla-catalog-v1.json")
    }

    func restore() -> Snapshot? {
        guard let data = try? Data(contentsOf: cacheURL),
              let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data) else { return nil }
        return snapshot
    }

    func save(_ snapshot: Snapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? FileManager.default.createDirectory(at: cacheURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: cacheURL, options: .atomic)
    }

    func page(offset: Int, limit: Int, country: String? = nil) async throws -> [Station] {
        var lastError: Error = URLError(.cannotConnectToHost)
        for host in ["de1.api.radio-browser.info", "nl1.api.radio-browser.info"] {
            try Task.checkCancellation()
            do {
                var components = URLComponents()
                components.scheme = "https"
                components.host = host
                components.path = "/json/stations/search"
                components.queryItems = [
                    URLQueryItem(name: "hidebroken", value: "true"),
                    URLQueryItem(name: "has_geo_info", value: "true"),
                    URLQueryItem(name: "order", value: "name"),
                    URLQueryItem(name: "limit", value: String(limit)),
                    URLQueryItem(name: "offset", value: String(offset))
                ]
                if let country { components.queryItems?.append(URLQueryItem(name: "countrycode", value: country)) }
                guard let url = components.url else { throw URLError(.badURL) }
                var request = URLRequest(url: url, timeoutInterval: country == nil ? 20 : 10)
                request.setValue("Radialla/0.1", forHTTPHeaderField: "User-Agent")
                let (data, response) = try await session.data(for: request)
                try Task.checkCancellation()
                guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
                return try JSONDecoder().decode([Station].self, from: data)
            } catch {
                try Task.checkCancellation()
                lastError = error
            }
        }
        throw lastError
    }
}
