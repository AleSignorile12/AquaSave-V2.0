import SwiftUI

struct StatCardView: View {
    let title: String
    let value: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        GlassCard {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(value)
                        .font(.system(size: 30, weight: .bold))
                        .monospacedDigit()

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(.green)
            }
        }
    }
}
