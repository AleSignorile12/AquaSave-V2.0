import Foundation

enum ForecastEngine {

    static func forecastText(todayUsage: Double, dailyGoal: Double) -> String {
        guard dailyGoal > 0 else { return "Set a daily goal to get forecasts." }

        let hour = Calendar.current.component(.hour, from: .now)
        let dayProgress = max(Double(hour) / 24.0, 0.1)

        let projected = todayUsage / dayProgress

        if projected < dailyGoal * 0.9 {
            return "At this pace, you’re on track to stay under your goal."
        } else if projected <= dailyGoal * 1.1 {
            return "You’re close to your target pace — a careful evening would keep you on track."
        } else {
            return "At this pace, you may finish the day above your water goal."
        }
    }
}
