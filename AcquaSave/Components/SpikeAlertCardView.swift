import SwiftUI

struct SpikeAlertCardView: View {
    let alert: SpikeAlert

    var body: some View {
        GlassCard {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)

                VStack(alignment: .leading, spacing: 6) {
                    Text(alert.title)
                        .font(.headline)

                    Text(alert.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
    }
}
