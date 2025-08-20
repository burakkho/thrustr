import SwiftUI
import SwiftData

struct CustomRoutineCard: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    let workout: LiftWorkout
    let onTap: () -> Void
    let onFavoriteToggle: (() -> Void)?
    
    private var totalSets: Int {
        workout.exercises.reduce(0) { $0 + $1.targetSets }
    }
    
    private var estimatedDuration: String {
        if let duration = workout.estimatedDuration {
            return "\(duration) min"
        }
        // Fallback calculation: 3-4 minutes per set
        let totalSets = self.totalSets
        let estimatedMinutes = totalSets * 3
        return "~\(estimatedMinutes) min"
    }
    
    private var exercisePreview: [String] {
        workout.exercises.prefix(3).map { $0.exerciseName }
    }
    
    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onTap()
        }) {
            VStack(alignment: .leading, spacing: theme.spacing.m) {
                // Header
                HStack {
                    Text(workout.localizedName)
                        .font(.headline)
                        .foregroundColor(theme.colors.textPrimary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Favorite Button
                    if let onFavoriteToggle = onFavoriteToggle {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            workout.toggleFavorite()
                            onFavoriteToggle()
                            
                            do {
                                try modelContext.save()
                            } catch {
                                print("Failed to save favorite state: \(error)")
                            }
                        }) {
                            Image(systemName: workout.isFavorite ? "heart.fill" : "heart")
                                .font(.title3)
                                .foregroundColor(workout.isFavorite ? .red : theme.colors.textSecondary)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(theme.colors.textSecondary)
                }
                
                // Exercise count and duration
                HStack(spacing: theme.spacing.l) {
                    statItem(
                        icon: "list.bullet",
                        value: "\(workout.exercises.count)",
                        label: "routine.exercises".localized
                    )
                    
                    statItem(
                        icon: "clock",
                        value: estimatedDuration,
                        label: "routine.template.duration".localized
                    )
                }
                
                // Exercise Preview
                if !exercisePreview.isEmpty {
                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        Text("routine.template.exercises".localized)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(theme.colors.textSecondary)
                        
                        ForEach(exercisePreview, id: \.self) { exercise in
                            HStack(spacing: 4) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 4))
                                    .foregroundColor(theme.colors.accent)
                                Text(exercise)
                                    .font(.caption)
                                    .foregroundColor(theme.colors.textPrimary)
                                    .lineLimit(1)
                                Spacer()
                            }
                        }
                        
                        if workout.exercises.count > 3 {
                            Text("+ \(workout.exercises.count - 3) more")
                                .font(.caption)
                                .foregroundColor(theme.colors.textSecondary)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(theme.spacing.m)
            .frame(height: 160)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.colors.cardBackground)
                    .shadow(color: Color.shadowLight, radius: 4, y: 1)
            )
        }
        .buttonStyle(PressableStyle())
    }
    
    private func statItem(icon: String, value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(theme.colors.textSecondary)
                Text(label)
                    .font(.caption2)
                    .foregroundColor(theme.colors.textSecondary)
            }
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(theme.colors.textPrimary)
        }
    }
}

#Preview {
    @Previewable @State var workout: LiftWorkout = {
        let workout = LiftWorkout(
            name: "My Custom Routine",
            isTemplate: true,
            isCustom: true
        )
        
        // Mock exercises
        let exercise1 = LiftExercise(exerciseId: UUID(), exerciseName: "Squat", targetSets: 3, targetReps: 8)
        let exercise2 = LiftExercise(exerciseId: UUID(), exerciseName: "Bench Press", targetSets: 3, targetReps: 8)
        let exercise3 = LiftExercise(exerciseId: UUID(), exerciseName: "Deadlift", targetSets: 3, targetReps: 5)
        let exercise4 = LiftExercise(exerciseId: UUID(), exerciseName: "Overhead Press", targetSets: 3, targetReps: 8)
        let exercise5 = LiftExercise(exerciseId: UUID(), exerciseName: "Barbell Rows", targetSets: 3, targetReps: 8)
        
        workout.exercises = [exercise1, exercise2, exercise3, exercise4, exercise5]
        workout.estimatedDuration = 60
        
        return workout
    }()
    
    LazyVGrid(
        columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ],
        spacing: 16
    ) {
        CustomRoutineCard(
            workout: workout,
            onTap: {
                print("Custom routine tapped")
            },
            onFavoriteToggle: {
                print("Favorite toggled")
            }
        )
        CustomRoutineCard(
            workout: workout,
            onTap: {
                print("Custom routine tapped")
            },
            onFavoriteToggle: {
                print("Favorite toggled")
            }
        )
    }
    .padding()
}