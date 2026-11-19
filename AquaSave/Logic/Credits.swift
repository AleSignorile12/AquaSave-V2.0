import Foundation
import SwiftData

/// How a home's daily limit is set and what saving water pays.
///
/// The first 14 days measure the home's usual day (its baseline). The limit then starts 15% below
/// that and tightens 5% a month toward 110 L per person. Credits pay for every liter saved against
/// the baseline, so they follow real savings instead of rewarding a day that only just squeaks under.
enum Credits {
    /// UK Building Regulations Part G optional standard for efficient new homes.
    static let targetPerPerson = 110.0
    /// The most-cited European household average. Caps the baseline, so using extra water
    /// during the measuring fortnight can't buy an easy limit or extra credits.
    static let capPerPerson = 144.0
    static let calibrationDays = 14
    static let startBelowBaseline = 0.85
    static let monthlyStep = 0.95
    /// 1 credit (worth 1 cent) per 10 L saved: €1 per m³, about half what the water costs.
    static let litersPerCredit = 10.0

    static func target(household: Int) -> Double { targetPerPerson * people(household) }
    static func cap(household: Int) -> Double { capPerPerson * people(household) }

    static func effectiveBaseline(_ measured: Double, household: Int) -> Double {
        min(measured, cap(household: household))
    }

    static func limit(baseline: Double, household: Int, monthsSinceCalibration: Int) -> Double {
        let base = effectiveBaseline(baseline, household: household)
        let stepped = base * startBelowBaseline * pow(monthlyStep, Double(max(monthsSinceCalibration, 0)))
        // Never below the target, and never below what an already-efficient home uses today.
        return max(stepped, min(target(household: household), base))
    }

    /// Liters used below the baseline, never negative.
    static func saved(used: Double, baseline: Double, household: Int) -> Double {
        max(0, effectiveBaseline(baseline, household: household) - used)
    }

    /// Credits for a day: 1 per 10 L used below the baseline, plus the tier's boost on those liters.
    static func earned(used: Double, baseline: Double, household: Int, boost: Double = 0) -> Int {
        Int(saved(used: used, baseline: baseline, household: household) * (1 + boost) / litersPerCredit)
    }

    private static func people(_ household: Int) -> Double { Double(max(household, 1)) }

    #if DEBUG
    static func selfCheck() {
        func near(_ a: Double, _ b: Double) -> Bool { abs(a - b) < 0.01 }
        assert(near(limit(baseline: 300, household: 2, monthsSinceCalibration: 0), 244.8), "15% under the capped baseline (288)")
        assert(near(limit(baseline: 300, household: 2, monthsSinceCalibration: 6), 220), "tightens, but stops at the target")
        assert(near(limit(baseline: 180, household: 2, monthsSinceCalibration: 0), 180), "an efficient home keeps its own level")
        assert(earned(used: 250, baseline: 300, household: 2) == 3, "saved against the capped baseline")
        assert(earned(used: 320, baseline: 300, household: 2) == 0, "never negative")

        let day = Calendar.current.startOfDay(for: .now)
        let days = (0..<14).map { (day: Calendar.current.date(byAdding: .day, value: $0 - 20, to: day)!, used: 280.0) }
        let measuring = Ledger.plan(Array(days.prefix(5)), household: 2)
        assert(measuring.baseline == nil && measuring.calibrationDay == 6, "still measuring")
        let settled = Ledger.plan(days, household: 2)
        assert(settled.baseline == 280 && near(settled.limit, 238), "baseline is the measured average")
    }
    #endif
}

/// Where a home stands today: still measuring its usual day, or settled with a baseline and a limit.
struct HomePlan {
    let baseline: Double?
    /// 1...14 while measuring.
    let calibrationDay: Int?
    let limit: Double

    var isCalibrating: Bool { baseline == nil }
    var daysUntilCredits: Int { Credits.calibrationDays + 1 - (calibrationDay ?? Credits.calibrationDays + 1) }
}

/// Settles finished days into `DayResult`s and answers plan, balance and streak questions.
enum Ledger {
    /// `history` is the settled days, oldest first.
    static func plan(_ history: [(day: Date, used: Double)], household: Int, on date: Date = .now) -> HomePlan {
        guard history.count >= Credits.calibrationDays else {
            return HomePlan(baseline: nil, calibrationDay: history.count + 1, limit: Credits.cap(household: household))
        }
        let measured = history.prefix(Credits.calibrationDays).map(\.used).filter { $0 > 0 }
        let baseline = measured.isEmpty ? Credits.cap(household: household) : measured.reduce(0, +) / Double(measured.count)
        let end = history[Credits.calibrationDays - 1].day
        let days = Calendar.current.dateComponents([.day], from: end, to: date).day ?? 0
        return HomePlan(baseline: baseline, calibrationDay: nil,
                        limit: Credits.limit(baseline: baseline, household: household, monthsSinceCalibration: days / 30))
    }

    static func plan(_ results: [DayResult], household: Int, on date: Date = .now) -> HomePlan {
        plan(results.map { (day: $0.day, used: $0.usedLiters) }, household: household, on: date)
    }

    static func settle(_ context: ModelContext, household: Int, now: Date = .now) throws {
        let cal = Calendar.current
        let today = cal.startOfDay(for: now)
        let settled = try context.fetch(FetchDescriptor<DayResult>(sortBy: [SortDescriptor(\.day)]))
        let events = try context.fetch(FetchDescriptor<UsageEvent>(predicate: #Predicate { $0.timestamp < today }))
        guard let firstReading = events.map(\.timestamp).min() else { return }
        let outages = try context.fetch(FetchDescriptor<SensorOutage>())

        let totals = Dictionary(grouping: events) { cal.startOfDay(for: $0.timestamp) }
            .mapValues { $0.sum(\.liters) }
        var history = settled.map { (day: $0.day, used: $0.usedLiters) }
        var day = settled.last.flatMap { cal.date(byAdding: .day, value: 1, to: $0.day) } ?? cal.startOfDay(for: firstReading)
        // Tier as of each day, from the days before it, so a boost never pays for the day that earned it.
        var savedSoFar = settled.sum(\.saved)
        var run = streak(settled)
        var best = bestStreak(settled)

        while day < today {
            guard let next = cal.date(byAdding: .day, value: 1, to: day) else { break }
            let used = totals[day] ?? 0
            let plan = plan(history, household: household, on: day)
            let result: DayResult
            if let baseline = plan.baseline {
                if outages.contains(where: { $0.overlaps(from: day, to: next, now: now) }) {
                    // A sensor that isn't reporting makes a day look thriftier than it was.
                    result = DayResult(day: day, usedLiters: used, limitLiters: plan.limit, credits: 0, metLimit: false, status: .offline)
                } else if used > 0 {
                    let tier = Tier.reached(saved: savedSoFar, bestStreak: best)
                    let base = Credits.earned(used: used, baseline: baseline, household: household)
                    let credits = Credits.earned(used: used, baseline: baseline, household: household, boost: tier.creditBoost)
                    result = DayResult(day: day, usedLiters: used, limitLiters: plan.limit, credits: credits,
                                       metLimit: used <= plan.limit,
                                       savedLiters: Credits.saved(used: used, baseline: baseline, household: household),
                                       bonusCredits: credits - base)
                } else {
                    // A day with no readings at all earns nothing, for the same reason.
                    result = DayResult(day: day, usedLiters: 0, limitLiters: plan.limit, credits: 0, metLimit: false)
                }
            } else {
                result = DayResult(day: day, usedLiters: used, limitLiters: plan.limit, credits: 0, metLimit: false, status: .calibrating)
            }
            context.insert(result)
            history.append((day: day, used: used))
            savedSoFar += result.saved
            run = result.metLimit ? run + 1 : 0
            best = max(best, run)
            day = next
        }
        try context.save()
    }

    /// Consecutive settled days under the limit, counting back from yesterday. `results` must be sorted by day.
    static func streak(_ results: [DayResult]) -> Int {
        results.reversed().prefix { $0.metLimit }.count
    }

    /// The longest run of days under the limit. `results` must be sorted by day.
    static func bestStreak(_ results: [DayResult]) -> Int {
        var best = 0, run = 0
        for result in results {
            run = result.metLimit ? run + 1 : 0
            best = max(best, run)
        }
        return best
    }

    static func balance(_ results: [DayResult], _ redemptions: [Redemption]) -> Int {
        results.sum(\.credits) - redemptions.sum(\.cost)
    }
}
