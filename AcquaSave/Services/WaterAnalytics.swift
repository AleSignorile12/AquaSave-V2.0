import Foundation

struct WaterAnalytics {

    static func startOfDay(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    static func sumLiters(on day: Date, records: [WaterUsageRecord]) -> Double {
        let start = startOfDay(day)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? Date()
        return records
            .filter { $0.timestamp >= start && $0.timestamp < end }
            .reduce(0) { $0 + $1.liters }
    }

    static func lastNDaysSeries(days: Int, from anchor: Date = Date(), records: [WaterUsageRecord]) -> [(day: Date, liters: Double)] {
        let cal = Calendar.current
        let anchorDay = startOfDay(anchor)

        return (0..<days).reversed().map { offset in
            let d = cal.date(byAdding: .day, value: -offset, to: anchorDay) ?? anchorDay
            return (day: d, liters: sumLiters(on: d, records: records))
        }
    }

    static func streakUnderGoal(dailyGoal: Double, records: [WaterUsageRecord], includeToday: Bool = true) -> Int {
        guard dailyGoal > 0 else { return 0 }
        guard !records.isEmpty else { return 0 }  // 🔒 niente dati = niente streak

        let cal = Calendar.current
        let today = startOfDay(Date())

        // 🔒 Non andare prima del primo giorno in cui hai dati (evita loop infinito)
        let earliestTimestamp = records.map(\.timestamp).min()!
        let earliestDay = startOfDay(earliestTimestamp)

        var streak = 0
        var cursor = includeToday ? today : (cal.date(byAdding: .day, value: -1, to: today) ?? today)

        // 🔒 Cap “hard” extra (paracadute)
        let hardCapDays = 3650

        while cursor >= earliestDay && streak < hardCapDays {
            let liters = sumLiters(on: cursor, records: records)

            // Se vuoi che i giorni SENZA dati interrompano lo streak, sblocca questa riga:
            if liters == 0 && !records.contains(where: { startOfDay($0.timestamp) == cursor }) { break }

            if liters <= dailyGoal {
                streak += 1
            } else {
                break
            }

            guard let prev = cal.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }

        return streak
    }

    static func dailyPoints(dailyGoal: Double, todayUsage: Double) -> Int {
        guard dailyGoal > 0 else { return 0 }
        let diff = max(dailyGoal - todayUsage, 0)
        return Int(diff * 2)
    }
}
