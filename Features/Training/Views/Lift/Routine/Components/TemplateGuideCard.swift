import SwiftUI
import SwiftData

struct TemplateGuideCard: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    let template: LiftWorkout
    let onStart: () -> Void
    let onCustomize: () -> Void
    let onFavoriteToggle: (() -> Void)?
    
    private var exercisePreview: String {
        let exerciseNames = (template.exercises ?? []).prefix(3).map { $0.exerciseName }
        if (template.exercises?.count ?? 0) > 3 {
            return exerciseNames.joined(separator: ", ") + "..."
        } else {
            return exerciseNames.joined(separator: ", ")
        }
    }
    
    private var totalSets: Int {
        (template.exercises ?? []).reduce(0) { $0 + $1.targetSets }
    }
    
    private var estimatedDuration: String {
        if let duration = template.estimatedDuration {
            return "\(duration) min"
        }
        // Fallback calculation: 3-4 minutes per set
        let totalSets = self.totalSets
        let estimatedMinutes = totalSets * 3
        return "~\(estimatedMinutes) min"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            // Header with icon and title
            HStack(spacing: theme.spacing.s) {
                ZStack {
                    Circle()
                        .fill(theme.colors.success.opacity(0.10))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "list.bullet.rectangle.fill")
                        .foregroundColor(theme.colors.success)
                        .font(.title3)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(template.localizedName)
                        .font(.headline)
                        .foregroundColor(theme.colors.textPrimary)
                        .lineLimit(1)
                    
                    Text("\(template.exercises?.count ?? 0) exercises")
                        .font(.caption)
                        .foregroundColor(theme.colors.textSecondary)
                }
                
                Spacer()
                
                // Favorite Button
                if let onFavoriteToggle = onFavoriteToggle {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        template.toggleFavorite()
                        onFavoriteToggle()
                        
                        do {
                            try modelContext.save()
                        } catch {
                            print("Failed to save favorite state: \(error)")
                        }
                    }) {
                        Image(systemName: template.isFavorite ? "heart.fill" : "heart")
                            .font(.title3)
                            .foregroundColor(template.isFavorite ? .red : theme.colors.textSecondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            // Exercise Preview
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text("routine.template.exercises".localized)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.colors.textSecondary)
                
                Text(exercisePreview)
                    .font(.subheadline)
                    .foregroundColor(theme.colors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            
            // Stats
            HStack(spacing: theme.spacing.l) {
                statItem(
                    icon: "timer",
                    value: estimatedDuration,
                    label: "routine.template.duration".localized
                )
                
                statItem(
                    icon: "number.square",
                    value: "\(totalSets)",
                    label: "routine.template.sets".localized
                )
            }
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: theme.spacing.s) {
                // Start Button
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onStart()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "play.fill")
                            .font(.caption)
                        Text("routine.template.start".localized)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(theme.colors.success)
                    .cornerRadius(8)
                }
                
                // Customize Button
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onCustomize()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.pencil")
                            .font(.caption)
                        Text("routine.template.customize".localized)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(theme.colors.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(theme.colors.backgroundSecondary)
                    .cornerRadius(8)
                }
            }
        }
        .frame(width: 240, height: 180)
        .padding(theme.spacing.m)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.colors.cardBackground)
                .shadow(color: Color.shadowLight, radius: 4, y: 1)
        )
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
    @Previewable @State var template: LiftWorkout = {
        let template = LiftWorkout(
            name: "Upper Body Power",
            isTemplate: true,
            isCustom: false
        )
        
        // Mock exercises
        let exercise1 = LiftExercise(exerciseId: UUID(), exerciseName: "Bench Press", targetSets: 4, targetReps: 6)
        let exercise2 = LiftExercise(exerciseId: UUID(), exerciseName: "Rows", targetSets: 4, targetReps: 8)
        let exercise3 = LiftExercise(exerciseId: UUID(), exerciseName: "Overhead Press", targetSets: 3, targetReps: 8)
        let exercise4 = LiftExercise(exerciseId: UUID(), exerciseName: "Pull-ups", targetSets: 3, targetReps: 10)
        
        template.exercises = [exercise1, exercise2, exercise3, exercise4]
        template.estimatedDuration = 45
        
        return template
    }()
    
    HStack {
        TemplateGuideCard(
            template: template,
            onStart: { print("Start template") },
            onCustomize: { print("Customize template") },
            onFavoriteToggle: { print("Favorite toggled") }
        )
    }
    .padding()
}