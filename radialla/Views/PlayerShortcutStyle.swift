import SwiftUI

struct PlayerShortcutStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.primary.opacity(0.85))
            .padding(.horizontal, 12)
            .frame(minWidth: 44, minHeight: 44)
            .background(.primary.opacity(configuration.isPressed ? 0.1 : 0.04), in: Capsule())
            .overlay(Capsule().strokeBorder(.primary.opacity(0.12), lineWidth: 1))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}
