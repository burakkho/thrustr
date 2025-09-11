import SwiftUI

// MARK: - Exercise Card Row Component
/// Clean, single-responsibility view component for displaying exercise data
struct ExerciseCardRow: View {
    // MARK: - Properties
    @Bindable var exerciseData: ExerciseResultData
    let isExpanded: Bool
    let previousSets: [SetData]?
    let isEditMode: Bool
    
    // MARK: - Actions
    let onToggle: () -> Void
    let onSetUpdate: () -> Void
    let onExerciseCompleted: (ExerciseResultData) -> Void
    
    // MARK: - Environment
    @Environment(\.theme) private var theme
    
    // MARK: - Body
    var body: some View {
        LiftAccordionCard(
            exerciseResult: createExerciseBinding(),
            isExpanded: isExpanded,
            previousSets: previousSets,
            onToggle: onToggle,
            onSetUpdate: onSetUpdate,
            onExerciseCompleted: { _ in
                onExerciseCompleted(exerciseData)
            },
            isEditMode: isEditMode
        )
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .deleteDisabled(!isEditMode)
    }
    
    // MARK: - Private Methods
    
    /// Creates a simple binding for the accordion card
    private func createExerciseBinding() -> Binding<LiftExerciseResult> {
        // This is a temporary binding that works with the existing LiftAccordionCard
        // In a perfect world, LiftAccordionCard would be refactored to work with ExerciseResultData directly
        Binding(
            get: {
                // Create a temporary LiftExerciseResult for the accordion card
                // This is not ideal but maintains compatibility during transition
                let tempResult = LiftExerciseResult(
                    exercise: LiftExercise() // This would need proper initialization
                )
                exerciseData.updateModel(tempResult)
                return tempResult
            },
            set: { newValue in
                // Update the DTO with changes from the accordion card
                let newData = ExerciseResultData(from: newValue)
                exerciseData = newData
                onSetUpdate()
            }
        )
    }
}

// MARK: - Simplified Exercise Card Row
/// Alternative simpler implementation that doesn't depend on LiftAccordionCard
struct SimpleExerciseCardRow: View {
    @Bindable var exerciseData: ExerciseResultData
    let isExpanded: Bool
    let isEditMode: Bool
    
    let onToggle: () -> Void
    let onAddSet: () -> Void
    let onCompleteSet: (Int) -> Void
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            // Header
            exerciseHeader
            
            // Sets (if expanded)
            if isExpanded {
                setsSection
            }
            
            // Progress bar
            progressBar
        }
        .padding(theme.spacing.m)
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.m)
        .onTapGesture {
            if !isEditMode {
                onToggle()
            }
        }
    }
    
    // MARK: - Subviews
    
    private var exerciseHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text(exerciseData.exerciseName)
                    .font(theme.typography.headline)
                    .foregroundColor(theme.colors.textPrimary)
                
                Text("\(exerciseData.completedSets)/\(exerciseData.targetSets) sets")
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }
            
            Spacer()
            
            if exerciseData.isPersonalRecord {
                Text("PR!")
                    .font(theme.typography.caption)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.accent)
            }
            
            if !isEditMode {
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .foregroundColor(theme.colors.textSecondary)
            }
        }
    }
    
    private var setsSection: some View {
        VStack(spacing: theme.spacing.s) {
            ForEach(Array(exerciseData.sets.enumerated()), id: \.element.id) { index, set in
                SetRow(
                    set: set,
                    setNumber: index + 1,
                    onComplete: { onCompleteSet(index) }
                )
            }
            
            // Add set button
            Button(action: onAddSet) {
                HStack {
                    Image(systemName: "plus.circle")
                    Text("Add Set")
                }
                .font(theme.typography.body)
                .foregroundColor(theme.colors.accent)
            }
        }
    }
    
    private var progressBar: some View {
        HStack {
            Text("Progress")
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textSecondary)
            
            Spacer()
            
            ProgressView(value: exerciseData.completionPercentage)
                .progressViewStyle(LinearProgressViewStyle())
                .frame(width: 100)
        }
    }
}

// MARK: - Set Row Component
struct SetRow: View {
    let set: SetData
    let setNumber: Int
    let onComplete: () -> Void
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack {
            Text("Set \(setNumber)")
                .font(theme.typography.body)
                .frame(width: 60, alignment: .leading)
            
            if let weight = set.weight {
                Text("\(weight, specifier: "%.1f") kg")
                    .font(theme.typography.body)
            }
            
            Text("\(set.reps) reps")
                .font(theme.typography.body)
            
            Spacer()
            
            if set.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(theme.colors.success)
            } else {
                Button("Complete", action: onComplete)
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.accent)
            }
        }
        .padding(.vertical, theme.spacing.xs)
    }
}

// MARK: - Preview
#Preview {
    let sampleData = ExerciseResultData(
        from: LiftExerciseResult(
            exercise: LiftExercise()
        )
    )
    
    return SimpleExerciseCardRow(
        exerciseData: .constant(sampleData),
        isExpanded: true,
        isEditMode: false,
        onToggle: {},
        onAddSet: {},
        onCompleteSet: { _ in }
    )
    .environment(\.theme, Theme.shared)
}