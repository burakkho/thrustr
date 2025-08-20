import SwiftUI
import SwiftData

// MARK: - Lift Accordion Card
struct LiftAccordionCard: View {
    @Environment(\.theme) private var theme
    @Binding var exerciseResult: LiftExerciseResult
    let isExpanded: Bool
    let previousSets: [SetData]?
    let onToggle: () -> Void
    let onSetUpdate: () -> Void
    let onExerciseCompleted: ((LiftExerciseResult) -> Void)?
    let isEditMode: Bool
    
    @State private var showingDeleteAlert = false
    @State private var setToDelete: Int?
    
    // Computed property to check if exercise is completed
    private var isExerciseCompleted: Bool {
        exerciseResult.sets.allSatisfy { $0.isCompleted }
    }
    
    // MARK: - Helper Methods
    private func completeAllSets() {
        for index in exerciseResult.sets.indices {
            if !exerciseResult.sets[index].isCompleted {
                exerciseResult.completeSet(at: index)
            }
        }
        onSetUpdate()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: onToggle) {
                HStack {
                    HStack(spacing: theme.spacing.s) {
                        // Drag handle (edit mode only)
                        if isEditMode {
                            Image(systemName: "line.horizontal.3")
                                .font(.title3)
                                .foregroundColor(theme.colors.textSecondary)
                                .opacity(0.6)
                        }
                        
                        // Completion checkmark
                        if !isEditMode && isExerciseCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                                .foregroundColor(theme.colors.success)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(exerciseResult.exercise.exerciseName)
                                .font(theme.typography.headline)
                                .foregroundColor(
                                    isExerciseCompleted ?
                                    theme.colors.success :
                                    theme.colors.textPrimary
                                )
                            
                            HStack(spacing: theme.spacing.s) {
                                Text("\(exerciseResult.completedSets)/\(exerciseResult.sets.count) sets")
                                    .font(theme.typography.caption)
                                    .foregroundColor(
                                        isExerciseCompleted ?
                                        theme.colors.success :
                                        theme.colors.textSecondary
                                    )
                                
                                if let previousSets = previousSets, !previousSets.isEmpty {
                                    Text("•")
                                        .foregroundColor(theme.colors.textSecondary)
                                    Text("Previous: \(previousSets.first?.displayText ?? "")")
                                        .font(theme.typography.caption)
                                        .foregroundColor(theme.colors.textSecondary)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Volume indicator
                    if exerciseResult.totalVolume > 0 {
                        Text("\(Int(exerciseResult.totalVolume))kg")
                            .font(theme.typography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.colors.accent)
                    }
                    
                    // Expansion arrow (hidden in edit mode)
                    if !isEditMode {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }
                .padding()
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expanded Content
            if isExpanded {
                Divider()
                
                VStack(spacing: 0) {
                    
                    // Set Header
                    HStack {
                        Text("SET")
                            .frame(width: 40, alignment: .leading)
                        Text("PREVIOUS")
                            .frame(maxWidth: .infinity, alignment: .center)
                        Text("KG")
                            .frame(width: 60, alignment: .center)
                        Text("REPS")
                            .frame(width: 60, alignment: .center)
                        Image(systemName: "checkmark")
                            .frame(width: 30)
                    }
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textSecondary)
                    .padding(.horizontal)
                    .padding(.vertical, theme.spacing.s)
                    
                    // Sets
                    ForEach(exerciseResult.sets.indices, id: \.self) { index in
                        if index < exerciseResult.sets.count {
                            SetTrackingRow(
                                set: Binding(
                                    get: { 
                                        guard index < exerciseResult.sets.count else {
                                            return SetData(setNumber: index + 1, weight: nil, reps: 10, isWarmup: false, isCompleted: false)
                                        }
                                        return exerciseResult.sets[index] 
                                    },
                                    set: { newValue in
                                        guard index < exerciseResult.sets.count else { return }
                                        exerciseResult.sets[index] = newValue
                                        onSetUpdate()
                                    }
                                ),
                            setNumber: index + 1,
                            previousSet: previousSets?.indices.contains(index) == true ? previousSets?[index] : nil,
                            onComplete: {
                                exerciseResult.completeSet(at: index)
                                onSetUpdate()
                                
                                // Check if exercise is now completed
                                let isCompleted = exerciseResult.sets.allSatisfy { $0.isCompleted }
                                if isCompleted {
                                    onExerciseCompleted?(exerciseResult)
                                }
                            },
                            onDelete: {
                                setToDelete = index
                                showingDeleteAlert = true
                            }
                            )
                            
                            if index < exerciseResult.sets.count - 1 {
                                Divider()
                                    .padding(.horizontal)
                            }
                        }
                    }
                    
                    // Action Buttons
                    HStack(spacing: theme.spacing.m) {
                        
                        // Add Set Button
                        Button(action: {
                            exerciseResult.addSet()
                            onSetUpdate()
                        }) {
                            HStack {
                                Image(systemName: "plus.circle")
                                Text("Add Set")
                            }
                            .font(theme.typography.body)
                            .foregroundColor(theme.colors.accent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, theme.spacing.s)
                            .background(theme.colors.backgroundSecondary)
                            .cornerRadius(theme.radius.s)
                        }
                        
                        // Complete All Sets Button
                        Button(action: {
                            completeAllSets()
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Complete All")
                            }
                            .font(theme.typography.body)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, theme.spacing.s)
                            .background(theme.colors.success)
                            .cornerRadius(theme.radius.s)
                        }
                        .disabled(exerciseResult.sets.allSatisfy { $0.isCompleted })
                    }
                    .padding(.horizontal)
                    .padding(.vertical, theme.spacing.s)
                }
            }
        }
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.m)
        .padding(.horizontal)
        .alert("Delete Set?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let index = setToDelete {
                    exerciseResult.removeSet(at: index)
                    onSetUpdate()
                }
            }
        } message: {
            Text("Are you sure you want to delete this set?")
        }
    }
}


