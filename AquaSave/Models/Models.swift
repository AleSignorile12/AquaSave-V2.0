import Foundation
import SwiftData

/// A physical AquaSave sensor clipped onto something that emits water.
@Model
final class Sensor {
    var name: String
    var location: String
    var categoryRawValue: String
    var installedAt: Date
    @Relationship(deleteRule: .cascade, inverse: \UsageEvent.sensor)
    var events: [UsageEvent] = []
    @Relationship(deleteRule: .cascade, inverse: \SensorOutage.sensor)
    var outages: [SensorOutage] = []

    /// The outage still going on, if the sensor isn't reporting right now.
    var currentOutage: SensorOutage? { outages.first { $0.end == nil } }

    init(name: String, location: String, category: DeviceCategory, installedAt: Date = .now) {
        self.name = name
        self.location = location
        self.categoryRawValue = category.rawValue
        self.installedAt = installedAt
    }

    var category: DeviceCategory {
        get { DeviceCategory(rawValue: categoryRawValue) ?? .other }
        set { categoryRawValue = newValue.rawValue }
    }
}

/// One flow reading: water that ran through a sensor, and how much of it the sensor judged wasted.
@Model
final class UsageEvent {
    var timestamp: Date
    var liters: Double
    var wastedLiters: Double
    var wasteKindRaw: String?
    var sensor: Sensor?

    init(timestamp: Date, liters: Double, wastedLiters: Double = 0, wasteKind: WasteKind? = nil) {
        self.timestamp = timestamp
        self.liters = liters
        self.wastedLiters = wastedLiters
        self.wasteKindRaw = wasteKind?.rawValue
    }

    var wasteKind: WasteKind? {
        guard wastedLiters > 0 else { return nil }
        // Readings saved before the current waste types have none, or an old one.
        return wasteKindRaw.flatMap(WasteKind.init(rawValue:)) ?? .leftRunning
    }
}

/// A stretch of time when a sensor stopped reporting. Days it touches earn no credits.
@Model
final class SensorOutage {
    var start: Date
    var end: Date?
    var sensor: Sensor?

    init(start: Date, end: Date? = nil) {
        self.start = start
        self.end = end
    }

    func overlaps(from dayStart: Date, to dayEnd: Date, now: Date = .now) -> Bool {
        start < dayEnd && (end ?? now) > dayStart
    }
}

enum DayStatus: String {
    case settled, calibrating, offline
}

/// A closed day in the credits ledger. Written once at midnight so later limit changes never rewrite history.
@Model
final class DayResult {
    @Attribute(.unique) var day: Date
    var usedLiters: Double
    var limitLiters: Double
    var credits: Int
    var metLimit: Bool
    var statusRaw: String = DayStatus.settled.rawValue
    /// Liters used below the usual day. Feeds tiers.
    var savedLiters: Double = 0
    /// The part of `credits` that came from the tier boost.
    var bonusCredits: Int = 0

    init(day: Date, usedLiters: Double, limitLiters: Double, credits: Int, metLimit: Bool,
         status: DayStatus = .settled, savedLiters: Double = 0, bonusCredits: Int = 0) {
        self.day = day
        self.usedLiters = usedLiters
        self.limitLiters = limitLiters
        self.credits = credits
        self.metLimit = metLimit
        self.statusRaw = status.rawValue
        self.savedLiters = savedLiters
        self.bonusCredits = bonusCredits
    }

    var status: DayStatus { DayStatus(rawValue: statusRaw) ?? .settled }

    /// Days settled before savings were recorded only kept their credits, which pay per 10 L saved.
    var saved: Double { savedLiters > 0 ? savedLiters : Double(credits - bonusCredits) * Credits.litersPerCredit }
}

@Model
final class Redemption {
    var date: Date
    var rewardID: String
    var title: String
    var cost: Int
    var code: String

    init(date: Date = .now, rewardID: String, title: String, cost: Int, code: String) {
        self.date = date
        self.rewardID = rewardID
        self.title = title
        self.cost = cost
        self.code = code
    }
}
