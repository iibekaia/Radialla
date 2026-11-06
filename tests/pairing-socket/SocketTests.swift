import Foundation

// Run against a disposable local instance of radialla-web, never production.
@main struct SocketTests {
    @MainActor static func main() async throws {
        let base = URL(string: CommandLine.arguments[1])!.appendingPathComponent("api/pairing")
        precondition(base.host == "127.0.0.1" || base.host == "localhost")
        let session = URLSession(configuration: .ephemeral)
        func request(_ action: String, _ body: [String: String] = [:], token: String? = nil) async throws -> [String: Any] {
            var req = URLRequest(url: base.appendingPathComponent(action))
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            if let token { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await session.data(for: req)
            precondition((response as! HTTPURLResponse).statusCode == 200)
            return try JSONSerialization.jsonObject(with: data) as! [String: Any]
        }
        func state(_ socket: PairingSocketConnection) async throws -> [String: Any] {
            while true {
                let data = try await socket.receive()
                let event = try JSONSerialization.jsonObject(with: data) as! [String: Any]
                if event["type"] as? String == "state" { return event["state"] as! [String: Any] }
                precondition(event["type"] as? String == "heartbeat")
            }
        }
        let receiver = try await request("create")
        let joined = try await request("join", ["code": receiver["code"] as! String])
        let token = joined["token"] as! String
        let socket = PairingSocketConnection(session: session, base: base)
        try await socket.authenticate(token: token)
        let initial = try await state(socket)
        precondition(initial["members"] as? Int == 2)
        _ = try await request("command", ["type": "play", "stationId": "test-radio"], token: receiver["token"] as? String)
        let update = try await state(socket)
        precondition((update["playback"] as? [String: Any])?["stationId"] as? String == "test-radio")
        socket.close()
        _ = try await request("command", ["type": "pause"], token: token)
        let restored = PairingSocketConnection(session: session, base: base)
        try await restored.authenticate(token: token)
        let snapshot = try await state(restored)
        precondition((snapshot["playback"] as? [String: Any])?["type"] as? String == "pause")
        precondition((snapshot["revision"] as! Int) > (update["revision"] as! Int))
        _ = try await request("leave", token: token)
        do {
            _ = try await restored.receive()
            preconditionFailure("Revoked membership must close the subscription")
        } catch { precondition(restored.expired) }
        restored.close()
        session.invalidateAndCancel()
        print("WebSocket authentication, live state, reconnect snapshot and 4401 expiry passed")
    }
}
