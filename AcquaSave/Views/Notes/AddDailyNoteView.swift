import SwiftUI

struct AddDailyNoteView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var text: String = ""

    let onSave: (String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Context note") {
                    TextEditor(text: $text)
                        .frame(minHeight: 180)
                }

                Section {
                    Text("Examples: Laundry day, guests at home, hot weather, garden watering.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("New Note")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        onSave(trimmed)
                        dismiss()
                    }
                }
            }
        }
    }
}
