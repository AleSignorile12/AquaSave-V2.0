import SwiftUI

struct GardenProgressCardView: View {
    let progress: GardenProgress

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Eco Garden")
                        .font(.headline)

                    Spacer()

                    Image(systemName: progress.stage.systemImage)
                        .foregroundStyle(.green)
                }

                Text(progress.stage.rawValue)
                    .font(.title3.bold())

                Text(progress.stage.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let next = progress.nextStageName {
                    ProgressView(value: progress.progressToNext)
                        .tint(.green)

                    Text("Growing toward \(next)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Maximum growth reached")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
