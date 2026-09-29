import SwiftUI
import SwiftData

// MARK: - Dashboard View

struct DashboardView: View {

    // MARK: - Environment / Queries

    @Environment(\.modelContext) private var context
    @Query(sort: \WaterUsageRecord.timestamp, order: .reverse) private var records: [WaterUsageRecord]
    @Query(sort: \HydrationRecord.timestamp, order: .reverse) private var hydration: [HydrationRecord]
    @Query(sort: \RewardRedemption.date, order: .reverse) private var redemptions: [RewardRedemption]
    @Query(sort: \SmartDevice.name, order: .forward) private var devices: [SmartDevice]

    // MARK: - Stored Settings

    @AppStorage("dailyGoalLiters") private var dailyGoal: Double = 120
    @AppStorage("hydrationGoalML") private var hydrationGoalML: Int = 2000
    @AppStorage("targetStreakDays") private var targetStreakDays: Int = 7
    @AppStorage("weeklyPointsGoal") private var weeklyPointsGoal: Int = 200

    // MARK: - Constants

    private let smartIntervalMinutes = 120
    private let reminderStartHour = 9
    private let reminderEndHour = 1

    // MARK: - UI State

    @State private var hydrationPulse: CGFloat = 1
    @State private var hydrationDeltaText: String? = nil
    @State private var hydrationDeltaId = UUID()
    @State private var showHydrationDelta = false

    @State private var lastHydrationInserted: HydrationRecord? = nil
    @State private var showUndoToast = false

    @State private var lastUsageInserted: WaterUsageRecord? = nil
    @State private var showUsageUndoToast = false

    @State private var previousAvailablePoints: Int = 0
    @State private var showLevelUpOverlay = false
    @State private var levelUpInfo: LevelInfo? = nil

    @State private var showAchievementToast = false
    @State private var achievementToastTitle: String = ""
    @State private var achievementToastSubtitle: String = ""
    @State private var achievementToastImage: String = "star.fill"

    @State private var showGoalsSheet = false
    @State private var showNotesSheet = false

    // MARK: - Derived Data

    private var todayChallenge: DailyChallenge {
        ChallengeEngine.todayChallenge(
            records: records,
            hydration: hydration,
            dailyGoal: dailyGoal,
            hydrationGoalML: hydrationGoalML
        )
    }

    private var weeklyRecap: WeeklyRecap {
        WeeklyRecapEngine.recap(
            records: records,
            hydration: hydration,
            hydrationGoalML: hydrationGoalML
        )
    }

    private var smartTipText: String {
        SmartTipsEngine.tip(
            records: records,
            todayUsage: todayUsage,
            dailyGoal: dailyGoal,
            todayHydrationML: todayHydrationML,
            hydrationGoalML: hydrationGoalML
        )
    }

    private var forecastText: String {
        ForecastEngine.forecastText(
            todayUsage: todayUsage,
            dailyGoal: dailyGoal
        )
    }

    private var spikeAlert: SpikeAlert? {
        SpikeDetectionEngine.detect(records: records)
    }

    private var ecoScore: Int {
        EcoScoreEngine.score(
            todayUsage: todayUsage,
            dailyGoal: dailyGoal,
            todayHydrationML: todayHydrationML,
            hydrationGoalML: hydrationGoalML,
            streak: streak
        )
    }

    private var ecoScoreLabel: String {
        EcoScoreEngine.label(for: ecoScore)
    }

    private var todayUsage: Double {
        WaterAnalytics.sumLiters(on: Date(), records: records)
    }

    private var progress: Double {
        guard dailyGoal > 0 else { return 0 }
        return min(todayUsage / dailyGoal, 1)
    }

    private var streak: Int {
        WaterAnalytics.streakUnderGoal(dailyGoal: dailyGoal, records: records, includeToday: true)
    }

    private var points: Int {
        WaterAnalytics.dailyPoints(dailyGoal: dailyGoal, todayUsage: todayUsage)
    }

    private var last7: [(day: Date, liters: Double)] {
        WaterAnalytics.lastNDaysSeries(days: 7, from: Date(), records: records)
    }

    private var hasAnyData: Bool {
        records.contains(where: { $0.liters > 0 })
    }

    private var totalAvailablePoints: Int {
        LevelEngine.availablePoints(records: records, dailyGoal: dailyGoal, redemptions: redemptions)
    }

    private var levelInfo: LevelInfo {
        LevelEngine.info(for: totalAvailablePoints)
    }

    private var dailyInsightText: String {
        InsightsEngine.dailyInsight(
            records: records,
            todayUsage: todayUsage,
            dailyGoal: dailyGoal,
            todayHydrationML: todayHydrationML,
            hydrationGoalML: hydrationGoalML
        )
    }

    private var gardenProgress: GardenProgress {
        GardenEngine.progress(
            ecoScore: ecoScore,
            streak: streak,
            totalPoints: totalAvailablePoints
        )
    }

    private var unlockedAchievementIDs: Set<String> {
        AchievementEngine.unlockedIDs(
            records: records,
            hydration: hydration,
            devices: devices,
            redemptions: redemptions,
            dailyGoal: dailyGoal,
            hydrationGoalML: hydrationGoalML
        )
    }

    private var todayHydrationML: Int {
        HydrationAnalytics.sumML(on: .now, records: hydration)
    }

    private var hydrationProgress: Double {
        guard hydrationGoalML > 0 else { return 0 }
        return min(Double(todayHydrationML) / Double(hydrationGoalML), 1)
    }

    private var lastDrinkText: String {
        if let last = HydrationAnalytics.lastDrink(on: .now, records: hydration) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            formatter.dateStyle = .none
            return "Last drink: \(formatter.string(from: last))"
        }
        return "Last drink: —"
    }

    private var remindersPausedNow: Bool {
        let hour = Calendar.current.component(.hour, from: .now)

        if reminderStartHour < reminderEndHour {
            return !(hour >= reminderStartHour && hour < reminderEndHour)
        } else {
            return !(hour >= reminderStartHour || hour < reminderEndHour)
        }
    }

    private var nextReminderTextPretty: String {
        guard let next = NotificationManager.shared.getNextReminderDate() else {
            return "Next reminder: —"
        }

        let calendar = Calendar.current
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        timeFormatter.dateStyle = .none

        if calendar.isDateInToday(next) {
            return "Next reminder: \(timeFormatter.string(from: next))"
        } else if calendar.isDateInTomorrow(next) {
            return "Next reminder: Tomorrow \(timeFormatter.string(from: next))"
        } else {
            let fullFormatter = DateFormatter()
            fullFormatter.dateStyle = .medium
            fullFormatter.timeStyle = .short
            return "Next reminder: \(fullFormatter.string(from: next))"
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                dashboardBackground

                ScrollView {
                    VStack(spacing: 14) {
                        header

                        usageCard

                        quickStatsRow

                        if let spikeAlert {
                            SpikeAlertCardView(alert: spikeAlert)
                        }

                        simulationCard
                        utilityShortcutsCard

                        LevelBadgeView(info: levelInfo)
                        DailyChallengeCardView(challenge: todayChallenge)

                        hydrationCard
                        
                        TipCardView(text: smartTipText)
                        InsightCardView(text: dailyInsightText)

                        
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
            }
            .overlay(alignment: .bottom) {
                bottomToasts
            }
            .overlay {
                levelUpOverlay
            }
            .overlay(alignment: .top) {
                achievementOverlay
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            pushWidgetSnapshot()
            previousAvailablePoints = totalAvailablePoints
        }
        .onChange(of: records.count) { _, _ in
            pushWidgetSnapshot()
            triggerLevelUpIfNeeded(newAvailablePoints: totalAvailablePoints)
            triggerAchievementToastIfNeeded()
        }
        .onChange(of: hydration.count) { _, _ in
            triggerAchievementToastIfNeeded()
        }
        .onChange(of: dailyGoal) { _, _ in
            pushWidgetSnapshot()
        }
        .sheet(isPresented: $showGoalsSheet) {
            NavigationStack {
                GoalsView()
            }
        }
        .sheet(isPresented: $showNotesSheet) {
            NavigationStack {
                DailyNotesView()
            }
        }
    }

    // MARK: - Main Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("AquaSave")
                    .font(.system(size: 34, weight: .bold, design: .rounded))

                Text("Track water usage. Earn rewards by staying sustainable.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
    }

    private var usageCard: some View {
        GlassCard {
            HStack(spacing: 14) {
                RingView(
                    progress: progress,
                    lineWidth: 16,
                    size: 150,
                    systemImage: "drop.fill",
                    centerValue: todayUsage,
                    subtitle: "Today",
                    goal: dailyGoal
                )

                VStack(alignment: .leading, spacing: 10) {
                    Label("Daily goal", systemImage: "target")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    AnimatedNumberText(
                        value: dailyGoal,
                        formatter: { "\(Int($0)) L" }
                    )
                    .font(.system(size: 28, weight: .bold))

                    ProgressView(value: progress)
                        .tint(.green)
                        .scaleEffect(x: 1, y: 1.25, anchor: .center)

                    Slider(value: $dailyGoal, in: 50...300, step: 5)
                        .tint(.green)
                }
            }
        }
    }

    private var quickStatsRow: some View {
        HStack(spacing: 12) {
            GlassCard {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Eco Points")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        AnimatedNumberText(
                            value: Double(points),
                            formatter: { "+\(Int($0))" }
                        )
                        .font(.system(size: 34, weight: .bold))
                    }

                    Spacer()

                    Image(systemName: "leaf.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                }
            }

            StatCardView(
                title: "Streak",
                value: "\(streak) days",
                subtitle: "under goal",
                systemImage: "flame.fill"
            )
        }
    }

    private var simulationCard: some View {
        GlassCard {
            VStack(spacing: 10) {
                Button {
                    addUsage(liters: 5, device: "Kitchen Faucet")
                } label: {
                    Label("Simulate +5L (Kitchen)", systemImage: "drop.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    addUsage(liters: 20, device: "Shower Head")
                } label: {
                    Label("Simulate Shower +20L", systemImage: "shower.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var utilityShortcutsCard: some View {
        GlassCard {
            VStack(spacing: 12) {
                Button {
                    showGoalsSheet = true
                } label: {
                    HStack {
                        Label("Edit Goals", systemImage: "target")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)

                Divider()

                Button {
                    showNotesSheet = true
                } label: {
                    HStack {
                        Label("Daily Notes", systemImage: "note.text")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var hydrationCard: some View {
        GlassCard {
            ZStack {
                HydrationBottleCard(
                    lastDrinkText: lastDrinkText,
                    nextReminderText: nextReminderTextPretty,
                    isPaused: remindersPausedNow,
                    progress: hydrationProgress,
                    todayML: todayHydrationML,
                    goalML: $hydrationGoalML,
                    onAdd200: { addDrink(ml: 200) },
                    onAdd300: { addDrink(ml: 300) },
                    onAdd500: { addDrink(ml: 500) },
                    onRemoveLast: { removeLastDrink() }
                )
                .scaleEffect(hydrationPulse)

                if showHydrationDelta, let txt = hydrationDeltaText {
                    VStack {
                        Text(txt)
                            .font(.headline)
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(.thinMaterial, in: Capsule())
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .id(hydrationDeltaId)
                            .padding(.top, 8)

                        Spacer()
                    }
                }
            }
        }
    }

    // MARK: - Overlays / Toasts

    private var bottomToasts: some View {
        VStack(spacing: 10) {
            if showUndoToast, let rec = lastHydrationInserted {
                HStack(spacing: 12) {
                    Text("+\(rec.ml) ml added")
                        .font(.subheadline)
                        .foregroundStyle(.primary)

                    Spacer()

                    Button("Undo") {
                        undoLastDrink()
                    }
                    .font(.subheadline.weight(.semibold))
                }
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation(.easeOut(duration: 0.25)) {
                            showUndoToast = false
                        }
                    }
                }
            }

            if showUsageUndoToast, let rec = lastUsageInserted {
                HStack(spacing: 12) {
                    Text("\(Int(rec.liters)) L added • \(rec.deviceName ?? "Device")")
                        .font(.subheadline)
                        .foregroundStyle(.primary)

                    Spacer()

                    Button("Undo") {
                        undoLastUsage()
                    }
                    .font(.subheadline.weight(.semibold))
                }
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }

    private var levelUpOverlay: some View {
        Group {
            if showLevelUpOverlay, let info = levelUpInfo {
                ZStack {
                    Color.black.opacity(0.18)
                        .ignoresSafeArea()

                    LevelUpOverlayView(levelInfo: info)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
    }

    private var achievementOverlay: some View {
        Group {
            if showAchievementToast {
                AchievementToastView(
                    title: achievementToastTitle,
                    subtitle: achievementToastSubtitle,
                    systemImage: achievementToastImage
                )
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    // MARK: - Background / Small UI Helpers

    
    private var dashboardBackground: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.green.opacity(0.10),
                    Color.teal.opacity(0.07),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [
                    Color.mint.opacity(0.12),
                    Color.clear
                ],
                center: .topLeading,
                startRadius: 40,
                endRadius: 420
            )
            .ignoresSafeArea()
        }
    }

    private func heroMetric(title: String, value: String, icon: String, tint: Color) -> some View {
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

    private func addUsage(liters: Double, device: String?) {
        let rec = WaterUsageRecord(timestamp: Date(), liters: liters, deviceName: device)

        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            context.insert(rec)
            try? context.save()
        }
        HapticManager.light()

        lastUsageInserted = rec

        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            showUsageUndoToast = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if lastUsageInserted?.id == rec.id {
                withAnimation(.easeOut(duration: 0.25)) {
                    showUsageUndoToast = false
                }
            }
        }

        pushWidgetSnapshot()
    }

    private func undoLastUsage() {
        guard let rec = lastUsageInserted else { return }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            context.delete(rec)
            try? context.save()
        }
        HapticManager.medium()

        lastUsageInserted = nil
        showUsageUndoToast = false
        pushWidgetSnapshot()
    }

    private func addDrink(ml: Int) {
        let rec = HydrationRecord(timestamp: .now, ml: ml)

        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            context.insert(rec)
            try? context.save()
        }
        HapticManager.light()

        withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) {
            hydrationPulse = 1.05
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85).delay(0.08)) {
            hydrationPulse = 1.0
        }

        hydrationDeltaText = "+\(ml) ml"
        hydrationDeltaId = UUID()

        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            showHydrationDelta = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeOut(duration: 0.25)) {
                showHydrationDelta = false
            }
        }

        lastHydrationInserted = rec

        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            showUndoToast = true
        }

        NotificationManager.shared.scheduleSmartReminder(
            intervalMinutes: smartIntervalMinutes,
            startHour: reminderStartHour,
            endHour: reminderEndHour
        )
    }

    private func undoLastDrink() {
        guard let rec = lastHydrationInserted else { return }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            context.delete(rec)
            try? context.save()
        }
        HapticManager.medium()

        lastHydrationInserted = nil
        showUndoToast = false
    }

    private func removeLastDrink() {
        guard let last = hydration.first else { return }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            context.delete(last)
            try? context.save()
        }
    }

    // MARK: - External Updates

    private func pushWidgetSnapshot() {
        WidgetBridge.save(
            todayLiters: todayUsage,
            dailyGoal: dailyGoal,
            points: points,
            streak: streak
        )
    }

    private func triggerAchievementToastIfNeeded() {
        let unlocked = Array(unlockedAchievementIDs)

        guard let firstID = unlocked.sorted().last,
              let achievement = AchievementEngine.all.first(where: { $0.id == firstID }) else {
            return
        }

        achievementToastTitle = "Achievement unlocked"
        achievementToastSubtitle = achievement.title
        achievementToastImage = achievement.systemImage

        withAnimation(.spring(response: 0.45, dampingFraction: 0.88)) {
            showAchievementToast = true
        }

        HapticManager.success()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(.easeOut(duration: 0.25)) {
                showAchievementToast = false
            }
        }
    }

    private func triggerLevelUpIfNeeded(newAvailablePoints: Int) {
        if let info = LevelUpEngine.newLevelInfo(
            oldPoints: previousAvailablePoints,
            newPoints: newAvailablePoints
        ) {
            levelUpInfo = info

            withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                showLevelUpOverlay = true
            }

            HapticManager.success()

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                withAnimation(.easeOut(duration: 0.25)) {
                    showLevelUpOverlay = false
                }
            }
        }

        previousAvailablePoints = newAvailablePoints
    }
}
