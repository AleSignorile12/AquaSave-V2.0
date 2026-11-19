import SwiftUI
import Charts

/// How today's water built up hour by hour, and where the waste came from.
struct WasteDetailView: View {
    /// Today's readings.
    let events: [UsageEvent]
    let limit: Double

    enum Series: String, CaseIterable {
        case wasted = "Wasted", used = "Used"
    }

    private struct Point {
        let time: Date
        let value: Double
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme

    @State private var series: Series = .wasted
    @State private var selected: Date?

    var body: some View {
        let points = cumulative(series)
        let total = points.last?.value ?? 0
        let used = events.sum(\.liters)
        let tint = series == .wasted ? Color.orange : theme.color

        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Picker("Show", selection: $series) {
                        ForEach(Series.allCases, id: \.self) { Text($0.rawValue) }
                    }
                    .pickerStyle(.segmented)

                    Card {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(series == .wasted ? "Wasted so far" : "Used so far")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.secondary)
                            Text(total.litersText)
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .contentTransition(.numericText(value: total))
                            Text(caption(total: total, used: used))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            trendChart(points, tint: tint, total: total)
                                .frame(height: 220)
                                .padding(.top, 12)

                            HStack(spacing: 14) {
                                legend(tint, series.rawValue)
                                if series == .used { limitLegend }
                                Spacer()
                                Text("Touch and hold to inspect")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.top, 6)
                        }
                    }
                    .animation(.spring(duration: 0.4, bounce: 0), value: series)

                    SectionTitle(title: "Where")
                    WasteSourceList(sources: events.wasteSources)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Today so far")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func caption(total: Double, used: Double) -> String {
        switch series {
        case .wasted:
            guard total > 0 else { return "Your sensors haven't caught any waste today." }
            let peak = WasteStats.peakHour(events.wasteSlots).map {
                ", mostly \($0.topKind.title.lowercased()) around \(WasteStats.date(forHour: $0.hour).formatted(date: .omitted, time: .shortened))"
            } ?? ""
            return "\(Int((total / max(used, 1) * 100).rounded()))% of today's water\(peak)"
        case .used:
            return total <= limit ? "\(Int((limit - total).rounded())) L left of your \(Int(limit)) L limit"
                                  : "\(Int((total - limit).rounded())) L over your \(Int(limit)) L limit"
        }
    }

    private func trendChart(_ points: [Point], tint: Color, total: Double) -> some View {
        let start = Calendar.current.startOfDay(for: .now)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? start
        let top = max(series == .used ? max(limit, total) : total, 1) * 1.15
        let inspected = selected.flatMap { time in points.last { $0.time <= time } }

        return Chart {
            ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                AreaMark(x: .value("Time", point.time), y: .value("Liters", point.value))
                    .interpolationMethod(.monotone)
                    .foregroundStyle(LinearGradient(colors: [tint.opacity(0.28), tint.opacity(0.02)],
                                                    startPoint: .top, endPoint: .bottom))
                LineMark(x: .value("Time", point.time), y: .value("Liters", point.value))
                    .interpolationMethod(.monotone)
                    .foregroundStyle(tint)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
            }
            if series == .used {
                RuleMark(y: .value("Limit", limit))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(.secondary)
            }
            if let inspected, let selected {
                RuleMark(x: .value("Time", selected))
                    .foregroundStyle(Color.secondary.opacity(0.35))
                    .annotation(position: .top, spacing: 4, overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))) {
                        ChartTooltip(title: selected.formatted(date: .omitted, time: .shortened),
                                     lines: [(series.rawValue, inspected.value.litersText, tint)])
                    }
                PointMark(x: .value("Time", inspected.time), y: .value("Liters", inspected.value))
                    .symbolSize(70)
                    .foregroundStyle(tint)
            }
        }
        .chartXScale(domain: start...end)
        .chartYScale(domain: 0...top)
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour, count: 6)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.hour())
            }
        }
        .holdToInspectX($selected)
        .sensoryFeedback(.selection, trigger: inspected?.time)
    }

    /// Running total through the day, starting at midnight and ending now.
    private func cumulative(_ series: Series) -> [Point] {
        var total = 0.0
        var points = [Point(time: Calendar.current.startOfDay(for: .now), value: 0)]
        for event in events.sorted(by: { $0.timestamp < $1.timestamp }) {
            total += series == .used ? event.liters : event.wastedLiters
            points.append(Point(time: event.timestamp, value: total))
        }
        points.append(Point(time: .now, value: total))
        return points
    }

    private func legend(_ color: Color, _ label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
    }

    private var limitLegend: some View {
        HStack(spacing: 4) {
            Rectangle()
                .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [3, 2]))
                .frame(width: 14, height: 0.5)
                .foregroundStyle(.secondary)
            Text("Limit \(Int(limit)) L").font(.caption).foregroundStyle(.secondary)
        }
    }
}
