import Foundation
import SwiftData

@Model
final class RewardRedemption: Identifiable {
    var id: UUID
    var date: Date
    var rewardId: String
    var rewardTitle: String
    var pointsSpent: Int

    init(date: Date, rewardId: String, rewardTitle: String, pointsSpent: Int) {
        self.id = UUID()
        self.date = date
        self.rewardId = rewardId
        self.rewardTitle = rewardTitle
        self.pointsSpent = pointsSpent
    }
}
