import SwiftUI

struct AchievementCardView: View {
    let achievement: AchievementDefinition
    let isUnlocked: Bool

    var body: some View {
        GlassCard {
            HStack(spacing: 12) {
                Image(systemName: achievement.systemImage)
                    .font(.title2)
                    .foregroundStyle(isUnlocked ? .green : .secondary)

                VStack(alignment: .leading, spacing: 4) {
                    Text(achievement.title)
                        .font(.headline)

                    Text(achievement.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: isUnlocked ? "checkmark.seal.fill" : "lock.fill")
                    .foregroundStyle(isUnlocked ? .green : .secondary)
            }
            .opacity(isUnlocked ? 1 : 0.65)
        }
    }
}
