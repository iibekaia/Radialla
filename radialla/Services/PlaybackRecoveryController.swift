import Foundation
import Network

@MainActor
final class PlaybackRecoveryController {
    var onRetry: (() -> Void)?
    var onWaitingForNetwork: (() -> Void)?
    var networkPermitsPlayback: Bool { networkAvailable }
    private let monitor = NWPathMonitor()
    private var retryTask: Task<Void, Never>?
    private var generation = 0
    private var attempts = 0
    private var wantsPlayback = false
    private var isPlaying = false
    private var networkAvailable = true

    init(monitorsNetwork: Bool = true) {
        guard monitorsNetwork else { return }
        monitor.pathUpdateHandler = { [weak self] path in
            let available = path.status == .satisfied
            Task { @MainActor [weak self] in self?.networkChanged(available: available) }
        }
        monitor.start(queue: DispatchQueue(label: "ge.radialla.playback-network"))
    }

    func begin(resetAttempts: Bool) {
        cancelRetry()
        wantsPlayback = true
        isPlaying = false
        if resetAttempts { attempts = 0 }
    }

    func stop() {
        wantsPlayback = false
        isPlaying = false
        attempts = 0
        cancelRetry()
    }

    func didStartPlaying() {
        guard wantsPlayback else { return }
        isPlaying = true
        attempts = 0
        cancelRetry()
    }

    func stalled() {
        guard wantsPlayback else { return }
        isPlaying = false
        schedule(after: max(8, retryDelay))
    }

    func failed() {
        guard wantsPlayback else { return }
        isPlaying = false
        cancelRetry()
        schedule(after: retryDelay)
    }

    private var retryDelay: Double { min(30, pow(2, Double(min(attempts + 1, 5)))) }

    func networkChanged(available: Bool) {
        let wasAvailable = networkAvailable
        networkAvailable = available
        guard wantsPlayback else { return }
        if !networkAvailable {
            cancelRetry()
            if !isPlaying {
                onWaitingForNetwork?()
            }
        } else if !isPlaying && !wasAvailable {
            cancelRetry()
            schedule(after: 1)
        }
    }

    private func schedule(after delay: Double) {
        guard wantsPlayback, !isPlaying, retryTask == nil else { return }
        guard networkAvailable else {
            onWaitingForNetwork?()
            return
        }
        let generation = generation
        retryTask = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(delay)) }
            catch { return }
            guard let self, self.generation == generation, self.wantsPlayback,
                  !self.isPlaying, self.networkAvailable else { return }
            self.retryTask = nil
            self.attempts = min(self.attempts + 1, 5)
            self.onRetry?()
        }
    }

    private func cancelRetry() {
        generation += 1
        retryTask?.cancel()
        retryTask = nil
    }

    deinit {
        retryTask?.cancel()
        monitor.cancel()
    }
}
