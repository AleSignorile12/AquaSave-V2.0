import Foundation

enum DeviceCategory: String, CaseIterable, Codable {
    case faucet = "Faucet"
    case shower = "Shower"
    case dishwasher = "Dishwasher"
    case washingMachine = "Washing Machine"
    case irrigation = "Irrigation"
    case toilet = "Toilet"
    case other = "Other"

    var systemImage: String {
        switch self {
        case .faucet: return "drop.circle.fill"
        case .shower: return "shower.fill"
        case .dishwasher: return "washer.fill"
        case .washingMachine: return "washer"
        case .irrigation: return "camera.metering.matrix"
        case .toilet: return "toilet.fill"
        case .other: return "switch.2"
        }
    }
}

enum DeviceCategoryHelper {

    static func guess(from name: String) -> DeviceCategory {
        let lower = name.lowercased()

        if lower.contains("faucet") || lower.contains("sink") || lower.contains("tap") {
            return .faucet
        }
        if lower.contains("shower") {
            return .shower
        }
        if lower.contains("dishwasher") {
            return .dishwasher
        }
        if lower.contains("washing") || lower.contains("washer") || lower.contains("laundry") {
            return .washingMachine
        }
        if lower.contains("irrigation") || lower.contains("garden") || lower.contains("sprinkler") {
            return .irrigation
        }
        if lower.contains("toilet") {
            return .toilet
        }

        return .other
    }
}
