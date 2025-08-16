import SwiftUI
import SwiftData

struct AccordionExerciseCard: View {
    let exercise: Exercise
    @Binding var sets: [ExerciseSet]
    let onNavigateToAdvancedEdit: (Exercise, [ExerciseSet]) -> Void
    
    @State private var isExpanded: Bool = false
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    
    private func deleteSet(at index: Int) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            let setToDelete = sets[index]
            modelContext.delete(setToDelete)
            sets.remove(at: index)
        }
    }
    
    private func addNewSet() {
        let nextSetNumber = Int16(sets.count + 1)
        let newSet = ExerciseSet(setNumber: nextSetNumber)
        
        // Copy values from last set if available
        if let lastSet = sets.last {
            newSet.weight = lastSet.weight
            newSet.reps = lastSet.reps
            newSet.duration = lastSet.duration
            newSet.distance = lastSet.distance
        }
        
        newSet.exercise = exercise
        modelContext.insert(newSet)
        sets.append(newSet)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with exercise name and toggle
            ExerciseHeaderView(
                exercise: exercise,
                sets: sets,
                isExpanded: $isExpanded,
                onAdvancedEdit: {
                    onNavigateToAdvancedEdit(exercise, sets)
                }
            )
            
            // Expandable content
            if isExpanded {
                VStack(spacing: theme.spacing.s) {
                    // Sets list
                    ForEach(Array(sets.enumerated()), id: \.element.id) { index, set in
                        QuickSetEditor(
                            exerciseSet: set,
                            setNumber: index + 1,
                            onDelete: { deleteSet(at: index) }
                        )
                        
                        if index < sets.count - 1 {
                            Divider()
                                .background(theme.colors.backgroundSecondary.opacity(0.3))
                                .padding(.horizontal, theme.spacing.m)
                        }
                    }
                    
                    // Add set button
                    Button(action: addNewSet) {
                        HStack(spacing: theme.spacing.s) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18))
                            Text(LocalizationKeys.Training.Exercise.addSet.localized)
                                .font(theme.typography.body)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(theme.colors.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, theme.spacing.m)
                        .background(theme.colors.accent.opacity(0.1))
                        .cornerRadius(theme.radius.m)
                    }
                    .padding(.horizontal, theme.spacing.m)
                    .padding(.top, theme.spacing.s)
                    .padding(.bottom, theme.spacing.m)
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
        .background(theme.colors.backgroundPrimary)
        .cornerRadius(theme.radius.m)
        .overlay(
            RoundedRectangle(cornerRadius: theme.radius.m)
                .stroke(theme.colors.backgroundSecondary.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: theme.shadows.card.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}