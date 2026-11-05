import SwiftUI

struct MenuCountBadge: View {
    let count: Int

    var body: some View {
        Text(count, format: .number)
            .font(.caption.weight(.semibold).monospacedDigit())
            .foregroundStyle(.primary.opacity(0.8))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .frame(minWidth: 30)
            .background(.primary.opacity(0.06), in: Capsule())
            .overlay(Capsule().strokeBorder(.primary.opacity(0.08), lineWidth: 1))
            .fixedSize()
            .accessibilityHidden(true)
    }
}
