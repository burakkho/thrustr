import SwiftUI

struct ExerciseResultRow: View {
    @Environment(\.theme) private var theme
    let result: LiftExerciseResult
    let unitSettings: UnitSettings

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(result.exercise?.exerciseName ?? "Unknown Exercise")
                    .font(theme.typography.body)
                    .fontWeight(.medium)
                    .foregroundColor(theme.colors.textPrimary)

                Text("\(result.completedSets) sets • \(result.totalReps) reps")
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(UnitsFormatter.formatWeight(kg: result.totalVolume, system: unitSettings.unitSystem))
                    .font(theme.typography.body)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)

                if let maxWeight = result.maxWeight {
                    Text("Max: \(UnitsFormatter.formatWeight(kg: maxWeight, system: unitSettings.unitSystem))")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
        }
        .padding(.vertical, theme.spacing.xs)
    }
}

#Preview {
    // This would need a mock LiftExerciseResult for preview
    Text("ExerciseResultRow Preview")
        .environment(\.theme, DefaultLightTheme())
}