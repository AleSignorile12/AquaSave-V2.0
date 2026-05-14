import SwiftUI

// MARK: - Device Stats Card View

struct DeviceStatsCardView: View {

    let summary: DeviceSummary
    let category: DeviceCategory
    let onSimulate: (Double) -> Void

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {

                headerSection
                metricsSection
                usageShareSection
                footerSection
                actionsSection
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .center, spacing: 12) {

            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(categoryTint.opacity(0.14))
                        .frame(width: 46, height: 46)

                    Image(systemName: category.systemImage)
                        .font(.title3)
                        .foregroundStyle(categoryTint)
                }

                VStack(alignment: .leading, spacing: 4) {

                    Text(summary.name)
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text(summary.location)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }

            Spacer()

            Text(summary.efficiencyLabel)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(categoryTint.opacity(0.12), in: Capsule())
                .foregroundStyle(categoryTint)
                .lineLimit(1)
        }
    }

    // MARK: - Metrics

    private var metricsSection: some View {
        HStack(spacing: 10) {
            metricCard(title: "Total", value: "\(Int(summary.totalLiters)) L")
            metricCard(title: "Uses", value: "\(summary.usageCount)")
            metricCard(title: "Avg/use", value: "\(Int(summary.averageLitersPerUse)) L")
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Usage Share

    private var usageShareSection: some View {
        VStack(alignment: .leading, spacing: 8) {

            HStack {
                Text("Share of total usage")
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                Spacer()

                Text("\(Int(summary.shareOfTotal * 100))%")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(categoryTint)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(categoryTint.opacity(0.10), in: Capsule())
                    .lineLimit(1)
            }

            ProgressView(value: summary.shareOfTotal)
                .tint(categoryTint)
                .scaleEffect(x: 1, y: 1.2)
        }
    }

    // MARK: - Footer Info

    private var footerSection: some View {
        VStack(alignment: .leading, spacing: 8) {

            if let last = summary.lastUsedAt {
                Label(
                    "Last used: \(last.formatted(date: .abbreviated, time: .shortened))",
                    systemImage: "clock"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            } else {
                Label("No usage logged yet", systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Text(summary.tip)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.9)
        }
    }

    // MARK: - Actions

    private var actionsSection: some View {
        HStack(spacing: 10) {

            actionButton("+2L", prominent: false) {
                onSimulate(2)
            }

            actionButton("+5L", prominent: false) {
                onSimulate(5)
            }

            actionButton("+20L", prominent: true) {
                onSimulate(20)
            }
        }
    }

    // MARK: - Metric Card

    private func metricCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Text(value)
                .font(.headline)
                .monospacedDigit()
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            Color(.tertiarySystemBackground),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
    }

    // MARK: - Action Button

    private func actionButton(_ title: String, prominent: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {

            Text(title)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .fill(prominent ? categoryTint.opacity(0.14) : Color(.tertiarySystemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(
                            prominent ? categoryTint.opacity(0.18) : Color.primary.opacity(0.05),
                            lineWidth: 1
                        )
                )
                .lineLimit(1)
        }
        .buttonStyle(.plain)
        .foregroundStyle(prominent ? categoryTint : .primary)
    }

    // MARK: - Colors

    private var categoryTint: Color {
        switch category {
        case .faucet: return .green
        case .shower: return .blue
        case .dishwasher: return .mint
        case .washingMachine: return .indigo
        case .irrigation: return .orange
        case .toilet: return .cyan
        case .other: return .teal
        }
    }
}
