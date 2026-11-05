import SwiftUI

struct FrequencyBadge: View {
    @Localized private var localized
    let label: String
    var body: some View {
        Text(label)
            .font(.system(size: 12, weight: .bold, design: .monospaced))
            .foregroundStyle(.primary)
            .padding(.horizontal, 6).padding(.vertical, 3)
            .background(.primary.opacity(0.07), in: Capsule())
            .fixedSize()
            .accessibilityLabel(localized("სიხშირე: %@", String(describing: label)))
    }
}
