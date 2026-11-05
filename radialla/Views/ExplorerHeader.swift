import SwiftUI

struct ExplorerHeader: View {
    @Localized private var localized
    @Binding var showsMenu: Bool

    var body: some View {
        HStack {
            Image("RadioLogo").resizable().scaledToFill()
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            Text("Radialla").font(.title2.bold()).lineLimit(1).minimumScaleFactor(0.7)
            Spacer()
            Button { showsMenu = true } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.title3).frame(width: 44, height: 44)
            }
            .accessibilityLabel(localized("Menu"))
        }
        .font(.system(.body, design: .rounded))
        .buttonStyle(.plain)
        .padding(.horizontal, 20).padding(.vertical, 14)
    }
}
