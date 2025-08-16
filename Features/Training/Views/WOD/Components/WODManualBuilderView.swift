import SwiftUI
import SwiftData

struct WODManualBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    
    let part: WorkoutPart
    let onSave: (String) -> Void
    
    @State private var wodDescription = ""
    @State private var scoreText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: theme.spacing.l) {
                VStack(alignment: .leading, spacing: theme.spacing.s) {
                    Label("WOD Description", systemImage: "text.alignleft")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                    
                    TextEditor(text: $wodDescription)
                        .frame(minHeight: 100)
                        .padding(theme.spacing.s)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                VStack(alignment: .leading, spacing: theme.spacing.s) {
                    Label("Score/Result", systemImage: "stopwatch")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                    
                    TextField("e.g., 12:45 or 5 rounds", text: $scoreText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Add WOD")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let finalScore = scoreText.isEmpty ? wodDescription : "\(wodDescription)\n\nScore: \(scoreText)"
                        onSave(finalScore)
                        dismiss()
                    }
                    .disabled(wodDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}