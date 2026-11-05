import SwiftUI

struct ExpandedPlayerBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Color.radioBackground
            .overlay {
                LinearGradient(stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .clear, location: 0.28),
                    .init(color: Color.radioAccent.opacity(0.07), location: 0.43),
                    .init(color: Color.radioAccent.opacity(0.24), location: 0.67),
                    .init(color: Color.radioAccent.opacity(colorScheme == .dark ? 0.78 : 0.48), location: 1)
                ], startPoint: .top, endPoint: .bottom)
            }
            .ignoresSafeArea()
    }
}
