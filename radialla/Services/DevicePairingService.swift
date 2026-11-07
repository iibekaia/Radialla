import Foundation
import Combine

@MainActor
final class DevicePairingService: ObservableObject {
    @Published private(set) var connected = false
    @Published private(set) var paired = false
    @Published private(set) var isControlling = false {
        didSet { if isControlling != oldValue { onControllerModeChange?(isControlling) } }
    }
    @Published private(set) var members = 0
    @Published private(set) var busy = false
    @Published private(set) var messageKey = ""
    var onControllerModeChange: ((Bool) -> Void)?
    var onPlaybackChange: ((String, String?) -> Void)?
    var onReceiverUnavailable: (() -> Void)?

    private struct State: Decodable {
        let revision: Int
        let playback: Playback?
        let members: Int
        let receiverOnline: Bool?
    }
    private struct SocketEvent: Decodable {
        let type: String
        let state: State?
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
    private let base: URL
    private let credentials = PairingCredentialStore()
    private let session: URLSession
    private var token: String?
    private var watchTask: Task<Void, Never>?
    private var socket: PairingSocketConnection?
    private var commandTask: Task<Void, Never>?
    private var fallbackTask: Task<Void, Never>?
    private let fallbackDelay: Duration
    private var revision = -1
    private var generation = UUID()

    init(session: URLSession? = nil, fallbackDelay: Duration = .seconds(8),
         base: URL = URL(string: "https://radialla-web-production.up.railway.app/api/pairing/")!) {
        self.base = base
        self.fallbackDelay = fallbackDelay
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 35
        config.timeoutIntervalForResource = 40
        self.session = session ?? URLSession(configuration: config)
        token = credentials.read()
        paired = token != nil
        isControlling = paired
        if paired { watch() }
    }

    // Preserve input order, including rapid play/pause and map changes.
    func send(_ command: PairingCommand) {
        guard isControlling, !busy else { return }
        let previous = commandTask
        let current = generation
        commandTask = Task { [weak self] in
            await previous?.value
            guard let self, !Task.isCancelled, self.generation == current, self.isControlling, !self.busy else { return }
            do {
                let state: State = try await self.request("command", body: command)
                guard !Task.isCancelled, self.generation == current else { return }
                self.messageKey = ""
                self.apply(state)
            } catch {
                if !Task.isCancelled, self.generation == current { self.handle(error) }
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
                isControlling = true
                revision = -1
            }
            if let state = reply.state { apply(state) }
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
        socket?.close()
        let current = generation
        watchTask = Task { [weak self] in
            var retryDelay = 0.5
            while !Task.isCancelled {
                guard let self, let token = self.token, self.generation == current else { return }
                let connection = PairingSocketConnection(session: self.session, base: self.base)
                self.socket = connection
                do {
                    try await connection.authenticate(token: token)
                    while !Task.isCancelled {
                        let data = try await connection.receive()
                        guard !Task.isCancelled, self.generation == current else { return }
                        let event = try JSONDecoder().decode(SocketEvent.self, from: data)
                        switch event.type {
                        case "state":
                            guard let state = event.state else { throw Failure.unavailable }
                            self.messageKey = ""
                            self.apply(state)
                            retryDelay = 0.5
                        case "heartbeat": break
                        default: throw Failure.unavailable
                        }
                    }
                } catch {
                    guard !Task.isCancelled, self.generation == current else { return }
                    let expired = connection.expired
                    connection.close()
                    self.socket = nil
                    self.handle(expired ? Failure.expired : error)
                    if self.token == nil { return }
                    do { try await Task.sleep(for: .seconds(retryDelay)) }
                    catch { return }
                    retryDelay = min(retryDelay * 2, 8)
                }
            }
        }
    }
    private func apply(_ state: State) {
        guard state.revision >= revision else { return }
        revision = state.revision
        members = state.members
        connected = state.receiverOnline != false
        if connected {
            cancelFallback()
            isControlling = true
        } else {
            scheduleFallback()
        }
        if isControlling, let playback = state.playback {
            onPlaybackChange?(playback.type, playback.stationId)
        }
    }
    private func handle(_ error: Error) {
        if case Failure.expired = error {
            fallBackToLocalPlayback()
            clear()
            messageKey = "Pairing expired. Pair again."
        } else {
            connected = false
            messageKey = "Pairing unavailable. Try again."
            scheduleFallback()
        }
    }
    private func scheduleFallback() {
        guard isControlling, fallbackTask == nil else { return }
        let current = generation
        fallbackTask = Task { [weak self, fallbackDelay] in
            do { try await Task.sleep(for: fallbackDelay) }
            catch { return }
            guard let self, self.generation == current, self.paired else { return }
            self.fallbackTask = nil
            self.fallBackToLocalPlayback()
        }
    }
    private func cancelFallback() {
        fallbackTask?.cancel()
        fallbackTask = nil
    }
    private func fallBackToLocalPlayback() {
        guard isControlling else { return }
        commandTask?.cancel()
        commandTask = nil
        isControlling = false
        connected = false
        onReceiverUnavailable?()
    }
    private func clear() {
        cancelFallback()
        generation = UUID()
        watchTask?.cancel()
        socket?.close()
        socket = nil
        commandTask?.cancel()
        commandTask = nil
        token = nil
        credentials.save(nil)
        paired = false
        isControlling = false
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
