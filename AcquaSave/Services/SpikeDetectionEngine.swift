import Foundation

struct SpikeAlert {
    let title: String
    let subtitle: String
}

enum SpikeDetectionEngine {

    static func detect(records: [WaterUsageRecord]) -> SpikeAlert? {
        let today = WaterAnalytics.sumLiters(on: .now, records: records)
        let last7 = WaterAnalytics.lastNDaysSeries(days: 7, from: .now, records: records).map(\.liters)

        guard !last7.isEmpty else { return nil }

        let average = last7.reduce(0, +) / Double(last7.count)

        if average > 0 && today > average * 1.7 {
            return SpikeAlert(
                title: "Unusual water spike",
                subtitle: "Today’s usage is much higher than your recent average."
            )
        }

        if let device = mostUsedDeviceToday(records: records),
           let deviceLiters = litersForDeviceToday(device, records: records),
           today > 0,
           deviceLiters / today > 0.6 {
            return SpikeAlert(
                title: "Device concentration detected",
                subtitle: "\(device) is responsible for most of today’s usage."
            )
        }

        return nil
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

    private static func litersForDeviceToday(_ device: String, records: [WaterUsageRecord]) -> Double? {
        let start = Calendar.current.startOfDay(for: .now)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? .now

        let filtered = records.filter {
            $0.timestamp >= start &&
            $0.timestamp < end &&
            ($0.deviceName ?? "Unknown device") == device
        }

        guard !filtered.isEmpty else { return nil }
        return filtered.reduce(0) { $0 + $1.liters }
    }
}
