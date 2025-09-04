import SwiftUI
import SwiftData

// MARK: - Lift Session View
struct LiftSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var unitSettings: UnitSettings
    @EnvironmentObject private var healthKitService: HealthKitService
    @Query private var user: [User]
    
    let workout: LiftWorkout
    let programExecution: ProgramExecution?
    @State private var session: LiftSession?
    @State private var expandedExerciseId: UUID?
    @State private var showingCompletion = false
    @State private var showingCancelAlert = false
    @State private var showingExerciseSelection = false
    @State private var previousSessions: [LiftSession] = []
    @State private var isEditingOrder = false
    @State private var showingNotes = false
    @State private var sessionNotes = ""
    @State private var showingProgramCelebration = false
    
    private var currentUser: User? {
        user.first
    }
    
    var body: some View {
        NavigationStack {
            if let session = session {
                mainContentView(session: session)
            } else {
                ProgressView("Starting workout...")
                    .onAppear {
                        startSession()
                    }
            }
        }
    }
    
    @ViewBuilder
    private func mainContentView(session: LiftSession) -> some View {
        ScrollView {
            VStack(spacing: theme.spacing.l) {
                sessionHeaderView
                progressOverview
                exerciseListView
                actionButtons
            }
            .padding(.bottom, 100)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(CommonKeys.Onboarding.Common.cancel.localized) {
                    showingCancelAlert = true
                }
            }
            
            ToolbarItem(placement: .principal) {
                HStack(spacing: theme.spacing.s) {
                    Text(workout.localizedName)
                        .font(theme.typography.headline)
                        .fontWeight(.semibold)
                    
                    if session.exerciseResults.count > 1 {
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                isEditingOrder.toggle()
                                if isEditingOrder {
                                    // Collapse all when entering edit mode
                                    expandedExerciseId = nil
                                }
                            }
                        }) {
                            Image(systemName: isEditingOrder ? "checkmark" : "arrow.up.arrow.down")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(theme.colors.accent)
                        }
                    }
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(CommonKeys.Onboarding.Common.finish.localized) {
                    completeSession()
                }
                .fontWeight(.semibold)
                .disabled(session.exerciseResults.allSatisfy { $0.completedSets == 0 })
            }
        }
        .alert(TrainingKeys.Alerts.cancelWorkout.localized, isPresented: $showingCancelAlert) {
            Button(TrainingKeys.Alerts.keepTraining.localized, role: .cancel) { }
            Button(TrainingKeys.Alerts.cancelWorkoutAction.localized, role: .destructive) {
                cancelSession()
            }
        } message: {
            Text(TrainingKeys.Alerts.cancelWorkoutMessage.localized)
        }
        .sheet(isPresented: $showingCompletion) {
            LiftSessionCompletionView(
                session: session,
                onCompletion: {
                    handleWorkoutCompletion()
                }
            )
        }
        .sheet(isPresented: $showingProgramCelebration) {
            ProgramCompletionCelebrationView(
                programName: workout.program?.localizedName ?? "Program",
                onDismiss: { showingProgramCelebration = false }
            )
        }
        .sheet(isPresented: $showingExerciseSelection) {
            ExerciseSelectionView { exercise in
                addExerciseToSession(exercise)
            }
        }
        .sheet(isPresented: $showingNotes) {
            WorkoutNotesSheet(
                notes: $sessionNotes,
                onSave: { notes in
                    session.notes = notes.isEmpty ? nil : notes
                    try? modelContext.save()
                    showingNotes = false
                }
            )
        }
    }
    
    private var exerciseListView: some View {
        VStack(spacing: theme.spacing.m) {
            if let session = session {
                ForEach(session.exerciseResults.indices, id: \.self) { index in
                    LiftAccordionCard(
                        exerciseResult: Binding(
                            get: { session.exerciseResults[index] },
                            set: { newValue in
                                self.session?.exerciseResults[index] = newValue
                            }
                        ),
                        isExpanded: !isEditingOrder && expandedExerciseId == session.exerciseResults[index].id,
                        previousSets: getPreviousSets(for: session.exerciseResults[index].exercise),
                        onToggle: {
                            if !isEditingOrder {
                                toggleExpansion(session.exerciseResults[index].id)
                            }
                        },
                        onSetUpdate: {
                            updateSessionTotals()
                        },
                        onExerciseCompleted: { exerciseResult in
                            handleSetCompletion(for: exerciseResult)
                        },
                        isEditMode: isEditingOrder
                    )
                    .deleteDisabled(!isEditingOrder)
                }
                .onMove(perform: isEditingOrder ? moveExercises : nil)
            }
        }
    }
    
    // MARK: - Session Header
    private var sessionHeaderView: some View {
        VStack(alignment: .leading, spacing: theme.spacing.s) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Session \(workout.sessions.count + 1)")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                    
                    if let program = workout.program {
                        Text(program.localizedName)
                            .font(theme.typography.body)
                            .foregroundColor(theme.colors.textPrimary)
                    }
                }
                
                Spacer()
                
                if let lastPerformed = workout.lastPerformed {
                    VStack(alignment: .trailing) {
                        Text("Last workout")
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textSecondary)
                        Text(lastPerformed, formatter: RelativeDateTimeFormatter())
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textPrimary)
                    }
                }
            }
        }
        .padding()
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.m)
        .padding(.horizontal)
    }
    
    // MARK: - Progress Overview
    private var progressOverview: some View {
        HStack(spacing: theme.spacing.m) {
            LiftStatCard(
                icon: "scalemass.fill",
                title: "Volume",
                value: UnitsFormatter.formatVolume(kg: session?.totalVolume ?? 0, system: unitSettings.unitSystem),
                color: theme.colors.accent
            )
            
            LiftStatCard(
                icon: "number",
                title: "Sets",
                value: "\(session?.totalSets ?? 0)",
                color: theme.colors.success
            )
            
            LiftStatCard(
                icon: "repeat",
                title: "Reps",
                value: "\(session?.totalReps ?? 0)",
                color: theme.colors.warning
            )
        }
        .padding(.horizontal)
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: theme.spacing.m) {
            // Add Exercise Button
            Button(action: {
                showingExerciseSelection = true
            }) {
                HStack {
                    Image(systemName: "plus.circle")
                    Text("Add Exercise")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(theme.colors.backgroundSecondary)
                .foregroundColor(theme.colors.textPrimary)
                .cornerRadius(theme.radius.m)
            }
            
            // Notes Button
            Button(action: {
                sessionNotes = session?.notes ?? ""
                showingNotes = true
            }) {
                HStack {
                    Image(systemName: "note.text")
                    Text("Workout Notes")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(theme.colors.backgroundSecondary)
                .foregroundColor(theme.colors.textPrimary)
                .cornerRadius(theme.radius.m)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Helper Methods
    private func startSession() {
        guard let user = currentUser else { return }
        session = workout.startSession(for: user, programExecution: programExecution)
        
        // Auto-expand first exercise
        if let firstExercise = session?.exerciseResults.first {
            expandedExerciseId = firstExercise.id
        }
        
        // Load previous sessions for comparison
        loadPreviousSessions()
    }
    
    private func toggleExpansion(_ id: UUID) {
        withAnimation(.spring(response: 0.3)) {
            if expandedExerciseId == id {
                expandedExerciseId = nil
            } else {
                expandedExerciseId = id
            }
        }
    }
    
    private func updateSessionTotals() {
        session?.calculateTotals()
        try? modelContext.save()
    }
    
    private func handleSetCompletion(for exerciseResult: LiftExerciseResult) {
        // Check if exercise just became completed
        let isCompleted = exerciseResult.sets.allSatisfy { $0.isCompleted }
        
        if isCompleted && expandedExerciseId == exerciseResult.id {
            // Auto-collapse completed exercise with animation
            withAnimation(.easeInOut(duration: 0.3)) {
                expandedExerciseId = nil
            }
            
            // Auto-expand next incomplete exercise
            if let session = session,
               let nextIncomplete = session.exerciseResults.first(where: { 
                   !$0.sets.allSatisfy { $0.isCompleted } 
               }) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        expandedExerciseId = nextIncomplete.id
                    }
                }
            }
        }
    }
    
    private func moveExercises(from sourceIndices: IndexSet, to destination: Int) {
        session?.moveExercise(from: sourceIndices, to: destination)
        try? modelContext.save()
    }
    
    private func completeSession() {
        session?.complete()
        try? modelContext.save()
        
        // Check for PRs and log activities
        if let completedSession = session, let user = fetchCurrentUser() {
            ActivityLoggerService.shared.setModelContext(modelContext)
            
            // Log workout completion
            ActivityLoggerService.shared.logWorkoutCompleted(
                workoutType: workout.name,
                duration: completedSession.duration,
                volume: completedSession.totalVolume,
                sets: completedSession.totalSets,
                reps: completedSession.totalReps,
                user: user
            )
            
            // Check for PRs in completed exercises
            checkAndLogPersonalRecords(session: completedSession, user: user)
            
            // Save to HealthKit
            Task {
                let estimatedCalories = HealthCalculator.estimateStrengthTrainingCalories(
                    duration: completedSession.duration,
                    bodyWeight: user.currentWeight,
                    intensity: .moderate
                )
                
                let success = await healthKitService.saveLiftWorkout(
                    duration: completedSession.duration,
                    caloriesBurned: estimatedCalories,
                    startDate: completedSession.startDate,
                    endDate: completedSession.endDate ?? Date(),
                    totalVolume: completedSession.totalVolume
                )
                
                if success {
                    Logger.info("Lift workout successfully synced to HealthKit")
                }
            }
        }
        
        showingCompletion = true
    }
    
    private func checkAndLogPersonalRecords(session: LiftSession, user: User) {
        for exerciseResult in session.exerciseResults {
            let exercise = exerciseResult.exercise
            
            // Calculate max weight for this exercise in this session
            let maxWeightThisSession = exerciseResult.sets
                .filter { $0.isCompleted && $0.reps > 0 }
                .compactMap { $0.weight }
                .max() ?? 0
            
            if maxWeightThisSession > 0 {
                // Get previous best for this exercise
                let previousBest = getPreviousBest(for: exercise, user: user)
                
                // Check if this is a PR (personal record)
                if maxWeightThisSession > previousBest {
                    ActivityLoggerService.shared.logPersonalRecord(
                        exerciseName: exercise.exerciseName,
                        newValue: maxWeightThisSession,
                        previousValue: previousBest > 0 ? previousBest : nil,
                        unit: "kg",
                        user: user
                    )
                }
            }
        }
    }
    
    private func getPreviousBest(for exercise: LiftExercise, user: User) -> Double {
        // Query previous sessions for this exercise
        let descriptor = FetchDescriptor<LiftSession>(
            predicate: #Predicate<LiftSession> { session in
                session.isCompleted
            },
            sortBy: [SortDescriptor(\LiftSession.startDate, order: .reverse)]
        )
        
        do {
            let previousSessions = try modelContext.fetch(descriptor)
            var maxWeight: Double = 0
            
            for session in previousSessions {
                for result in session.exerciseResults {
                    if result.exercise.exerciseName == exercise.exerciseName {
                        let sessionMax = result.sets
                            .filter { $0.isCompleted && $0.reps > 0 }
                            .compactMap { $0.weight }
                            .max() ?? 0
                        maxWeight = max(maxWeight, sessionMax)
                    }
                }
            }
            
            return maxWeight
        } catch {
            Logger.error("Error fetching previous sessions for PR check: \(error)")
            return 0
        }
    }
    
    private func cancelSession() {
        if let session = session {
            modelContext.delete(session)
            try? modelContext.save()
        }
        dismiss()
    }
    
    private func loadPreviousSessions() {
        // Get previous sessions for this workout
        previousSessions = workout.sessions
            .filter { $0.isCompleted }
            .sorted { $0.startDate > $1.startDate }
    }
    
    // Helper to get current user
    private func fetchCurrentUser() -> User? {
        let descriptor = FetchDescriptor<User>(sortBy: [SortDescriptor(\User.createdAt)])
        do {
            let users = try modelContext.fetch(descriptor)
            return users.first
        } catch {
            return nil
        }
    }
    
    // MARK: - Program Integration
    private func handleWorkoutCompletion() {
        // First, close the session view to return to dashboard
        dismiss()
        
        guard let execution = programExecution else {
            Logger.info("Workout completed without program context")
            return
        }
        
        // Mark current workout as completed in program
        execution.completeCurrentWorkout()
        
        do {
            try modelContext.save()
            Logger.success("Program advanced: Week \(execution.currentWeek), Day \(execution.currentDay)")
            
            // Check if program is completed
            if execution.isCompleted {
                Logger.success("Program completed! \(execution.program.localizedName)")
                showingProgramCelebration = true
                HapticManager.shared.notification(.success)
            }
            
        } catch {
            Logger.error("Failed to advance program: \(error)")
        }
    }
    
    private func getPreviousSets(for exercise: LiftExercise) -> [SetData]? {
        // Find the most recent completed session with this exercise
        for session in previousSessions {
            if let result = session.exerciseResults.first(where: { $0.exercise.exerciseId == exercise.exerciseId }) {
                return result.sets.filter { $0.isCompleted }
            }
        }
        return nil
    }
    
    private func addExerciseToSession(_ exercise: Exercise) {
        guard let session = session else { return }
        
        // Create a LiftExercise from the selected Exercise
        let liftExercise = LiftExercise(
            exerciseId: exercise.id,
            exerciseName: exercise.nameEN,
            orderIndex: session.exerciseResults.count,
            targetSets: 3,
            targetReps: 10
        )
        
        // Add to workout if not already there
        if !workout.exercises.contains(where: { $0.exerciseId == exercise.id }) {
            workout.addExercise(liftExercise)
        }
        
        // Create exercise result for the session
        let exerciseResult = LiftExerciseResult(exercise: liftExercise)
        
        // Add 1 initial set with smart defaults
        let setData = SetData(
            setNumber: 1,
            weight: nil, // Will be populated by previous workout data if available
            reps: 10,
            isWarmup: false,
            isCompleted: false
        )
        exerciseResult.sets.append(setData)
        
        session.addExerciseResult(exerciseResult)
        
        // Save changes first to ensure model consistency
        do {
            try modelContext.save()
            
            // Then update UI state
            DispatchQueue.main.async {
                expandedExerciseId = exerciseResult.id
            }
        } catch {
            print("❌ Failed to save exercise: \(error)")
        }
    }
}

// MARK: - Workout Notes Sheet
struct WorkoutNotesSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Binding var notes: String
    let onSave: (String) -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: theme.spacing.m) {
                // Header
                VStack(alignment: .leading, spacing: theme.spacing.s) {
                    Text("Workout Notes")
                        .font(theme.typography.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Text("Add notes about your workout, form cues, or how you're feeling")
                        .font(theme.typography.body)
                        .foregroundColor(theme.colors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                // Text Editor
                TextEditor(text: $notes)
                    .font(theme.typography.body)
                    .padding(theme.spacing.m)
                    .background(theme.colors.backgroundSecondary)
                    .cornerRadius(theme.radius.m)
                    .frame(minHeight: 200)
                    .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle(CommonKeys.Navigation.notes.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(notes)
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Lift Stat Card Component
struct LiftStatCard: View {
    @Environment(\.theme) private var theme
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: theme.spacing.s) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(theme.typography.headline)
                .fontWeight(.bold)
                .foregroundColor(theme.colors.textPrimary)
            
            Text(title)
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.m)
    }
}

// MARK: - Session Completion View
struct LiftSessionCompletionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @EnvironmentObject private var unitSettings: UnitSettings
    let session: LiftSession?
    let onCompletion: (() -> Void)?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: theme.spacing.xl) {
                // Success Icon
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(theme.colors.success)
                
                Text("Workout Complete!")
                    .font(theme.typography.title2)
                    .fontWeight(.bold)
                
                // Stats Summary
                if let session = session {
                    VStack(spacing: theme.spacing.m) {
                        LiftStatRow(label: "Duration", value: session.formattedDuration)
                        LiftStatRow(label: "Total Volume", value: UnitsFormatter.formatVolume(kg: session.totalVolume, system: unitSettings.unitSystem))
                        LiftStatRow(label: "Sets Completed", value: "\(session.totalSets)")
                        LiftStatRow(label: "Total Reps", value: "\(session.totalReps)")
                        
                        if !session.prsHit.isEmpty {
                            VStack(alignment: .leading, spacing: theme.spacing.s) {
                                Text("Personal Records!")
                                    .font(theme.typography.headline)
                                    .foregroundColor(theme.colors.warning)
                                
                                ForEach(session.prsHit, id: \.self) { pr in
                                    HStack {
                                        Image(systemName: "trophy.fill")
                                            .foregroundColor(theme.colors.warning)
                                        Text(pr)
                                            .font(theme.typography.body)
                                    }
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(theme.colors.warning.opacity(0.1))
                            .cornerRadius(theme.radius.m)
                        }
                    }
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: theme.spacing.m) {
                    Button(action: {
                        // Share workout
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Workout")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(theme.colors.backgroundSecondary)
                        .foregroundColor(theme.colors.textPrimary)
                        .cornerRadius(theme.radius.m)
                    }
                    
                    Button(action: {
                        onCompletion?()
                        dismiss()
                    }) {
                        Text("Done")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(theme.colors.accent)
                            .foregroundColor(.white)
                            .cornerRadius(theme.radius.m)
                    }
                }
            }
            .padding()
            .navigationTitle(CommonKeys.Navigation.summary.localized)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Lift Stat Row
struct LiftStatRow: View {
    @Environment(\.theme) private var theme
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(theme.typography.body)
                .foregroundColor(theme.colors.textSecondary)
            Spacer()
            Text(value)
                .font(theme.typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(theme.colors.textPrimary)
        }
        .padding()
        .background(theme.colors.backgroundSecondary)
        .cornerRadius(theme.radius.s)
    }
}

