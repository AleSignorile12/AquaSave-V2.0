import SwiftUI
import SwiftData

struct DailyNotesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \DailyNote.createdAt, order: .reverse) private var notes: [DailyNote]

    @State private var showAdd = false

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 14) {
                    if notes.isEmpty {
                        GlassCard {
                            Text("No notes yet. Add context like guests, laundry day, or hot weather.")
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    } else {
                        ForEach(notes) { note in
                            NoteCardView(note: note)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Daily Notes")
        .toolbar {
            Button {
                showAdd = true
            } label: {
                Image(systemName: "plus")
            }
        }
        .sheet(isPresented: $showAdd) {
            AddDailyNoteView { text in
                context.insert(DailyNote(text: text))
                try? context.save()
            }
        }
    }
}
