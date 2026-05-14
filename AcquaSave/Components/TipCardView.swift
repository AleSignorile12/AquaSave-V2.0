import SwiftUI

struct TipCardView: View {
    let text: String

    var body: some View {
        GlassCard {
            HStack(spacing: 12) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)

                Text(text)
                    .font(.subheadline)

                Spacer()
            }
        }
    }
}
