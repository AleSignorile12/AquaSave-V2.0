import Foundation
import SwiftData

@Model
final class SmartDevice {
    var id: UUID
    var name: String
    var location: String
    var categoryRawValue: String

    init(
        name: String,
        location: String,
        categoryRawValue: String = DeviceCategory.other.rawValue
    ) {
        self.id = UUID()
        self.name = name
        self.location = location
        self.categoryRawValue = categoryRawValue
    }

    var category: DeviceCategory {
        get { DeviceCategory(rawValue: categoryRawValue) ?? .other }
        set { categoryRawValue = newValue.rawValue }
    }
}
