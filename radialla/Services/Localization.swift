import Foundation
import SwiftUI

@propertyWrapper
struct Localized: DynamicProperty {
    @Environment(\.locale) private var locale

    var wrappedValue: LocalizedStrings { LocalizedStrings(language: locale.identifier) }
}

struct LocalizedStrings {
    let language: String

    func callAsFunction(_ key: String, _ arguments: String...) -> String {
        formatLocalized(key, arguments: arguments, language: language)
    }
}

enum InterfaceLanguage {
    static var current: String {
        let manual = UserDefaults.standard.string(forKey: "manualLanguage") ?? "auto"
        return manual == "auto" ? UserDefaults.standard.string(forKey: "interfaceLanguage") ?? "en" : manual
    }
}

func localized(_ key: String, _ arguments: String...) -> String {
    formatLocalized(key, arguments: arguments)
}

struct RadioMessage {
    let key: String
    let arguments: [String]

    init(_ key: String, _ arguments: String...) {
        self.key = key
        self.arguments = arguments
    }

    var text: String { formatLocalized(key, arguments: arguments) }
}

private func formatLocalized(_ key: String, arguments: [String], language: String = InterfaceLanguage.current) -> String {
    let path = Bundle.main.path(forResource: language, ofType: "lproj")
    let bundle = path.flatMap(Bundle.init(path:)) ?? .main
    let format = bundle.localizedString(forKey: key, value: nil, table: nil)
    return String(format: format, locale: Locale(identifier: language), arguments: arguments.map { $0 as CVarArg })
}
