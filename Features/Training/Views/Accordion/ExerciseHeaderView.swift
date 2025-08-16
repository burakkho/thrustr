import SwiftUI
import SwiftData

struct ExerciseHeaderView: View {
    let exercise: Exercise
    let sets: [ExerciseSet]
    @Binding var isExpanded: Bool
    let onAdvancedEdit: () -> Void
    
    @Environment(\.theme) private var theme
    @AppStorage("weightUnit") private var weightUnit: String = "kg"
    
    private var summaryText: String {
        guard !sets.isEmpty else { return LocalizationKeys.Training.Exercise.noSets.localized }
        
        let completedSets = sets.filter { $0.isCompleted }
        let totalSets = sets.count
        
        if let lastSet = completedSets.last {
            let weightText = lastSet.weight.map { "\(Int($0))\(weightUnit)" } ?? ""
            let repsText = lastSet.reps.map { "× \(Int($0))" } ?? ""
            let rpeText = lastSet.rpe.map { "RPE: \(Int($0))" } ?? ""
            
            var summary = [weightText, repsText].filter { !$0.isEmpty }.joined(separator: " ")
            if !rpeText.isEmpty {
                summary += " │ \(rpeText)"
            }
            summary += " (\(completedSets.count)/\(totalSets))"
            return summary
        }
        
        return "\(completedSets.count)/\(totalSets) \(LocalizationKeys.Training.Exercise.sets.localized)"
    }
    
    var body: some View {
        HStack(spacing: theme.spacing.m) {
            // Exercise info
            VStack(alignment: .leading, spacing: theme.spacing.s) {
                Text(exercise.nameTR)
                    .font(theme.typography.body)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                
                if !isExpanded {
                    Text(summaryText)
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: theme.spacing.m) {
                // Advanced Edit button
                Button(action: onAdvancedEdit) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 18))
                        .foregroundColor(theme.colors.textSecondary)
                }
                
                // Expand/Collapse toggle
                Button(action: { 
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.colors.accent)
                        .frame(width: 28, height: 28)
                        .background(theme.colors.accent.opacity(0.1))
                        .clipShape(Circle())
                }
            }
        }
        .padding(theme.spacing.m)
        .contentShape(Rectangle())
    }
}