import SwiftUI

struct InsightCardView: View {
    let text: String

    var body: some View {
        GlassCard {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .foregroundStyle(.green)

                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(.primary)

                Spacer()
            }
        }
    }
}
