import SwiftUI
import SwiftData

@main
struct AquaSaveApp: App {
    init() {
        #if DEBUG
        Credits.selfCheck()
        WasteStats.selfCheck()
        Tier.selfCheck()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [Sensor.self, UsageEvent.self, SensorOutage.self, DayResult.self, Redemption.self])
    }
}
