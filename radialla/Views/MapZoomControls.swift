import SwiftUI

struct MapZoomControls: View {
    @Localized private var localized
    let zoomIn: () -> Void
    let zoomOut: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: zoomIn) {
                Image(systemName: "plus").frame(width: 44, height: 44)
            }.accessibilityLabel(localized("Zoom in"))
            Divider().frame(width: 28)
            Button(action: zoomOut) {
                Image(systemName: "minus").frame(width: 44, height: 44)
            }.accessibilityLabel(localized("Zoom out"))
        }
        .font(.title3.weight(.semibold))
        .buttonStyle(.plain)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
