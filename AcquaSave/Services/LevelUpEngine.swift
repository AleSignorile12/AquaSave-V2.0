import Foundation

enum LevelUpEngine {

    static func didLevelUp(oldPoints: Int, newPoints: Int) -> Bool {
        let oldLevel = LevelEngine.info(for: oldPoints).level
        let newLevel = LevelEngine.info(for: newPoints).level
        return oldLevel != newLevel
    }

    static func newLevelInfo(oldPoints: Int, newPoints: Int) -> LevelInfo? {
        guard didLevelUp(oldPoints: oldPoints, newPoints: newPoints) else { return nil }
        return LevelEngine.info(for: newPoints)
    }
}
