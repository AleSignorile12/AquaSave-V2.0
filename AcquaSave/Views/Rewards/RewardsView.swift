import SwiftUI
import SwiftData

struct RewardsView: View {
    @Environment(\.theme) private var theme

    @Query(sort: \DayResult.day) private var results: [DayResult]
    @Query(sort: \Redemption.date, order: .reverse) private var redemptions: [Redemption]

    @AppStorage("trackedReward") private var trackedID = ""

    @State private var selected: Reward?

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        let balance = Ledger.balance(results, redemptions)
        let weekEarned = results.suffix(7).sum(\.credits)
        let tracked = Reward.catalog.first { $0.id == trackedID }
        let milestone = tracked ?? Reward.catalog.filter { $0.cost > balance }.min { $0.cost < $1.cost }

        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    WalletCard(balance: balance, weekEarned: weekEarned, milestone: milestone, isTracked: tracked != nil)

                    TierCard(progress: TierProgress(results))

                    ForEach(Reward.Group.allCases, id: \.self) { group in
                        SectionTitle(title: group.rawValue)
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(Reward.catalog.filter { $0.group == group }) { reward in
                                Button { selected = reward } label: {
                                    RewardTile(reward: reward, balance: balance, isTracked: reward.id == trackedID)
                                }
                                .buttonStyle(.pressable)
                                .contextMenu { trackButton(reward) }
                            }
                        }
                        if group == .sensors {
                            NavigationLink { ShopView() } label: {
                                Card {
                                    HStack(spacing: 12) {
                                        IconCircle(systemImage: "bag.fill", tint: theme.color, size: 36)
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text("Sensor Shop").font(.subheadline.weight(.semibold))
                                            Text("Your tier discount is applied at checkout")
                                                .font(.footnote).foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.footnote.weight(.semibold))
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                            }
                            .buttonStyle(.pressable)
                            .foregroundStyle(.primary)
                        }
                    }

                    SectionTitle(title: "How you earn")
                    EarnCard()

                    NavigationLink {
                        CreditHistoryView(results: results, redemptions: redemptions)
                    } label: {
                        Card {
                            HStack {
                                Label("Credit history", systemImage: "clock.arrow.circlepath")
                                    .font(.body.weight(.semibold))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .buttonStyle(.pressable)
                    .foregroundStyle(.primary)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Rewards")
            .sheet(item: $selected) { reward in
                RedeemSheet(reward: reward, balance: balance, trackedID: $trackedID)
            }
            .sensoryFeedback(.selection, trigger: trackedID)
        }
    }

    private func trackButton(_ reward: Reward) -> some View {
        Button(reward.id == trackedID ? "Stop tracking" : "Track this reward",
               systemImage: reward.id == trackedID ? "pin.slash" : "pin") {
            withAnimation(.snappy) { trackedID = reward.id == trackedID ? "" : reward.id }
        }
    }
}

extension Reward {
    func color(_ theme: AccentTheme) -> Color { tint ?? theme.color }
}

// MARK: - Wallet

private struct WalletCard: View {
    let balance: Int
    let weekEarned: Int
    let milestone: Reward?
    let isTracked: Bool

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 6) {
                    CreditMark(size: 14, weight: 0.16)
                    Text("Credits")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.85))
                Spacer()
                Text("+\(weekEarned) this week")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.white.opacity(0.16), in: .capsule)
            }

            HStack(alignment: .center, spacing: 8) {
                CreditMark(size: 40, weight: 0.12)
                    .foregroundStyle(.white.opacity(0.9))
                Text(balance, format: .number)
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .contentTransition(.numericText(value: Double(balance)))
                    .monospacedDigit()
            }
            .foregroundStyle(.white)

            if let milestone {
                let ready = balance >= milestone.cost
                HStack(spacing: 12) {
                    Image(systemName: milestone.systemImage)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(.white.opacity(0.18), in: .circle)
                    VStack(alignment: .leading, spacing: 7) {
                        HStack(spacing: 5) {
                            if isTracked {
                                Image(systemName: "pin.fill").font(.caption2)
                            }
                            Text(ready ? "\(milestone.title) is ready to redeem"
                                       : "\(milestone.cost - balance) more for \(milestone.title)")
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.92))
                        ProgressView(value: Double(min(max(balance, 0), milestone.cost)), total: Double(milestone.cost))
                            .tint(.white)
                    }
                }
            } else {
                Text("You can redeem anything in the catalog.")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack(alignment: .bottomTrailing) {
                LinearGradient(colors: [theme.deep.0, theme.deep.1], startPoint: .topLeading, endPoint: .bottomTrailing)
                CreditMark(size: 190, weight: 0.12)
                    .foregroundStyle(.white.opacity(0.06))
                    .offset(x: 40, y: 50)
            }
        }
        .clipShape(.rect(cornerRadius: 28, style: .continuous))
        .accessibilityElement(children: .combine)
        .animation(.snappy, value: milestone?.id)
    }
}

// MARK: - Tier

private struct TierCard: View {
    let progress: TierProgress

    var body: some View {
        let tier = progress.tier
        Card {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    IconCircle(systemImage: tier.systemImage, tint: tier.tint, size: 46)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(tier.name) tier").font(.headline)
                        Text(tier.perks.joined(separator: " · "))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                    HStack(spacing: 3) {
                        ForEach(Tier.allCases, id: \.self) { step in
                            Capsule()
                                .fill(step <= tier ? tier.tint : Color.secondary.opacity(0.2))
                                .frame(width: 8, height: 8)
                        }
                    }
                    .accessibilityHidden(true)
                }

                if let next = tier.next, let toNext = progress.toNext {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Next: \(next.name) · \(next.perks.first ?? "")")
                            .font(.subheadline.weight(.semibold))
                        bar("Saved", "\(Int(progress.saved).formatted()) of \(Int(next.savedNeeded).formatted()) L",
                            toNext.saved, next.tint)
                        bar("Best streak", "\(progress.bestStreak) of \(next.streakNeeded) days", toNext.streak, .orange)
                    }
                } else {
                    Text("You've reached the top tier. Every perk is yours.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func bar(_ title: String, _ value: String, _ fraction: Double, _ tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(title).font(.caption.weight(.medium)).foregroundStyle(.secondary)
                Spacer()
                Text(value).font(.caption.weight(.semibold)).monospacedDigit()
                if fraction >= 1 {
                    Image(systemName: "checkmark.circle.fill").font(.caption).foregroundStyle(tint)
                }
            }
            ProgressView(value: fraction).tint(tint)
        }
    }
}

// MARK: - Tiles

private struct RewardTile: View {
    let reward: Reward
    let balance: Int
    let isTracked: Bool

    @Environment(\.theme) private var theme

    var body: some View {
        let affordable = balance >= reward.cost
        let tint = reward.color(theme)
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                IconCircle(systemImage: reward.systemImage, tint: tint, size: 42)
                Spacer()
                if isTracked {
                    Image(systemName: "pin.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(tint)
                        .padding(6)
                        .background(tint.opacity(0.14), in: .circle)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(reward.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2, reservesSpace: true)
                Text(reward.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .multilineTextAlignment(.leading)

            HStack(spacing: 4) {
                if !affordable { Image(systemName: "lock.fill").font(.caption2) }
                CreditAmount(value: reward.cost, size: 13)
            }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(affordable ? Color.credit : .secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background((affordable ? Color.credit : Color.secondary).opacity(0.12), in: .capsule)

            ProgressView(value: Double(min(max(balance, 0), reward.cost)), total: Double(reward.cost))
                .tint(affordable ? Color.credit : tint)
                .opacity(affordable ? 0 : 1)
                .accessibilityHidden(affordable)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(isTracked ? tint.opacity(0.6) : .clear, lineWidth: 1.5)
        }
        .foregroundStyle(.primary)
        .animation(.snappy, value: isTracked)
    }
}

private struct EarnCard: View {
    @Environment(\.theme) private var theme

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                rule("ruler", .secondary, "Your first \(Credits.calibrationDays) days set your usual day", "Credits start once we know it")
                rule("drop.fill", theme.color, "Use less than your usual day", "+1 credit for every \(Int(Credits.litersPerCredit)) L you save")
                rule("chart.line.uptrend.xyaxis", .indigo, "Climb the tiers", "Save more and keep a streak for up to +15% credits")
                rule("wifi.slash", .orange, "Keep every sensor online", "Days with an offline sensor don't earn")
            }
        }
    }

    private func rule(_ icon: String, _ tint: Color, _ title: String, _ detail: String) -> some View {
        HStack(spacing: 12) {
            IconCircle(systemImage: icon, tint: tint, size: 36)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(detail).font(.footnote).foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Redeem

private struct RedeemSheet: View {
    let reward: Reward
    let balance: Int
    @Binding var trackedID: String

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @State private var redeemed: Redemption?
    @State private var copied = false

    var body: some View {
        let tracked = trackedID == reward.id
        VStack(spacing: 20) {
            IconCircle(systemImage: redeemed == nil ? reward.systemImage : "checkmark", tint: reward.color(theme), size: 72)
                .contentTransition(.symbolEffect(.replace))
                .padding(.top, 28)

            VStack(spacing: 4) {
                Text(reward.title).font(.title2.weight(.bold))
                Text(reward.detail).foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)

            if let redeemed {
                VStack(spacing: 10) {
                    Text(redeemed.code)
                        .font(.system(.title3, design: .monospaced).weight(.semibold))
                        .textSelection(.enabled)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                        .background(Color(.tertiarySystemGroupedBackground), in: .rect(cornerRadius: 16, style: .continuous))
                    Text("Demo code. Partner vouchers aren't connected yet.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .transition(.opacity.combined(with: .scale(0.96)))

                HStack(spacing: 12) {
                    Button(copied ? "Copied" : "Copy code", systemImage: copied ? "checkmark" : "doc.on.doc") {
                        UIPasteboard.general.string = redeemed.code
                        copied = true
                    }
                    .buttonStyle(.glass)
                    Button("Done") { dismiss() }
                        .buttonStyle(.glassProminent)
                }
                .controlSize(.large)
            } else {
                HStack {
                    detail("Cost", reward.cost)
                    Divider().frame(height: 36)
                    detail("Balance after", balance - reward.cost)
                }
                .padding(.vertical, 4)

                VStack(spacing: 10) {
                    Button(action: redeem) {
                        HStack(spacing: 6) {
                            if balance >= reward.cost {
                                Text("Redeem for")
                                CreditAmount(value: reward.cost, size: 16)
                            } else {
                                CreditAmount(value: reward.cost - balance, size: 16)
                                Text("more needed")
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .disabled(balance < reward.cost)

                    Button {
                        withAnimation(.snappy) { trackedID = tracked ? "" : reward.id }
                    } label: {
                        Label(tracked ? "Tracking on your wallet" : "Track this reward",
                              systemImage: tracked ? "pin.fill" : "pin")
                            .frame(maxWidth: .infinity)
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .buttonStyle(.glass)
                }
                .controlSize(.large)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .sensoryFeedback(.success, trigger: redeemed != nil)
        .animation(.spring(duration: 0.35, bounce: 0), value: redeemed != nil)
    }

    private func detail(_ title: String, _ value: Int) -> some View {
        VStack(spacing: 2) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            CreditAmount(value: value, size: 18)
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .foregroundStyle(value < 0 ? .red : .primary)
        }
        .frame(maxWidth: .infinity)
    }

    private func redeem() {
        guard balance >= reward.cost, redeemed == nil else { return }
        let redemption = Redemption(rewardID: reward.id, title: "\(reward.title) · \(reward.detail)",
                                    cost: reward.cost, code: Reward.makeCode())
        context.insert(redemption)
        try? context.save()
        if trackedID == reward.id { trackedID = "" }
        redeemed = redemption
    }
}

// MARK: - History

private struct CreditHistoryView: View {
    let results: [DayResult]
    let redemptions: [Redemption]

    @Environment(\.theme) private var theme

    private enum Entry: Identifiable {
        case day(DayResult), redemption(Redemption)
        var id: PersistentIdentifier {
            switch self {
            case .day(let r): r.persistentModelID
            case .redemption(let r): r.persistentModelID
            }
        }
        var date: Date {
            switch self {
            case .day(let r): r.day
            case .redemption(let r): r.date
            }
        }
    }

    var body: some View {
        let entries = (results.map(Entry.day) + redemptions.map(Entry.redemption)).sorted { $0.date > $1.date }
        List(entries) { entry in
            switch entry {
            case .day(let r):
                row(r.status == .calibrating ? "Measuring your usual day" : r.status == .offline ? "Sensor offline" : r.metLimit ? "Under limit" : "Over limit",
                    "\(r.day.formatted(.dateTime.weekday(.wide).day().month())) · \(Int(r.usedLiters)) of \(Int(r.limitLiters)) L"
                        + (r.bonusCredits > 0 ? " · +\(r.bonusCredits) tier bonus" : ""),
                    r.credits, prefix: r.credits > 0 ? "+" : "",
                    r.credits > 0 ? theme.color : .secondary)
            case .redemption(let r):
                row(r.title, r.date.formatted(date: .abbreviated, time: .shortened), r.cost, prefix: "−", .primary)
            }
        }
        .navigationTitle("Credit history")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if entries.isEmpty {
                ContentUnavailableView {
                    Label { Text("No credits yet") } icon: { CreditMark(size: 44) }
                } description: {
                    Text("Your first day under the limit settles at midnight.")
                }
            }
        }
    }

    private func row(_ title: String, _ subtitle: String, _ amount: Int, prefix: String, _ tint: Color) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body.weight(.medium))
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            CreditAmount(value: amount, prefix: prefix, size: 15)
                .font(.body.weight(.semibold))
                .foregroundStyle(tint)
        }
    }
}
