import SwiftUI

struct EcoScoreCardView: View {
    let score: Int
    let label: String

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Eco Score")
                        .font(.headline)

                    Spacer()

                    Text(label)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.thinMaterial, in: Capsule())
                }

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(score)")
                        .font(.system(size: 36, weight: .bold))
                        .monospacedDigit()

                    Text("/ 100")
                        .foregroundStyle(.secondary)
                }

                ProgressView(value: Double(score), total: 100)
                    .tint(.green)
            }
        }
    }
}
