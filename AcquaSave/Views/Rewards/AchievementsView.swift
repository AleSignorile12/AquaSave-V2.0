import SwiftUI
import SwiftData

struct AchievementsView: View {
    @Query(sort: \WaterUsageRecord.timestamp, order: .reverse) private var records: [WaterUsageRecord]
    @Query(sort: \HydrationRecord.timestamp, order: .reverse) private var hydration: [HydrationRecord]
    @Query(sort: \SmartDevice.name, order: .forward) private var devices: [SmartDevice]
    @Query(sort: \RewardRedemption.date, order: .reverse) private var redemptions: [RewardRedemption]

    @AppStorage("dailyGoalLiters") private var dailyGoal: Double = 120
    @AppStorage("hydrationGoalML") private var hydrationGoalML: Int = 2000

    private var unlockedIDs: Set<String> {
        AchievementEngine.unlockedIDs(
            records: records,
            hydration: hydration,
            devices: devices,
            redemptions: redemptions,
            dailyGoal: dailyGoal,
            hydrationGoalML: hydrationGoalML
        )
    }

    private var unlockedCount: Int {
        AchievementEngine.all.filter { unlockedIDs.contains($0.id) }.count
    }

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 14) {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Achievements")
                                .font(.headline)

                            Text("\(unlockedCount)/\(AchievementEngine.all.count) unlocked")
                                .font(.title2.bold())

                            ProgressView(value: Double(unlockedCount), total: Double(AchievementEngine.all.count))
                                .tint(.green)
                        }
                    }

                    ForEach(AchievementEngine.all) { achievement in
                        AchievementCardView(
                            achievement: achievement,
                            isUnlocked: unlockedIDs.contains(achievement.id)
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Achievements")
    }
}
