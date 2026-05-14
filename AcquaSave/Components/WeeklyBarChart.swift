import SwiftUI

struct WeeklyBarChart: View {
    let data: [(day: Date, liters: Double)]

    private var maxLiters: Double {
        max(data.map(\.liters).max() ?? 1, 1)
    }

    private func dayLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = .current
        f.dateFormat = "E"
        return f.string(from: date)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            ForEach(Array(data.enumerated()), id: \.offset) { _, item in
                VStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.green.opacity(item.liters == 0 ? 0.25 : 1))
                        .frame(height: CGFloat(item.liters / maxLiters) * 120 + 6)

                    Text(dayLabel(item.day))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity, alignment: .bottom)
        .padding(.top, 6)
    }
}
