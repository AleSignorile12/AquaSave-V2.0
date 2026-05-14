import SwiftUI

struct WeeklyRecapCardView: View {
    let recap: WeeklyRecap

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Weekly Recap")
                    .font(.headline)

                HStack(spacing: 12) {
                    metric("Avg/day", "\(Int(recap.averageUsage)) L")
                    metric("Best day", "\(Int(recap.bestDayUsage)) L")
                    metric("Worst day", "\(Int(recap.worstDayUsage)) L")
                }

                Text("Hydration goal reached \(recap.hydrationGoalReachedDays) times this week")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let device = recap.mostUsedDevice {
                    Text("Most used device: \(device)")
                        .font(.subheadline)
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
