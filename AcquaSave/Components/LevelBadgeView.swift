import SwiftUI

struct LevelBadgeView: View {
    let info: LevelInfo

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("User Level")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 8) {
                            Image(systemName: info.level.systemImage)
                                .foregroundStyle(.green)

                            Text(info.level.rawValue)
                                .font(.title2.bold())
                        }
                    }

                    Spacer()

                    Text("\(info.currentPoints) pt")
                        .font(.headline)
                        .monospacedDigit()
                }

                if let next = info.nextLevelName {
                    ProgressView(value: info.progressToNext)
                        .tint(.green)

                    Text("\(max(info.pointsNeededForNextLevel - info.pointsIntoCurrentLevel, 0)) pt to \(next)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Max level reached")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
