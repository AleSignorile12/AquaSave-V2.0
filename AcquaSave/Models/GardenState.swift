import Foundation

enum GardenStage: String, CaseIterable {
    case seed = "Seed"
    case sprout = "Sprout"
    case bloom = "Bloom"
    case tree = "Tree"
    case forest = "Forest"

    var systemImage: String {
        switch self {
        case .seed: return "circle.hexagongrid.fill"
        case .sprout: return "leaf.fill"
        case .bloom: return "camera.macro"
        case .tree: return "tree.fill"
        case .forest: return "leaf.circle.fill"
        }
    }

    var subtitle: String {
        switch self {
        case .seed: return "Your eco journey just started."
        case .sprout: return "You’re building healthy habits."
        case .bloom: return "Your consistency is paying off."
        case .tree: return "Strong impact, strong routine."
        case .forest: return "You built a whole ecosystem."
        }
    }
}
