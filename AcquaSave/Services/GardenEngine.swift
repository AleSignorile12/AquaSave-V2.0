import Foundation

struct GardenProgress {
    let stage: GardenStage
    let score: Int
    let progressToNext: Double
    let nextStageName: String?
}

enum GardenEngine {

    static func progress(
        ecoScore: Int,
        streak: Int,
        totalPoints: Int
    ) -> GardenProgress {

        let growthScore = ecoScore + min(streak * 6, 30) + min(totalPoints / 20, 40)

        switch growthScore {
        case ..<35:
            return GardenProgress(stage: .seed, score: growthScore, progressToNext: Double(growthScore) / 35.0, nextStageName: GardenStage.sprout.rawValue)
        case ..<65:
            return GardenProgress(stage: .sprout, score: growthScore, progressToNext: Double(growthScore - 35) / 30.0, nextStageName: GardenStage.bloom.rawValue)
        case ..<95:
            return GardenProgress(stage: .bloom, score: growthScore, progressToNext: Double(growthScore - 65) / 30.0, nextStageName: GardenStage.tree.rawValue)
        case ..<130:
            return GardenProgress(stage: .tree, score: growthScore, progressToNext: Double(growthScore - 95) / 35.0, nextStageName: GardenStage.forest.rawValue)
        default:
            return GardenProgress(stage: .forest, score: growthScore, progressToNext: 1, nextStageName: nil)
        }
    }
}
