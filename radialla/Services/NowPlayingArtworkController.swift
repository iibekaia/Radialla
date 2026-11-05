import Foundation
import UIKit
import ImageIO
import MediaPlayer

@MainActor
final class NowPlayingArtworkController {
    var onChange: (() -> Void)?
    private(set) var artwork: MPMediaItemArtwork?
    private let cache = NSCache<NSURL, UIImage>()
    private var task: Task<Void, Never>?
    private var requestID = UUID()
    private var stationID: String?
    private var logoURL: URL?
    private var hasLoadedLogo = false

    init() {
        cache.totalCostLimit = 12 * 1024 * 1024
        cache.countLimit = 20
    }

    func update(for station: Station) {
        let sameStation = stationID == station.id && logoURL == station.logoURL
        guard !sameStation || (!hasLoadedLogo && task == nil && station.logoURL != nil) else { return }
        task?.cancel()
        requestID = UUID()
        stationID = station.id
        logoURL = station.logoURL
        hasLoadedLogo = false
        setImage(UIImage(named: "RadioLogo"))
        guard let url = station.logoURL else { return }
        if let cached = cache.object(forKey: url as NSURL) {
            hasLoadedLogo = true
            setImage(cached)
            return
        }
        let requestID = requestID
        task = Task { [weak self] in
            let image = await Self.downloadImage(from: url)
            guard !Task.isCancelled, let self, self.requestID == requestID else { return }
            self.task = nil
            guard let image else { return }
            self.hasLoadedLogo = true
            self.cache.setObject(image, forKey: url as NSURL,
                                 cost: (image.cgImage?.bytesPerRow ?? 0) * (image.cgImage?.height ?? 0))
            self.setImage(image)
        }
    }

    private func setImage(_ image: UIImage?) {
        artwork = image.map { image in
            MPMediaItemArtwork(boundsSize: image.size) { size in
                guard size.width > 0, size.height > 0 else { return image }
                let scale = min(1, min(size.width / image.size.width, size.height / image.size.height))
                let target = CGSize(width: image.size.width * scale, height: image.size.height * scale)
                let format = UIGraphicsImageRendererFormat()
                format.scale = 1
                return UIGraphicsImageRenderer(size: target, format: format).image { _ in
                    image.draw(in: CGRect(origin: .zero, size: target))
                }
            }
        }
        onChange?()
    }

    nonisolated private static func downloadImage(from url: URL) async -> UIImage? {
        var request = URLRequest(url: url)
        request.timeoutInterval = 12
        do {
            let (bytes, response) = try await URLSession.shared.bytes(for: request)
            defer { bytes.task.cancel() }
            let byteLimit = 5 * 1024 * 1024
            guard !Task.isCancelled, let response = response as? HTTPURLResponse,
                  response.statusCode == 200,
                  response.url?.scheme?.lowercased() == "https",
                  response.expectedContentLength <= byteLimit else { return nil }
            var data = Data()
            data.reserveCapacity(256 * 1024)
            for try await byte in bytes {
                guard data.count < byteLimit, !Task.isCancelled else { return nil }
                data.append(byte)
            }
            guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: 512,
                kCGImageSourceShouldCacheImmediately: true
            ]
            guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
            return UIImage(cgImage: image)
        } catch {
            return nil
        }
    }

    deinit { task?.cancel() }
}
