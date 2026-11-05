import AVFoundation

@MainActor
final class StreamMetadataReader: NSObject, @preconcurrency AVPlayerItemMetadataOutputPushDelegate {
    var onUpdate: ((NowPlayingTrack?) -> Void)?
    private weak var item: AVPlayerItem?
    private var output: AVPlayerItemMetadataOutput?
    private var readTask: Task<Void, Never>?
    private var queuedReads: [UUID: Task<Void, Never>] = [:]
    private var currentTitle: String?
    private var currentArtist: String?
    private var artistAwaitingTitle = false

    func attach(to item: AVPlayerItem) {
        detach()
        self.item = item
        let output = AVPlayerItemMetadataOutput(identifiers: nil)
        self.output = output
        output.setDelegate(self, queue: .main)
        item.add(output)
    }

    func detach() {
        for task in queuedReads.values { task.cancel() }
        queuedReads.removeAll()
        readTask = nil
        if let output {
            output.setDelegate(nil, queue: nil)
            self.item?.remove(output)
        }
        output = nil
        item = nil
        currentTitle = nil
        currentArtist = nil
        artistAwaitingTitle = false
        onUpdate?(nil)
    }

    func metadataOutput(_ output: AVPlayerItemMetadataOutput,
                        didOutputTimedMetadataGroups groups: [AVTimedMetadataGroup],
                        from track: AVPlayerItemTrack?) {
        guard output === self.output else { return }
        let fields = groups.flatMap(\.items).compactMap { item -> (AVMetadataItem, Bool)? in
            guard let isTitle = Self.titleField(item) else { return nil }
            return (item, isTitle)
        }
        guard !fields.isEmpty else { return }
        let previousRead = readTask
        let readID = UUID()
        readTask = Task { [weak self] in
            await previousRead?.value
            guard let self, !Task.isCancelled, output === self.output else { return }
            defer { self.queuedReads.removeValue(forKey: readID) }
            var title: String?
            var artist: String?
            for (metadata, isTitle) in fields {
                guard let value = try? await metadata.load(.stringValue) else { continue }
                guard !Task.isCancelled, output === self.output else { return }
                if isTitle { title = value } else { artist = value }
            }
            if let title {
                if title != self.currentTitle && !self.artistAwaitingTitle { self.currentArtist = nil }
                self.currentTitle = title
                self.artistAwaitingTitle = false
            }
            if let artist {
                self.currentArtist = artist
                self.artistAwaitingTitle = title == nil
            }
            if title != nil || artist != nil {
                self.onUpdate?(NowPlayingTrack(title: self.currentTitle, artist: self.currentArtist))
            }
        }
        queuedReads[readID] = readTask
    }

    private static func titleField(_ item: AVMetadataItem) -> Bool? {
        let identifier = item.identifier?.rawValue.lowercased() ?? ""
        let key = (item.key as? String)?.lowercased() ?? ""
        if item.commonKey == .commonKeyTitle || identifier.contains("streamtitle")
            || key == "streamtitle" || identifier == "id3/tit2" { return true }
        if item.commonKey == .commonKeyArtist || identifier == "id3/tpe1" { return false }
        return nil
    }

    deinit { for task in queuedReads.values { task.cancel() } }
}
