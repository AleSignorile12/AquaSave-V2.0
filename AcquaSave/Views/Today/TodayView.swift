import SwiftUI
import SwiftData

struct TodayView: View {
    @Binding var tab: AppTab

    @Environment(\.modelContext) private var context
    @Environment(\.theme) private var theme

    @Query(sort: \UsageEvent.timestamp, order: .reverse) private var events: [UsageEvent]
    @Query(sort: \DayResult.day) private var results: [DayResult]
    @Query(sort: \Sensor.name) private var sensors: [Sensor]
    @Query private var redemptions: [Redemption]
    @Query private var outages: [SensorOutage]

    @AppStorage("household") private var household = 2
    @AppStorage("userName") private var userName = ""
    @AppStorage("showSimulators") private var showSimulators = true

    @State private var showSettings = false
    @State private var showWaste = false

    private var todayEvents: [UsageEvent] {
        let start = Calendar.current.startOfDay(for: .now)
        return Array(events.prefix { $0.timestamp >= start })
    }

    var body: some View {
        let today = todayEvents
        let used = today.sum(\.liters)
        let wasted = today.sum(\.wastedLiters)
        let plan = Ledger.plan(results, household: household)
        let streak = Ledger.streak(results)
        let balance = Ledger.balance(results, redemptions)
        let tier = TierProgress(results).tier
        let tonight = tonightTile(plan: plan, used: used, tier: tier)

        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    BudgetHero(used: used, limit: plan.limit, calibrationDay: plan.calibrationDay,
                               simulations: showSimulators ? Simulation.allCases.filter { $0.sensor(in: sensors) != nil } : [],
                               onSimulate: simulate)

                    HStack(spacing: 12) {
                        Button { showWaste = true } label: {
                            StatTile(title: "Wasted", value: wasted.litersText,
                                     systemImage: "drop.triangle.fill", tint: .orange,
                                     caption: today.wasteSources.first?.label ?? "Nothing wasted yet",
                                     showsChevron: true)
                        }
                        .buttonStyle(.pressable)
                        .foregroundStyle(.primary)
                        .accessibilityHint("Shows how today's use and waste built up")

                        StatTile(title: "Tonight", value: tonight.value, tint: .credit, caption: tonight.caption) {
                            CreditMark(size: 14, weight: 0.16)
                        }
                    }

                    WeekStrip(results: results, todayUsed: used, limit: plan.limit, streak: streak)

                    SectionTitle(title: "Recent activity", trailing: today.isEmpty ? nil : today.count == 1 ? "1 reading" : "\(today.count) readings")
                    activity(today)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(userName.isEmpty ? "Hello" : "Hi, \(userName)")
            .navigationSubtitle(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)))
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    CreditCounter(balance: balance, weekEarned: results.suffix(7).sum(\.credits), tier: tier) {
                        tab = .rewards
                    }
                }
                ToolbarSpacer(.fixed, placement: .topBarTrailing)
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Settings", systemImage: "person.crop.circle") { showSettings = true }
                }
            }
            .sheet(isPresented: $showSettings) { ProfileView() }
            .sheet(isPresented: $showWaste) { WasteDetailView(events: today, limit: plan.limit) }
            .task(id: used) {
                WidgetBridge.save(todayLiters: used, dailyGoal: plan.limit, points: balance, streak: streak)
            }
        }
    }

    /// What today will pay at midnight if no more water runs, mirroring `Ledger.settle`.
    private func tonightTile(plan: HomePlan, used: Double, tier: Tier) -> (value: String, caption: String) {
        guard let baseline = plan.baseline else {
            let days = plan.daysUntilCredits
            return ("–", "Credits start in \(days) \(days == 1 ? "day" : "days")")
        }
        let start = Calendar.current.startOfDay(for: .now)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? start
        if outages.contains(where: { $0.overlaps(from: start, to: end) }) {
            return ("0", "A sensor went offline today")
        }
        let credits = Credits.earned(used: used, baseline: baseline, household: household, boost: tier.creditBoost)
        guard credits > 0 else { return ("0", "Above your usual day") }
        return ("+\(credits)", tier.creditBoost > 0
                ? "With your \(tier.name) boost, if you use no more"
                : "if you use no more today")
    }

    private func simulate(_ simulation: Simulation) {
        guard let sensor = simulation.sensor(in: sensors) else { return }
        withAnimation(.spring(duration: 0.5, bounce: 0)) {
            let event = UsageEvent(timestamp: .now, liters: simulation.liters,
                                   wastedLiters: simulation.waste == nil ? 0 : simulation.liters,
                                   wasteKind: simulation.waste)
            context.insert(event)
            event.sensor = sensor
            try? context.save()
        }
    }

    @ViewBuilder
    private func activity(_ today: [UsageEvent]) -> some View {
        Card(padding: 0) {
            if today.isEmpty {
                Text("No water used yet today.")
                    .foregroundStyle(.secondary)
                    .padding(16)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(today.prefix(6).enumerated()), id: \.element.id) { index, event in
                        if index > 0 { Divider().padding(.leading, 68) }
                        ActivityRow(event: event)
                    }
                }
            }
        }
    }
}

// MARK: - Credit counter

/// The balance in the toolbar. A tap flips the coin and opens a summary.
private struct CreditCounter: View {
    let balance: Int
    let weekEarned: Int
    let tier: Tier
    let onOpenRewards: () -> Void

    @State private var flips = 0
    @State private var showDetails = false

    private struct Flip {
        var angle = 0.0
        var scale = 1.0
        var lift = 0.0
    }

    var body: some View {
        Button {
            flips += 1
            showDetails = true
        } label: {
            // An HStack, not a Label: toolbars collapse Labels to their icon.
            HStack(spacing: 5) {
                CreditMark(size: 15, weight: 0.16)
                    .foregroundStyle(Color.credit)
                    .keyframeAnimator(initialValue: Flip(), trigger: flips) { mark, flip in
                        mark
                            .rotation3DEffect(.degrees(flip.angle), axis: (0, 1, 0), perspective: 0.6)
                            .scaleEffect(flip.scale)
                            .offset(y: flip.lift)
                    } keyframes: { _ in
                        KeyframeTrack(\.angle) {
                            CubicKeyframe(540, duration: 0.42)
                            SpringKeyframe(720, duration: 0.38, spring: .bouncy)
                        }
                        KeyframeTrack(\.scale) {
                            SpringKeyframe(1.45, duration: 0.16, spring: .snappy)
                            SpringKeyframe(1, duration: 0.5, spring: .bouncy(extraBounce: 0.2))
                        }
                        KeyframeTrack(\.lift) {
                            CubicKeyframe(-7, duration: 0.18)
                            SpringKeyframe(0, duration: 0.5, spring: .bouncy(extraBounce: 0.25))
                        }
                    }
                Text(balance, format: .number)
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText(value: Double(balance)))
            }
            .font(.body.weight(.semibold))
            .padding(.horizontal, 4)
        }
        .accessibilityLabel("\(balance) credits")
        .sensoryFeedback(.impact(weight: .medium, intensity: 0.8), trigger: flips)
        .popover(isPresented: $showDetails) {
            details
                .presentationCompactAdaptation(.popover)
        }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Your credits")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                HStack(alignment: .center, spacing: 8) {
                    CreditMark(size: 30, weight: 0.13).foregroundStyle(Color.credit)
                    Text(balance, format: .number)
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .monospacedDigit()
                }
                Text("+\(weekEarned) in the last 7 days · worth about \((Double(balance) / 100).formatted(.currency(code: "EUR")))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Label("\(tier.name) tier\(tier.creditBoost > 0 ? " · +\(Int(tier.creditBoost * 100))% credits" : "")",
                  systemImage: tier.systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tier.tint)

            Button {
                showDetails = false
                onOpenRewards()
            } label: {
                Text("Open Rewards").frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
        }
        .padding(20)
        .frame(width: 280)
    }
}

// MARK: - Simulators

/// Beta: fake readings for trying the app without hardware.
enum Simulation: String, CaseIterable, Identifiable {
    case shower, handWash, laundry, warmUp, leftRunning, leak

    var id: Self { self }

    var title: String {
        switch self {
        case .shower: "Shower"
        case .handWash: "Wash hands"
        case .laundry: "Laundry"
        case .warmUp: "Warm-up"
        case .leftRunning: "Tap left on"
        case .leak: "Leak"
        }
    }

    var systemImage: String {
        switch self {
        case .shower: "shower.fill"
        case .handWash: "hands.and.sparkles.fill"
        case .laundry: "washer.fill"
        case .warmUp: WasteKind.hotWater.systemImage
        case .leftRunning: WasteKind.leftRunning.systemImage
        case .leak: WasteKind.leak.systemImage
        }
    }

    var liters: Double {
        switch self {
        case .shower: 45
        case .handWash: 1.5
        case .laundry: 50
        case .warmUp: 4
        case .leftRunning: 8
        case .leak: 3
        }
    }

    var waste: WasteKind? {
        switch self {
        case .warmUp: .hotWater
        case .leftRunning: .leftRunning
        case .leak: .leak
        default: nil
        }
    }

    private var categories: [DeviceCategory] {
        switch self {
        case .shower: [.shower]
        case .handWash: [.faucet]
        case .laundry: [.washingMachine, .dishwasher]
        case .warmUp: [.shower, .faucet]
        case .leftRunning: [.faucet, .irrigation]
        case .leak: [.toilet, .faucet]
        }
    }

    /// The first sensor that could have produced this reading.
    func sensor(in sensors: [Sensor]) -> Sensor? {
        categories.lazy.compactMap { category in sensors.first { $0.category == category } }.first
    }
}

// MARK: - Budget hero

private struct BudgetHero: View {
    let used: Double
    let limit: Double
    let calibrationDay: Int?
    let simulations: [Simulation]
    let onSimulate: (Simulation) -> Void

    @Environment(\.theme) private var theme
    @State private var simulated = 0

    private var remaining: Double { limit - used }
    private var level: Double { min(max(remaining / limit, 0), 1) }
    private var tint: Color { remaining < 0 ? .red : level < 0.25 ? .orange : theme.color }
    private var status: (text: String, icon: String, tint: Color) {
        if let calibrationDay {
            return ("Measuring · day \(calibrationDay) of \(Credits.calibrationDays)", "ruler", .secondary)
        }
        if remaining < 0 { return ("Over your limit", "exclamationmark.circle.fill", tint) }
        if level < 0.25 { return ("Running low", "gauge.with.dots.needle.33percent", tint) }
        return ("On track", "checkmark.circle.fill", tint)
    }

    var body: some View {
        Card(padding: 18) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 20) {
                    WaterDrop(level: level, tint: tint)
                        .frame(width: 76, height: 116)
                        .padding(.leading, 6)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(remaining >= 0 ? "Left today" : "Over by")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)

                        HStack(alignment: .firstTextBaseline, spacing: 3) {
                            Text("\(Int(abs(remaining).rounded()))")
                                .font(.system(size: 52, weight: .bold, design: .rounded))
                                .contentTransition(.numericText(value: remaining))
                                .monospacedDigit()
                            Text("L")
                                .font(.system(.title2, design: .rounded).weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)

                        Text("\(Int(used.rounded())) of \(Int(limit)) L used")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .contentTransition(.numericText(value: used))

                        Label(status.text, systemImage: status.icon)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(status.tint)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(status.tint.opacity(0.12), in: .capsule)
                            .padding(.top, 6)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .accessibilityElement(children: .combine)

                if !simulations.isEmpty { simulators }
            }
        }
        .animation(.spring(duration: 0.5, bounce: 0), value: used)
    }

    private var simulators: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text("Try a reading")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text("BETA")
                    .font(.system(size: 9, weight: .heavy))
                    .tracking(0.6)
                    .foregroundStyle(theme.color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(theme.color.opacity(0.14), in: .capsule)
            }
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(simulations) { simulation in
                        let chipTint = simulation.waste?.tint ?? theme.color
                        Button {
                            simulated += 1
                            onSimulate(simulation)
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: simulation.systemImage)
                                Text(simulation.title)
                                Text("+\(simulation.liters.litersText)")
                                    .foregroundStyle(chipTint.opacity(0.8))
                            }
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(chipTint)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(chipTint.opacity(0.12), in: .capsule)
                        }
                        .buttonStyle(.pressable)
                        .accessibilityLabel("Simulate \(simulation.title), \(simulation.liters.litersText)")
                    }
                }
            }
            .scrollIndicators(.hidden)
            .contentMargins(.horizontal, 18, for: .scrollContent)
            .padding(.horizontal, -18)
        }
        .sensoryFeedback(.impact(weight: .light), trigger: simulated)
    }
}

// MARK: - Stat tile

struct StatTile<Icon: View>: View {
    let title: String
    let value: String
    let tint: Color
    let caption: String
    var showsChevron = false
    let icon: Icon

    init(title: String, value: String, tint: Color, caption: String, showsChevron: Bool = false,
         @ViewBuilder icon: () -> Icon) {
        self.title = title
        self.value = value
        self.tint = tint
        self.caption = caption
        self.showsChevron = showsChevron
        self.icon = icon()
    }

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label { Text(title) } icon: { icon }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(tint)
                    if showsChevron {
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                            .accessibilityHidden(true)
                    }
                }
                Text(value)
                    .font(.system(.title, design: .rounded).weight(.bold))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2, reservesSpace: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

extension StatTile where Icon == Image {
    init(title: String, value: String, systemImage: String, tint: Color, caption: String, showsChevron: Bool = false) {
        self.init(title: title, value: value, tint: tint, caption: caption, showsChevron: showsChevron) {
            Image(systemName: systemImage)
        }
    }
}

// MARK: - Week strip

private struct WeekStrip: View {
    let results: [DayResult]
    let todayUsed: Double
    let limit: Double
    let streak: Int

    @Environment(\.theme) private var theme

    var body: some View {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let byDay = Dictionary(results.suffix(14).map { ($0.day, $0) }, uniquingKeysWith: { first, _ in first })
        let days = (0..<7).reversed().compactMap { cal.date(byAdding: .day, value: -$0, to: today) }

        Card {
            VStack(alignment: .leading, spacing: 14) {
                Label("\(streak)-day streak", systemImage: "flame.fill")
                    .font(.headline)
                    .foregroundStyle(streak > 0 ? Color.orange : .secondary)

                HStack(spacing: 0) {
                    ForEach(days, id: \.self) { day in
                        VStack(spacing: 6) {
                            Text(day.formatted(.dateTime.weekday(.narrow)))
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(day == today ? .primary : .secondary)
                            dot(day == today ? nil : byDay[day], isToday: day == today)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func dot(_ result: DayResult?, isToday: Bool) -> some View {
        let size: CGFloat = 32
        if isToday {
            let progress = min(todayUsed / limit, 1)
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: 4)
                .overlay {
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(todayUsed > limit ? Color.red : theme.color, style: .init(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: size - 4, height: size - 4)
                .frame(width: size, height: size)
                .accessibilityLabel("Today, \(Int(progress * 100)) percent of limit used")
        } else if let result {
            let style: (icon: String, fg: Color, bg: Color, label: String) = switch result.status {
            case .calibrating: ("ruler", .secondary, Color.secondary.opacity(0.12), "Measuring baseline")
            case .offline: ("wifi.slash", .secondary, Color.secondary.opacity(0.12), "Sensor offline")
            case .settled where result.metLimit: ("checkmark", .white, theme.color, "Under limit")
            case .settled: ("xmark", .red, Color.red.opacity(0.14), "Over limit")
            }
            Image(systemName: style.icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(style.fg)
                .frame(width: size, height: size)
                .background(style.bg, in: .circle)
                .accessibilityLabel(style.label)
        } else {
            Circle()
                .strokeBorder(Color.secondary.opacity(0.25), style: .init(lineWidth: 1.5, dash: [3, 3]))
                .frame(width: size, height: size)
                .accessibilityLabel("No readings")
        }
    }
}

// MARK: - Activity row

private struct ActivityRow: View {
    let event: UsageEvent

    var body: some View {
        let category = event.sensor?.category ?? .other
        HStack(spacing: 12) {
            IconCircle(systemImage: category.systemImage, tint: category.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(event.sensor?.name ?? "Sensor")
                    .font(.body.weight(.semibold))
                    .lineLimit(1)
                Text(event.timestamp, format: .dateTime.hour().minute())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(event.liters.litersText)
                    .font(.body.weight(.semibold))
                    .monospacedDigit()
                if let kind = event.wasteKind, event.wastedLiters >= 0.1 {
                    Text(kind.title)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(kind.tint)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }
}
