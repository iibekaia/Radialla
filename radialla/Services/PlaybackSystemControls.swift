import AVFoundation
import MediaPlayer

@MainActor
final class PlaybackSystemControls {
    var onPlay: (() -> Void)?
    var onPause: (() -> Void)?
    var onSkip: ((Bool) -> Void)?
    var onInterruptionBegan: (() -> Void)?
    var onInterruptionEnded: ((Bool) -> Void)?
    private var remoteTargets: [(MPRemoteCommand, Any)] = []
    private var notificationTokens: [NSObjectProtocol] = []

    init() {
        let commands = MPRemoteCommandCenter.shared()
        register(commands.playCommand) { [weak self] in self?.onPlay?() }
        register(commands.pauseCommand) { [weak self] in self?.onPause?() }
        register(commands.nextTrackCommand) { [weak self] in self?.onSkip?(true) }
        register(commands.previousTrackCommand) { [weak self] in self?.onSkip?(false) }
        setCanSkip(false)
        notificationTokens.append(NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification, object: AVAudioSession.sharedInstance(), queue: .main
        ) { [weak self] notification in
            let type = (notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt) ?? 0
            let options = (notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt) ?? 0
            Task { @MainActor in
                if type == AVAudioSession.InterruptionType.began.rawValue {
                    self?.onInterruptionBegan?()
                } else if type == AVAudioSession.InterruptionType.ended.rawValue {
                    self?.onInterruptionEnded?(AVAudioSession.InterruptionOptions(rawValue: options).contains(.shouldResume))
                }
            }
        })
        notificationTokens.append(NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification, object: AVAudioSession.sharedInstance(), queue: .main
        ) { [weak self] notification in
            let reason = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt
            if reason == AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue {
                Task { @MainActor in self?.onPause?() }
            }
        })
    }

    func setCanSkip(_ allowed: Bool) {
        MPRemoteCommandCenter.shared().nextTrackCommand.isEnabled = allowed
        MPRemoteCommandCenter.shared().previousTrackCommand.isEnabled = allowed
    }

    func update(station: Station, track: NowPlayingTrack?, artwork: MPMediaItemArtwork?, rate: Double) {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: track?.title ?? station.name,
            MPMediaItemPropertyArtist: track?.artist ?? station.name,
            MPMediaItemPropertyAlbumTitle: station.name,
            MPNowPlayingInfoPropertyIsLiveStream: true,
            MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.audio.rawValue,
            MPNowPlayingInfoPropertyPlaybackRate: rate
        ]
        if let artwork { info[MPMediaItemPropertyArtwork] = artwork }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func register(_ command: MPRemoteCommand, action: @escaping @MainActor () -> Void) {
        let target = command.addTarget { _ in
            Task { @MainActor in action() }
            return .success
        }
        remoteTargets.append((command, target))
    }

    deinit {
        for (command, target) in remoteTargets { command.removeTarget(target) }
        for token in notificationTokens { NotificationCenter.default.removeObserver(token) }
    }
}
