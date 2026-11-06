import Foundation
import Combine

@MainActor
final class DevicePairingService: ObservableObject {
    @Published private(set) var connected = false
    @Published private(set) var paired = false {
        didSet { if paired != oldValue { onControllerModeChange?(paired) } }
    }
    @Published private(set) var members = 0
    @Published private(set) var busy = false
    @Published private(set) var messageKey = ""
    var onControllerModeChange: ((Bool) -> Void)?
    var onPlaybackChange: ((String, String?) -> Void)?

    private struct State: Decodable {
        let revision: Int
        let playback: Playback?
        let members: Int
    }
    private struct Playback: Decodable {
        let type: String
        let stationId: String?
    }
    private struct Reply: Decodable {
        let token: String?
        let state: State?
    }
    private enum Failure: Error { case expired, unavailable }
    private let base = URL(string: "https://radialla-web-production.up.railway.app/api/pairing/")!
    private let credentials = PairingCredentialStore()
    private let session: URLSession
    private var token: String?
    private var watchTask: Task<Void, Never>?
    private var commandTask: Task<Void, Never>?
    private var revision = -1
    private var generation = UUID()

    init(session: URLSession? = nil) {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 35
        config.timeoutIntervalForResource = 40
        self.session = session ?? URLSession(configuration: config)
        token = credentials.read()
        paired = token != nil
        if paired { watch() }
    }

    // Preserve input order, including rapid play/pause and map changes.
    func send(_ command: PairingCommand) {
        guard paired, !busy else { return }
        let previous = commandTask
        let current = generation
        commandTask = Task { [weak self] in
            await previous?.value
            guard let self, !Task.isCancelled, self.generation == current, self.paired, !self.busy else { return }
            do {
                let state: State = try await self.request("command", body: command)
                guard self.generation == current else { return }
                self.connected = true
                self.messageKey = ""
                self.apply(state)
            } catch {
                if self.generation == current { self.handle(error) }
            }
        }
    }

    private func join(_ code: String) async {
        guard token == nil else { return }
        await connect(action: "join", body: ["code": code])
    }
    func joinQRCode(_ text: String) async {
        do {
            let code = try PairingQRPayload.validatedCode(from: text, server: base)
            await join(code)
        } catch let failure as PairingQRPayload.Failure {
            messageKey = failure.messageKey
        } catch {
            messageKey = "Invalid Radialla QR code. Try again."
        }
    }

    private func connect(action: String, body: [String: String]) async {
        guard !busy else { return }
        busy = true
        messageKey = ""
        defer { busy = false }
        let current = generation
        do {
            let reply: Reply = try await request(action, body: body)
            guard generation == current else { return }
            if let newToken = reply.token {
                token = newToken
                credentials.save(newToken)
                paired = true
                revision = -1
            }
            if let state = reply.state { apply(state) }
            connected = true
            watch()
        } catch {
            handle(error)
        }
    }

    func disconnect() async {
        guard !busy else { return }
        busy = true
        defer { busy = false }
        do {
            let _: Reply = try await request("leave", body: [String: String]())
            clear()
        } catch Failure.expired { clear() }
        catch { messageKey = "Pairing unavailable. Try again." }
    }

    private func watch() {
        watchTask?.cancel()
        let current = generation
        watchTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self, self.token != nil, self.generation == current else { return }
                do {
                    let state: State = try await self.request("wait", body: ["afterRevision": self.revision])
                    guard !Task.isCancelled, self.generation == current else { return }
                    self.connected = true
                    self.messageKey = ""
                    self.apply(state)
                } catch {
                    guard !Task.isCancelled, self.generation == current else { return }
                    self.handle(error)
                    if self.token == nil { return }
                    try? await Task.sleep(for: .seconds(3))
                }
            }
        }
    }
    private func apply(_ state: State) {
        guard state.revision >= revision else { return }
        revision = state.revision
        members = state.members
        if let playback = state.playback { onPlaybackChange?(playback.type, playback.stationId) }
    }
    private func handle(_ error: Error) {
        if case Failure.expired = error {
            clear()
            messageKey = "Pairing expired. Pair again."
        } else {
            connected = false
            messageKey = "Pairing unavailable. Try again."
        }
    }
    private func clear() {
        generation = UUID()
        watchTask?.cancel()
        commandTask?.cancel()
        commandTask = nil
        token = nil
        credentials.save(nil)
        paired = false
        connected = false
        members = 0
        revision = -1
    }
    private func request<T: Decodable, B: Encodable>(_ action: String, body: B) async throws -> T {
        var request = URLRequest(url: base.appendingPathComponent(action))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        request.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse else { throw Failure.unavailable }
        if response.statusCode == 401 { throw Failure.expired }
        guard response.statusCode == 200 else { throw Failure.unavailable }
        return try JSONDecoder().decode(T.self, from: data)
    }
}
