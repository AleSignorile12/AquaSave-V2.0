import Foundation
import SwiftData

/// Simulated sensor readings until real hardware exists.
enum DemoData {
    /// 14 measuring days of a typical home, then about two months of it using less.
    static func seed(_ context: ModelContext, household: Int, presets: [SensorPreset] = SensorPreset.defaults,
                     days: Int = 75, now: Date = .now) {
        let cal = Calendar.current
        let start = cal.startOfDay(for: now)
        let installed = cal.date(byAdding: .day, value: -days, to: start) ?? start
        let sensors = (presets.isEmpty ? SensorPreset.defaults : presets).map {
            Sensor(name: $0.name, location: $0.location, category: $0.category, installedAt: installed)
        }
        sensors.forEach(context.insert)

        let people = Double(max(household, 1))
        var measuredTotal = 0.0
        for offset in (0...days).reversed() {
            guard let day = cal.date(byAdding: .day, value: -offset, to: start) else { continue }
            let target: Double
            if offset > days - Credits.calibrationDays {
                target = people * .random(in: 125...160)
                measuredTotal += target
            } else {
                // Good days stay under even the tightest limit; the last few are good so there's a streak.
                let baseline = min(measuredTotal / Double(Credits.calibrationDays), Credits.cap(household: household))
                let good = offset <= 5 || Double.random(in: 0...1) < 0.8
                target = baseline * (good ? .random(in: 0.66...0.76) : .random(in: 0.9...1.05))
            }
            let drafts = sensors.flatMap { s in naturalDay(s.category, household: household).map { (s, $0) } }
            let scale = target / max(drafts.sum { $0.1.liters }, 1)

            for (sensor, draft) in drafts {
                let time = day.addingTimeInterval(draft.secondsIntoDay)
                guard time <= now else { continue }
                let event = UsageEvent(timestamp: time, liters: draft.liters * scale,
                                       wastedLiters: draft.wasted * scale, wasteKind: draft.kind)
                context.insert(event)
                event.sensor = sensor
            }
        }

        // One past outage, so the ledger shows a day that earned nothing because a sensor was down.
        if let outageDay = cal.date(byAdding: .day, value: -9, to: start) {
            let outage = SensorOutage(start: outageDay.addingTimeInterval(10 * 3600), end: outageDay.addingTimeInterval(13 * 3600))
            context.insert(outage)
            outage.sensor = sensors[min(2, sensors.count - 1)]
        }
        try? context.save()
    }

    /// Fresh readings for the sensors the home has now.
    static func reset(_ context: ModelContext, household: Int) {
        let current = (try? context.fetch(FetchDescriptor<Sensor>())) ?? []
        let presets = current.map { SensorPreset(id: $0.name, name: $0.name, location: $0.location, category: $0.category) }
        // One by one so the cascade removes each sensor's readings and outages: a batch delete can't nullify those links.
        for sensor in current { context.delete(sensor) }
        try? context.delete(model: DayResult.self)
        try? context.delete(model: Redemption.self)
        try? context.save()
        seed(context, household: household, presets: presets)
        try? Ledger.settle(context, household: household)
    }

    private struct Draft {
        var secondsIntoDay: TimeInterval
        var liters: Double
        var wasted: Double
        var kind: WasteKind? = nil
    }

    /// A plausible day of readings for one fixture, before scaling to the day's target.
    private static func naturalDay(_ category: DeviceCategory, household n: Int) -> [Draft] {
        func at(_ hours: ClosedRange<Double>) -> TimeInterval { .random(in: hours) * 3600 }
        func maybe(_ chance: Double, _ liters: ClosedRange<Double>) -> Double {
            Double.random(in: 0...1) < chance ? .random(in: liters) : 0
        }
        func use(_ time: TimeInterval, liters: Double) -> Draft {
            Draft(secondsIntoDay: time, liters: liters, wasted: 0)
        }
        /// Water that did nothing useful: a drip, a warm-up, or a tap nobody was using.
        func lost(_ time: TimeInterval, liters: Double, _ kind: WasteKind) -> [Draft] {
            liters > 0 ? [Draft(secondsIntoDay: time, liters: liters, wasted: liters, kind: kind)] : []
        }

        switch category {
        case .shower:
            return (0..<n).flatMap { _ -> [Draft] in
                let start = at(Bool.random() ? 6.5...8.5 : 19...22.5)
                return [use(start, liters: .random(in: 30...68))] + lost(start - 60, liters: .random(in: 2...6), .hotWater)
            }
        case .faucet:
            return (0..<(7 * n)).map { _ in use(at(6.5...23), liters: .random(in: 0.4...3.5)) }
                + lost(at(7...21), liters: maybe(0.6, 1...3), .hotWater)
                + lost(at(6.5...23), liters: maybe(0.15, 2...5), .leftRunning)
                + lost(at(1...5), liters: maybe(0.35, 0.3...1.5), .leak)
        case .toilet:
            return (0..<(5 * n)).map { _ in use(at(6...23.5), liters: .random(in: 3...6)) }
                + lost(at(1...5), liters: maybe(0.3, 4...12), .leak)
        case .washingMachine:
            return Bool.random() ? [use(at(9...20), liters: .random(in: 45...60))] : []
        case .dishwasher:
            return Bool.random() ? [use(at(20...22.5), liters: .random(in: 10...14))] : []
        case .irrigation:
            return (Bool.random() ? [use(at(6...9), liters: .random(in: 40...90))] : [])
                + lost(at(10...18), liters: maybe(0.1, 10...30), .leftRunning)
        case .other:
            return (0..<3).map { _ in use(at(8...22), liters: .random(in: 1...10)) }
        }
    }
}
