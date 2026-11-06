import Foundation
import Combine

@MainActor
final class DevicePairingService: ObservableObject {
    @Published private(set) var connected = false
    @Published private(set) var paired = false
    @Published private(set) var members = 0
    @Published private(set) var code = ""
    @Published private(set) var codeExpiresAt: Date?
    @Published private(set) var busy = false
    @Published private(set) var messageKey = ""
    var onRemotePause: (() -> Void)?

    private struct State: Decodable {
        let revision: Int
        let owner: String?
        let members: Int
    }
    private struct Reply: Decodable {
        let token: String?
        let code: String?
        let expiresAt: Double?
        let state: State?
    }
    private enum Failure: Error { case expired, unavailable }
    private let base = URL(string: "https://radialla-web-production.up.railway.app/api/pairing/")!
    private let credentials = PairingCredentialStore()
    private let clientID = UUID().uuidString
    private let session: URLSession
    private var token: String?
    private var watchTask: Task<Void, Never>?
    private var claimTask: Task<Void, Never>?
    private var revision = -1
    private var owner: String?
    private var localPlaying = false
    private var claimed = false
    private var claiming = false
    private var generation = UUID()

    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 35
        config.timeoutIntervalForResource = 40
        session = URLSession(configuration: config)
        token = credentials.read()
        paired = token != nil
        if paired { watch() }
    }

    // Call only after AVPlayer reports actual playback, not on button taps/loading.
    func playbackStarted() {
        localPlaying = true
        if paired && !claimed && !claiming { claim() }
    }
    func playbackSuspended() { localPlaying = false }

    func playbackStopped() {
        localPlaying = false
        claimed = false
    }

    func createCode() async { await connect(action: token == nil ? "create" : "code", body: [:]) }
    func join(_ code: String) async {
        guard token == nil else { return }
        await connect(action: "join", body: ["code": code])
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
                claimed = false
            }
            if let code = reply.code { self.code = code }
            if let expiry = reply.expiresAt { codeExpiresAt = Date(timeIntervalSince1970: expiry / 1000) }
            // A currently playing joining device claims after the successful stream start.
            if localPlaying { claiming = true }
            if let state = reply.state { apply(state) }
            connected = true
            watch()
            claiming = false
            if localPlaying && !claimed { claim() }
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

    private func claim() {
        guard token != nil, !claiming else { return }
        claiming = true
        let current = generation
        claimTask = Task { [weak self] in
            guard let self else { return }
            defer { if self.generation == current { self.claiming = false } }
            do {
                let state: State = try await self.request("claim", body: ["clientId": self.clientID])
                guard self.generation == current else { return }
                self.claimed = true
                self.apply(state)
                self.claiming = false
                self.enforceOwner()
            } catch {
                if self.generation == current { self.handle(error) }
            }
        }
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
                    if self.localPlaying && !self.claimed && !self.claiming { self.claim() }
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
        owner = state.owner
        members = state.members
        enforceOwner()
    }
    private func enforceOwner() {
        guard !claiming, localPlaying, let owner, owner != clientID else { return }
        playbackStopped()
        onRemotePause?()
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
        claimTask?.cancel()
        token = nil
        credentials.save(nil)
        paired = false
        connected = false
        claimed = false
        claiming = false
        code = ""
        codeExpiresAt = nil
        members = 0
        revision = -1
        owner = nil
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
