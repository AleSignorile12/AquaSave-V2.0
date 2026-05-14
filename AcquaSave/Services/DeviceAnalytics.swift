import Foundation

struct DeviceSummary: Identifiable {
    let id = UUID()
    let name: String
    let location: String
    let totalLiters: Double
    let usageCount: Int
    let averageLitersPerUse: Double
    let lastUsedAt: Date?
    let shareOfTotal: Double

    var efficiencyLabel: String {
        switch averageLitersPerUse {
        case 0..<4: return "Efficient"
        case 4..<10: return "Average"
        default: return "High usage"
        }
    }

    var tip: String {
        switch efficiencyLabel {
        case "Efficient":
            return "Nice — this device is staying efficient."
        case "Average":
            return "This device is okay, but could be optimized."
        default:
            return "This device is your biggest saving opportunity."
        }
    }
}

enum DeviceAnalytics {

    static func summaries(devices: [SmartDevice], records: [WaterUsageRecord]) -> [DeviceSummary] {
        let totalAll = records.reduce(0) { $0 + $1.liters }

        return devices.map { device in
            let matching = records.filter { ($0.deviceName ?? "") == device.name }
            let total = matching.reduce(0) { $0 + $1.liters }
            let count = matching.count
            let avg = count > 0 ? total / Double(count) : 0
            let last = matching.sorted(by: { $0.timestamp > $1.timestamp }).first?.timestamp
            let share = totalAll > 0 ? total / totalAll : 0

            return DeviceSummary(
                name: device.name,
                location: device.location,
                totalLiters: total,
                usageCount: count,
                averageLitersPerUse: avg,
                lastUsedAt: last,
                shareOfTotal: share
            )
        }
        .sorted { $0.totalLiters > $1.totalLiters }
    }
}
