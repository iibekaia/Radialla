import Foundation

struct NowPlayingTrack: Codable, Equatable, Sendable {
    let title: String
    let artist: String?

    var searchText: String { [artist, title].compactMap { $0 }.joined(separator: " ") }
    var youtubeSearchURL: URL? {
        var components = URLComponents(string: "https://www.youtube.com/results")
        components?.queryItems = [URLQueryItem(name: "search_query", value: searchText)]
        return components?.url
    }

    var storageKey: String {
        [artist ?? "", title].map {
            $0.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
                .folding(options: [.caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
        }.joined(separator: "\u{001F}")
    }

    init?(title: String?, artist: String?) {
        guard let title = title?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty else { return nil }
        let artist = artist?.trimmingCharacters(in: .whitespacesAndNewlines)
        if artist == nil || artist?.isEmpty == true,
            let separator = title.range(of: " - "),
            !title[..<separator.lowerBound].trimmingCharacters(in: .whitespaces).isEmpty,
            !title[separator.upperBound...].trimmingCharacters(in: .whitespaces).isEmpty
        {
            self.artist = String(title[..<separator.lowerBound]).trimmingCharacters(in: .whitespaces)
            self.title = String(title[separator.upperBound...]).trimmingCharacters(in: .whitespaces)
        } else {
            self.title = title
            self.artist = artist?.isEmpty == false ? artist : nil
        }
    }
}
