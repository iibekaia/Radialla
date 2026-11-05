import SwiftUI

struct InterfaceLanguagePicker: View {
    @Localized private var localized
    @AppStorage("manualLanguage") private var manualLanguage = "auto"
    @AppStorage("interfaceLanguage") private var interfaceLanguage = "en"

    private var effectiveLanguage: String {
        manualLanguage == "auto" ? interfaceLanguage : manualLanguage
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "globe")
                .accessibilityHidden(true)
            Picker(selection: Binding(get: { effectiveLanguage }, set: { manualLanguage = $0 })) {
                Text(verbatim: "English").tag("en")
                Text(verbatim: "ქართული").tag("ka")
                Text(verbatim: "Русский").tag("ru")
                Text(verbatim: "Українська").tag("uk")
                Text(verbatim: "简体中文").tag("zh-Hans")
                Text(verbatim: "한국어").tag("ko")
                Text(verbatim: "Հայերեն").tag("hy")
                Text(verbatim: "Türkçe").tag("tr")
            } label: {
                Text(localized("Language"))
            }
            .labelsHidden()
        }
    }
}
