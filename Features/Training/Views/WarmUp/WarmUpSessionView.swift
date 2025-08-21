import SwiftUI
import SwiftData

struct WarmUpSessionView: View {
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let template: WarmUpTemplate
    @State private var timerViewModel = TimerViewModel()
    @State private var currentSession: WarmUpSession?
    @State private var showingCompletion = false
    @State private var selectedFeeling: WarmUpFeeling?
    @State private var sessionNotes = ""
    
    // Exercises loaded from Exercise model based on template
    @State private var exercises: [(id: UUID, name: String, isCompleted: Bool)] = []
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Timer Display
                timerSection
                
                // Exercise List
                exerciseListSection
                
                // Bottom Controls
                bottomControlsSection
            }
            .navigationTitle(template.localizedName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        handleCancel()
                    }
                    .foregroundColor(theme.colors.textSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if timerViewModel.isRunning || timerViewModel.isPaused {
                        Button("Finish") {
                            finishSession()
                        }
                        .foregroundColor(theme.colors.accent)
                    }
                }
            }
        }
        .onAppear {
            setupSession()
        }
        .sheet(isPresented: $showingCompletion) {
            completionSheet
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: theme.spacing.s) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.localizedName)
                        .font(theme.typography.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Text("Expected: \(template.formattedDuration)")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(completedExercises)/\(exercises.count)")
                        .font(theme.typography.title3)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.accent)
                    Text("Exercises")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
            
            // Progress Bar
            ProgressView(value: progressValue)
                .progressViewStyle(LinearProgressViewStyle(tint: theme.colors.accent))
                .scaleEffect(y: 2)
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
    
    // MARK: - Timer Section
    private var timerSection: some View {
        VStack(spacing: theme.spacing.l) {
            TimerDisplay(
                formattedTime: timerViewModel.formattedTime,
                isRunning: timerViewModel.isRunning,
                size: .large
            )
            
            TimerControls(
                timerState: timerControlsState,
                onStart: {
                    timerViewModel.startCountdown()
                },
                onPause: {
                    timerViewModel.pauseTimer()
                },
                onResume: {
                    timerViewModel.resumeTimer()
                },
                onStop: {
                    finishSession()
                },
                onReset: {
                    timerViewModel.resetTimer()
                }
            )
        }
        .padding(.vertical, theme.spacing.xl)
        .background(theme.colors.backgroundPrimary)
    }
    
    // MARK: - Exercise List Section
    private var exerciseListSection: some View {
        ScrollView {
            LazyVStack(spacing: theme.spacing.s) {
                ForEach(exercises.indices, id: \.self) { index in
                    exerciseRow(exercises[index], index: index)
                }
            }
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func exerciseRow(_ exercise: (id: UUID, name: String, isCompleted: Bool), index: Int) -> some View {
        HStack(spacing: theme.spacing.m) {
            // Completion Button
            Button(action: {
                toggleExerciseCompletion(at: index)
            }) {
                Image(systemName: exercise.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(exercise.isCompleted ? theme.colors.accent : theme.colors.textSecondary)
            }
            
            // Exercise Info
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(theme.typography.body)
                    .fontWeight(.medium)
                    .foregroundColor(exercise.isCompleted ? theme.colors.textSecondary : theme.colors.textPrimary)
                    .strikethrough(exercise.isCompleted)
                
                Text("Complete when ready")
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }
            
            Spacer()
            
            // Exercise Number
            Text("\(index + 1)")
                .font(theme.typography.caption)
                .fontWeight(.semibold)
                .foregroundColor(theme.colors.textSecondary)
                .frame(width: 24, height: 24)
                .background(theme.colors.backgroundSecondary)
                .cornerRadius(12)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: theme.radius.m)
                .fill(exercise.isCompleted ? theme.colors.backgroundSecondary : theme.colors.cardBackground)
                .shadow(color: theme.shadows.card.opacity(0.05), radius: 2)
        )
        .animation(.easeInOut(duration: 0.2), value: exercise.isCompleted)
    }
    
    // MARK: - Bottom Controls
    private var bottomControlsSection: some View {
        VStack(spacing: theme.spacing.m) {
            if !timerViewModel.isRunning && !timerViewModel.isPaused {
                QuickActionButton(
                    title: "Start Warm-Up",
                    icon: "play.fill",
                    style: .primary,
                    size: .fullWidth
                ) {
                    timerViewModel.startCountdown()
                }
            } else if allExercisesCompleted {
                QuickActionButton(
                    title: "Complete Session",
                    icon: "checkmark.circle.fill",
                    style: .primary,
                    size: .fullWidth
                ) {
                    finishSession()
                }
            }
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
    
    // MARK: - Completion Sheet
    private var completionSheet: some View {
        NavigationStack {
            VStack(spacing: theme.spacing.xl) {
                // Success Icon
                ZStack {
                    Circle()
                        .fill(theme.colors.accent.opacity(0.1))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(theme.colors.accent)
                }
                
                // Stats
                VStack(spacing: theme.spacing.m) {
                    Text("Warm-Up Complete!")
                        .font(theme.typography.title2)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    HStack(spacing: theme.spacing.xl) {
                        VStack {
                            Text(timerViewModel.formattedTime)
                                .font(theme.typography.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(theme.colors.accent)
                            Text("Duration")
                                .font(theme.typography.caption)
                                .foregroundColor(theme.colors.textSecondary)
                        }
                        
                        VStack {
                            Text("\(completedExercises)/\(exercises.count)")
                                .font(theme.typography.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(theme.colors.accent)
                            Text("Exercises")
                                .font(theme.typography.caption)
                                .foregroundColor(theme.colors.textSecondary)
                        }
                    }
                }
                
                // Feeling Selection
                VStack(alignment: .leading, spacing: theme.spacing.m) {
                    Text("How do you feel?")
                        .font(theme.typography.headline)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    HStack(spacing: theme.spacing.s) {
                        ForEach(WarmUpFeeling.allCases.dropLast(), id: \.self) { feeling in
                            Button(action: { selectedFeeling = feeling }) {
                                VStack(spacing: 4) {
                                    Text(feeling.emoji)
                                        .font(.title2)
                                    Text(feeling.displayName)
                                        .font(.caption)
                                        .foregroundColor(selectedFeeling == feeling ? .white : theme.colors.textPrimary)
                                }
                                .padding(.vertical, theme.spacing.s)
                                .frame(maxWidth: .infinity)
                                .background(selectedFeeling == feeling ? theme.colors.accent : theme.colors.backgroundSecondary)
                                .cornerRadius(theme.radius.s)
                            }
                        }
                    }
                }
                
                // Notes
                VStack(alignment: .leading, spacing: theme.spacing.s) {
                    Text("Notes (optional)")
                        .font(theme.typography.headline)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    TextField("How was your warm-up?", text: $sessionNotes, axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(theme.colors.backgroundSecondary)
                        .cornerRadius(theme.radius.m)
                        .lineLimit(3...6)
                }
                
                Spacer()
                
                // Done Button
                QuickActionButton(
                    title: "Done",
                    icon: "checkmark",
                    style: .primary,
                    size: .fullWidth
                ) {
                    completeSession()
                }
            }
            .padding()
            .navigationTitle("Session Complete")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.large])
    }
    
    // MARK: - Computed Properties
    private var completedExercises: Int {
        exercises.filter { $0.isCompleted }.count
    }
    
    private var progressValue: Double {
        guard !exercises.isEmpty else { return 0 }
        return Double(completedExercises) / Double(exercises.count)
    }
    
    private var allExercisesCompleted: Bool {
        !exercises.isEmpty && exercises.allSatisfy { $0.isCompleted }
    }
    
    private var timerControlsState: TimerControls.TimerState {
        switch timerViewModel.timerState {
        case .stopped: return .stopped
        case .countdown: return .countdown
        case .running: return .running
        case .paused: return .paused
        case .completed: return .completed
        }
    }
    
    // MARK: - Methods
    private func setupSession() {
        // Load exercises from template using Exercise model
        loadExercisesFromTemplate()
        
        // Create session
        let user = try? modelContext.fetch(FetchDescriptor<User>()).first
        if let user = user {
            currentSession = template.startSession(for: user)
        }
    }
    
    private func loadExercisesFromTemplate() {
        guard !template.exerciseIds.isEmpty else {
            Logger.warning("Template '\(template.name)' has no exercises, using fallback")
            // Fallback exercises from warmup_exercises.csv
            exercises = [
                (UUID(), "Jumping Jacks", false),
                (UUID(), "Arm Circles", false),
                (UUID(), "Bodyweight Squats", false),
                (UUID(), "High Knees", false),
                (UUID(), "Shoulder Rolls", false)
            ]
            return
        }
        
        Logger.info("Loading \(template.exerciseIds.count) exercises from template '\(template.name)'")
        
        // Fetch exercises from database by IDs
        var loadedExercises: [(id: UUID, name: String, isCompleted: Bool)] = []
        
        for exerciseId in template.exerciseIds {
            let descriptor = FetchDescriptor<Exercise>(
                predicate: #Predicate<Exercise> { $0.id == exerciseId }
            )
            
            if let exercise = try? modelContext.fetch(descriptor).first {
                // Use localized name based on current locale
                let exerciseName: String = {
                    let languageCode = Locale.current.language.languageCode?.identifier ?? "en"
                    switch languageCode {
                    case "tr":
                        return exercise.nameTR.isEmpty ? exercise.nameEN : exercise.nameTR
                    default:
                        return exercise.nameEN
                    }
                }()
                
                loadedExercises.append((exerciseId, exerciseName, false))
                Logger.info("✅ Loaded exercise: \(exerciseName)")
            } else {
                Logger.warning("⚠️ Could not find exercise with ID: \(exerciseId)")
                // Add placeholder with localized name
                let unknownExerciseName = Locale.current.language.languageCode?.identifier == "tr" ? "Bilinmeyen Egzersiz" : "Unknown Exercise"
                loadedExercises.append((exerciseId, unknownExerciseName, false))
            }
        }
        
        exercises = loadedExercises
        Logger.success("Loaded \(exercises.count) exercises for warmup session '\(template.localizedName)'")
    }
    
    private func toggleExerciseCompletion(at index: Int) {
        guard index < exercises.count else { return }
        exercises[index].isCompleted.toggle()
        
        // Update session
        if let session = currentSession {
            if exercises[index].isCompleted {
                session.markExerciseCompleted(exerciseId: exercises[index].id)
            } else {
                session.markExerciseIncomplete(exerciseId: exercises[index].id)
            }
        }
        
        // Auto-complete if all exercises done
        if allExercisesCompleted && timerViewModel.isRunning {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                finishSession()
            }
        }
    }
    
    private func finishSession() {
        timerViewModel.stopTimer()
        showingCompletion = true
    }
    
    private func completeSession() {
        currentSession?.completeSession(
            feeling: selectedFeeling?.rawValue,
            notes: sessionNotes.isEmpty ? nil : sessionNotes
        )
        
        try? modelContext.save()
        dismiss()
    }
    
    private func handleCancel() {
        if timerViewModel.isRunning || timerViewModel.isPaused {
            currentSession?.cancelSession()
        }
        dismiss()
    }
}

#Preview {
    let sampleTemplate = WarmUpTemplate(
        name: "Quick 5-Min",
        nameEN: "Quick 5-Min",
        nameTR: "Hızlı 5 Dakika",
        description: "Perfect quick warm-up for any workout",
        category: "general",
        estimatedDuration: 300
    )
    
    return WarmUpSessionView(template: sampleTemplate)
}