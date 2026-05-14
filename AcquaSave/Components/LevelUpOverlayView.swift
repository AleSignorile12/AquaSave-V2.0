import SwiftUI

struct LevelUpOverlayView: View {
    let levelInfo: LevelInfo

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: levelInfo.level.systemImage)
                .font(.system(size: 42))
                .foregroundStyle(.green)

            Text("Level Up!")
                .font(.title.bold())

            Text("You reached \(levelInfo.level.rawValue)")
                .font(.headline)

            Text("\(levelInfo.currentPoints) pt")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(28)
        .frame(maxWidth: 280)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28))
        .shadow(radius: 18, y: 8)
    }
}
