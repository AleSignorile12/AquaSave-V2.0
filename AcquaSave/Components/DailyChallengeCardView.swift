import SwiftUI

struct DailyChallengeCardView: View {
    let challenge: DailyChallenge

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Daily Challenge", systemImage: challenge.systemImage)
                        .font(.headline)

                    Spacer()

                    Image(systemName: challenge.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(challenge.isCompleted ? .green : .secondary)
                }

                Text(challenge.title)
                    .font(.title3.bold())

                Text(challenge.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ProgressView(value: challenge.progress)
                    .tint(.green)
            }
        }
    }
}
