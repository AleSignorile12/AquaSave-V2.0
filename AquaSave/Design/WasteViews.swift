import SwiftUI
import Charts

/// Wasted volume against time of day, stacked by type. Touch and hold to read an hour.
struct WasteHourChart: View {
    let slots: [WasteStats.Slot]

    @State private var selected: Date?

    var body: some View {
        let start = WasteStats.date(forHour: 0)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? start
        let hour = selected.map { Calendar.current.component(.hour, from: $0) }
        let inHour = slots.filter { $0.hour == hour }

        Chart {
            ForEach(slots) { slot in
                BarMark(x: .value("Time", WasteStats.date(forHour: slot.hour), unit: .hour),
                        y: .value("Liters", slot.liters))
                    .foregroundStyle(by: .value("Type", slot.kind.title))
                    .cornerRadius(2)
                    .opacity(hour == nil || slot.hour == hour ? 1 : 0.35)
            }
            if let hour {
                RuleMark(x: .value("Time", WasteStats.date(forHour: hour), unit: .hour))
                    .foregroundStyle(Color.secondary.opacity(0.35))
                    .annotation(position: .top, spacing: 4, overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))) {
                        let from = WasteStats.date(forHour: hour)
                        ChartTooltip(title: from.formatted(date: .omitted, time: .shortened) + "–"
                                        + from.addingTimeInterval(3600).formatted(date: .omitted, time: .shortened),
                                     lines: inHour.isEmpty ? [("No waste", "0 L", .secondary)]
                                        : inHour.map { ($0.kind.title, $0.liters.litersText, $0.kind.tint) })
                    }
            }
        }
        .chartForegroundStyleScale(domain: WasteKind.allCases.map(\.title),
                                   range: WasteKind.allCases.map(\.tint))
        .chartXScale(domain: start...end)
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour, count: 6)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.hour())
            }
        }
        .chartYAxisLabel("Liters")
        .chartLegend(position: .bottom, alignment: .leading)
        .holdToInspectX($selected)
        .sensoryFeedback(.selection, trigger: hour)
    }
}

extension View {
    /// Touch and hold, then slide, to inspect a chart. A quick swipe still scrolls the page.
    func holdToInspectX<P: Plottable>(_ selection: Binding<P?>) -> some View {
        chartXSelection(value: selection)
            .chartGesture { proxy in
                LongPressGesture(minimumDuration: 0.15)
                    .sequenced(before: DragGesture(minimumDistance: 0))
                    .onChanged { value in
                        if case .second(true, let drag?) = value { proxy.selectXValue(at: drag.location.x) }
                    }
                    .onEnded { _ in selection.wrappedValue = nil }
            }
    }

    func holdToInspectAngle<P: Plottable>(_ selection: Binding<P?>) -> some View {
        chartAngleSelection(value: selection)
            .chartGesture { proxy in
                LongPressGesture(minimumDuration: 0.15)
                    .sequenced(before: DragGesture(minimumDistance: 0))
                    .onChanged { value in
                        guard case .second(true, let drag?) = value else { return }
                        // Clockwise from 12 o'clock, the way sector charts are laid out.
                        let dx = drag.location.x - proxy.plotSize.width / 2
                        let dy = drag.location.y - proxy.plotSize.height / 2
                        let radians = atan2(dx, -dy)
                        proxy.selectAngleValue(at: .radians(radians < 0 ? radians + 2 * .pi : radians))
                    }
                    .onEnded { _ in selection.wrappedValue = nil }
            }
    }
}

/// Where the waste is: one row per fixture and kind, with the fix.
struct WasteSourceList: View {
    let sources: [WasteStats.Source]

    var body: some View {
        Card(padding: 0) {
            if sources.isEmpty {
                Label("No waste detected.", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(.secondary)
                    .padding(16)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(sources.enumerated()), id: \.element.id) { index, source in
                        if index > 0 { Divider().padding(.leading, 68) }
                        row(source)
                    }
                }
            }
        }
    }

    private func row(_ source: WasteStats.Source) -> some View {
        HStack(alignment: .top, spacing: 12) {
            IconCircle(systemImage: source.category.systemImage, tint: source.kind.tint)
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline) {
                    Text(source.label).font(.body.weight(.semibold))
                    Spacer(minLength: 8)
                    Text(source.liters.litersText)
                        .font(.body.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(source.kind.tint)
                }
                if !source.location.isEmpty {
                    Text(source.location).font(.caption).foregroundStyle(.secondary)
                }
                Text(source.kind.fix(for: source.category))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }
}
