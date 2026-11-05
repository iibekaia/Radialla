import SwiftUI
import CoreLocation

extension Color {
    static let radioAccent = Color(red: 241.0 / 255, green: 90.0 / 255, blue: 34.0 / 255)
    static let radioBackground = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 13.0 / 255, green: 14.0 / 255, blue: 15.0 / 255, alpha: 1)
            : UIColor(white: 244.0 / 255, alpha: 1)
    })
    static let radioSurface = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 43.0 / 255, green: 44.0 / 255, blue: 46.0 / 255, alpha: 1)
            : .white
    })
}

enum ThemeResolver {
    static func colorScheme(at date: Date, coordinate: CLLocationCoordinate2D?) -> ColorScheme {
        guard let coordinate = coordinate else {
            let hour = Calendar.current.component(.hour, from: date)
            return (7..<19).contains(hour) ? .light : .dark
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let day = Double(calendar.ordinality(of: .day, in: .year, for: date) ?? 1)
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        let hour = Double(parts.hour ?? 0) + Double(parts.minute ?? 0) / 60
        let annualAngle = 2 * Double.pi / 365 * (day - 1 + (hour - 12) / 24)
        let equationOfTime = 229.18 * (0.000075 + 0.001868 * cos(annualAngle)
            - 0.032077 * sin(annualAngle) - 0.014615 * cos(2 * annualAngle)
            - 0.040849 * sin(2 * annualAngle))
        let declination = 0.006918 - 0.399912 * cos(annualAngle) + 0.070257 * sin(annualAngle)
            - 0.006758 * cos(2 * annualAngle) + 0.000907 * sin(2 * annualAngle)
            - 0.002697 * cos(3 * annualAngle) + 0.00148 * sin(3 * annualAngle)
        let solarMinutes = (hour * 60 + equationOfTime + 4 * coordinate.longitude)
            .truncatingRemainder(dividingBy: 1440)
        let hourAngle = (solarMinutes / 4 - 180) * .pi / 180
        let latitude = coordinate.latitude * .pi / 180
        let elevationSine = sin(latitude) * sin(declination)
            + cos(latitude) * cos(declination) * cos(hourAngle)
        return elevationSine > sin(-0.833 * .pi / 180) ? .light : .dark
    }

}
