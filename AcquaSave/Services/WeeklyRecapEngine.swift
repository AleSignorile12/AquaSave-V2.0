import Foundation

struct WeeklyRecap {
    let averageUsage: Double
    let bestDayUsage: Double
    let worstDayUsage: Double
    let hydrationGoalReachedDays: Int
    let mostUsedDevice: String?
}

enum WeeklyRecapEngine {

    static func recap(
        records: [WaterUsageRecord],
        hydration: [HydrationRecord],
        hydrationGoalML: Int
    ) -> WeeklyRecap {

        let series = WaterAnalytics.lastNDaysSeries(days: 7, from: .now, records: records)
        let values = series.map(\.liters)

        let average = values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)
        let best = values.min() ?? 0
        let worst = values.max() ?? 0

        let hydrationDaysReached = hydrationGoalReachedDays(records: hydration, goalML: hydrationGoalML)
        let topDevice = mostUsedDeviceLast7Days(records: records)

        return WeeklyRecap(
            averageUsage: average,
            bestDayUsage: best,
            worstDayUsage: worst,
            hydrationGoalReachedDays: hydrationDaysReached,
            mostUsedDevice: topDevice
        )
    }

    private static func hydrationGoalReachedDays(records: [HydrationRecord], goalML: Int) -> Int {
        let start = Calendar.current.date(byAdding: .day, value: -6, to: Calendar.current.startOfDay(for: .now)) ?? .now

        let filtered = records.filter { $0.timestamp >= start }
        let grouped = Dictionary(grouping: filtered) { Calendar.current.startOfDay(for: $0.timestamp) }

        return grouped.values.filter { dayRecords in
            dayRecords.reduce(0) { $0 + $1.ml } >= goalML
        }.count
    }

    private static func mostUsedDeviceLast7Days(records: [WaterUsageRecord]) -> String? {
        let start = Calendar.current.date(byAdding: .day, value: -6, to: Calendar.current.startOfDay(for: .now)) ?? .now
        let filtered = records.filter { $0.timestamp >= start }

        let grouped = Dictionary(grouping: filtered) { $0.deviceName ?? "Unknown device" }

        return grouped.max { lhs, rhs in
            lhs.value.reduce(0) { $0 + $1.liters } < rhs.value.reduce(0) { $0 + $1.liters }
        }?.key
    }
}
