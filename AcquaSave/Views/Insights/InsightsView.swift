import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    enum Span: String, CaseIterable {
        case week = "Week", month = "Month"
        var days: Int { self == .week ? 7 : 30 }
    }

    private struct DayTotal: Identifiable {
        let day: Date
        let used: Double
        let wasted: Double
        var id: Date { day }
    }

    private struct Slice: Identifiable {
        let id: PersistentIdentifier
        let name: String
        let category: DeviceCategory
        let used: Double
    }

    private struct DeviceDay: Identifiable {
        let day: Date
        let name: String
        let liters: Double
        var id: String { "\(day.timeIntervalSince1970)-\(name)" }
    }

    private struct DeviceDayKey: Hashable {
        let day: Date
        let name: String
    }

    @Environment(\.theme) private var theme

    @Query(sort: \UsageEvent.timestamp) private var events: [UsageEvent]
    @Query(sort: \Sensor.name) private var sensors: [Sensor]
    @Query(sort: \DayResult.day) private var results: [DayResult]

    @AppStorage("household") private var household = 2

    @State private var span: Span = .week
    @State private var usageDay: Date?
    @State private var wasteDay: Date?
    @State private var deviceDay: Date?
    @State private var sliceAngle: Double?

    var body: some View {
        let limit = Ledger.plan(results, household: household).limit
        let days = dailyTotals(span.days)
        let since = days.first?.day ?? .now
        let spanEvents = events.filter { $0.timestamp >= since }
        let total = days.sum(\.used)
        let wasted = days.sum(\.wasted)
        let finished = days.dropLast() // today is still running
        let under = finished.filter { $0.used > 0 && $0.used <= limit }.count
        let average = finished.isEmpty ? 0 : finished.sum(\.used) / Double(finished.count)
        let slices = sensors.map { sensor in
            let readings = sensor.events.filter { $0.timestamp >= since }
            return Slice(id: sensor.persistentModelID, name: sensor.name, category: sensor.category,
                         used: readings.sum(\.liters))
        }
        .filter { $0.used > 0 }
        .sorted { $0.used > $1.used }

        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Picker("Range", selection: $span) {
                        ForEach(Span.allCases, id: \.self) { Text($0.rawValue) }
                    }
                    .pickerStyle(.segmented)

                    usageChart(days, limit: limit, average: average)

                    HStack(spacing: 12) {
                        StatTile(title: "Under limit", value: "\(under)/\(finished.count)",
                                 systemImage: "checkmark.circle.fill", tint: theme.color,
                                 caption: "days this \(span.rawValue.lowercased())")
                        StatTile(title: "Wasted", value: wasted.litersText,
                                 systemImage: "drop.triangle.fill", tint: .orange,
                                 caption: total > 0 ? "\(Int((wasted / total * 100).rounded()))% of all water used" : "No readings yet")
                    }

                    if !slices.isEmpty {
                        SectionTitle(title: "By device")
                        breakdown(slices, total: total)
                        deviceChart(deviceDays(spanEvents), slices: slices)

                        SectionTitle(title: "Waste patterns")
                        wastePatterns(days, slots: spanEvents.wasteSlots)

                        SectionTitle(title: "Where water is wasted")
                        WasteSourceList(sources: spanEvents.wasteSources)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Insights")
        }
    }

    // MARK: - Usage

    private func usageChart(_ days: [DayTotal], limit: Double, average: Double) -> some View {
        let picked = usageDay.flatMap { day in days.first { $0.day == Calendar.current.startOfDay(for: day) } }
        let dayLimit = picked.map { day in results.first { $0.day == day.day }?.limitLiters ?? limit } ?? limit

        return Card {
            VStack(alignment: .leading, spacing: 4) {
                Text("Daily average")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("\(Int(average.rounded()))")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .contentTransition(.numericText(value: average))
                    Text("L").font(.headline).foregroundStyle(.secondary)
                }

                Chart {
                    ForEach(days) { day in
                        BarMark(x: .value("Day", day.day, unit: .day), y: .value("Liters", day.used))
                            .foregroundStyle(day.used > limit ? Color.orange : theme.color)
                            .opacity(dimmed(day.day, selected: picked?.day, today: true))
                            .cornerRadius(span == .week ? 6 : 3)
                    }
                    RuleMark(y: .value("Limit", limit))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .foregroundStyle(.secondary)
                    if let picked {
                        RuleMark(x: .value("Day", picked.day, unit: .day))
                            .foregroundStyle(Color.secondary.opacity(0.3))
                            .annotation(position: .top, spacing: 4, overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))) {
                                ChartTooltip(title: dayTitle(picked.day), lines: [
                                    ("Used", picked.used.litersText, picked.used > dayLimit ? .orange : theme.color),
                                    ("Wasted", picked.wasted.litersText, .orange),
                                    ("Limit", "\(Int(dayLimit)) L", .secondary),
                                ])
                            }
                    }
                }
                .chartXAxis { dayAxis }
                .holdToInspectX($usageDay)
                .sensoryFeedback(.selection, trigger: picked?.day)
                .frame(height: 200)
                .padding(.top, 12)
                .animation(.spring(duration: 0.4, bounce: 0), value: span)

                // The legend carries the limit's value, so nothing sits on top of the bars.
                HStack(spacing: 14) {
                    legendDot(theme.color, "Under")
                    legendDot(.orange, "Over")
                    limitLegend(limit)
                }
                .padding(.top, 10)
            }
        }
    }

    // MARK: - Devices

    private func breakdown(_ slices: [Slice], total: Double) -> some View {
        let picked = slice(at: sliceAngle, in: slices)

        return Card {
            HStack(spacing: 20) {
                Chart(Array(slices.enumerated()), id: \.element.id) { index, slice in
                    SectorMark(angle: .value("Liters", slice.used), innerRadius: .ratio(0.64), angularInset: 1.5)
                        .cornerRadius(3)
                        .foregroundStyle(Color.chart(index))
                        .opacity(picked == nil || picked?.id == slice.id ? 1 : 0.3)
                }
                .holdToInspectAngle($sliceAngle)
                .sensoryFeedback(.selection, trigger: picked?.id)
                .frame(width: 124, height: 124)
                .overlay {
                    VStack(spacing: 0) {
                        if let picked {
                            Text(Int(picked.used.rounded()), format: .number)
                                .font(.system(.headline, design: .rounded))
                            Text(picked.name).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                        } else {
                            Text(Int(total.rounded()), format: .number)
                                .font(.system(.headline, design: .rounded))
                            Text("liters").font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 76)
                    .allowsHitTesting(false)
                }

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(slices.enumerated()), id: \.element.id) { index, slice in
                        HStack(spacing: 8) {
                            Circle().fill(Color.chart(index)).frame(width: 8, height: 8)
                            Text(slice.name).font(.subheadline).lineLimit(1)
                            Spacer(minLength: 4)
                            Text("\(Int((slice.used / total * 100).rounded()))%")
                                .font(.subheadline.weight(.semibold))
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                        .opacity(picked == nil || picked?.id == slice.id ? 1 : 0.4)
                    }
                }
            }
        }
    }

    private func deviceChart(_ data: [DeviceDay], slices: [Slice]) -> some View {
        let picked = deviceDay.map { Calendar.current.startOfDay(for: $0) }
        let onDay = data.filter { $0.day == picked }.sorted { $0.liters > $1.liters }

        return Card {
            VStack(alignment: .leading, spacing: 4) {
                Text(span == .week ? "Each day this week" : "Each day this month")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                Chart {
                    ForEach(data) { item in
                        BarMark(x: .value("Day", item.day, unit: .day), y: .value("Liters", item.liters))
                            .foregroundStyle(by: .value("Device", item.name))
                            .opacity(dimmed(item.day, selected: picked, today: false))
                    }
                    if let picked {
                        RuleMark(x: .value("Day", picked, unit: .day))
                            .foregroundStyle(Color.secondary.opacity(0.3))
                            .annotation(position: .top, spacing: 4, overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))) {
                                ChartTooltip(title: dayTitle(picked), lines: onDay.map { item in
                                    (item.name, item.liters.litersText,
                                     Color.chart(slices.firstIndex { $0.name == item.name } ?? 0))
                                })
                            }
                    }
                }
                .chartForegroundStyleScale(domain: slices.map(\.name), range: slices.indices.map(Color.chart))
                .chartLegend(.hidden)
                .chartXAxis { dayAxis }
                .holdToInspectX($deviceDay)
                .sensoryFeedback(.selection, trigger: picked)
                .frame(height: 180)
                .padding(.top, 12)
                .animation(.spring(duration: 0.4, bounce: 0), value: span)
            }
        }
    }

    // MARK: - Waste

    @ViewBuilder
    private func wastePatterns(_ days: [DayTotal], slots: [WasteStats.Slot]) -> some View {
        let picked = wasteDay.flatMap { day in days.first { $0.day == Calendar.current.startOfDay(for: day) } }

        Card {
            VStack(alignment: .leading, spacing: 4) {
                Text("Waste per day")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                Chart {
                    ForEach(days) { day in
                        BarMark(x: .value("Day", day.day, unit: .day), y: .value("Liters", day.wasted))
                            .foregroundStyle(Color.orange)
                            .opacity(dimmed(day.day, selected: picked?.day, today: true))
                            .cornerRadius(span == .week ? 5 : 2)
                    }
                    if let picked {
                        RuleMark(x: .value("Day", picked.day, unit: .day))
                            .foregroundStyle(Color.secondary.opacity(0.3))
                            .annotation(position: .top, spacing: 4, overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))) {
                                ChartTooltip(title: dayTitle(picked.day), lines: [
                                    ("Wasted", picked.wasted.litersText, .orange),
                                    ("Share", picked.used > 0 ? "\(Int((picked.wasted / picked.used * 100).rounded()))%" : "–", .secondary),
                                ])
                            }
                    }
                }
                .chartXAxis { dayAxis }
                .holdToInspectX($wasteDay)
                .sensoryFeedback(.selection, trigger: picked?.day)
                .frame(height: 130)
                .padding(.top, 8)
            }
        }

        if let peak = WasteStats.peakHour(slots) {
            Card {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Peak waste hour")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                    Text(WasteStats.date(forHour: peak.hour).formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Text("\(peak.liters.litersText) this \(span.rawValue.lowercased()), mostly \(peak.topKind.title.lowercased())")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    WasteHourChart(slots: slots)
                        .frame(height: 190)
                        .padding(.top, 10)
                }
            }
        }
    }

    // MARK: - Helpers

    private var dayAxis: some AxisContent {
        AxisMarks(values: .stride(by: .day, count: span == .week ? 1 : 7)) { _ in
            AxisValueLabel(format: span == .week ? .dateTime.weekday(.narrow) : .dateTime.day().month(.abbreviated))
        }
    }

    /// Full strength for the inspected day; otherwise today is faded because it's still running.
    private func dimmed(_ day: Date, selected: Date?, today: Bool) -> Double {
        if let selected { return day == selected ? 1 : 0.3 }
        return today && Calendar.current.isDateInToday(day) ? 0.45 : 1
    }

    private func dayTitle(_ day: Date) -> String {
        Calendar.current.isDateInToday(day) ? "Today so far" : day.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
    }

    private func slice(at value: Double?, in slices: [Slice]) -> Slice? {
        guard let value else { return nil }
        var running = 0.0
        for slice in slices {
            running += slice.used
            if value <= running { return slice }
        }
        return slices.last
    }

    private func legendDot(_ color: Color, _ label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
    }

    private func limitLegend(_ limit: Double) -> some View {
        HStack(spacing: 4) {
            Rectangle()
                .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [3, 2]))
                .frame(width: 14, height: 0.5)
                .foregroundStyle(.secondary)
            Text("Limit \(Int(limit)) L").font(.caption).foregroundStyle(.secondary)
        }
    }

    // MARK: - Data

    private func dailyTotals(_ count: Int) -> [DayTotal] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        guard let start = cal.date(byAdding: .day, value: -(count - 1), to: today) else { return [] }
        let grouped = Dictionary(grouping: events.filter { $0.timestamp >= start }) { cal.startOfDay(for: $0.timestamp) }
        return (0..<count).compactMap { cal.date(byAdding: .day, value: $0, to: start) }.map { day in
            let readings = grouped[day] ?? []
            return DayTotal(day: day, used: readings.sum(\.liters), wasted: readings.sum(\.wastedLiters))
        }
    }

    private func deviceDays(_ events: [UsageEvent]) -> [DeviceDay] {
        let cal = Calendar.current
        return Dictionary(grouping: events) { DeviceDayKey(day: cal.startOfDay(for: $0.timestamp), name: $0.sensor?.name ?? "Other") }
            .map { DeviceDay(day: $0.key.day, name: $0.key.name, liters: $0.value.sum(\.liters)) }
            .sorted { ($0.day, $0.name) < ($1.day, $1.name) }
    }
}
