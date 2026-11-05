import Foundation

struct SpeedVolumePolicy {
    func gain(for speedKPH: Double) -> Float {
        guard speedKPH.isFinite, speedKPH >= 0 else { return 1 }
        let progress = min(1, max(0, (speedKPH - 110) / 10))
        return Float(1 - 0.35 * progress)
    }
}
