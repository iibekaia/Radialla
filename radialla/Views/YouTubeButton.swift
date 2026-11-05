import SwiftUI

struct YouTubeButton: View {
    let track: NowPlayingTrack

    var body: some View {
        if let url = track.youtubeSearchURL {
            Link(destination: url) {
                HStack(spacing: 6) {
                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: 18, weight: .medium))
                    Text("YouTube").font(.subheadline.weight(.medium))
                }
            }
            .buttonStyle(PlayerShortcutStyle())
            .accessibilityLabel("YouTube: \(track.searchText)")
        }
    }
}
