import Foundation

struct PairingQRPayload: Decodable {
    let type: String
    let version: Int
    let apiBaseUrl: String
    let code: String
    let expiresAt: Double

    static func validatedCode(from text: String, server: URL, now: Date = .now) throws -> String {
        guard text.utf8.count < 4096,
              let data = text.data(using: .utf8),
              let payload = try? JSONDecoder().decode(Self.self, from: data),
              payload.type == "radialla-pairing", payload.version == 1,
              payload.code.count == 8,
              payload.code.utf8.allSatisfy({ (48...57).contains($0) }) else {
            throw Failure.invalid
        }
        guard let url = URLComponents(string: payload.apiBaseUrl),
              url.scheme == server.scheme, url.host == server.host,
              url.port == server.port, url.user == nil, url.password == nil,
              url.query == nil, url.fragment == nil,
              url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")).isEmpty else {
            throw Failure.server
        }
        guard payload.expiresAt.isFinite, payload.expiresAt > now.timeIntervalSince1970 * 1000 else {
            throw Failure.expired
        }
        return payload.code
    }

    enum Failure: Error {
        case invalid, server, expired

        var messageKey: String {
            switch self {
            case .invalid: return "Invalid Radialla QR code. Try again."
            case .server: return "This QR code uses a different Radialla server."
            case .expired: return "Code expired. Generate a new one."
            }
        }
    }
}
