import Foundation
import SwiftData

@Model
final class WaterUsageRecord: Identifiable {
    var id: UUID
    var timestamp: Date
    var liters: Double
    var deviceName: String?

    init(timestamp: Date, liters: Double, deviceName: String? = nil) {
        self.id = UUID()
        self.timestamp = timestamp
        self.liters = liters
        self.deviceName = deviceName
    }
}
