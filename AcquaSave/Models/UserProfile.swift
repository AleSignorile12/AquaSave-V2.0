import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID
    var createdAt: Date

    init(createdAt: Date = .now) {
        self.id = UUID()
        self.createdAt = createdAt
    }
}
