import Foundation

// One authenticated subscription. Commands and membership changes remain HTTP requests.
@MainActor
final class PairingSocketConnection {
    private let task: URLSessionWebSocketTask
    private var watchdog: Task<Void, Never>?

    var expired: Bool { task.closeCode.rawValue == 4401 }

    init(session: URLSession, base: URL) {
        var components = URLComponents(url: base.appendingPathComponent("socket"), resolvingAgainstBaseURL: false)!
        components.scheme = components.scheme == "https" ? "wss" : "ws"
        task = session.webSocketTask(with: components.url!)
        task.maximumMessageSize = 64 * 1024
    }

    func authenticate(token: String) async throws {
        task.resume()
        armWatchdog(seconds: 10)
        // Match the server's first-frame authentication; keep credentials out of URLs.
        let data = try JSONEncoder().encode(["token": token])
        try await task.send(.string(String(decoding: data, as: UTF8.self)))
    }

    func receive() async throws -> Data {
        let message = try await task.receive()
        armWatchdog(seconds: 45) // Server publishes a heartbeat every 20 seconds.
        switch message {
        case .string(let text): return Data(text.utf8)
        case .data(let data): return data
        @unknown default: throw URLError(.cannotParseResponse)
        }
    }

    func close() {
        watchdog?.cancel()
        watchdog = nil
        task.cancel(with: .goingAway, reason: nil)
    }

    private func armWatchdog(seconds: Double) {
        watchdog?.cancel()
        let socket = task
        watchdog = Task {
            do { try await Task.sleep(for: .seconds(seconds)) }
            catch { return }
            socket.cancel(with: .goingAway, reason: nil)
        }
    }

    deinit {
        watchdog?.cancel()
        task.cancel(with: .goingAway, reason: nil)
    }
}
