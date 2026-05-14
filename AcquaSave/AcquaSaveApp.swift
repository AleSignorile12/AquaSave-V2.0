import SwiftUI
import SwiftData

@main
struct AquaSaveApp: App {

    private let container: ModelContainer

    init() {
        let schema = Schema([
            WaterUsageRecord.self,
            HydrationRecord.self,
            SmartDevice.self,
            RewardRedemption.self,
            UserProfile.self,
            AchievementUnlock.self,
            DailyNote.self,
            UserGoals.self
        ])

        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try! ModelContainer(for: schema, configurations: [config])
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(container)
    }
}
