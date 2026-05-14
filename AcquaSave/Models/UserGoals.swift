import Foundation
import SwiftData

@Model
final class UserGoals {
    var id: UUID
    var dailyUsageGoalLiters: Double
    var hydrationGoalML: Int
    var targetStreakDays: Int
    var weeklyPointsGoal: Int

    init(
        dailyUsageGoalLiters: Double = 120,
        hydrationGoalML: Int = 2000,
        targetStreakDays: Int = 7,
        weeklyPointsGoal: Int = 200
    ) {
        self.id = UUID()
        self.dailyUsageGoalLiters = dailyUsageGoalLiters
        self.hydrationGoalML = hydrationGoalML
        self.targetStreakDays = targetStreakDays
        self.weeklyPointsGoal = weeklyPointsGoal
    }
}
