import Foundation

enum EcoScoreEngine {

    static func score(
        todayUsage: Double,
        dailyGoal: Double,
        todayHydrationML: Int,
        hydrationGoalML: Int,
        streak: Int
    ) -> Int {

        var total = 0

        if dailyGoal > 0 {
            let usageRatio = todayUsage / dailyGoal
            switch usageRatio {
            case ..<0.6: total += 45
            case ..<0.85: total += 35
            case ..<1.0: total += 25
            case ..<1.2: total += 10
            default: total += 0
            }
        }

        if hydrationGoalML > 0 {
            let hydrationRatio = Double(todayHydrationML) / Double(hydrationGoalML)
            switch hydrationRatio {
            case 1...: total += 30
            case 0.75..<1: total += 22
            case 0.4..<0.75: total += 12
            default: total += 4
            }
        }

        switch streak {
        case 7...: total += 25
        case 4..<7: total += 18
        case 2..<4: total += 10
        case 1: total += 5
        default: break
        }

        return min(max(total, 0), 100)
    }

    static func label(for score: Int) -> String {
        switch score {
        case 85...: return "Excellent"
        case 70..<85: return "Great"
        case 50..<70: return "Balanced"
        case 30..<50: return "Needs attention"
        default: return "Critical"
        }
    }
}
