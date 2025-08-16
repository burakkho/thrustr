import SwiftUI
import SwiftData

// MARK: - New Workout View
struct NewWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var workoutName = ""
    let onWorkoutCreated: (Workout) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text(LocalizationKeys.Training.New.title.localized)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(LocalizationKeys.Training.New.subtitle.localized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                // Workout name
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizationKeys.Training.New.nameLabel.localized)
                        .font(.headline)
                    
                    TextField(LocalizationKeys.Training.New.namePlaceholder.localized, text: $workoutName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal)
                
                // Quick start options
                VStack(spacing: 12) {
                    Text(LocalizationKeys.Training.New.quickStart.localized)
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    VStack(spacing: 8) {
                        QuickStartButton(
                            title: LocalizationKeys.Training.New.Empty.title.localized,
                            subtitle: LocalizationKeys.Training.New.Empty.subtitle.localized,
                            icon: "plus.circle.fill",
                            color: .blue
                        ) {
                            startEmptyWorkout()
                        }
                        
                        // Functional quick start removed in new part system
                        
                        QuickStartButton(
                            title: LocalizationKeys.Training.Part.cardio.localized,
                            subtitle: LocalizationKeys.Training.Part.cardioDesc.localized,
                            icon: "figure.run",
                            color: .orange
                        ) {
                            startCardioWorkout()
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizationKeys.Training.New.cancel.localized) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func startEmptyWorkout() {
        let workout = Workout(name: workoutName.isEmpty ? LocalizationKeys.Training.History.defaultName.localized : workoutName)
        modelContext.insert(workout)
        do { try modelContext.save() } catch { /* ignore */ }
        
        dismiss()
        
        // Call the callback to show workout detail
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            onWorkoutCreated(workout)
        }
    }
    
    // startFunctionalWorkout removed in new part system
    
    private func startCardioWorkout() {
        let workout = Workout(name: workoutName.isEmpty ? LocalizationKeys.Training.Part.cardio.localized : workoutName)
        
        // Add cardio part
        let _ = workout.addPart(name: LocalizationKeys.Training.Part.cardio.localized, type: .cardio)
        
        modelContext.insert(workout)
        do { try modelContext.save() } catch { /* ignore */ }
        
        dismiss()
        
        // Call the callback to show workout detail
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            onWorkoutCreated(workout)
        }
    }
}

// MARK: - Quick Start Button
struct QuickStartButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - New Workout Flow
struct NewWorkoutFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let onComplete: (Workout) -> Void

    @State private var createdWorkout: Workout? = nil
    @State private var createdPart: WorkoutPart? = nil

    private func inferPartType(from exercise: Exercise) -> WorkoutPartType {
        ExerciseCategory(rawValue: exercise.category)?.toWorkoutPartType() ?? .powerStrength
    }

    var body: some View {
        NavigationStack {
            ExerciseSelectionView(workoutPart: createdPart) { exercise in
                if createdWorkout == nil {
                    let workout = Workout()
                    modelContext.insert(workout)
                    createdWorkout = workout

                    let type = inferPartType(from: exercise)
                    let part = workout.addPart(name: type.displayName, type: type)
                    createdPart = part
                    do { try modelContext.save() } catch { /* ignore */ }
                }

                if let workout = createdWorkout {
                    onComplete(workout)
                    dismiss()
                }
            }
            .navigationTitle(LocalizationKeys.Training.Exercise.title.localized)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizationKeys.Common.close.localized) { dismiss() }
                }
            }
        }
    }
}
