import SwiftUI

struct ExplorerHeader: View {
    @Localized private var localized
    @EnvironmentObject private var store: RadioStore
    @Binding var showsMenu: Bool

    var body: some View {
        HStack {
            Image("RadioLogo").resizable().scaledToFill()
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 2) {
                Text("Radialla").font(.title2.bold()).lineLimit(1).minimumScaleFactor(0.7)
                if store.isController {
                    Label(localized("Controller mode"), systemImage: "appletvremote.gen1")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
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
