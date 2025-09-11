import SwiftUI
import SwiftData

// MARK: - Lift Accordion Card
struct LiftAccordionCard: View {
    @Environment(\.theme) private var theme
    @Environment(UnitSettings.self) var unitSettings
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
                            Text(exerciseResult.exercise?.exerciseName ?? "Unknown Exercise")
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
                        Text(UnitsFormatter.formatVolume(kg: exerciseResult.totalVolume, system: unitSettings.unitSystem))
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
                    HStack(spacing: 4) {
                        Text("SET")
                            .frame(width: 32, alignment: .leading)
                        Text("PREV")
                            .frame(width: 50, alignment: .center)
                        Text(unitSettings.unitSystem == .metric ? "KG" : "LB")
                            .frame(width: 120, alignment: .center)
                        Text("REPS")
                            .frame(width: 100, alignment: .center)
                        Image(systemName: "checkmark")
                            .frame(width: 32)
                    }
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textSecondary)
                    .padding(.horizontal, theme.spacing.xs)
                    .padding(.vertical, 6)
                    
                    // Sets - Safe ForEach with stable IDs
                    ForEach(Array(exerciseResult.sets.enumerated()), id: \.element.id) { index, setData in
                        SetTrackingRow(
                            set: Binding(
                                get: { 
                                    // Safe get: Find by ID to ensure consistency
                                    if let currentIndex = exerciseResult.sets.firstIndex(where: { $0.id == setData.id }) {
                                        return exerciseResult.sets[currentIndex]
                                    }
                                    // Fallback: return original if not found (shouldn't happen)
                                    return setData
                                },
                                set: { newValue in
                                    // Safe set: Find current index by ID and update
                                    if let currentIndex = exerciseResult.sets.firstIndex(where: { $0.id == setData.id }) {
                                        exerciseResult.sets[currentIndex] = newValue
                                        onSetUpdate()
                                    }
                                }
                            ),
                            setNumber: index + 1,
                            previousSet: previousSets?.indices.contains(index) == true ? previousSets?[index] : nil,
                            onComplete: {
                                // Find current index by ID for safe completion
                                if let currentIndex = exerciseResult.sets.firstIndex(where: { $0.id == setData.id }) {
                                    exerciseResult.completeSet(at: currentIndex)
                                    onSetUpdate()
                                    
                                    // Check if exercise is now completed
                                    let isCompleted = exerciseResult.sets.allSatisfy { $0.isCompleted }
                                    if isCompleted {
                                        onExerciseCompleted?(exerciseResult)
                                    }
                                }
                            },
                            onDelete: {
                                // Find current index by ID for safe deletion
                                if let currentIndex = exerciseResult.sets.firstIndex(where: { $0.id == setData.id }) {
                                    setToDelete = currentIndex
                                    showingDeleteAlert = true
                                }
                            }
                        )
                        
                        if index < exerciseResult.sets.count - 1 {
                            Divider()
                                .padding(.horizontal, theme.spacing.m)
                        }
                    }
                    
                    // Action Buttons
                    HStack(spacing: theme.spacing.s) {
                        
                        // Add Set Button
                        Button(action: {
                            exerciseResult.addSet()
                            onSetUpdate()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle")
                                    .font(.caption)
                                Text("Add Set")
                                    .font(theme.typography.caption)
                            }
                            .foregroundColor(theme.colors.accent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(theme.colors.backgroundSecondary)
                            .cornerRadius(theme.radius.s)
                        }
                        
                        // Complete All Sets Button
                        Button(action: {
                            completeAllSets()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption)
                                Text("Complete All")
                                    .font(theme.typography.caption)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(theme.colors.success)
                            .cornerRadius(theme.radius.s)
                        }
                        .disabled(exerciseResult.sets.allSatisfy { $0.isCompleted })
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
            }
        }
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.m)
        .padding(.horizontal)
        .alert(TrainingKeys.Alerts.deleteSet.localized, isPresented: $showingDeleteAlert) {
            Button(TrainingKeys.Common.cancel.localized, role: .cancel) { }
            Button(TrainingKeys.Alerts.delete.localized, role: .destructive) {
                if let index = setToDelete {
                    exerciseResult.removeSet(at: index)
                    onSetUpdate()
                }
            }
        } message: {
            Text(TrainingKeys.AlertsExtended.deleteSetConfirmation.localized)
        }
    }
}


