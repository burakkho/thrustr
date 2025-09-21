import SwiftUI

struct WorkoutNotesSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Binding var notes: String
    let onSave: (String) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: theme.spacing.m) {
                // Header
                VStack(alignment: .leading, spacing: theme.spacing.s) {
                    Text("Workout Notes")
                        .font(theme.typography.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.colors.textPrimary)

                    Text("Add notes about your workout, form cues, or how you're feeling")
                        .font(theme.typography.body)
                        .foregroundColor(theme.colors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

                // Text Editor
                TextEditor(text: $notes)
                    .font(theme.typography.body)
                    .padding(theme.spacing.m)
                    .background(theme.colors.backgroundSecondary)
                    .cornerRadius(theme.radius.m)
                    .frame(minHeight: 200)
                    .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(notes)
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    WorkoutNotesSheet(
        notes: .constant("Sample workout notes"),
        onSave: { _ in print("Notes saved") }
    )
    .environment(\.theme, DefaultLightTheme())
}