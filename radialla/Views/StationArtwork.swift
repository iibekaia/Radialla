import SwiftUI

struct StationArtwork: View {
    @Localized private var localized
    let station: Station

    var body: some View {
        Group {
            if let logoURL = station.logoURL {
                AsyncImage(url: logoURL) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFit()
                    } else if phase.error == nil {
                        ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        Image("RadioLogo").resizable().scaledToFit()
                    }
                }
                .id(logoURL)
            } else {
                Image("RadioLogo").resizable().scaledToFit()
            }
        }
        .accessibilityLabel(localized("%@ — ლოგო", station.name))
    }
}
