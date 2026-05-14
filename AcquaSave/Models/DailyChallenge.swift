import Foundation

struct DailyChallenge: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let systemImage: String
    let isCompleted: Bool
    let progress: Double
}
