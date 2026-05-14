import Foundation

enum ChallengeEngine {

    static func todayChallenge(
        records: [WaterUsageRecord],
        hydration: [HydrationRecord],
        dailyGoal: Double,
        hydrationGoalML: Int
    ) -> DailyChallenge {

        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: .now) ?? 1
        let type = dayOfYear % 3

        let todayUsage = WaterAnalytics.sumLiters(on: .now, records: records)
        let todayHydration = HydrationAnalytics.sumML(on: .now, records: hydration)

        switch type {
        case 0:
            let target = max(dailyGoal * 0.8, 1)
            let progress = min(todayUsage / target, 1)
            let completed = todayUsage <= target && todayUsage > 0

            return DailyChallenge(
                id: "eco_under_80",
                title: "Eco Saver",
                subtitle: "Stay under \(Int(target))L today",
                systemImage: "leaf.fill",
                isCompleted: completed,
                progress: todayUsage > target ? 1 : progress
            )

        case 1:
            let target = max(hydrationGoalML, 1)
            let progress = min(Double(todayHydration) / Double(target), 1)
            let completed = todayHydration >= target

            return DailyChallenge(
                id: "hydration_goal",
                title: "Hydration Hero",
                subtitle: "Reach \(target) ml today",
                systemImage: "cup.and.saucer.fill",
                isCompleted: completed,
                progress: progress
            )

        default:
            let yesterday = WaterAnalytics.sumLiters(
                on: Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now,
                records: records
            )

            let baseline = max(yesterday, 1)
            let completed = todayUsage < yesterday && todayUsage > 0
            let progress = yesterday > 0 ? min(todayUsage / baseline, 1) : 0

            return DailyChallenge(
                id: "beat_yesterday",
                title: "Beat Yesterday",
                subtitle: yesterday > 0
                    ? "Use less than yesterday (\(Int(yesterday))L)"
                    : "Keep usage low today",
                systemImage: "arrow.down.circle.fill",
                isCompleted: completed,
                progress: progress
            )
        }
    }
}
