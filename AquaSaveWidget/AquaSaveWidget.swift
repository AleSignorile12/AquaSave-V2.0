import WidgetKit
import SwiftUI

struct AquaEntry: TimelineEntry {
    let date: Date
    let todayLiters: Double
    let dailyGoal: Double
    let points: Int
    let streak: Int
    let lastUpdated: Date?
}

struct AquaProvider: TimelineProvider {

    // ⚠️ deve combaciare con l’app
    private let appGroupID = "group.com.alessandrosignorile.AquaSave"

    func placeholder(in context: Context) -> AquaEntry {
        AquaEntry(
            date: Date(),
            todayLiters: 72,
            dailyGoal: 120,
            points: 96,
            streak: 4,
            lastUpdated: Date()
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (AquaEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AquaEntry>) -> Void) {
        let entry = loadEntry()

        // refresh ogni 15 minuti
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func loadEntry() -> AquaEntry {
        let defaults = UserDefaults(suiteName: appGroupID)

        let todayLiters = defaults?.double(forKey: "widget_today_liters") ?? 0
        let dailyGoal = defaults?.double(forKey: "widget_daily_goal") ?? 120
        let points = defaults?.integer(forKey: "widget_points") ?? 0
        let streak = defaults?.integer(forKey: "widget_streak") ?? 0

        let last = defaults?.double(forKey: "widget_last_updated") ?? 0
        let lastUpdated = last > 0 ? Date(timeIntervalSince1970: last) : nil

        return AquaEntry(
            date: Date(),
            todayLiters: todayLiters,
            dailyGoal: dailyGoal,
            points: points,
            streak: streak,
            lastUpdated: lastUpdated
        )
    }
}

struct AquaSaveWidgetView: View {
    var entry: AquaProvider.Entry

    private var progress: Double {
        guard entry.dailyGoal > 0 else { return 0 }
        return min(entry.todayLiters / entry.dailyGoal, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            HStack {
                Label("AquaSave", systemImage: "drop.fill")
                    .font(.headline)

                Spacer()

                Text("\(Int(entry.todayLiters))L")
                    .font(.headline)
                    .monospacedDigit()
            }

            ProgressView(value: progress)
                .tint(.green)

            HStack(spacing: 12) {
                miniStat(title: "Limit", value: "\(Int(entry.dailyGoal))L")
                miniStat(title: "Credits", value: "\(entry.points)")
                miniStat(title: "Streak", value: "\(entry.streak)d")
            }
            .font(.caption)

        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)   // 👈 QUESTO È IL FIX
    }

    private func miniStat(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).foregroundStyle(.secondary)
            Text(value).monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

@main
struct AquaSaveWidget: Widget {
    let kind: String = "AquaSaveWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AquaProvider()) { entry in
            AquaSaveWidgetView(entry: entry)
        }
        .configurationDisplayName("AquaSave")
        .description("Today’s water use, daily limit, credits and streak.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
