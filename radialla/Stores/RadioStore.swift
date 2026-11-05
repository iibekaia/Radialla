import Foundation
import Combine
import AVFoundation

@MainActor
final class RadioStore: ObservableObject {
    @Published var stations: [Station] = []
    @Published private(set) var selected: Station?
    @Published private(set) var playerPresentationID = UUID()
    var status: String { selected == nil ? catalogMessage.text : playbackStatus }
    var playbackStatus: String {
        if !playbackRequested { return localized("პაუზა") }
        if playing && isMuted { return localized("Muted") }
        return message.text
    }
    @Published var catalogMessage = RadioMessage("აირჩიე ადგილი და მოუსმინე მსოფლიოს")
    @Published var message = RadioMessage("აირჩიე ადგილი და მოუსმინე მსოფლიოს")
    @Published private(set) var playing = false
    @Published private(set) var playbackRequested = false
    @Published private(set) var isMuted = false
    private let speedVolume = SpeedVolumeController()
    private let lastStationStore = LastStationStore()
    private let metadataReader = StreamMetadataReader()
    private let artworkController = NowPlayingArtworkController()
    private let recovery = PlaybackRecoveryController()
    private let systemControls = PlaybackSystemControls()
    @Published private(set) var nowPlayingTrack: NowPlayingTrack?
    @Published var loading = false
    @Published var backgroundLoading = false
    let catalogService = StationCatalogService()
    var priorityCountry: String?
    var completedCountries: Set<String> = []
    var countryRequestInProgress: String?
    var restoredCatalog = false
    var stationIndices: [String: Int] = [:]
    @Published var catalogRevision = 0
    @Published private(set) var favorites: Set<String> = Set(UserDefaults.standard.stringArray(forKey: "favorites") ?? [])
    private let player = AVPlayer()
    private var stationQueue: [Station] = []
    var catalogOffset = 0
    var catalogComplete = false
    private lazy var playbackObserver = PlaybackItemObserver(player: player)
    private var resumeAfterInterruption = false

    init() {
        artworkController.onChange = { [weak self] in
            guard let self else { return }
            self.updateNowPlaying(rate: self.playing ? 1 : 0)
        }
        recovery.onRetry = { [weak self] in
            guard let self, self.playbackRequested, let station = self.selected else { return }
            self.play(station, showPlayer: false, reconnecting: true)
        }
        recovery.onWaitingForNetwork = { [weak self] in
            self?.message = RadioMessage("Waiting for internet…")
        }
        metadataReader.onUpdate = { [weak self] track in
            guard let self else { return }
            self.nowPlayingTrack = track
            self.updateNowPlaying(rate: self.playing ? 1 : 0)
        }
        speedVolume.onVolumeChange = { [weak self] gain in self?.player.volume = gain }
        playbackObserver.onStateChanged = { [weak self] state in
            guard let self else { return }
            self.playing = state == .playing
            self.updateNowPlaying(rate: self.playing ? 1 : 0)
            self.speedVolume.setActive(state == .playing)
            if state == .waitingToPlayAtSpecifiedRate {
                self.message = RadioMessage("იტვირთება აუდიო…")
                self.recovery.stalled()
            }
            if state == .playing {
                self.recovery.didStartPlaying()
                self.message = RadioMessage("LIVE")
                if let selected = self.selected {
                    self.lastStationStore.save(selected)
                    WidgetStationBridge.update(selected)
                }
            }
        }
        playbackObserver.onFailure = { [weak self] in
            guard let self, self.playbackRequested else { return }
            self.playing = false
            self.speedVolume.setActive(false)
            self.updateNowPlaying(rate: 0)
            self.message = RadioMessage("აუდიოს ჩართვა ვერ მოხერხდა")
            self.recovery.failed()
        }
        playbackObserver.onStall = { [weak self] in
            guard let self, self.playbackRequested else { return }
            self.message = RadioMessage("იტვირთება აუდიო…")
            self.recovery.stalled()
        }
        systemControls.onPlay = { [weak self] in self?.resume() }
        systemControls.onPause = { [weak self] in self?.pause() }
        systemControls.onSkip = { [weak self] forward in self?.skipStation(forward: forward) }
        systemControls.onInterruptionBegan = { [weak self] in
            guard let self else { return }
            let requested = self.playbackRequested
            self.pause()
            self.resumeAfterInterruption = requested
        }
        systemControls.onInterruptionEnded = { [weak self] shouldResume in
            guard let self else { return }
            let requested = self.resumeAfterInterruption
            self.resumeAfterInterruption = false
            if requested && shouldResume { self.resume() }
        }
        if let lastStation = lastStationStore.load() {
            WidgetStationBridge.update(lastStation)
            play(lastStation, showPlayer: false)
        }
    }

    func play(_ station: Station, showPlayer: Bool = true, reconnecting: Bool = false) {
        guard let url = station.streamURL else {
            message = RadioMessage("ამ სადგურის ბმული არასწორია")
            return
        }
        resumeAfterInterruption = false
        recovery.begin(resetAttempts: !reconnecting)
        playbackRequested = true
        selected = station
        nowPlayingTrack = nil
        artworkController.update(for: station)
        if showPlayer { playerPresentationID = UUID() }
        guard recovery.networkPermitsPlayback else {
            suspendForNetwork()
            recovery.stalled()
            return
        }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            playing = false
            message = RadioMessage(reconnecting ? "Reconnecting…" : "იტვირთება აუდიო…")
            let asset = AVURLAsset(url: url, options: [AVURLAssetAllowsCellularAccessKey: true])
            let item = AVPlayerItem(asset: asset)
            metadataReader.attach(to: item)
            playbackObserver.observe(item)
            player.replaceCurrentItem(with: item)
            player.play()
            recovery.stalled()
            updateNowPlaying(rate: 1)
        } catch {
            message = RadioMessage("აუდიოს ჩართვა ვერ მოხერხდა")
            recovery.failed()
        }
    }

    func setStationQueue(_ queue: [Station]) {
        stationQueue = queue
        systemControls.setCanSkip(queue.count > 1)
    }

    func skipStation(forward: Bool) {
        guard !stationQueue.isEmpty else { return }
        let currentIndex = stationQueue.firstIndex { $0.id == selected?.id }
        let nextIndex: Int
        if let currentIndex {
            nextIndex = (currentIndex + (forward ? 1 : -1) + stationQueue.count) % stationQueue.count
        } else {
            nextIndex = forward ? 0 : stationQueue.count - 1
        }
        play(stationQueue[nextIndex], showPlayer: false)
    }

    func resume() {
        resumeAfterInterruption = false
        guard let selected else { return }
        artworkController.update(for: selected)
        if player.currentItem == nil || player.currentItem?.status == .failed
            || !recovery.networkPermitsPlayback {
            play(selected, showPlayer: false)
            return
        }
        playbackRequested = true
        recovery.begin(resetAttempts: true)
        do {
            try AVAudioSession.sharedInstance().setActive(true)
            player.play()
            recovery.stalled()
            updateNowPlaying(rate: 1)
        } catch {
            message = RadioMessage("აუდიოს ჩართვა ვერ მოხერხდა")
            recovery.failed()
        }
    }

    func toggleMute() {
        isMuted.toggle()
        player.isMuted = isMuted
    }

    func pause() {
        resumeAfterInterruption = false
        playbackRequested = false
        recovery.stop()
        player.pause()
        playing = false
        speedVolume.setActive(false)
        updateNowPlaying(rate: 0)
    }

    private func suspendForNetwork() {
        player.pause()
        player.replaceCurrentItem(with: nil)
        playbackObserver.clearItem()
        metadataReader.detach()
        playing = false
        speedVolume.setActive(false)
        updateNowPlaying(rate: 0)
    }

    private func updateNowPlaying(rate: Double) {
        guard let selected else { return }
        systemControls.update(station: selected, track: nowPlayingTrack,
                              artwork: artworkController.artwork, rate: rate)
    }

    func toggleFavorite(_ station: Station) {
        if favorites.contains(station.id) { favorites.remove(station.id) }
        else { favorites.insert(station.id) }
        UserDefaults.standard.set(Array(favorites), forKey: "favorites")
    }
}
