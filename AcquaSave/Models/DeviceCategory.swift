import SwiftUI

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
        case .faucet: "spigot.fill"
        case .shower: "shower.fill"
        case .dishwasher: "dishwasher.fill"
        case .washingMachine: "washer.fill"
        case .irrigation: "sprinkler.and.droplets.fill"
        case .toilet: "toilet.fill"
        case .other: "drop.fill"
        }
    }

    var tint: Color {
        switch self {
        case .faucet: .green
        case .shower: .blue
        case .dishwasher: .mint
        case .washingMachine: .indigo
        case .irrigation: .orange
        case .toilet: .cyan
        case .other: .teal
        }
    }

}

/// A common fixture, used to pick sensors during setup and to prefill the Add Sensor sheet.
struct SensorPreset: Identifiable, Hashable {
    let id: String
    let name: String
    let location: String
    let category: DeviceCategory

    static let all: [SensorPreset] = [
        SensorPreset(id: "shower", name: "Shower Head", location: "Main bathroom", category: .shower),
        SensorPreset(id: "bathroomSink", name: "Bathroom Sink", location: "Main bathroom", category: .faucet),
        SensorPreset(id: "kitchenSink", name: "Kitchen Sink", location: "Kitchen", category: .faucet),
        SensorPreset(id: "washingMachine", name: "Washing Machine", location: "Laundry", category: .washingMachine),
        SensorPreset(id: "dishwasher", name: "Dishwasher", location: "Kitchen", category: .dishwasher),
        SensorPreset(id: "toilet", name: "Toilet", location: "Main bathroom", category: .toilet),
        SensorPreset(id: "garden", name: "Garden Sprinkler", location: "Garden", category: .irrigation),
    ]

    static let defaults = all.filter { ["shower", "bathroomSink", "kitchenSink", "washingMachine"].contains($0.id) }
}
