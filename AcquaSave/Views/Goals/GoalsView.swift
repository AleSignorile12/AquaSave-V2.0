import SwiftUI
import SwiftData

struct GoalsView: View {
    @Environment(\.modelContext) private var context
    @Query private var storedGoals: [UserGoals]

    @AppStorage("dailyGoalLiters") private var dailyGoal: Double = 120
    @AppStorage("hydrationGoalML") private var hydrationGoalML: Int = 2000
    @AppStorage("targetStreakDays") private var targetStreakDays: Int = 7
    @AppStorage("weeklyPointsGoal") private var weeklyPointsGoal: Int = 200

    var body: some View {
        Form {
            Section("Daily Goals") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Daily water usage")
                    Slider(value: $dailyGoal, in: 50...300, step: 5)
                    Text("\(Int(dailyGoal)) L")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Stepper("Hydration goal: \(hydrationGoalML) ml", value: $hydrationGoalML, in: 500...5000, step: 100)
            }

            Section("Progress Goals") {
                Stepper("Target streak: \(targetStreakDays) days", value: $targetStreakDays, in: 1...60, step: 1)
                Stepper("Weekly points goal: \(weeklyPointsGoal)", value: $weeklyPointsGoal, in: 50...2000, step: 25)
            }

            Section {
                Button("Save Goals") {
                    saveGoals()
                }
            }
        }
        .navigationTitle("Goals")
        .onAppear {
            syncFromStoredGoalsIfNeeded()
        }
    }

    private func syncFromStoredGoalsIfNeeded() {
        guard let g = storedGoals.first else { return }
        dailyGoal = g.dailyUsageGoalLiters
        hydrationGoalML = g.hydrationGoalML
        targetStreakDays = g.targetStreakDays
        weeklyPointsGoal = g.weeklyPointsGoal
    }

    private func saveGoals() {
        if let g = storedGoals.first {
            g.dailyUsageGoalLiters = dailyGoal
            g.hydrationGoalML = hydrationGoalML
            g.targetStreakDays = targetStreakDays
            g.weeklyPointsGoal = weeklyPointsGoal
        } else {
            let g = UserGoals(
                dailyUsageGoalLiters: dailyGoal,
                hydrationGoalML: hydrationGoalML,
                targetStreakDays: targetStreakDays,
                weeklyPointsGoal: weeklyPointsGoal
            )
            context.insert(g)
        }

        try? context.save()
    }
}
