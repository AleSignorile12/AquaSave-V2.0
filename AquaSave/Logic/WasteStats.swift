import SwiftUI
import SwiftData

/// The three kinds of waste a sensor can actually prove. Long showers and high flow are choices, not waste.
enum WasteKind: String, CaseIterable {
    case leak, hotWater, leftRunning

    var title: String {
        switch self {
        case .leak: "Leak"
        case .hotWater: "Warm-up water"
        case .leftRunning: "Left running"
        }
    }

    var detail: String {
        switch self {
        case .leak: "Water flowing when nothing should be running."
        case .hotWater: "Water down the drain while waiting for it to get hot."
        case .leftRunning: "A steady flow that went on far longer than normal use."
        }
    }

    var systemImage: String {
        switch self {
        case .leak: "drop.fill"
        case .hotWater: "thermometer.medium"
        case .leftRunning: "timer"
        }
    }

    var tint: Color {
        switch self {
        case .leak: .cyan
        case .hotWater: .pink
        case .leftRunning: .orange
        }
    }

    /// The concrete fix, for where it happened.
    func fix(for category: DeviceCategory) -> String {
        switch (self, category) {
        case (.leak, .toilet): "Replace the flapper or fill valve so the toilet stops running."
        case (.leak, .faucet): "A dripping tap usually needs a new washer or cartridge."
        case (.leak, .shower): "Replace the shower head washer or tighten the connection."
        case (.leak, _): "Check the hose, seals and connections."
        case (.hotWater, _): "Catch warm-up water in a jug for plants, or insulate the hot pipe."
        case (.leftRunning, .irrigation): "Put the sprinkler on a timer."
        case (.leftRunning, _): "Turn the tap off while brushing or scrubbing."
        }
    }
}

enum WasteStats {
    struct Slot: Identifiable {
        let hour: Int
        let kind: WasteKind
        let liters: Double
        var id: String { "\(hour)-\(kind.rawValue)" }
    }

    /// One fixture and one kind of waste, like "Kitchen Sink: leak".
    struct Source: Identifiable {
        let id: String
        let sensorName: String
        let location: String
        let category: DeviceCategory
        let kind: WasteKind
        let liters: Double

        var label: String { "\(sensorName): \(kind.title.lowercased())" }
    }

    struct SourceKey: Hashable {
        let sensor: PersistentIdentifier?
        let kind: WasteKind
    }

    /// Wasted liters per hour of the day and type. Readings from different days share an hour.
    static func byHour(_ readings: [(date: Date, kind: WasteKind, liters: Double)],
                       calendar: Calendar = .current) -> [Slot] {
        Dictionary(grouping: readings) { "\(calendar.component(.hour, from: $0.date))-\($0.kind.rawValue)" }
            .values
            .compactMap { group in
                group.first.map { Slot(hour: calendar.component(.hour, from: $0.date), kind: $0.kind, liters: group.sum(\.liters)) }
            }
            .sorted { ($0.hour, $0.kind.rawValue) < ($1.hour, $1.kind.rawValue) }
    }

    static func peakHour(_ slots: [Slot]) -> (hour: Int, liters: Double, topKind: WasteKind)? {
        let hours = Dictionary(grouping: slots, by: \.hour)
        guard let peak = hours.max(by: { $0.value.sum(\.liters) < $1.value.sum(\.liters) }),
              let top = peak.value.max(by: { $0.liters < $1.liters }) else { return nil }
        return (peak.key, peak.value.sum(\.liters), top.kind)
    }

    /// Today's date at `hour`, used to place any day's waste on a shared 24-hour axis.
    static func date(forHour hour: Int, calendar: Calendar = .current) -> Date {
        let day = calendar.startOfDay(for: .now)
        return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day) ?? day
    }

    #if DEBUG
    static func selfCheck() {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: .now)
        let at7 = calendar.date(byAdding: .hour, value: 7, to: day)!
        let yesterdayAt7 = calendar.date(byAdding: .day, value: -1, to: at7)!
        let at3 = calendar.date(byAdding: .hour, value: 3, to: day)!
        let slots = byHour([(at7, .hotWater, 2), (yesterdayAt7, .hotWater, 3), (at7, .leak, 1), (at3, .leak, 4)])
        assert(slots.count == 3, "same hour and type merge across days")
        let peak = peakHour(slots)
        assert(peak?.hour == 7 && peak?.liters == 6 && peak?.topKind == .hotWater, "peak sums every type in the hour")
    }
    #endif
}

extension Sequence where Element == UsageEvent {
    var wasteSlots: [WasteStats.Slot] {
        WasteStats.byHour(compactMap { event in
            event.wasteKind.map { (event.timestamp, $0, event.wastedLiters) }
        })
    }

    /// Wasted liters per fixture and kind, biggest first.
    var wasteSources: [WasteStats.Source] {
        let wasted = compactMap { event in event.wasteKind.map { (event, $0) } }
        return Dictionary(grouping: wasted) { WasteStats.SourceKey(sensor: $0.0.sensor?.persistentModelID, kind: $0.1) }
            .compactMap { key, group -> WasteStats.Source? in
                guard let sensor = group.first?.0.sensor else { return nil }
                return WasteStats.Source(id: "\(sensor.persistentModelID)-\(key.kind.rawValue)",
                                         sensorName: sensor.name,
                                         location: sensor.location,
                                         category: sensor.category,
                                         kind: key.kind,
                                         liters: group.sum { $0.0.wastedLiters })
            }
            .sorted { $0.liters > $1.liters }
    }
}
