import SwiftUI
import SwiftData

// MARK: - Rewards View

struct RewardsView: View {

    // MARK: - Local Reward Model
    // Catalogo locale semplice, così non dipendiamo da tipi assenti nel progetto.

    struct RewardItem: Identifiable {
        let id: String
        let title: String
        let subtitle: String
        let cost: Int
        let systemImage: String
        let tint: Color
    }

    // MARK: - Environment / Queries

    @Environment(\.modelContext) private var context
    @Query(sort: \WaterUsageRecord.timestamp, order: .reverse) private var records: [WaterUsageRecord]
    @Query(sort: \RewardRedemption.date, order: .reverse) private var redemptions: [RewardRedemption]
    @Query(sort: \HydrationRecord.timestamp, order: .reverse) private var hydration: [HydrationRecord]
    @Query(sort: \SmartDevice.name, order: .forward) private var devices: [SmartDevice]

    // MARK: - Settings

    @AppStorage("dailyGoalLiters") private var dailyGoal: Double = 120
    @AppStorage("hydrationGoalML") private var hydrationGoalML: Int = 2000

    // MARK: - Derived Data

    private var availablePoints: Int {
        LevelEngine.availablePoints(
            records: records,
            dailyGoal: dailyGoal,
            redemptions: redemptions
        )
    }

    private var totalEarnedPoints: Int {
        LevelEngine.totalEarnedPoints(records: records, dailyGoal: dailyGoal)
    }

    private var levelInfo: LevelInfo {
        LevelEngine.info(for: totalEarnedPoints)
    }

    private var unlockedAchievementCount: Int {
        AchievementEngine.unlockedIDs(
            records: records,
            hydration: hydration,
            devices: devices,
            redemptions: redemptions,
            dailyGoal: dailyGoal,
            hydrationGoalML: hydrationGoalML
        ).count
    }

    private let rewards: [RewardItem] = [
        .init(
            id: "amazon10",
            title: "Amazon Gift Card",
            subtitle: "€10 voucher",
            cost: 1200,
            systemImage: "cart.fill",
            tint: .green
        ),
        .init(
            id: "spotify1m",
            title: "Spotify Premium",
            subtitle: "1 month",
            cost: 800,
            systemImage: "music.note",
            tint: .pink
        ),
        .init(
            id: "appcredit",
            title: "AquaSave Credit",
            subtitle: "€15 in-app",
            cost: 1500,
            systemImage: "creditcard.fill",
            tint: .orange
        )
    ]

    private var ecoScorePreview: Int {
        EcoScoreEngine.score(
            todayUsage: WaterAnalytics.sumLiters(on: .now, records: records),
            dailyGoal: dailyGoal,
            todayHydrationML: HydrationAnalytics.sumML(on: .now, records: hydration),
            hydrationGoalML: hydrationGoalML,
            streak: WaterAnalytics.streakUnderGoal(
                dailyGoal: dailyGoal,
                records: records,
                includeToday: true
            )
        )
    }

    private var gardenProgress: GardenProgress {
        GardenEngine.progress(
            ecoScore: ecoScorePreview,
            streak: WaterAnalytics.streakUnderGoal(
                dailyGoal: dailyGoal,
                records: records,
                includeToday: true
            ),
            totalPoints: totalEarnedPoints
        )
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                rewardsBackground

                ScrollView {
                    VStack(spacing: 14) {
                        header
                        levelSection
                        achievementsShortcut
                        pointsCard
                        rewardsList
                        redemptionHistoryCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Rewards")
        }
    }

    // MARK: - Main Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Your rewards")
                    .font(.system(size: 30, weight: .bold, design: .rounded))

                Text("Save water, earn points and redeem them for useful perks.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var levelSection: some View {
        VStack(spacing: 12) {
            LevelBadgeView(info: levelInfo)
            GardenProgressCardView(progress: gardenProgress)
        }
    }

    private var achievementsShortcut: some View {
        NavigationLink {
            AchievementsView()
        } label: {
            GlassCard {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Achievements")
                            .font(.headline)

                        Text("\(unlockedAchievementCount)/\(AchievementEngine.all.count) unlocked")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var pointsCard: some View {
        GlassCard {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Available Points")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("\(availablePoints)")
                        .font(.system(size: 42, weight: .bold))
                        .monospacedDigit()
                }

                Spacer()

                Image(systemName: "leaf.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.green)
            }
        }
    }

    private var rewardsList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Redeem")
                .font(.headline)
                .padding(.horizontal, 4)

            ForEach(rewards) { reward in
                RewardCard(
                    reward: reward,
                    canRedeem: availablePoints >= reward.cost
                ) {
                    redeem(reward)
                }
            }
        }
    }

    private var redemptionHistoryCard: some View {
        Group {
            if !redemptions.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("History")
                        .font(.headline)
                        .padding(.horizontal, 4)

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(redemptions.prefix(6)) { item in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.rewardTitle)
                                            .font(.subheadline)

                                        Text(item.date, style: .date)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    Text("-\(item.pointsSpent)")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                        .monospacedDigit()
                                }

                                if item.id != redemptions.prefix(6).last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Styling Helpers

    private var rewardsBackground: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.orange.opacity(0.08),
                    Color.green.opacity(0.06),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [
                    Color.yellow.opacity(0.10),
                    Color.clear
                ],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 340
            )
            .ignoresSafeArea()
        }
    }

    private func topMetric(title: String, value: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.14))
                    .frame(width: 38, height: 38)

                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(tint)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.subheadline.weight(.bold))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.16), lineWidth: 1)
        )
    }

    // MARK: - Actions

    private func redeem(_ reward: RewardItem) {
        guard availablePoints >= reward.cost else { return }

        let redemption = RewardRedemption(
            date: .now,
            rewardId: reward.id,
            rewardTitle: reward.title,
            pointsSpent: reward.cost
        )

        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            context.insert(redemption)
            try? context.save()
        }

        HapticManager.success()
    }
}

// MARK: - Reward Card

private struct RewardCard: View {
    let reward: RewardsView.RewardItem
    let canRedeem: Bool
    let onRedeem: () -> Void

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(reward.tint.opacity(0.14))
                            .frame(width: 46, height: 46)

                        Image(systemName: reward.systemImage)
                            .font(.title3)
                            .foregroundStyle(reward.tint)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(reward.title)
                            .font(.headline)

                        Text(reward.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text("\(reward.cost)")
                        .font(.subheadline.weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(reward.tint.opacity(0.12), in: Capsule())
                        .foregroundStyle(reward.tint)
                }

                Button {
                    onRedeem()
                } label: {
                    Text(canRedeem ? "Redeem reward" : "Not enough points")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(
                                    canRedeem
                                    ? reward.tint.opacity(0.14)
                                    : Color(.tertiarySystemBackground)
                                )
                        )
                }
                .buttonStyle(.plain)
                .foregroundStyle(canRedeem ? reward.tint : .secondary)
                .disabled(!canRedeem)
            }
        }
    }
}
