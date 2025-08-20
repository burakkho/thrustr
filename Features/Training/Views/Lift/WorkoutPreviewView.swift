import SwiftUI
import SwiftData

// MARK: - Workout Preview View
struct WorkoutPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    
    let workout: LiftWorkout
    let programExecution: ProgramExecution?
    let onBeginWorkout: () -> Void
    
    @State private var showingWarmupTips = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: theme.spacing.l) {
                    // Header Section
                    workoutHeaderSection
                    
                    // Program Context (if from program)
                    if let execution = programExecution {
                        programContextSection(execution: execution)
                    }
                    
                    // Exercise List
                    exerciseListSection
                    
                    // Warm-up Tips
                    warmupSection
                    
                    // Action Buttons
                    actionButtonsSection
                }
                .padding(.horizontal)
                .padding(.bottom, theme.spacing.xl)
            }
            .navigationTitle("Workout Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var workoutHeaderSection: some View {
        VStack(spacing: theme.spacing.m) {
            // Workout Icon & Name
            VStack(spacing: theme.spacing.s) {
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 48))
                    .foregroundColor(theme.colors.accent)
                
                Text(workout.localizedName)
                    .font(theme.typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textPrimary)
                    .multilineTextAlignment(.center)
            }
            
            // Workout Stats
            HStack(spacing: theme.spacing.l) {
                statItem(
                    icon: "list.bullet",
                    title: "Exercises",
                    value: "\(workout.exercises.count)"
                )
                
                Divider()
                    .frame(height: 30)
                
                statItem(
                    icon: "clock",
                    title: "Duration",
                    value: "\(workout.estimatedDuration ?? 45) min"
                )
                
                Divider()
                    .frame(height: 30)
                
                statItem(
                    icon: "target",
                    title: "Sets",
                    value: "\(totalSets)"
                )
            }
            .padding(.vertical, theme.spacing.m)
            .padding(.horizontal, theme.spacing.l)
            .background(theme.colors.cardBackground)
            .cornerRadius(theme.radius.m)
        }
    }
    
    private func statItem(icon: String, title: String, value: String) -> some View {
        VStack(spacing: theme.spacing.xs) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(theme.colors.accent)
            
            Text(value)
                .font(theme.typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(theme.colors.textPrimary)
            
            Text(title)
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Program Context Section
    private func programContextSection(execution: ProgramExecution) -> some View {
        VStack(spacing: theme.spacing.s) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title3)
                    .foregroundColor(theme.colors.success)
                
                Text("PROGRAM PROGRESS")
                    .font(theme.typography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.colors.textSecondary)
                    .tracking(1.0)
                
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(execution.program.localizedName)
                        .font(theme.typography.body)
                        .fontWeight(.medium)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Text("Week \(execution.currentWeek) of \(execution.program.weeks) • Workout \(execution.completedWorkouts.count + 1)")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(execution.progressPercentage * 100))%")
                        .font(theme.typography.headline)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.accent)
                    
                    Text("Complete")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
        }
        .padding()
        .background(theme.colors.success.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radius.m)
                .stroke(theme.colors.success.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(theme.radius.m)
    }
    
    // MARK: - Exercise List Section
    private var exerciseListSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            HStack {
                Text("Exercises")
                    .font(theme.typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                
                Spacer()
                
                Text("\(workout.exercises.count) exercises")
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }
            
            VStack(spacing: theme.spacing.s) {
                ForEach(Array(workout.exercises.enumerated()), id: \.element.id) { index, exercise in
                    ExercisePreviewCard(
                        exercise: exercise,
                        index: index + 1
                    )
                }
            }
        }
    }
    
    // MARK: - Warm-up Section
    private var warmupSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            Button(action: { showingWarmupTips.toggle() }) {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(theme.colors.warning)
                    
                    Text("Warm-up Recommendations")
                        .font(theme.typography.body)
                        .fontWeight(.medium)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: showingWarmupTips ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(theme.colors.textSecondary)
                }
                .padding()
                .background(theme.colors.warning.opacity(0.05))
                .cornerRadius(theme.radius.m)
            }
            .buttonStyle(PlainButtonStyle())
            
            if showingWarmupTips {
                warmupTipsContent
                    .transition(.slide)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showingWarmupTips)
    }
    
    private var warmupTipsContent: some View {
        VStack(alignment: .leading, spacing: theme.spacing.s) {
            warmupTip(icon: "heart.fill", text: "5-10 minutes light cardio")
            warmupTip(icon: "figure.flexibility", text: "Dynamic stretching for major muscle groups")
            warmupTip(icon: "arrow.up.circle", text: "Practice movement patterns with bodyweight")
            warmupTip(icon: "dumbbell", text: "Warm-up sets with lighter weights")
        }
        .padding()
        .background(theme.colors.backgroundSecondary)
        .cornerRadius(theme.radius.m)
    }
    
    private func warmupTip(icon: String, text: String) -> some View {
        HStack(spacing: theme.spacing.s) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(theme.colors.warning)
                .frame(width: 20)
            
            Text(text)
                .font(theme.typography.body)
                .foregroundColor(theme.colors.textPrimary)
            
            Spacer()
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtonsSection: some View {
        VStack(spacing: theme.spacing.m) {
            // Primary Action - Begin Workout
            Button(action: onBeginWorkout) {
                HStack(spacing: theme.spacing.m) {
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                    
                    Text("BEGIN WORKOUT")
                        .font(theme.typography.headline)
                        .fontWeight(.bold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, theme.spacing.l)
                .background(theme.colors.accent)
                .cornerRadius(theme.radius.m)
            }
            .buttonStyle(PressableStyle())
            
            // Secondary Action - View Previous Sessions
            if hasPreviousSessions {
                Button(action: { /* Show previous sessions */ }) {
                    HStack(spacing: theme.spacing.s) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.body)
                        Text("View Previous Sessions")
                            .font(theme.typography.body)
                    }
                    .foregroundColor(theme.colors.accent)
                    .padding(.vertical, theme.spacing.s)
                }
            }
        }
        .padding(.top, theme.spacing.l)
    }
    
    // MARK: - Computed Properties
    private var totalSets: Int {
        workout.exercises.reduce(0) { $0 + $1.targetSets }
    }
    
    private var hasPreviousSessions: Bool {
        // TODO: Check if user has previous sessions for this workout
        false
    }
}

// MARK: - Exercise Preview Card
struct ExercisePreviewCard: View {
    @Environment(\.theme) private var theme
    
    let exercise: LiftExercise
    let index: Int
    
    var body: some View {
        HStack(spacing: theme.spacing.m) {
            // Exercise Number
            Text("\(index)")
                .font(theme.typography.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(theme.colors.accent)
                .clipShape(Circle())
            
            // Exercise Info
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.exerciseName)
                    .font(theme.typography.body)
                    .fontWeight(.medium)
                    .foregroundColor(theme.colors.textPrimary)
                
                HStack(spacing: theme.spacing.m) {
                    Text("\(exercise.targetSets) × \(exercise.targetReps)")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                    
                    if let restTime = exercise.restTime, restTime > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption)
                            Text("\(restTime)s rest")
                        }
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                    }
                }
            }
            
            Spacer()
            
            // Target Weight (if available)
            if let targetWeight = exercise.targetWeight {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(targetWeight))kg")
                        .font(theme.typography.body)
                        .fontWeight(.medium)
                        .foregroundColor(theme.colors.accent)
                    
                    Text("Target")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                }
            } else {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Progressive")
                        .font(theme.typography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(theme.colors.accent)
                    
                    Text("Weight")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
        }
        .padding()
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.m)
    }
}

// MARK: - Preview
#Preview {
    WorkoutPreviewView(
        workout: LiftWorkout(
            name: "Workout A",
            nameEN: "Workout A",
            nameTR: "Antrenman A",
            dayNumber: 1,
            estimatedDuration: 45,
            isTemplate: true,
            isCustom: false
        ),
        programExecution: nil,
        onBeginWorkout: {}
    )
}