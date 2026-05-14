import Foundation
import SwiftData

@Model
final class AchievementUnlock {
    var id: UUID
    var achievementID: String
    var unlockedAt: Date

    init(achievementID: String, unlockedAt: Date = .now) {
        self.id = UUID()
        self.achievementID = achievementID
        self.unlockedAt = unlockedAt
    }
}
