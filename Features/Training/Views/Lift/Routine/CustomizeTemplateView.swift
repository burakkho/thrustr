import SwiftUI
import SwiftData

// MARK: - Customize Template View
struct CustomizeTemplateView: View {
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let sourceTemplate: LiftWorkout
    @State private var workingExercises: [LiftExercise]
    @State private var showingExerciseLibrary = false
    @State private var showingNameInput = false
    
    init(template: LiftWorkout) {
        self.sourceTemplate = template
        // Create working copy of exercises
        self._workingExercises = State(initialValue: template.exercises?.map { exercise in
            LiftExercise(
                exerciseId: exercise.exerciseId,
                exerciseName: exercise.exerciseName,
                orderIndex: exercise.orderIndex
            )
        } ?? [])
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with template info
                headerSection
                
                // Exercise list
                exerciseListSection
                
                // Bottom actions
                bottomActionsSection
            }
            .navigationTitle("routine.copyCustomize".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("common.cancel".localized) {
                        dismiss()
                    }
                    .foregroundColor(theme.colors.textSecondary)
                }
            }
        }
        .sheet(isPresented: $showingExerciseLibrary) {
            ExerciseLibraryView(
                selectedExercises: $workingExercises,
                isPresented: $showingExerciseLibrary
            )
        }
        .sheet(isPresented: $showingNameInput) {
            RoutineNameInputView(
                exercises: workingExercises,
                onSave: { routineName in
                    saveCustomRoutine(name: routineName)
                }
            )
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.s) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(sourceTemplate.localizedName)
                        .font(theme.typography.title2)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Text("Based on \(sourceTemplate.localizedName)")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(workingExercises.count)")
                        .font(theme.typography.title2)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.accent)
                    Text("routine.exercises".localized)
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
        }
        .padding()
        .background(theme.colors.cardBackground)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(theme.colors.textSecondary)
                .opacity(0.2),
            alignment: .bottom
        )
    }
    
    // MARK: - Exercise List Section
    private var exerciseListSection: some View {
        ScrollView {
            LazyVStack(spacing: theme.spacing.s) {
                ForEach(workingExercises.indices, id: \.self) { index in
                    ExerciseEditRow(
                        exercise: workingExercises[index],
                        onRemove: {
                            removeExercise(at: index)
                        },
                        onMoveUp: index > 0 ? {
                            moveExercise(from: index, to: index - 1)
                        } : nil,
                        onMoveDown: index < workingExercises.count - 1 ? {
                            moveExercise(from: index, to: index + 1)
                        } : nil
                    )
                }
                
                // Add Exercise Button
                Button(action: {
                    showingExerciseLibrary = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(theme.colors.accent)
                        
                        Text("training.exercise.addCustom".localized)
                            .font(theme.typography.body)
                            .fontWeight(.medium)
                            .foregroundColor(theme.colors.accent)
                        
                        Spacer()
                    }
                    .padding()
                    .background(theme.colors.accent.opacity(0.1))
                    .cornerRadius(theme.radius.m)
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.radius.m)
                            .strokeBorder(theme.colors.accent.opacity(0.3), lineWidth: 1, antialiased: true)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal)
                .padding(.top, theme.spacing.s)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Bottom Actions Section  
    private var bottomActionsSection: some View {
        VStack(spacing: theme.spacing.m) {
            Button(action: {
                if workingExercises.isEmpty {
                    // Show alert that routine needs exercises
                    return
                }
                showingNameInput = true
            }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                    Text("routine.create.save".localized)
                        .font(theme.typography.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, theme.spacing.m)
                .background(workingExercises.isEmpty ? theme.colors.textSecondary : theme.colors.accent)
                .cornerRadius(theme.radius.m)
            }
            .disabled(workingExercises.isEmpty)
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(theme.colors.backgroundPrimary)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(theme.colors.textSecondary)
                .opacity(0.2),
            alignment: .top
        )
    }
    
    // MARK: - Actions
    private func removeExercise(at index: Int) {
        withAnimation(.easeInOut(duration: 0.2)) {
            workingExercises.remove(at: index)
            // Update order indices
            for i in 0..<workingExercises.count {
                workingExercises[i].orderIndex = i
            }
        }
    }
    
    private func moveExercise(from sourceIndex: Int, to destIndex: Int) {
        withAnimation(.easeInOut(duration: 0.2)) {
            let exercise = workingExercises.remove(at: sourceIndex)
            workingExercises.insert(exercise, at: destIndex)
            // Update order indices
            for i in 0..<workingExercises.count {
                workingExercises[i].orderIndex = i
            }
        }
    }
    
    private func saveCustomRoutine(name: String) {
        // Create new custom routine
        let customWorkout = LiftWorkout(
            name: name,
            nameEN: name,
            nameTR: name,
            estimatedDuration: sourceTemplate.estimatedDuration,
            isTemplate: true,
            isCustom: true
        )
        
        // Add exercises
        for exercise in workingExercises {
            let newExercise = LiftExercise(
                exerciseId: exercise.exerciseId,
                exerciseName: exercise.exerciseName,
                orderIndex: exercise.orderIndex
            )
            customWorkout.addExercise(newExercise)
        }
        
        // Save to database
        modelContext.insert(customWorkout)
        
        do {
            try modelContext.save()
            Logger.success("Custom routine '\(name)' created successfully")
            dismiss()
        } catch {
            Logger.error("Failed to save custom routine: \(error)")
        }
    }
}

// ExerciseEditRow is now available from Shared/Components/EditableRow.swift

// MARK: - Preview
#Preview {
    let sampleTemplate = LiftWorkout(
        name: "Upper Body Template",
        nameEN: "Upper Body Template",
        nameTR: "Üst Vücut Şablonu",
        estimatedDuration: 60,
        isTemplate: true,
        isCustom: false
    )
    
    // Add sample exercises
    let sampleExercises = [
        LiftExercise(exerciseId: UUID(), exerciseName: "Bench Press", orderIndex: 0),
        LiftExercise(exerciseId: UUID(), exerciseName: "Barbell Row", orderIndex: 1),
        LiftExercise(exerciseId: UUID(), exerciseName: "Overhead Press", orderIndex: 2)
    ]
    
    sampleExercises.forEach { sampleTemplate.addExercise($0) }
    
    return CustomizeTemplateView(template: sampleTemplate)
}