import SwiftUI

struct ExplorerDrawer: View {
    @Binding var isPresented: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .top) {
            if isPresented {
                ExplorerMenu(close: { isPresented = false })
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.radioBackground.ignoresSafeArea())
                    .transition(reduceMotion ? .opacity : .move(edge: .top))
                    .accessibilityAddTraits(.isModal)
                    .accessibilityAction(.escape) { isPresented = false }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: isPresented)
        .allowsHitTesting(isPresented)
    }
}
