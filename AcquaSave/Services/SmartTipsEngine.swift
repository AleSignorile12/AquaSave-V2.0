import Foundation

enum SmartTipsEngine {

    static func tip(
        records: [WaterUsageRecord],
        todayUsage: Double,
        dailyGoal: Double,
        todayHydrationML: Int,
        hydrationGoalML: Int
    ) -> String {

        if todayUsage > dailyGoal {
            return "You’re above your daily water goal — shower and faucet use might be worth checking."
        }

        if todayUsage > dailyGoal * 0.8 {
            return "You’re getting close to your water limit today. A shorter shower could help."
        }

        if hydrationGoalML > 0 && Double(todayHydrationML) < Double(hydrationGoalML) * 0.4 {
            return "Hydration is still low today — a glass of water now would help."
        }

        if let device = mostUsedDeviceToday(records: records) {
            return "\(device) is leading today’s usage — that’s your best saving opportunity."
        }

        return "You’re doing well today. Keep the same pace and stay consistent."
    }

    private static func mostUsedDeviceToday(records: [WaterUsageRecord]) -> String? {
        let start = Calendar.current.startOfDay(for: .now)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? .now

        let filtered = records.filter { $0.timestamp >= start && $0.timestamp < end }
        let grouped = Dictionary(grouping: filtered) { $0.deviceName ?? "Unknown device" }

        return grouped.max { lhs, rhs in
            lhs.value.reduce(0) { $0 + $1.liters } < rhs.value.reduce(0) { $0 + $1.liters }
        }?.key
    }
}
