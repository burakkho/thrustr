import SwiftUI

struct LiftSessionActionButtons: View {
    @Environment(\.theme) private var theme
    let onAddExercise: () -> Void
    let onShowNotes: () -> Void

    var body: some View {
        VStack(spacing: theme.spacing.m) {
            // Add Exercise Button
            Button(action: onAddExercise) {
                HStack {
                    Image(systemName: "plus.circle")
                    Text("Add Exercise")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(theme.colors.backgroundSecondary)
                .foregroundColor(theme.colors.textPrimary)
                .cornerRadius(theme.radius.m)
            }

            // Notes Button
            Button(action: onShowNotes) {
                HStack {
                    Image(systemName: "note.text")
                    Text("Workout Notes")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(theme.colors.backgroundSecondary)
                .foregroundColor(theme.colors.textPrimary)
                .cornerRadius(theme.radius.m)
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    LiftSessionActionButtons(
        onAddExercise: { print("Add Exercise") },
        onShowNotes: { print("Show Notes") }
    )
    .environment(\.theme, DefaultLightTheme())
}