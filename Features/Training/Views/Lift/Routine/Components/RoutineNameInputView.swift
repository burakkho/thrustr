import SwiftUI

// MARK: - Routine Name Input View
struct RoutineNameInputView: View {
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    
    let exercises: [LiftExercise]
    let onSave: (String) -> Void
    
    @State private var routineName = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: theme.spacing.l) {
                // Header section
                headerSection
                
                // Name input section
                nameInputSection
                
                // Routine summary
                routineSummarySection
                
                Spacer()
                
                // Save button
                saveButtonSection
            }
            .padding()
            .navigationTitle("routine.create.save".localized)
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
        .onAppear {
            // Auto-focus text field and suggest default name
            isTextFieldFocused = true
            if routineName.isEmpty {
                routineName = generateDefaultName()
            }
        }
        .alert(TrainingKeys.AlertsExtended.error.localized, isPresented: $showingError) {
            Button("common.ok".localized, role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.s) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(theme.colors.success)
                
                Text("Almost Done!")
                    .font(theme.typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textPrimary)
            }
            
            Text("Give your routine a name to save it to your custom routines.")
                .font(theme.typography.body)
                .foregroundColor(theme.colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Name Input Section
    private var nameInputSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.s) {
            Text(TrainingKeys.FormsExtended.routineName.localized)
                .font(theme.typography.headline)
                .fontWeight(.medium)
                .foregroundColor(theme.colors.textPrimary)
            
            TextField("Enter routine name", text: $routineName)
                .focused($isTextFieldFocused)
                .font(theme.typography.body)
                .padding()
                .background(theme.colors.backgroundSecondary)
                .cornerRadius(theme.radius.m)
                .overlay(
                    RoundedRectangle(cornerRadius: theme.radius.m)
                        .stroke(isTextFieldFocused ? theme.colors.accent : Color.clear, lineWidth: 1)
                )
                .onSubmit {
                    saveRoutine()
                }
            
            // Quick suggestions
            quickSuggestionsSection
        }
    }
    
    // MARK: - Quick Suggestions Section
    private var quickSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.s) {
            Text(TrainingKeys.FormsExtended.quickSuggestions.localized)
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textSecondary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: theme.spacing.s) {
                ForEach(getSuggestions(), id: \.self) { suggestion in
                    Button(action: {
                        routineName = suggestion
                    }) {
                        Text(suggestion)
                            .font(theme.typography.caption)
                            .fontWeight(.medium)
                            .foregroundColor(theme.colors.accent)
                            .padding(.horizontal, theme.spacing.s)
                            .padding(.vertical, 6)
                            .background(theme.colors.accent.opacity(0.1))
                            .cornerRadius(theme.radius.s)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    // MARK: - Routine Summary Section  
    private var routineSummarySection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            Text("Routine Summary")
                .font(theme.typography.headline)
                .fontWeight(.medium)
                .foregroundColor(theme.colors.textPrimary)
            
            VStack(spacing: theme.spacing.s) {
                // Exercise count
                summaryRow(
                    icon: "list.bullet",
                    title: "Exercises",
                    value: "\(exercises.count)"
                )
                
                // Estimated duration
                summaryRow(
                    icon: "clock",
                    title: "Estimated Duration",
                    value: estimatedDuration
                )
                
                // Exercise preview
                exercisePreviewSection
            }
            .padding()
            .background(theme.colors.cardBackground)
            .cornerRadius(theme.radius.m)
        }
    }
    
    // MARK: - Exercise Preview Section
    private var exercisePreviewSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.s) {
            HStack {
                Image(systemName: "dumbbell")
                    .font(.caption)
                    .foregroundColor(theme.colors.accent)
                
                Text("Exercises")
                    .font(theme.typography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.colors.textPrimary)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(exercises.prefix(3), id: \.id) { exercise in
                    Text("• \(exercise.exerciseName)")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                }
                
                if exercises.count > 3 {
                    Text("• +\(exercises.count - 3) more exercises")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.accent)
                }
            }
        }
    }
    
    // MARK: - Save Button Section
    private var saveButtonSection: some View {
        Button(action: saveRoutine) {
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
            .background(isValidName ? theme.colors.accent : theme.colors.textSecondary)
            .cornerRadius(theme.radius.m)
        }
        .disabled(!isValidName)
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Helper Views
    private func summaryRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(theme.colors.accent)
                .frame(width: 16)
            
            Text(title)
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(theme.typography.caption)
                .fontWeight(.medium)
                .foregroundColor(theme.colors.textPrimary)
        }
    }
    
    // MARK: - Computed Properties
    private var isValidName: Bool {
        !routineName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var estimatedDuration: String {
        let baseTime = exercises.count * 3 // 3 minutes per exercise
        let totalMinutes = max(20, baseTime + 10) // Minimum 20 minutes, +10 for rest
        return "\(totalMinutes) min"
    }
    
    // MARK: - Helper Methods
    private func generateDefaultName() -> String {
        let dominantCategory = findDominantCategory()
        let timestamp = Date().formatted(.dateTime.month().day())
        
        switch dominantCategory {
        case "push":
            return "Push Workout - \(timestamp)"
        case "pull":
            return "Pull Workout - \(timestamp)"
        case "legs":
            return "Leg Workout - \(timestamp)"
        case "strength":
            return "Strength Workout - \(timestamp)"
        case "core":
            return "Core Workout - \(timestamp)"
        default:
            return "My Workout - \(timestamp)"
        }
    }
    
    private func findDominantCategory() -> String {
        // This would require accessing Exercise models to get category
        // For now, return generic
        return "custom"
    }
    
    private func getSuggestions() -> [String] {
        let base = ["Push Day", "Pull Day", "Upper Body", "Lower Body", "Full Body", "Custom Workout"]
        return base.filter { $0 != routineName }
    }
    
    private func saveRoutine() {
        let trimmedName = routineName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            showError("Routine name cannot be empty")
            return
        }
        
        guard trimmedName.count <= 50 else {
            showError("Routine name is too long (max 50 characters)")
            return
        }
        
        // Call save callback
        onSave(trimmedName)
        dismiss()
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}

// MARK: - Preview
#Preview {
    let sampleExercises = [
        LiftExercise(exerciseId: UUID(), exerciseName: "Bench Press", orderIndex: 0),
        LiftExercise(exerciseId: UUID(), exerciseName: "Barbell Row", orderIndex: 1),
        LiftExercise(exerciseId: UUID(), exerciseName: "Overhead Press", orderIndex: 2),
        LiftExercise(exerciseId: UUID(), exerciseName: "Pull Up", orderIndex: 3)
    ]
    
    return RoutineNameInputView(
        exercises: sampleExercises,
        onSave: { name in
            print("Saving routine: \(name)")
        }
    )
}