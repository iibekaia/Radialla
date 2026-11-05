import AVFoundation

@MainActor
final class PlaybackItemObserver {
    var onStateChanged: ((AVPlayer.TimeControlStatus) -> Void)?
    var onFailure: (() -> Void)?
    var onStall: (() -> Void)?
    private weak var player: AVPlayer?
    private var stateObservation: NSKeyValueObservation?
    private var itemObservation: NSKeyValueObservation?
    private var notificationTokens: [NSObjectProtocol] = []

    init(player: AVPlayer) {
        self.player = player
        stateObservation = player.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
            let state = player.timeControlStatus
            Task { @MainActor in
                guard let self, self.player?.timeControlStatus == state else { return }
                self.onStateChanged?(state)
            }
        }
        for name in [AVPlayerItem.playbackStalledNotification, AVPlayerItem.failedToPlayToEndTimeNotification,
                     AVPlayerItem.didPlayToEndTimeNotification] {
            notificationTokens.append(NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] notification in
                guard let item = notification.object as? AVPlayerItem else { return }
                Task { @MainActor in
                    guard let self, self.player?.currentItem === item else { return }
                    if name == AVPlayerItem.playbackStalledNotification {
                        self.onStall?()
                    } else {
                        self.onFailure?()
                    }
                }
            })
        }
    }

    func observe(_ item: AVPlayerItem) {
        itemObservation = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
            let failed = item.status == .failed
            Task { @MainActor in
                guard let self, failed, self.player?.currentItem === item else { return }
                self.onFailure?()
            }
        }
    }

    func clearItem() { itemObservation = nil }

    deinit {
        for token in notificationTokens { NotificationCenter.default.removeObserver(token) }
    }
}
