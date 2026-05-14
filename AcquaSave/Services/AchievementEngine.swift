import Foundation

struct AchievementDefinition: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let systemImage: String
}

enum AchievementEngine {

    static let all: [AchievementDefinition] = [
        .init(id: "first_usage", title: "First Drop", subtitle: "Log your first water usage", systemImage: "drop.fill"),
        .init(id: "first_hydration", title: "Hydrated", subtitle: "Log your first drink", systemImage: "cup.and.saucer.fill"),
        .init(id: "under_goal_3", title: "Eco Start", subtitle: "Stay under goal for 3 days", systemImage: "leaf.fill"),
        .init(id: "under_goal_7", title: "Green Streak", subtitle: "Stay under goal for 7 days", systemImage: "flame.fill"),
        .init(id: "hydration_goal_3", title: "Hydration Hero", subtitle: "Reach hydration goal 3 times", systemImage: "figure.run"),
        .init(id: "device_count_3", title: "Connected Home", subtitle: "Add 3 smart devices", systemImage: "dot.radiowaves.left.and.right"),
        .init(id: "points_500", title: "Point Collector", subtitle: "Earn 500 total points", systemImage: "star.fill")
    ]

    static func unlockedIDs(
        records: [WaterUsageRecord],
        hydration: [HydrationRecord],
        devices: [SmartDevice],
        redemptions: [RewardRedemption],
        dailyGoal: Double,
        hydrationGoalML: Int
    ) -> Set<String> {

        var unlocked = Set<String>()

        if !records.isEmpty {
            unlocked.insert("first_usage")
        }

        if !hydration.isEmpty {
            unlocked.insert("first_hydration")
        }

        if WaterAnalytics.streakUnderGoal(dailyGoal: dailyGoal, records: records, includeToday: true) >= 3 {
            unlocked.insert("under_goal_3")
        }

        if WaterAnalytics.streakUnderGoal(dailyGoal: dailyGoal, records: records, includeToday: true) >= 7 {
            unlocked.insert("under_goal_7")
        }

        let hydrationDaysReached = hydrationGoalReachedDays(records: hydration, goalML: hydrationGoalML)
        if hydrationDaysReached >= 3 {
            unlocked.insert("hydration_goal_3")
        }

        if devices.count >= 3 {
            unlocked.insert("device_count_3")
        }

        let totalPoints = LevelEngine.totalEarnedPoints(records: records, dailyGoal: dailyGoal)
        if totalPoints >= 500 {
            unlocked.insert("points_500")
        }

        return unlocked
    }

    static func hydrationGoalReachedDays(records: [HydrationRecord], goalML: Int) -> Int {
        let grouped = Dictionary(grouping: records) { Calendar.current.startOfDay(for: $0.timestamp) }

        return grouped.values.filter { dayRecords in
            dayRecords.reduce(0) { $0 + $1.ml } >= goalML
        }.count
    }
}
