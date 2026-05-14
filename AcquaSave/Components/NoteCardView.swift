import SwiftUI

struct NoteCardView: View {
    let note: DailyNote

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(note.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(note.text)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
        }
    }
}
