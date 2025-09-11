import SwiftUI

// MARK: - Template Card Component
struct TemplateCard: View {
    @Environment(\.theme) private var theme
    
    let workout: LiftWorkout
    let onStartWorkout: () -> Void
    let onCopyCustomize: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            // Header with template info
            VStack(alignment: .leading, spacing: theme.spacing.s) {
                Text(workout.localizedName)
                    .font(theme.typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                
                Text("\(workout.exercises?.count ?? 0) exercises")
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }
            
            // Action buttons
            HStack(spacing: theme.spacing.m) {
                // Start Workout button (Primary)
                Button(action: onStartWorkout) {
                    Text("training.lift.startWorkout".localized)
                        .font(theme.typography.body)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, theme.spacing.s)
                        .background(theme.colors.accent)
                        .cornerRadius(theme.radius.s)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Copy & Customize button (Secondary)
                Button(action: onCopyCustomize) {
                    Text("routine.copyCustomize".localized)
                        .font(theme.typography.body)
                        .fontWeight(.medium)
                        .foregroundColor(theme.colors.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, theme.spacing.s)
                        .background(theme.colors.accent.opacity(0.1))
                        .cornerRadius(theme.radius.s)
                        .overlay(
                            RoundedRectangle(cornerRadius: theme.radius.s)
                                .stroke(theme.colors.accent.opacity(0.3), lineWidth: 1)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(theme.spacing.m)
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.m)
        .shadow(color: theme.shadows.card.opacity(0.05), radius: 2)
    }
}

// MARK: - Preview
#Preview {
    let sampleWorkout = LiftWorkout(
        name: "Upper Body Template",
        nameEN: "Upper Body Template",
        nameTR: "Üst Vücut Şablonu",
        estimatedDuration: 60,
        isTemplate: true,
        isCustom: false
    )
    
    // Add sample exercises for preview
    let sampleExercises = [
        LiftExercise(exerciseId: UUID(), exerciseName: "Bench Press"),
        LiftExercise(exerciseId: UUID(), exerciseName: "Barbell Row"),
        LiftExercise(exerciseId: UUID(), exerciseName: "Overhead Press")
    ]
    
    sampleExercises.forEach { sampleWorkout.addExercise($0) }
    
    return TemplateCard(
        workout: sampleWorkout,
        onStartWorkout: { print("Start workout") },
        onCopyCustomize: { print("Copy & Customize") }
    )
    .padding()
}