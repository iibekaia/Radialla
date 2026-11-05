import SwiftUI

struct RadioSheetStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .top, spacing: 0) {
                Capsule()
                    .fill(.secondary.opacity(0.4))
                    .frame(width: 36, height: 5)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)
                    .padding(.bottom, 12)
                    .accessibilityHidden(true)
                    .allowsHitTesting(false)
            }
            .presentationDetents([.fraction(0.85)])
            .presentationDragIndicator(.hidden)
            .presentationBackground(Color.radioBackground)
    }
}
