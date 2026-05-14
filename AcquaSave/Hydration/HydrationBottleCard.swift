import SwiftUI

struct HydrationBottleCard: View {
    let lastDrinkText: String
    let nextReminderText: String
    let isPaused: Bool

    let progress: Double
    let todayML: Int
    @Binding var goalML: Int

    let onAdd200: () -> Void
    let onAdd300: () -> Void
    let onAdd500: () -> Void
    let onRemoveLast: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            headerSection

            HStack {
                Spacer()

                BottleHydrationChartFitness(
                    progress: progress,
                    currentML: todayML,
                    goalML: goalML,
                    subtitle: "Today"
                )
                .frame(width: 136, height: 220)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("Daily hydration goal", systemImage: "target")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Spacer()

                    Text("\(Int(progress * 100))%")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.blue.opacity(0.10), in: Capsule())
                        .foregroundStyle(.blue)
                }

                Stepper("\(goalML) ml", value: $goalML, in: 500...5000, step: 100)
                    .font(.subheadline.weight(.medium))
            }

            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    ActionPillButton("+200 ml", prominent: true, action: onAdd200)
                    ActionPillButton("+300 ml", prominent: true, action: onAdd300)
                }

                HStack(spacing: 10) {
                    ActionPillButton("+500 ml", prominent: true, action: onAdd500)
                    ActionPillButton("Remove last", prominent: false, action: onRemoveLast)
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
    }

    private var headerSection: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Label("Hydration", systemImage: "drop.circle.fill")
                        .font(.headline)

                    if isPaused {
                        Text("Paused")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.thinMaterial, in: Capsule())
                            .foregroundStyle(.secondary)
                    }
                }

                Text(lastDrinkText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(nextReminderText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.18),
                                Color.cyan.opacity(0.10)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 46, height: 46)

                Image(systemName: "cup.and.saucer.fill")
                    .font(.title3)
                    .foregroundStyle(.blue)
            }
        }
    }
}

private struct ActionPillButton: View {
    let title: String
    let prominent: Bool
    let action: () -> Void

    init(_ title: String, prominent: Bool, action: @escaping () -> Void) {
        self.title = title
        self.prominent = prominent
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(prominent ? Color.blue.opacity(0.12) : Color(.tertiarySystemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            prominent ? Color.blue.opacity(0.16) : Color.primary.opacity(0.05),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
        .foregroundStyle(prominent ? .blue : .primary)
        .shadow(color: .black.opacity(prominent ? 0.04 : 0.02), radius: 8, x: 0, y: 4)
    }
}
