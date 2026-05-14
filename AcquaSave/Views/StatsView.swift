import SwiftUI
import SwiftData

// MARK: - Stats View

struct StatsView: View {

    // MARK: - Range Picker

    enum Range: String, CaseIterable, Identifiable {
        case week = "Week"
        case month = "Month"

        var id: String { rawValue }
    }

    // MARK: - Queries / Settings

    @Query(sort: \WaterUsageRecord.timestamp, order: .reverse)
    private var records: [WaterUsageRecord]

    @Query(sort: \HydrationRecord.timestamp, order: .reverse)
    private var hydration: [HydrationRecord]

    @AppStorage("dailyGoalLiters") private var dailyGoal: Double = 120
    @AppStorage("hydrationGoalML") private var hydrationGoalML: Int = 2000

    // MARK: - UI State

    @State private var range: Range = .week

    // MARK: - Derived Data

    private var weekData: [(day: Date, liters: Double)] {
        WaterAnalytics.lastNDaysSeries(days: 7, from: Date(), records: records)
    }

    private var monthData: [(day: Date, liters: Double)] {
        WaterAnalytics.lastNDaysSeries(days: 30, from: Date(), records: records)
    }

    private var selectedData: [(day: Date, liters: Double)] {
        range == .week ? weekData : monthData
    }

    private var hasAnyData: Bool {
        records.contains(where: { $0.liters > 0 })
    }

    private var weekTotal: Double {
        weekData.reduce(0) { $0 + $1.liters }
    }

    private var monthTotal: Double {
        monthData.reduce(0) { $0 + $1.liters }
    }

    private var selectedTotal: Double {
        range == .week ? weekTotal : monthTotal
    }

    private var averagePerDay: Double {
        switch range {
        case .week:
            return weekTotal / 7.0
        case .month:
            return monthTotal / 30.0
        }
    }

    private var peakDay: (date: Date, liters: Double)? {
        guard let best = selectedData.max(by: { $0.liters < $1.liters }) else { return nil }
        return (best.day, best.liters)
    }

    private var previousPeriodTotal: Double {
        let daysBack = (range == .week) ? 7 : 30
        return totalForPreviousPeriod(days: daysBack)
    }

    private var deltaFromPreviousPeriod: Double {
        selectedTotal - previousPeriodTotal
    }

    private var deltaPercent: Double? {
        guard previousPeriodTotal > 0 else { return nil }
        return (deltaFromPreviousPeriod / previousPeriodTotal) * 100
    }

    private var comparisonText: String {
        if previousPeriodTotal == 0 && selectedTotal == 0 {
            return "No meaningful comparison yet."
        }

        if previousPeriodTotal == 0 && selectedTotal > 0 {
            return "This is your first tracked \(range == .week ? "week" : "month")."
        }

        let absPercent = Int(abs(deltaPercent ?? 0))

        if deltaFromPreviousPeriod < 0 {
            return "You used \(absPercent)% less than the previous \(range == .week ? "week" : "month")."
        } else if deltaFromPreviousPeriod > 0 {
            return "You used \(absPercent)% more than the previous \(range == .week ? "week" : "month")."
        } else {
            return "You matched the previous \(range == .week ? "week" : "month")."
        }
    }

    private var weeklyRecap: WeeklyRecap {
        WeeklyRecapEngine.recap(
            records: records,
            hydration: hydration,
            hydrationGoalML: hydrationGoalML
        )
    }

    private var todayUsage: Double {
        WaterAnalytics.sumLiters(on: .now, records: records)
    }

    private var forecastText: String {
        ForecastEngine.forecastText(
            todayUsage: todayUsage,
            dailyGoal: dailyGoal
        )
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                statsBackground

                ScrollView {
                    VStack(spacing: 14) {
                        header

                        rangePickerCard

                        chartCard

                        summaryRow

                        if let peakDay, hasAnyData {
                            peakDayCard(peakDay)
                        }

                        comparisonCard

                        WeeklyRecapCardView(recap: weeklyRecap)
                        ForecastCardView(text: forecastText)

                        recentActivityCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Stats")
        }
    }

    // MARK: - Main Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Your water trends")
                    .font(.system(size: 30, weight: .bold, design: .rounded))

                Text("A clearer view of your habits, peaks and progress over time.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var rangePickerCard: some View {
        GlassCard {
            Picker("Range", selection: $range) {
                ForEach(Range.allCases) { item in
                    Text(item.rawValue).tag(item)
                }
            }
            .pickerStyle(.segmented)
            .animation(.easeInOut(duration: 0.22), value: range)
        }
    }

    private var chartCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(range == .week ? "Last 7 days" : "Last 30 days")
                            .font(.headline)

                        Text("Daily water usage")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text("Liters")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.thinMaterial, in: Capsule())
                }

                if !hasAnyData {
                    ContentUnavailableView(
                        "No data yet",
                        systemImage: "chart.bar.xaxis",
                        description: Text("Add usage from Home or Devices to start seeing trends.")
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                } else {
                    if range == .week {
                        WeeklyBarChart(data: weekData)
                            .frame(height: 190)
                    } else {
                        MonthlySparkline(data: monthData)
                            .frame(height: 150)
                    }
                }
            }
        }
    }

    private var summaryRow: some View {
        HStack(spacing: 12) {
            StatCardView(
                title: "Average",
                value: "\(Int(averagePerDay)) L",
                subtitle: "per day",
                systemImage: "speedometer"
            )

            StatCardView(
                title: "Total",
                value: "\(Int(selectedTotal)) L",
                subtitle: range == .week ? "this week" : "this month",
                systemImage: "sum"
            )
        }
    }

    private func peakDayCard(_ peak: (date: Date, liters: Double)) -> some View {
        GlassCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.14))
                        .frame(width: 50, height: 50)

                    Image(systemName: "arrow.up.right.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.green)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Peak day")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("\(Int(peak.liters)) L")
                        .font(.system(size: 30, weight: .bold))
                        .monospacedDigit()

                    Text(peak.date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
    }

    private var comparisonCard: some View {
        GlassCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(comparisonTint.opacity(0.14))
                        .frame(width: 50, height: 50)

                    Image(systemName: comparisonImage)
                        .font(.title3)
                        .foregroundStyle(comparisonTint)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Period comparison")
                        .font(.headline)

                    Text(comparisonText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if let deltaPercent {
                        Text("\(Int(deltaPercent.rounded()))% vs previous \(range == .week ? "week" : "month")")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(comparisonTint)
                    }
                }

                Spacer()
            }
        }
    }

    private var recentActivityCard: some View {
        Group {
            if !records.isEmpty {
                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Recent activity")
                            .font(.headline)

                        ForEach(records.prefix(6)) { record in
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(record.deviceName ?? "Unknown device")
                                        .font(.subheadline)

                                    Text(record.timestamp, style: .time)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Text("\(Int(record.liters)) L")
                                    .font(.subheadline.weight(.semibold))
                                    .monospacedDigit()
                            }

                            if record.id != records.prefix(6).last?.id {
                                Divider()
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Styling Helpers

    private var statsBackground: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.blue.opacity(0.08),
                    Color.green.opacity(0.06),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [
                    Color.mint.opacity(0.10),
                    Color.clear
                ],
                center: .topTrailing,
                startRadius: 30,
                endRadius: 350
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

    private var comparisonTint: Color {
        if deltaFromPreviousPeriod < 0 { return .green }
        if deltaFromPreviousPeriod > 0 { return .orange }
        return .blue
    }

    private var comparisonImage: String {
        if deltaFromPreviousPeriod < 0 { return "arrow.down.right" }
        if deltaFromPreviousPeriod > 0 { return "arrow.up.right" }
        return "equal"
    }

    // MARK: - Data Helpers

    private func totalForPreviousPeriod(days: Int) -> Double {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: .now)

        guard
            let currentStart = calendar.date(byAdding: .day, value: -(days - 1), to: todayStart),
            let previousStart = calendar.date(byAdding: .day, value: -days, to: currentStart)
        else {
            return 0
        }

        return records
            .filter { $0.timestamp >= previousStart && $0.timestamp < currentStart }
            .reduce(0) { $0 + $1.liters }
    }
}
