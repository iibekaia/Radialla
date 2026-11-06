import Foundation

func json(_ command: PairingCommand) throws -> [String: Any] {
    try JSONSerialization.jsonObject(with: JSONEncoder().encode(command)) as! [String: Any]
}
let play = try json(PairingCommand(type: "play", stationId: "station-123"))
assert(play["type"] as? String == "play")
assert(play["stationId"] as? String == "station-123")
assert(play["zoom"] == nil)
let pause = try json(PairingCommand(type: "pause"))
assert(pause.count == 1 && pause["type"] as? String == "pause")
let world = PairingCommand.viewport(latitude: 90, longitude: 200, longitudeDelta: 360)
assert(world.latitude == 85 && world.longitude == 180 && world.zoom == 2)
let city = PairingCommand.viewport(latitude: 41.7, longitude: 44.8, longitudeDelta: 0.25)
assert(abs(city.zoom! - log2(1440)) < 0.000001)
let close = PairingCommand.viewport(latitude: -90, longitude: -200, longitudeDelta: 0)
assert(close.latitude == -85 && close.longitude == -180 && close.zoom == 18)
print("Pairing command encoding and viewport validation passed")
