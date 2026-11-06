import Foundation

let server = URL(string: "https://radialla-web-production.up.railway.app/api/pairing/")!
let now = Date(timeIntervalSince1970: 1_800_000_000)
func payload(_ changes: [String: Any] = [:]) -> String {
    var fields: [String: Any] = ["type": "radialla-pairing", "version": 1,
        "apiBaseUrl": "https://radialla-web-production.up.railway.app",
        "code": "01234567", "expiresAt": now.timeIntervalSince1970 * 1000 + 300_000]
    fields.merge(changes) { _, new in new }
    return String(data: try! JSONSerialization.data(withJSONObject: fields), encoding: .utf8)!
}
func rejects(_ text: String, as expected: PairingQRPayload.Failure) {
    do {
        _ = try PairingQRPayload.validatedCode(from: text, server: server, now: now)
        fatalError("Expected rejection")
    } catch let error as PairingQRPayload.Failure {
        precondition(error == expected)
    } catch { fatalError("Unexpected error: \(error)") }
}
let code = try PairingQRPayload.validatedCode(from: payload(), server: server, now: now)
precondition(code == "01234567")
rejects("01234567", as: .invalid)
rejects(payload(["version": 2]), as: .invalid)
rejects(payload(["type": "other"]), as: .invalid)
rejects(payload(["code": "１２３４５６７８"]), as: .invalid)
rejects(payload(["code": "1234567"]), as: .invalid)
rejects(payload(["expiresAt": now.timeIntervalSince1970 * 1000]), as: .expired)
for url in ["https://example.com", "http://radialla-web-production.up.railway.app", "https://user@radialla-web-production.up.railway.app", "https://radialla-web-production.up.railway.app/other", "https://radialla-web-production.up.railway.app?x=1"] {
    rejects(payload(["apiBaseUrl": url]), as: .server)
}
print("Pairing QR validation passed")
