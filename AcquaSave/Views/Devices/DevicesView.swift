import SwiftUI
import SwiftData

// MARK: - Devices View

struct DevicesView: View {

    @Environment(\.modelContext) private var context
    @Environment(\.theme) private var theme
    @Query(sort: \Sensor.name) private var sensors: [Sensor]

    @State private var showAdd = false
    @State private var pendingRemoval: Sensor?

    var body: some View {
        let totalAll = sensors.sum { $0.events.sum(\.liters) }
        let rows = sensors
            .map { (sensor: $0, summary: DeviceSummary(sensor: $0, totalAll: totalAll)) }
            .sorted { $0.summary.totalLiters > $1.summary.totalLiters }
        let activeToday = sensors.filter { $0.events.contains { Calendar.current.isDateInToday($0.timestamp) } }.count

        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    header(total: totalAll, active: activeToday)
                    overviewRow(rows.map(\.summary), total: totalAll)

                    if sensors.isEmpty {
                        emptyStateCard
                    } else {
                        ForEach(rows, id: \.sensor.id) { row in
                            DeviceCard(summary: row.summary, category: row.sensor.category,
                                       offlineSince: row.sensor.currentOutage?.start) { liters in
                                simulateUsage(on: row.sensor, liters: liters)
                            }
                            .contextMenu {
                                Button(row.sensor.currentOutage == nil ? "Simulate going offline" : "Reconnect",
                                       systemImage: row.sensor.currentOutage == nil ? "wifi.slash" : "wifi") {
                                    toggleOutage(row.sensor)
                                }
                                Button("Remove sensor", systemImage: "trash", role: .destructive) {
                                    pendingRemoval = row.sensor
                                }
                            }
                        }
                        addSensorCard
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .background(devicesBackground)
            .navigationTitle("Devices")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink { ShopView() } label: {
                        Label("Sensor Shop", systemImage: "bag")
                    }
                }
                ToolbarSpacer(.fixed, placement: .topBarTrailing)
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add sensor", systemImage: "plus") { showAdd = true }
                }
            }
            .sheet(isPresented: $showAdd) {
                AddDeviceSheet { name, location, category in
                    context.insert(Sensor(name: name, location: location, category: category))
                    try? context.save()
                    showAdd = false
                }
            }
            .confirmationDialog("Remove \(pendingRemoval?.name ?? "sensor")?",
                                isPresented: .init(get: { pendingRemoval != nil }, set: { if !$0 { pendingRemoval = nil } }),
                                titleVisibility: .visible) {
                Button("Remove", role: .destructive) {
                    if let pendingRemoval { context.delete(pendingRemoval) }
                    try? context.save()
                }
            } message: {
                Text("Its readings are deleted too. Credits you've already earned stay.")
            }
        }
    }

    // MARK: - Main Sections

    private func header(total: Double, active: Int) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Track where water is used most and explore your device habits.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                topMetric(title: "Devices", value: "\(sensors.count)", icon: "dot.radiowaves.left.and.right", tint: .teal)
                topMetric(title: "Active today", value: "\(active)", icon: "bolt.fill", tint: .green)
                topMetric(title: "Total", value: "\(Int(total).formatted()) L", icon: "drop.fill", tint: .blue)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func overviewRow(_ summaries: [DeviceSummary], total: Double) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Card {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Top device")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if let top = summaries.first, top.totalLiters > 0 {
                        Text(top.name).font(.headline).lineLimit(1)
                        Text("\(Int(top.totalLiters).formatted()) L")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Text(top.location).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    } else {
                        Text("No data yet").font(.headline).foregroundStyle(.secondary)
                    }
                }
                .frame(maxHeight: .infinity, alignment: .top)
            }

            Card {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Usage spread")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(total > 0 ? "\(summaries.filter { $0.totalLiters > 0 }.count) sensors" : "Waiting")
                        .font(.headline)

                    spreadBar(summaries, total: total)
                        .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 3) {
                        ForEach(Array(summaries.prefix(2).enumerated()), id: \.offset) { index, summary in
                            HStack(spacing: 5) {
                                Circle().fill(Color.chart(index)).frame(width: 6, height: 6)
                                Text("\(summary.name) \(Int((summary.shareOfTotal * 100).rounded()))%")
                                    .lineLimit(1)
                            }
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .frame(maxHeight: .infinity, alignment: .top)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private func spreadBar(_ summaries: [DeviceSummary], total: Double) -> some View {
        GeometryReader { geo in
            let shown = summaries.filter { $0.totalLiters > 0 }
            let gaps = CGFloat(max(shown.count - 1, 0)) * 2
            HStack(spacing: 2) {
                if shown.isEmpty {
                    Capsule().fill(Color.secondary.opacity(0.15))
                }
                ForEach(Array(shown.enumerated()), id: \.offset) { index, summary in
                    Rectangle()
                        .fill(Color.chart(index))
                        .frame(width: max((geo.size.width - gaps) * summary.shareOfTotal, 2))
                }
            }
            .clipShape(.capsule)
        }
        .frame(height: 10)
    }

    private var emptyStateCard: some View {
        VStack(spacing: 14) {
            Card {
                ContentUnavailableView(
                    "No devices yet",
                    systemImage: "dot.radiowaves.left.and.right",
                    description: Text("Add your first sensor to start tracking usage across your home.")
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            addSensorCard
        }
    }

    /// The way in for new sensors, always at the end of the list.
    private var addSensorCard: some View {
        Button { showAdd = true } label: {
            HStack(spacing: 14) {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(theme.color.gradient, in: .circle)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Add a sensor")
                        .font(.headline)
                    Text("Clip one onto a tap, shower or appliance")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.color.opacity(0.08), in: .rect(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(theme.color.opacity(0.45), style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
            }
        }
        .buttonStyle(.pressable)
        .foregroundStyle(.primary)
    }

    // MARK: - Styling Helpers

    private var devicesBackground: some View {
        ZStack {
            Color(.systemGroupedBackground)
            LinearGradient(colors: [theme.color.opacity(0.10), Color.blue.opacity(0.04), .clear],
                           startPoint: .top, endPoint: .center)
        }
        .ignoresSafeArea()
    }

    private func topMetric(title: String, value: String, icon: String, tint: Color) -> some View {
        VStack(spacing: 8) {
            IconCircle(systemImage: icon, tint: tint, size: 38)

            VStack(spacing: 3) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 104)
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 20, style: .continuous))
    }

    // MARK: - Actions

    /// Demo stand-in for a sensor that stops reporting: days it touches earn no credits.
    private func toggleOutage(_ sensor: Sensor) {
        if let outage = sensor.currentOutage {
            outage.end = .now
        } else {
            let outage = SensorOutage(start: .now)
            context.insert(outage)
            outage.sensor = sensor
        }
        try? context.save()
    }

    private func simulateUsage(on sensor: Sensor, liters: Double) {
        withAnimation(.spring(duration: 0.45, bounce: 0)) {
            let event = UsageEvent(timestamp: .now, liters: liters)
            context.insert(event)
            event.sensor = sensor
            try? context.save()
        }
    }
}

// MARK: - Device Summary

struct DeviceSummary {
    let name: String
    let location: String
    let totalLiters: Double
    let wastedLiters: Double
    let usageCount: Int
    let lastUsedAt: Date?
    let shareOfTotal: Double

    init(sensor: Sensor, totalAll: Double) {
        let events = sensor.events
        name = sensor.name
        location = sensor.location
        totalLiters = events.sum(\.liters)
        wastedLiters = events.sum(\.wastedLiters)
        usageCount = events.count
        lastUsedAt = events.map(\.timestamp).max()
        shareOfTotal = totalAll > 0 ? totalLiters / totalAll : 0
    }

    var averageLitersPerUse: Double { usageCount > 0 ? totalLiters / Double(usageCount) : 0 }
    var wasteShare: Double { totalLiters > 0 ? wastedLiters / totalLiters : 0 }

    var efficiencyLabel: String {
        guard usageCount > 0 else { return "New" }
        switch wasteShare {
        case ..<0.05: return "Efficient"
        case ..<0.15: return "Average"
        default: return "High waste"
        }
    }

    var tip: String {
        let pct = Int((wasteShare * 100).rounded())
        switch efficiencyLabel {
        case "New": return "Waiting for its first reading."
        case "Efficient": return "Nice — this device is staying efficient."
        case "Average": return "\(pct)% of its water was wasted. It could be optimized."
        default: return "\(pct)% of its water was wasted. This is your biggest saving opportunity."
        }
    }
}

// MARK: - Device Card

private struct DeviceCard: View {

    let summary: DeviceSummary
    let category: DeviceCategory
    let offlineSince: Date?
    let onSimulate: (Double) -> Void

    @State private var taps = 0

    private var tint: Color { category.tint }

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                headerSection
                metricsSection
                usageShareSection
                footerSection
                actionsSection
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: taps)
    }

    private var headerSection: some View {
        HStack(spacing: 12) {
            IconCircle(systemImage: category.systemImage, tint: tint, size: 46)

            VStack(alignment: .leading, spacing: 4) {
                Text(summary.name)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(summary.location)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                if let offlineSince {
                    Label("Offline since \(offlineSince.formatted(date: .omitted, time: .shortened))", systemImage: "wifi.slash")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.red)
                        .lineLimit(1)
                }
            }

            Spacer()

            Text(summary.efficiencyLabel)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(tint.opacity(0.12), in: .capsule)
                .foregroundStyle(tint)
                .lineLimit(1)
        }
    }

    private var metricsSection: some View {
        HStack(spacing: 10) {
            metric("Total", "\(Int(summary.totalLiters).formatted()) L")
            metric("Uses", "\(summary.usageCount)")
            metric("Avg/use", summary.averageLitersPerUse.litersText)
        }
    }

    private var usageShareSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Share of total usage")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(Int((summary.shareOfTotal * 100).rounded()))%")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(tint)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(tint.opacity(0.10), in: .capsule)
                    .contentTransition(.numericText(value: summary.shareOfTotal))
            }

            ProgressView(value: summary.shareOfTotal)
                .tint(tint)
        }
    }

    private var footerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(summary.lastUsedAt.map { "Last used: \($0.formatted(date: .abbreviated, time: .shortened))" } ?? "No usage logged yet",
                  systemImage: "clock")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Text(summary.tip)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Simulate a reading")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            HStack(spacing: 10) {
                actionButton(2, prominent: false)
                actionButton(5, prominent: false)
                actionButton(20, prominent: true)
            }
        }
    }

    private func metric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.tertiarySystemGroupedBackground), in: .rect(cornerRadius: 16, style: .continuous))
    }

    private func actionButton(_ liters: Double, prominent: Bool) -> some View {
        Button {
            taps += 1
            onSimulate(liters)
        } label: {
            Text("+\(Int(liters))L")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(prominent ? tint.opacity(0.14) : Color(.tertiarySystemGroupedBackground),
                            in: .rect(cornerRadius: 15, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(prominent ? tint.opacity(0.18) : Color.primary.opacity(0.05), lineWidth: 1)
                )
        }
        .buttonStyle(.pressable)
        .foregroundStyle(prominent ? tint : .primary)
        .accessibilityLabel("Add \(Int(liters)) liters to \(summary.name)")
    }
}

// MARK: - Add Device Sheet

private struct AddDeviceSheet: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme

    @State private var name = ""
    @State private var location = ""
    @State private var category: DeviceCategory = .faucet
    @State private var preset: SensorPreset.ID?

    let onAdd: (String, String, DeviceCategory) -> Void

    private static let places = ["Kitchen", "Main bathroom", "Guest bathroom", "Laundry", "Garden"]

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    preview

                    section("Quick pick") {
                        ScrollView(.horizontal) {
                            HStack(spacing: 8) {
                                ForEach(SensorPreset.all) { item in
                                    chip(item.name, systemImage: item.category.systemImage,
                                         tint: item.category.tint, on: preset == item.id) {
                                        preset = item.id
                                        name = item.name
                                        location = item.location
                                        category = item.category
                                    }
                                }
                            }
                        }
                        .scrollIndicators(.hidden)
                        .contentMargins(.horizontal, 20, for: .scrollContent)
                        .padding(.horizontal, -20)
                    }

                    section("Name") {
                        field("e.g. Shower Head", text: $name)
                    }

                    section("Where is it?") {
                        field("e.g. Bathroom", text: $location)
                        ScrollView(.horizontal) {
                            HStack(spacing: 8) {
                                ForEach(Self.places, id: \.self) { place in
                                    chip(place, systemImage: nil, tint: theme.color, on: location == place) {
                                        location = place
                                    }
                                }
                            }
                        }
                        .scrollIndicators(.hidden)
                        .contentMargins(.horizontal, 20, for: .scrollContent)
                        .padding(.horizontal, -20)
                    }

                    section("What does it measure?") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                            ForEach(DeviceCategory.allCases, id: \.self) { item in
                                categoryTile(item)
                            }
                        }
                    }

                    NavigationLink { ShopView() } label: {
                        HStack(spacing: 12) {
                            IconCircle(systemImage: "bag.fill", tint: theme.color, size: 36)
                            VStack(alignment: .leading, spacing: 1) {
                                Text("No sensor yet?").font(.subheadline.weight(.semibold))
                                Text("Browse the Sensor Shop").font(.footnote).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(14)
                        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 18, style: .continuous))
                    }
                    .buttonStyle(.pressable)
                    .foregroundStyle(.primary)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("New Sensor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    let place = location.trimmingCharacters(in: .whitespacesAndNewlines)
                    onAdd(trimmedName, place.isEmpty ? "Home" : place, category)
                } label: {
                    Text("Add sensor")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .controlSize(.extraLarge)
                .disabled(trimmedName.isEmpty)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }
            .sensoryFeedback(.selection, trigger: category)
            .onChange(of: name) {
                if let preset, SensorPreset.all.first(where: { $0.id == preset })?.name != name { self.preset = nil }
            }
        }
    }

    private var preview: some View {
        HStack(spacing: 14) {
            IconCircle(systemImage: category.systemImage, tint: category.tint, size: 56)
                .contentTransition(.symbolEffect(.replace))
            VStack(alignment: .leading, spacing: 3) {
                Text(trimmedName.isEmpty ? "New sensor" : trimmedName)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(trimmedName.isEmpty ? .secondary : .primary)
                    .lineLimit(1)
                Text("\(location.isEmpty ? "Home" : location) · \(category.rawValue)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay(alignment: .topTrailing) {
                    Image(systemName: category.systemImage)
                        .font(.system(size: 90))
                        .foregroundStyle(category.tint.opacity(0.08))
                        .offset(x: 10, y: -6)
                }
                .clipShape(.rect(cornerRadius: 24, style: .continuous))
        }
        .padding(.top, 8)
        .animation(.snappy(duration: 0.25), value: category)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            content()
        }
    }

    private func field(_ prompt: String, text: Binding<String>) -> some View {
        TextField(prompt, text: text)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 16, style: .continuous))
    }

    private func chip(_ title: String, systemImage: String?, tint: Color, on: Bool, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.snappy(duration: 0.2)) { action() }
        } label: {
            HStack(spacing: 5) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title)
            }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(on ? .white : tint)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(on ? AnyShapeStyle(tint) : AnyShapeStyle(tint.opacity(0.12)), in: .capsule)
        }
        .buttonStyle(.pressable)
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    private func categoryTile(_ item: DeviceCategory) -> some View {
        let on = category == item
        return Button {
            withAnimation(.snappy(duration: 0.2)) {
                category = item
                preset = nil
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: item.systemImage)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(on ? .white : item.tint)
                    .frame(width: 46, height: 46)
                    .background(on ? AnyShapeStyle(item.tint) : AnyShapeStyle(item.tint.opacity(0.14)), in: .circle)
                Text(item.rawValue)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(on ? .primary : .secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.pressable)
        .accessibilityLabel(item.rawValue)
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}
