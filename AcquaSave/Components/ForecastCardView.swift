import SwiftUI

struct ForecastCardView: View {
    let text: String

    var body: some View {
        GlassCard {
            HStack(spacing: 12) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundStyle(.blue)

                Text(text)
                    .font(.subheadline)

                Spacer()
            }
        }
    }
}
