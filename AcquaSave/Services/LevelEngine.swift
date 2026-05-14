import Foundation

enum UserLevel: String, CaseIterable {
    case seed = "Seed"
    case sprout = "Sprout"
    case plant = "Plant"
    case tree = "Tree"
    case forest = "Forest"

    var systemImage: String {
        switch self {
        case .seed: return "leaf"
        case .sprout: return "leaf.fill"
        case .plant: return "camera.macro"
        case .tree: return "tree.fill"
        case .forest: return "leaf.circle.fill"
        }
    }
}

struct LevelInfo {
    let level: UserLevel
    let currentPoints: Int
    let pointsIntoCurrentLevel: Int
    let pointsNeededForNextLevel: Int
    let progressToNext: Double
    let nextLevelName: String?
}

enum LevelEngine {

    static func totalEarnedPoints(records: [WaterUsageRecord], dailyGoal: Double) -> Int {
        guard !records.isEmpty else { return 0 }

        let uniqueDays = Set(records.map { Calendar.current.startOfDay(for: $0.timestamp) })

        return uniqueDays.reduce(0) { partial, day in
            let usage = WaterAnalytics.sumLiters(on: day, records: records)
            return partial + WaterAnalytics.dailyPoints(dailyGoal: dailyGoal, todayUsage: usage)
        }
    }

    static func availablePoints(records: [WaterUsageRecord], dailyGoal: Double, redemptions: [RewardRedemption]) -> Int {
        let earned = totalEarnedPoints(records: records, dailyGoal: dailyGoal)
        let spent = redemptions.reduce(0) { $0 + $1.pointsSpent }
        return max(earned - spent, 0)
    }

    static func info(for points: Int) -> LevelInfo {
        let tiers: [(UserLevel, Int, Int?)] = [
            (.seed, 0, 100),
            (.sprout, 100, 250),
            (.plant, 250, 500),
            (.tree, 500, 1000),
            (.forest, 1000, nil)
        ]

        for (index, tier) in tiers.enumerated() {
            let currentLevel = tier.0
            let minPoints = tier.1
            let nextMin = tier.2

            if let nextMin, points < nextMin {
                let current = points - minPoints
                let needed = nextMin - minPoints
                return LevelInfo(
                    level: currentLevel,
                    currentPoints: points,
                    pointsIntoCurrentLevel: max(current, 0),
                    pointsNeededForNextLevel: needed,
                    progressToNext: needed > 0 ? Double(current) / Double(needed) : 1,
                    nextLevelName: tiers[index + 1].0.rawValue
                )
            }
        }

        return LevelInfo(
            level: .forest,
            currentPoints: points,
            pointsIntoCurrentLevel: 0,
            pointsNeededForNextLevel: 1,
            progressToNext: 1,
            nextLevelName: nil
        )
    }
}
