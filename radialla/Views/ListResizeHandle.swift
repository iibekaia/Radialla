import SwiftUI

struct ListResizeHandle: View {
    @Localized private var localized
    @Binding var height: CGFloat
    @Binding var isResizing: Bool
    let maximumHeight: CGFloat
    let onResizeEnded: () -> Void
    @State private var startingHeight: CGFloat?
    @State private var resizeGeneration = 0

    var body: some View {
        Capsule().fill(.secondary.opacity(0.5)).frame(width: 42, height: 5)
            .frame(maxWidth: .infinity).frame(height: 28)
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 3, coordinateSpace: .global)
                .onChanged { value in
                    if startingHeight == nil {
                        resizeGeneration += 1
                        startingHeight = height
                    }
                    isResizing = true
                    height = min(maximumHeight, max(155, (startingHeight ?? height) - value.translation.height))
                }
                .onEnded { value in
                    let projectedHeight = (startingHeight ?? height) - value.predictedEndTranslation.height
                    let expanded = projectedHeight > (155 + maximumHeight) / 2
                    startingHeight = nil
                    settle(expanded: expanded)
                })
            .accessibilityLabel(localized("Resize station list"))
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: settle(expanded: true)
                case .decrement: settle(expanded: false)
                @unknown default: break
                }
            }
    }

    private func settle(expanded: Bool) {
        resizeGeneration += 1
        let generation = resizeGeneration
        isResizing = true
        withAnimation(.snappy(duration: 0.3)) {
            height = expanded ? maximumHeight : 155
        } completion: {
            guard generation == resizeGeneration else { return }
            isResizing = false
            onResizeEnded()
        }
    }
}
