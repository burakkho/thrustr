import SwiftUI
import SwiftData

// MARK: - Main Training View
struct TrainingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var workouts: [Workout]
    @Query private var exercises: [Exercise]
    
    @State private var showingNewWorkout = false
    @State private var selectedTab = 0
    @State private var workoutToShow: Workout?
    @State private var showWorkoutDetail = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segment Control
                Picker(LocalizationKeys.Training.title.localized, selection: $selectedTab) {
                    Text(LocalizationKeys.Training.history.localized).tag(0)
                    Text(LocalizationKeys.Training.active.localized).tag(1)
                    Text(LocalizationKeys.Training.templates.localized).tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content based on selected tab
                switch selectedTab {
                case 0:
                    WorkoutHistoryView(workouts: workouts)
                case 1:
                    ActiveWorkoutView(onWorkoutTap: { workout in
                        workoutToShow = workout
                        showWorkoutDetail = true
                    })
                case 2:
                    WorkoutTemplatesView()
                default:
                    EmptyView()
                }
            }
            .navigationTitle(LocalizationKeys.Training.title.localized)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        let newWorkout = Workout(name: LocalizationKeys.Training.History.defaultName.localized)
                        modelContext.insert(newWorkout)
                        workoutToShow = newWorkout
                    }) {
                        Image(systemName: "plus")
                            .font(.headline)
                            .accessibilityLabel(LocalizationKeys.Common.add.localized)
                    }
                }
            }
            .fullScreenCover(item: $workoutToShow) { workout in
                WorkoutDetailView(workout: workout)
            }
        }
    }
}

// MARK: - Workout History View
struct WorkoutHistoryView: View {
    let workouts: [Workout]
    @Environment(\.theme) private var theme
    
    var completedWorkouts: [Workout] {
        workouts.filter { $0.isCompleted }.sorted { $0.date > $1.date }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: theme.spacing.m) {
                if completedWorkouts.isEmpty {
                    // Empty state
                    VStack(spacing: theme.spacing.m) {
                        Image(systemName: "dumbbell")
                            .font(.system(size: 50))
                            .foregroundColor(theme.colors.textSecondary)
                        
                        Text(LocalizationKeys.Training.History.emptyTitle.localized)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(LocalizationKeys.Training.History.emptySubtitle.localized)
                            .foregroundColor(theme.colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 100)
                } else {
                    ForEach(completedWorkouts) { workout in
                        WorkoutHistoryCard(workout: workout)
                    }
                }
            }
            .padding(theme.spacing.m)
        }
    }
}

// MARK: - Workout History Card
struct WorkoutHistoryCard: View {
    let workout: Workout
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.name ?? LocalizationKeys.Training.History.defaultName.localized)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(workout.date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(workout.durationInMinutes) \(LocalizationKeys.Training.Time.minutes.localized)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("\(workout.totalSets) \(LocalizationKeys.Training.Stats.sets.localized.lowercased())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Parts summary
            HStack(spacing: 8) {
                ForEach(workout.parts.sorted(by: { $0.orderIndex < $1.orderIndex }), id: \.id) { part in
                    PartTypeChip(partType: WorkoutPartType(rawValue: part.type) ?? .strength)
                }
                
                if workout.parts.isEmpty {
                    Text(LocalizationKeys.Training.History.noParts.localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Volume info
            if workout.totalVolume > 0 {
                HStack {
                    Image(systemName: "scalemass")
                        .foregroundColor(.blue)
                        .font(.caption)
                    
                    Text(LocalizationKeys.Training.History.totalVolume.localized(with: Int(workout.totalVolume)))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(theme.spacing.m)
        .background(theme.colors.cardBackground)
        .cornerRadius(12)
    }
}

// MARK: - Part Type Chip
struct PartTypeChip: View {
    let partType: WorkoutPartType
    @Environment(\.theme) private var theme
    
    var localizedDisplayName: String {
        switch partType {
        case .strength:
            return LocalizationKeys.Training.Part.strength.localized
        case .conditioning:
            return LocalizationKeys.Training.Part.conditioning.localized
        case .accessory:
            return LocalizationKeys.Training.Part.accessory.localized
        case .warmup:
            return LocalizationKeys.Training.Part.warmup.localized
        case .functional:
            return LocalizationKeys.Training.Part.functional.localized
        case .olympic:
            return "Olimpik"
        case .plyometric:
            return "Plyometrik"
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: partType.icon)
                .font(.caption)
            Text(localizedDisplayName)
                .font(.caption)
        }
        .padding(.horizontal, theme.spacing.s)
        .padding(.vertical, theme.spacing.xs)
        .background(partColor.opacity(0.2))
        .foregroundColor(partColor)
        .cornerRadius(8)
    }
    
    private var partColor: Color {
        switch partType {
        case .strength: return .blue
        case .conditioning: return .red
        case .accessory: return .green
        case .warmup: return .orange
        case .functional: return .purple
        case .olympic: return .yellow
        case .plyometric: return .pink
        }
    }
}

// MARK: - Active Workout View
struct ActiveWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.theme) private var theme
    @Query(filter: #Predicate<Workout> { !$0.isCompleted }) private var activeWorkouts: [Workout]
    
    let onWorkoutTap: (Workout) -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let activeWorkout = activeWorkouts.first {
                    // Active workout exists
                    ActiveWorkoutCard(workout: activeWorkout) {
                        onWorkoutTap(activeWorkout)
                    }
                } else {
                    // No active workout
                    VStack(spacing: theme.spacing.m) {
                        Image(systemName: "play.circle")
                            .font(.system(size: 50))
                            .foregroundColor(theme.colors.accent)
                        
                        Text(LocalizationKeys.Training.Active.emptyTitle.localized)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(LocalizationKeys.Training.Active.emptySubtitle.localized)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button(LocalizationKeys.Training.Active.startButton.localized) {
                            startNewWorkout()
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(theme.spacing.m)
                        .background(theme.colors.accent)
                        .cornerRadius(12)
                        .buttonStyle(PressableStyle())
                        .accessibilityLabel(LocalizationKeys.Training.Active.startButton.localized)
                    }
                    .padding(.top, 80)
                }
            }
            .padding(theme.spacing.m)
        }
    }
    
    private func startNewWorkout() {
        let newWorkout = Workout(name: LocalizationKeys.Training.History.defaultName.localized)
        modelContext.insert(newWorkout)
        onWorkoutTap(newWorkout)
    }
}

// MARK: - Active Workout Card
struct ActiveWorkoutCard: View {
    let workout: Workout
    let onTap: () -> Void
    @Environment(\.modelContext) private var modelContext
    @Environment(\.theme) private var theme
    @State private var currentTime = Date()
    @State private var timerText: String = ""
    @State private var timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with timer
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizationKeys.Training.Active.title.localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(workout.name ?? LocalizationKeys.Training.History.defaultName.localized)
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(LocalizationKeys.Training.Active.duration.localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(timerText)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.accent)
                }
            }
            
            // Quick stats
            HStack(spacing: 20) {
                StatItem(title: LocalizationKeys.Training.Stats.parts.localized, value: "\(workout.parts.count)")
                StatItem(title: LocalizationKeys.Training.Stats.sets.localized, value: "\(workout.totalSets)")
                StatItem(title: LocalizationKeys.Training.Stats.volume.localized, value: "\(Int(workout.totalVolume))kg")
            }
            
            // Actions
            HStack(spacing: theme.spacing.m) {
                Button(LocalizationKeys.Training.Active.continueButton.localized) {
                    onTap()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(theme.spacing.m)
                .background(theme.colors.accent)
                .cornerRadius(12)
                .buttonStyle(PressableStyle())
                .accessibilityLabel(LocalizationKeys.Training.Active.continueButton.localized)
                
                Button(LocalizationKeys.Training.Active.finish.localized) {
                    workout.finishWorkout()
                    do { try modelContext.save() } catch { /* ignore */ }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
                .font(.headline)
                .foregroundColor(theme.colors.accent)
                .frame(maxWidth: .infinity)
                .padding(theme.spacing.m)
                .background(theme.colors.accent.opacity(0.1))
                .cornerRadius(12)
                .buttonStyle(PressableStyle())
                .accessibilityLabel(LocalizationKeys.Training.Active.finish.localized)
            }
        }
        .padding(theme.spacing.m)
        .background(theme.colors.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.colors.accent, lineWidth: 2)
        )
        .cornerRadius(12)
        .onReceive(timer) { _ in
            currentTime = Date()
            timerText = formatDuration(Int(currentTime.timeIntervalSince(workout.startTime)))
        }
        .onAppear {
            timerText = formatDuration(Int(Date().timeIntervalSince(workout.startTime)))
        }
        .onDisappear {
            timer.upstream.connect().cancel()
        }
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
}

// MARK: - Stat Item
struct StatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Workout Templates View
struct WorkoutTemplatesView: View {
    @Environment(\.theme) private var theme
    var body: some View {
        ScrollView {
            VStack(spacing: theme.spacing.m) {
                Image(systemName: "doc.text")
                    .font(.system(size: 50))
                    .foregroundColor(theme.colors.success)
                
                Text(LocalizationKeys.Training.Templates.title.localized)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(LocalizationKeys.Training.Templates.empty.localized)
                    .foregroundColor(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 100)
        }
        .padding(theme.spacing.m)
    }
}

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
                        
                        QuickStartButton(
                            title: LocalizationKeys.Training.New.Functional.title.localized,
                            subtitle: LocalizationKeys.Training.New.Functional.subtitle.localized,
                            icon: "figure.strengthtraining.functional",
                            color: .green
                        ) {
                            startFunctionalWorkout()
                        }
                        
                        QuickStartButton(
                            title: LocalizationKeys.Training.New.Cardio.title.localized,
                            subtitle: LocalizationKeys.Training.New.Cardio.subtitle.localized,
                            icon: "heart.fill",
                            color: .red
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
    
    private func startFunctionalWorkout() {
        let workout = Workout(name: workoutName.isEmpty ? LocalizationKeys.Training.New.Functional.title.localized : workoutName)
        
        // Add functional training part
        let _ = workout.addPart(name: LocalizationKeys.Training.Part.functional.localized, type: .functional)
        
        modelContext.insert(workout)
        do { try modelContext.save() } catch { /* ignore */ }
        
        dismiss()
        
        // Call the callback to show workout detail
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            onWorkoutCreated(workout)
        }
    }
    
    private func startCardioWorkout() {
        let workout = Workout(name: workoutName.isEmpty ? LocalizationKeys.Training.New.Cardio.title.localized : workoutName)
        
        // Add cardio part
        let _ = workout.addPart(name: LocalizationKeys.Training.Part.conditioning.localized, type: .conditioning)
        
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

#Preview {
    TrainingView()
        .modelContainer(for: [Workout.self, Exercise.self], inMemory: true)
}

// MARK: - New Workout Flow
struct NewWorkoutFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let onComplete: (Workout) -> Void

    @State private var createdWorkout: Workout? = nil
    @State private var createdPart: WorkoutPart? = nil

    private func inferPartType(from exercise: Exercise) -> WorkoutPartType {
        let cat = ExerciseCategory(rawValue: exercise.category) ?? .other
        switch cat {
        case .cardio: return .conditioning
        case .functional: return .functional
        case .core, .isolation: return .accessory
        case .warmup, .flexibility, .plyometric: return .warmup
        default: return .strength
        }
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
            .navigationTitle("Egzersiz Ekle")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }
}
