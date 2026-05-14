import SwiftUI

struct GoalsSummaryCardView: View {
    let usageGoal: Double
    let hydrationGoal: Int
    let targetStreak: Int
    let weeklyPointsGoal: Int

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Your Goals")
                    .font(.headline)

                HStack(spacing: 12) {
                    metric("Usage", "\(Int(usageGoal)) L")
                    metric("Hydration", "\(hydrationGoal) ml")
                }

                HStack(spacing: 12) {
                    metric("Streak", "\(targetStreak) d")
                    metric("Weekly pts", "\(weeklyPointsGoal)")
                }
            }
        }
    }

    @ViewBuilder
    private func metric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.headline)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
