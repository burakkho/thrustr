import SwiftUI
import SwiftData

// MARK: - Scratch Routine Builder View
struct ScratchRoutineBuilderView: View {
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedExercises: [LiftExercise] = []
    @State private var showingExerciseLibrary = false
    @State private var showingNameInput = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header section
                headerSection
                
                // Exercise list or empty state
                if selectedExercises.isEmpty {
                    emptyStateSection
                } else {
                    exerciseListSection
                }
                
                // Bottom actions
                bottomActionsSection
            }
            .navigationTitle("routine.create.fromScratch".localized)
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
                selectedExercises: $selectedExercises,
                isPresented: $showingExerciseLibrary
            )
        }
        .sheet(isPresented: $showingNameInput) {
            RoutineNameInputView(
                exercises: selectedExercises,
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
                    Text("Build Your Routine")
                        .font(theme.typography.title2)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Text("Add exercises to create your custom routine")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                }
                
                Spacer()
                
                if !selectedExercises.isEmpty {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(selectedExercises.count)")
                            .font(theme.typography.title2)
                            .fontWeight(.bold)
                            .foregroundColor(theme.colors.accent)
                        Text("routine.exercises".localized)
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textSecondary)
                    }
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
    
    // MARK: - Empty State Section
    private var emptyStateSection: some View {
        VStack(spacing: theme.spacing.l) {
            Spacer()
            
            VStack(spacing: theme.spacing.m) {
                // Icon
                ZStack {
                    Circle()
                        .fill(theme.colors.accent.opacity(0.1))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "dumbbell.fill")
                        .font(.largeTitle)
                        .foregroundColor(theme.colors.accent)
                }
                
                // Text content
                VStack(spacing: theme.spacing.s) {
                    Text("No Exercises Yet")
                        .font(theme.typography.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Text("Add exercises to start building your routine")
                        .font(theme.typography.body)
                        .foregroundColor(theme.colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                
                // Add first exercise button
                Button(action: {
                    showingExerciseLibrary = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                        Text("Add Your First Exercise")
                            .font(theme.typography.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, theme.spacing.m)
                    .background(theme.colors.accent)
                    .cornerRadius(theme.radius.m)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, theme.spacing.m)
            }
            .padding(.horizontal, theme.spacing.l)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Exercise List Section
    private var exerciseListSection: some View {
        ScrollView {
            LazyVStack(spacing: theme.spacing.s) {
                ForEach(selectedExercises.indices, id: \.self) { index in
                    ExerciseEditRow(
                        exercise: selectedExercises[index],
                        onRemove: {
                            removeExercise(at: index)
                        },
                        onMoveUp: index > 0 ? {
                            moveExercise(from: index, to: index - 1)
                        } : nil,
                        onMoveDown: index < selectedExercises.count - 1 ? {
                            moveExercise(from: index, to: index + 1)
                        } : nil
                    )
                }
                
                // Add More Exercises Button
                Button(action: {
                    showingExerciseLibrary = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(theme.colors.accent)
                        
                        Text("Add More Exercises")
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
                if selectedExercises.isEmpty {
                    showingExerciseLibrary = true
                } else {
                    showingNameInput = true
                }
            }) {
                HStack {
                    if selectedExercises.isEmpty {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                        Text("Add Exercises")
                            .font(theme.typography.headline)
                            .fontWeight(.semibold)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                        Text("routine.create.save".localized)
                            .font(theme.typography.headline)
                            .fontWeight(.semibold)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, theme.spacing.m)
                .background(theme.colors.accent)
                .cornerRadius(theme.radius.m)
            }
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
            selectedExercises.remove(at: index)
            // Update order indices
            for i in 0..<selectedExercises.count {
                selectedExercises[i].orderIndex = i
            }
        }
    }
    
    private func moveExercise(from sourceIndex: Int, to destIndex: Int) {
        withAnimation(.easeInOut(duration: 0.2)) {
            let exercise = selectedExercises.remove(at: sourceIndex)
            selectedExercises.insert(exercise, at: destIndex)
            // Update order indices
            for i in 0..<selectedExercises.count {
                selectedExercises[i].orderIndex = i
            }
        }
    }
    
    private func saveCustomRoutine(name: String) {
        // Create new custom routine
        let customWorkout = LiftWorkout(
            name: name,
            nameEN: name,
            nameTR: name,
            estimatedDuration: max(20, selectedExercises.count * 3 + 10), // Dynamic estimation
            isTemplate: true,
            isCustom: true
        )
        
        // Add exercises
        for exercise in selectedExercises {
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
            Logger.success("Custom routine '\(name)' created from scratch")
            dismiss()
        } catch {
            Logger.error("Failed to save custom routine: \(error)")
        }
    }
}

// MARK: - Preview
#Preview {
    ScratchRoutineBuilderView()
}