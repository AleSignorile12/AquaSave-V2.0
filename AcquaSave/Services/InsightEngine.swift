import Foundation

enum InsightsEngine {

    static func usageDifferenceVsYesterday(records: [WaterUsageRecord]) -> Double {
        let today = WaterAnalytics.sumLiters(on: .now, records: records)
        let yesterday = WaterAnalytics.sumLiters(
            on: Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now,
            records: records
        )
        return today - yesterday
    }

    static func mostUsedDeviceToday(records: [WaterUsageRecord]) -> String? {
        let start = Calendar.current.startOfDay(for: .now)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? .now

        let today = records.filter { $0.timestamp >= start && $0.timestamp < end }

        let grouped = Dictionary(grouping: today) { $0.deviceName ?? "Unknown device" }
        let best = grouped.max { lhs, rhs in
            lhs.value.reduce(0) { $0 + $1.liters } < rhs.value.reduce(0) { $0 + $1.liters }
        }

        return best?.key
    }

    static func hydrationStatus(todayHydrationML: Int, hydrationGoalML: Int) -> String {
        guard hydrationGoalML > 0 else { return "Set a hydration goal to track your progress." }

        let ratio = Double(todayHydrationML) / Double(hydrationGoalML)

        switch ratio {
        case 1...:
            return "Nice — you already reached your hydration goal today."
        case 0.75..<1:
            return "You’re close to your hydration goal."
        case 0.4..<0.75:
            return "Hydration is moving, but you could drink a bit more."
        default:
            return "Hydration is still low today."
        }
    }

    static func dailyInsight(
        records: [WaterUsageRecord],
        todayUsage: Double,
        dailyGoal: Double,
        todayHydrationML: Int,
        hydrationGoalML: Int
    ) -> String {

        let diff = usageDifferenceVsYesterday(records: records)

        if todayUsage <= dailyGoal * 0.8 && todayUsage > 0 {
            return "Great job — you’re comfortably under your daily water goal."
        }

        if diff < 0 {
            return "Nice improvement — you used \(Int(abs(diff)))L less than yesterday."
        }

        if let device = mostUsedDeviceToday(records: records) {
            return "\(device) is your most impactful device today."
        }

        return hydrationStatus(todayHydrationML: todayHydrationML, hydrationGoalML: hydrationGoalML)
    }
}
