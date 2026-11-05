import SwiftUI

struct PlayerTransportControls: View {
    @Localized private var localized
    @EnvironmentObject private var store: RadioStore
    let canSkip: Bool
    var playButtonSize: CGFloat = 44

    var body: some View {
        HStack(spacing: playButtonSize > 44 ? 20 : 8) {
            skipButton(forward: false)
            Button { store.playbackRequested ? store.pause() : store.resume() } label: {
                Image(systemName: store.playbackRequested ? "pause.fill" : "play.fill")
                    .font(.title2)
                    .frame(width: playButtonSize, height: playButtonSize)
                    .background(Color.radioAccent, in: Circle())
                    .foregroundStyle(.black)
            }
            .accessibilityLabel(localized(store.playbackRequested ? "პაუზა" : "დაკვრა"))
            skipButton(forward: true)
        }
        .buttonStyle(.plain)
    }

    private func skipButton(forward: Bool) -> some View {
        Button { store.skipStation(forward: forward) } label: {
            Image(systemName: forward ? "forward.end.fill" : "backward.end.fill")
                .font(playButtonSize > 44 ? .title2 : .title3)
                .frame(width: playButtonSize > 44 ? 52 : 44, height: playButtonSize > 44 ? 52 : 44)
                .background {
                    if playButtonSize > 44 {
                        Circle()
                            .fill(Color.primary.opacity(0.06))
                            .overlay {
                                Circle().strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
                            }
                    }
                }
                .contentShape(Circle())
        }
        .disabled(!canSkip)
        .accessibilityLabel(localized(forward ? "შემდეგი რადიოსადგური" : "წინა რადიოსადგური"))
    }
}
