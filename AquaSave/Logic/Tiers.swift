import SwiftUI

/// Levels earned by saving water and keeping a streak. Each one pays a little more per liter saved
/// and takes a little off AquaSave hardware.
enum Tier: Int, CaseIterable, Comparable {
    case drop, stream, river, ocean

    var name: String {
        switch self {
        case .drop: "Drop"
        case .stream: "Stream"
        case .river: "River"
        case .ocean: "Ocean"
        }
    }

    var systemImage: String {
        switch self {
        case .drop: "drop.fill"
        case .stream: "water.waves"
        case .river: "mountain.2.fill"
        case .ocean: "globe.europe.africa.fill"
        }
    }

    var tint: Color {
        switch self {
        case .drop: .teal
        case .stream: .cyan
        case .river: .blue
        case .ocean: .indigo
        }
    }

    /// Liters saved against the usual day, lifetime.
    var savedNeeded: Double {
        switch self {
        case .drop: 0
        case .stream: 500
        case .river: 2_000
        case .ocean: 6_000
        }
    }

    /// Longest run of days under the limit.
    var streakNeeded: Int {
        switch self {
        case .drop: 0
        case .stream: 5
        case .river: 14
        case .ocean: 30
        }
    }

    /// Extra credits on every liter saved.
    var creditBoost: Double { Double(rawValue) * 0.05 }
    /// Off AquaSave sensors in the shop.
    var hardwareDiscount: Double { Double(rawValue) * 0.05 }

    var perks: [String] {
        guard self > .drop else { return ["Earn 1 credit for every \(Int(Credits.litersPerCredit)) L you save"] }
        return ["+\(Int(creditBoost * 100))% credits on every liter saved",
                "\(Int(hardwareDiscount * 100))% off AquaSave sensors"]
    }

    var next: Tier? { Tier(rawValue: rawValue + 1) }

    static func < (a: Tier, b: Tier) -> Bool { a.rawValue < b.rawValue }

    /// Both bars have to be cleared: savings alone can come from one good month, a streak alone from a small home.
    static func reached(saved: Double, bestStreak: Int) -> Tier {
        allCases.last { saved >= $0.savedNeeded && bestStreak >= $0.streakNeeded } ?? .drop
    }

    #if DEBUG
    static func selfCheck() {
        assert(reached(saved: 0, bestStreak: 0) == .drop)
        assert(reached(saved: 2_500, bestStreak: 6) == .stream, "savings alone don't unlock River")
        assert(reached(saved: 2_000, bestStreak: 14) == .river)
        assert(reached(saved: 50_000, bestStreak: 30) == .ocean)
        assert(Credits.earned(used: 200, baseline: 300, household: 2, boost: river.creditBoost) == 9,
               "88 L saved × 1.10 = 96.8 L → 9 credits")
    }
    #endif
}

/// Where a home stands on the tier ladder, from its settled days.
struct TierProgress {
    let tier: Tier
    let saved: Double
    let bestStreak: Int

    init(_ results: [DayResult]) {
        saved = results.sum(\.saved)
        bestStreak = Ledger.bestStreak(results)
        tier = Tier.reached(saved: saved, bestStreak: bestStreak)
    }

    /// 0...1 toward the next tier on each bar, nil at the top.
    var toNext: (saved: Double, streak: Double)? {
        guard let next = tier.next else { return nil }
        return (min(saved / next.savedNeeded, 1), min(Double(bestStreak) / Double(next.streakNeeded), 1))
    }
}
