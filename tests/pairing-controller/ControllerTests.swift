import Foundation

// Test credentials stay in memory and never touch the user's Keychain.
struct PairingCredentialStore {
    func read() -> String? { nil }
    func save(_ token: String?) {}
}

final class PairingProtocol: URLProtocol {
    static let lock = NSLock()
    static var actions: [String] = []
    static var commands: [String] = []
    static var revision = 1
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func stopLoading() {}
    override func startLoading() {
        Self.lock.lock()
        defer { Self.lock.unlock() }
        let action = request.url!.lastPathComponent
        Self.actions.append(action)
        if action == "socket" {
            client!.urlProtocol(self, didFailWithError: URLError(.cannotConnectToHost))
            return // Socket transport is exercised separately against the web server.
        }
        var state: [String: Any] = ["revision": Self.revision, "members": 2]
        var result: [String: Any] = [:]
        var status = 200
        if action == "join" {
            result = ["token": "test-token", "state": state]
        } else if action == "command" {
            precondition(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-token")
            let data: Data
            if let body = request.httpBody { data = body }
            else {
                let stream = request.httpBodyStream!
                stream.open()
                defer { stream.close() }
                var bytes = [UInt8](repeating: 0, count: 4096)
                let count = stream.read(&bytes, maxLength: bytes.count)
                data = Data(bytes.prefix(count))
            }
            var command = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
            let type = command["type"] as! String
            Self.commands.append(type)
            if command["stationId"] as? String == "expired" { status = 401 }
            Self.revision += 1
            state["revision"] = Self.revision
            command["revision"] = Self.revision
            state["playback"] = command
            result = state
        } else { precondition(action == "leave") }
        let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
        client!.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client!.urlProtocol(self, didLoad: try! JSONSerialization.data(withJSONObject: result))
        client!.urlProtocolDidFinishLoading(self)
    }
}

@main struct ControllerTests {
    @MainActor static func main() async throws {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [PairingProtocol.self]
        let service = DevicePairingService(session: URLSession(configuration: config))
        var modes: [Bool] = []
        var playback: [String] = []
        service.onControllerModeChange = { modes.append($0) }
        service.onPlaybackChange = { type, _ in playback.append(type) }
        let payload: [String: Any] = ["type": "radialla-pairing", "version": 1,
            "apiBaseUrl": "https://radialla-web-production.up.railway.app", "code": "01234567",
            "expiresAt": Date().addingTimeInterval(300).timeIntervalSince1970 * 1000]
        let qr = String(data: try JSONSerialization.data(withJSONObject: payload), encoding: .utf8)!
        await service.joinQRCode(qr)
        precondition(service.paired && modes == [true])
        service.send(PairingCommand(type: "play", stationId: "radio-123"))
        service.send(PairingCommand(type: "pause"))
        for _ in 0..<100 where playback.count < 2 { try await Task.sleep(for: .milliseconds(10)) }
        precondition(playback == ["play", "pause"])
        await service.disconnect()
        precondition(!service.paired && modes == [true, false])
        await service.joinQRCode(qr)
        service.send(PairingCommand(type: "play", stationId: "expired"))
        for _ in 0..<100 where service.paired { try await Task.sleep(for: .milliseconds(10)) }
        precondition(!service.paired && modes == [true, false, true, false])
        precondition(service.messageKey == "Pairing expired. Pair again.")
        precondition(!PairingProtocol.actions.contains("claim"))
        precondition(!PairingProtocol.actions.contains("wait"))
        let offline = DevicePairingService(session: URLSession(configuration: config), fallbackDelay: .milliseconds(50))
        var fallbacks = 0
        offline.onReceiverUnavailable = { fallbacks += 1 }
        await offline.joinQRCode(qr)
        for _ in 0..<100 where offline.isControlling { try await Task.sleep(for: .milliseconds(10)) }
        precondition(offline.paired && !offline.isControlling && fallbacks == 1)
        // Explicit disconnect must stay paused and cancel pending fallback.
        await offline.disconnect()
        precondition(!offline.paired)
        await offline.joinQRCode(qr)
        await offline.disconnect()
        try await Task.sleep(for: .milliseconds(100))
        precondition(fallbacks == 1)
        print("Controller pairing, command order, disconnect, expiry and local fallback passed")
        if let origin = CommandLine.arguments.dropFirst().first {
            try await verifyReceiverReturn(origin: URL(string: origin)!)
        }
    }

    // Optional end-to-end check against a disposable local pairing server.
    @MainActor static func verifyReceiverReturn(origin: URL) async throws {
        precondition(origin.host == "127.0.0.1" || origin.host == "localhost")
        let base = origin.appendingPathComponent("api/pairing/")
        let session = URLSession(configuration: .ephemeral)
        var request = URLRequest(url: base.appendingPathComponent("create"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = Data("{}".utf8)
        let (data, _) = try await session.data(for: request)
        let receiver = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let token = receiver["token"] as! String
        let socket = PairingSocketConnection(session: session, base: base)
        try await socket.authenticate(token: token)
        _ = try await socket.receive()

        let service = DevicePairingService(session: session, fallbackDelay: .milliseconds(50), base: base)
        var modes: [Bool] = []
        service.onControllerModeChange = { modes.append($0) }
        let payload: [String: Any] = ["type": "radialla-pairing", "version": 1,
            "apiBaseUrl": origin.absoluteString, "code": receiver["code"] as! String,
            "expiresAt": receiver["expiresAt"] as! Double]
        let qr = String(decoding: try JSONSerialization.data(withJSONObject: payload), as: UTF8.self)
        await service.joinQRCode(qr)
        precondition(service.connected && modes == [true])
        socket.close()
        for _ in 0..<100 where service.isControlling { try await Task.sleep(for: .milliseconds(10)) }
        precondition(service.paired && modes == [true, false])

        let restored = PairingSocketConnection(session: session, base: base)
        try await restored.authenticate(token: token)
        for _ in 0..<100 where !service.isControlling { try await Task.sleep(for: .milliseconds(10)) }
        precondition(service.connected && modes == [true, false, true])
        await service.disconnect()
        restored.close()
        session.invalidateAndCancel()
        print("Receiver loss and return restored controller mode with the same pairing")
    }
}
