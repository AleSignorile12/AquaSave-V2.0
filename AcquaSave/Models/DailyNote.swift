import Foundation
import SwiftData

@Model
final class DailyNote {
    var id: UUID
    var createdAt: Date
    var text: String

    init(createdAt: Date = .now, text: String) {
        self.id = UUID()
        self.createdAt = createdAt
        self.text = text
    }
}
