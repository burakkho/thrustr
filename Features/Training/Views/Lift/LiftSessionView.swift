import SwiftUI
import SwiftData

// Import our ViewModels and DTOs
// Note: These files need to be added to Xcode project
class LiftSessionViewModel: ObservableObject {
    // Temporary placeholder until files are added to Xcode project
    @Published var exercises: [ExerciseResultData] = []
    @Published var isLoading = false
    @Published var expandedExerciseId: UUID?
    @Published var isEditingOrder = false
    
    var hasExercises: Bool { !exercises.isEmpty }
    
    func loadSession(_ session: LiftSession, context: ModelContext) {
        // Placeholder implementation
    }
    
    func toggleExpansion(for exerciseId: UUID) {
        expandedExerciseId = expandedExerciseId == exerciseId ? nil : exerciseId
    }
    
    func toggleEditingOrder() {
        isEditingOrder.toggle()
        if isEditingOrder {
            expandedExerciseId = nil
        }
    }
    
    func addSet(to exerciseId: UUID) {
        // Placeholder
    }
    
    func completeSet(exerciseId: UUID, setIndex: Int) {
        // Placeholder
    }
    
    func moveExercises(from source: IndexSet, to destination: Int) {
        // Placeholder
    }
}

struct ExerciseResultData: Identifiable, Sendable {
    let id: UUID = UUID()
    let exerciseId: String = ""
    let exerciseName: String = ""
    let targetSets: Int = 0
    let targetReps: Int = 0
    let targetWeight: Double?
    var sets: [SetData] = []
    var notes: String?
    var isPersonalRecord: Bool = false
    var isCompleted: Bool = false
    
    var completedSets: Int { 0 }
    var totalVolume: Double { 0 }
    var maxWeight: Double? { nil }
    var totalReps: Int { 0 }
    var completionPercentage: Double { 0 }
}

struct SimpleExerciseCardRow: View {
    @Binding var exerciseData: ExerciseResultData
    let isExpanded: Bool
    let isEditMode: Bool
    
    let onToggle: () -> Void
    let onAddSet: () -> Void
    let onCompleteSet: (Int) -> Void
    
    var body: some View {
        VStack {
            Text("Exercise: \(exerciseData.exerciseName)")
            Text("Placeholder component")
        }
        .onTapGesture {
            onToggle()
        }
    }
}

// MARK: - Lift Session View
struct LiftSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(UnitSettings.self) private var unitSettings
    @Environment(HealthKitService.self) private var healthKitService
    @Query private var users: [User]
    
    let workout: LiftWorkout
    let programExecution: ProgramExecution?
    @StateObject private var viewModel = LiftSessionViewModel()
    @State private var session: LiftSession?
    @State private var showingCompletion = false
    @State private var showingCancelAlert = false
    @State private var showingExerciseSelection = false
    @State private var showingNotes = false
    @State private var sessionNotes = ""
    @State private var showingProgramCelebration = false
    @State private var saveWorkItem: DispatchWorkItem?
    @State private var previousSessions: [LiftSession] = []
    
    private var currentUser: User? {
        users.first
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
                    
                    if (session.exerciseResults?.count ?? 0) > 1 {
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                viewModel.toggleEditingOrder()
                            }
                        }) {
                            Image(systemName: viewModel.isEditingOrder ? "checkmark" : "arrow.up.arrow.down")
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
                .disabled(session.exerciseResults?.allSatisfy { $0.completedSets == 0 } ?? true)
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
            if let user = currentUser {
                LiftSessionSummaryView(
                    session: session,
                    user: user,
                    onDismiss: {
                        handleWorkoutCompletion()
                    }
                )
            }
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
            exerciseListContent
        }
    }
    
    @ViewBuilder
    private var exerciseListContent: some View {
        if viewModel.hasExercises {
            List {
                ForEach(Array(viewModel.exercises.enumerated()), id: \.element.id) { index, exerciseData in
                    SimpleExerciseCardRow(
                        exerciseData: Binding(
                            get: { viewModel.exercises[index] },
                            set: { viewModel.exercises[index] = $0 }
                        ),
                        isExpanded: viewModel.expandedExerciseId == exerciseData.id,
                        isEditMode: viewModel.isEditingOrder,
                        onToggle: {
                            viewModel.toggleExpansion(for: exerciseData.id)
                        },
                        onAddSet: {
                            viewModel.addSet(to: exerciseData.id)
                        },
                        onCompleteSet: { setIndex in
                            viewModel.completeSet(exerciseId: exerciseData.id, setIndex: setIndex)
                        }
                    )
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .deleteDisabled(!viewModel.isEditingOrder)
                }
                .onMove(perform: viewModel.isEditingOrder ? viewModel.moveExercises : nil)
            }
            .listStyle(PlainListStyle())
        } else {
            EmptyView()
        }
    }
    
    
    // MARK: - Session Header
    private var sessionHeaderView: some View {
        VStack(alignment: .leading, spacing: theme.spacing.s) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Session \((workout.sessions?.count ?? 0) + 1)")
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
        
        // Load session data into ViewModel
        if let session = session {
            viewModel.loadSession(session, context: modelContext)
            
            // Smart auto-expand: first incomplete exercise
            if let firstIncompleteData = viewModel.exercises.first(where: { !$0.isCompleted }) {
                viewModel.toggleExpansion(for: firstIncompleteData.id)
            } else if let firstExercise = viewModel.exercises.first {
                viewModel.toggleExpansion(for: firstExercise.id)
            }
        }
        
        // Load previous sessions for comparison
        loadPreviousSessions()
    }
    
    
    private func updateSessionTotals() {
        session?.calculateTotals()
        scheduleDebouncedSave()
    }
    
    private func scheduleDebouncedSave() {
        saveWorkItem?.cancel()
        
        saveWorkItem = DispatchWorkItem {
            try? modelContext.save()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: saveWorkItem!)
    }
    
    private func handleSetCompletion(for exerciseResult: LiftExerciseResult) {
        // Auto-expand logic now handled by ViewModel
        // The ViewModel automatically manages expansion state
    }
    
    // Exercise movement now handled by ViewModel
    
    
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
        for exerciseResult in session.exerciseResults ?? [] {
            guard let exercise = exerciseResult.exercise else { continue }
            
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
        // Optimized query: only fetch recent sessions with limit
        var descriptor = FetchDescriptor<LiftSession>(
            predicate: #Predicate<LiftSession> { session in
                session.isCompleted
            },
            sortBy: [SortDescriptor(\LiftSession.startDate, order: .reverse)]
        )
        
        // Limit to last 20 sessions for performance
        descriptor.fetchLimit = 20
        
        do {
            let recentSessions = try modelContext.fetch(descriptor)
            var maxWeight: Double = 0
            
            // Early exit optimization: stop when we find enough data
            for session in recentSessions {
                for result in session.exerciseResults ?? [] {
                    if result.exercise?.exerciseName == exercise.exerciseName {
                        let sessionMax = result.sets
                            .filter { $0.isCompleted && $0.reps > 0 }
                            .compactMap { $0.weight }
                            .max() ?? 0
                        maxWeight = max(maxWeight, sessionMax)
                        
                        // Performance boost: if we found good data, no need to check all sessions
                        if maxWeight > 0 && recentSessions.count > 5 {
                            break
                        }
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
        previousSessions = workout.sessions?
            .filter { $0.isCompleted }
            .sorted { $0.startDate > $1.startDate } ?? []
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
                Logger.success("Program completed! \(execution.program?.localizedName ?? "Unknown")")
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
            if let result = session.exerciseResults?.first(where: { $0.exercise?.exerciseId == exercise.exerciseId }) {
                return result.sets.filter { $0.isCompleted }
            }
        }
        return nil
    }
    
    private func addExerciseToSession(_ exercise: Exercise) {
        guard let session = session else { return }
        
        // Check if exercise already exists in session
        if session.exerciseResults?.contains(where: { $0.exercise?.exerciseId == exercise.id }) == true {
            print("⚠️ Exercise already exists in session")
            return
        }
        
        // Create a LiftExercise from the selected Exercise
        let liftExercise = LiftExercise(
            exerciseId: exercise.id,
            exerciseName: exercise.nameEN,
            orderIndex: session.exerciseResults?.count ?? 0,
            targetSets: 3,
            targetReps: 10
        )
        
        // Add to workout if not already there
        if !(workout.exercises?.contains(where: { $0.exerciseId == exercise.id }) == true) {
            workout.addExercise(liftExercise)
        }
        
        // Create exercise result for the session
        let exerciseResult = LiftExerciseResult(exercise: liftExercise)
        
        // Add 1 initial set with smart defaults
        let setData = SetData(
            setNumber: 1,
            weight: getLastUsedWeight(for: exercise),
            reps: 10,
            isWarmup: false,
            isCompleted: false
        )
        exerciseResult.sets.append(setData)
        
        // Use safe add method
        session.safeAddExerciseResult(exerciseResult)
        
        // Save changes first to ensure model consistency
        do {
            try modelContext.save()
            
            // Reload ViewModel with updated session data
            viewModel.loadSession(session, context: modelContext)
            // Auto-expand the newly added exercise
            viewModel.toggleExpansion(for: exerciseResult.id)
        } catch {
            print("❌ Failed to save exercise: \(error)")
        }
    }
    
    // MARK: - Helper Methods for Exercise Setup
    
    private func getLastUsedWeight(for exercise: Exercise) -> Double? {
        // In a real implementation, this would query previous lift sessions
        // For now, return a reasonable default based on exercise type
        guard let oneRM = getOneRMForExercise(exercise) else { return nil }
        return oneRM * 0.7 // Start with 70% of 1RM as a reasonable working weight
    }
    
    private func getOneRMForExercise(_ exercise: Exercise) -> Double? {
        guard let user = currentUser else { return nil }
        
        let exerciseName = exercise.displayName.lowercased()
        if exerciseName.contains("bench") || exerciseName.contains("press") {
            return user.benchPressOneRM
        } else if exerciseName.contains("squat") {
            return user.squatOneRM
        } else if exerciseName.contains("deadlift") {
            return user.deadliftOneRM
        } else if exerciseName.contains("overhead") {
            return user.overheadPressOneRM
        } else if exerciseName.contains("pull") {
            return user.pullUpOneRM
        }
        
        return nil
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
struct LiftSessionSummaryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(UnitSettings.self) private var unitSettings
    @Environment(HealthKitService.self) private var healthKitService
    
    let session: LiftSession
    let user: User
    let onDismiss: (() -> Void)?
    
    init(session: LiftSession, user: User, onDismiss: (() -> Void)? = nil) {
        self.session = session
        self.user = user
        self.onDismiss = onDismiss
    }
    
    @State private var feeling: SessionFeeling = .good
    @State private var notes: String = ""
    @State private var showingShareSheet = false
    
    // Edit modals
    @State private var showingDurationEdit = false
    @State private var showingVolumeEdit = false
    @State private var showingSetsEdit = false
    @State private var showingRepsEdit = false
    
    // Edit values
    @State private var editHours: Int = 0
    @State private var editMinutes: Int = 0
    @State private var editSeconds: Int = 0
    @State private var editVolume: Double = 0.0
    @State private var editSets: Int = 0
    @State private var editReps: Int = 0
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: theme.spacing.l) {
                    // Success Header
                    successHeader
                    
                    // Main Stats
                    mainStatsSection
                    
                    // Exercise Results Summary
                    exerciseResultsSection
                    
                    // Personal Records (if any)
                    if !session.prsHit.isEmpty {
                        personalRecordsSection
                    }
                    
                    // Feeling Selection
                    feelingSection
                    
                    // Notes
                    notesSection
                    
                    // Action Buttons
                    actionButtons
                }
                .padding(theme.spacing.m)
            }
            .navigationTitle("Workout Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingShareSheet = true }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let shareText = createShareText() {
                LiftShareSheet(items: [shareText])
            }
        }
        .sheet(isPresented: $showingDurationEdit) {
            LiftDurationEditSheet(
                hours: $editHours,
                minutes: $editMinutes,
                seconds: $editSeconds,
                onSave: saveDurationEdit,
                onCancel: { showingDurationEdit = false }
            )
        }
    }
    
    // MARK: - Success Header
    private var successHeader: some View {
        VStack(spacing: theme.spacing.m) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(theme.colors.success)
                .symbolRenderingMode(.hierarchical)
            
            Text("Tebrikler!")
                .font(theme.typography.title2)
                .fontWeight(.bold)
                .foregroundColor(theme.colors.textPrimary)
            
            Text("Antrenmanı Tamamladın!")
                .font(theme.typography.body)
                .foregroundColor(theme.colors.textSecondary)
        }
        .padding(.vertical, theme.spacing.l)
    }
    
    // MARK: - Main Stats
    private var mainStatsSection: some View {
        VStack(spacing: theme.spacing.m) {
            HStack(spacing: theme.spacing.m) {
                LiftMainStatCard(
                    icon: "timer",
                    value: session.formattedDuration,
                    label: "Duration",
                    color: theme.colors.accent,
                    onEdit: { 
                        initializeDurationEdit()
                        showingDurationEdit = true 
                    }
                )
                
                LiftMainStatCard(
                    icon: "scalemass.fill",
                    value: UnitsFormatter.formatVolume(kg: session.totalVolume, system: unitSettings.unitSystem),
                    label: "Volume",
                    color: theme.colors.success,
                    onEdit: nil // Volume hesaplanır, edit edilmez
                )
            }
            
            HStack(spacing: theme.spacing.m) {
                LiftMainStatCard(
                    icon: "list.number",
                    value: "\(session.totalSets)",
                    label: "Sets",
                    color: theme.colors.warning,
                    onEdit: nil // Sets hesaplanır
                )
                
                LiftMainStatCard(
                    icon: "repeat",
                    value: "\(session.totalReps)",
                    label: "Reps",
                    color: theme.colors.error,
                    onEdit: nil // Reps hesaplanır
                )
            }
        }
    }
    
    // MARK: - Exercise Results
    private var exerciseResultsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            HStack {
                Image(systemName: "list.clipboard.fill")
                    .foregroundColor(theme.colors.accent)
                Text("Exercise Summary")
                    .font(theme.typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                Spacer()
            }
            
            VStack(spacing: theme.spacing.s) {
                ForEach(session.exerciseResults ?? []) { result in
                    ExerciseResultRow(result: result, unitSettings: unitSettings)
                }
            }
        }
        .cardStyle()
    }
    
    // MARK: - Personal Records
    private var personalRecordsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(theme.colors.warning)
                Text("Personal Records!")
                    .font(theme.typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.warning)
                Spacer()
            }
            
            VStack(spacing: theme.spacing.s) {
                ForEach(session.prsHit, id: \.self) { pr in
                    HStack {
                        Image(systemName: "trophy.fill")
                            .font(.caption)
                            .foregroundColor(theme.colors.warning)
                        Text(pr)
                            .font(theme.typography.body)
                            .foregroundColor(theme.colors.textPrimary)
                        Spacer()
                    }
                }
            }
        }
        .padding(theme.spacing.m)
        .background(theme.colors.warning.opacity(0.1))
        .cornerRadius(theme.radius.m)
    }
    
    // MARK: - Feeling Section
    private var feelingSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            Text("How do you feel?")
                .font(theme.typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(theme.colors.textPrimary)
            
            HStack(spacing: theme.spacing.s) {
                ForEach(SessionFeeling.allCases, id: \.self) { feelingOption in
                    Button(action: { feeling = feelingOption }) {
                        VStack(spacing: 4) {
                            Text(feelingOption.emoji)
                                .font(.title2)
                            Text(feelingOption.displayName)
                                .font(.caption2)
                                .fontWeight(feeling == feelingOption ? .semibold : .regular)
                        }
                        .foregroundColor(feeling == feelingOption ? .white : theme.colors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, theme.spacing.s)
                        .background(
                            RoundedRectangle(cornerRadius: theme.radius.s)
                                .fill(feeling == feelingOption ? theme.colors.accent : theme.colors.backgroundSecondary)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.s) {
            Text("Notes (Optional)")
                .font(theme.typography.body)
                .fontWeight(.medium)
                .foregroundColor(theme.colors.textPrimary)
            
            TextField("Add notes about your workout...", text: $notes, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(theme.spacing.m)
                .background(theme.colors.backgroundSecondary)
                .cornerRadius(theme.radius.m)
                .lineLimit(3...5)
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: theme.spacing.m) {
            Button(action: saveSession) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                    Text("Save Workout")
                        .font(theme.typography.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(theme.spacing.l)
                .background(theme.colors.accent)
                .cornerRadius(theme.radius.m)
            }
            
            Button(action: discardSession) {
                Text("Exit without saving")
                    .font(theme.typography.body)
                    .foregroundColor(theme.colors.textSecondary)
            }
        }
        .padding(.vertical, theme.spacing.l)
    }
    
    // MARK: - Helper Methods
    private func saveSession() {
        // Update session with feeling and notes - convert to Int for LiftSession
        switch feeling {
        case .exhausted: session.feeling = 1
        case .tired: session.feeling = 2
        case .okay: session.feeling = 3
        case .good: session.feeling = 4
        case .great: session.feeling = 5
        }
        session.notes = notes.isEmpty ? nil : notes
        
        // Mark as completed if not already
        if !session.isCompleted {
            session.endDate = Date()
            session.isCompleted = true
        }
        
        // Update user stats with final values
        user.addLiftSession(
            duration: session.duration,
            volume: session.totalVolume,
            sets: session.totalSets,
            reps: session.totalReps
        )
        
        do {
            try modelContext.save()
            
            // Save to HealthKit
            Task {
                let success = await healthKitService.saveLiftWorkout(
                    duration: session.duration,
                    startDate: session.startDate,
                    endDate: session.endDate ?? Date(),
                    totalVolume: session.totalVolume
                )
                
                if success {
                    Logger.info("Lift workout successfully synced to HealthKit")
                }
            }
            
            // Dismiss with callback
            if let onDismiss = onDismiss {
                onDismiss()
            } else {
                dismiss()
            }
        } catch {
            Logger.error("Failed to save lift session: \(error)")
        }
    }
    
    private func discardSession() {
        if let onDismiss = onDismiss {
            onDismiss()
        } else {
            dismiss()
        }
    }
    
    private func createShareText() -> String? {
        var text = "💪 Workout Completed!\n\n"
        text += "⏱️ Duration: \(session.formattedDuration)\n"
        text += "📊 Volume: \(UnitsFormatter.formatVolume(kg: session.totalVolume, system: unitSettings.unitSystem))\n"
        text += "🔢 Sets: \(session.totalSets)\n"
        text += "🔄 Reps: \(session.totalReps)\n"
        
        if !session.prsHit.isEmpty {
            text += "\n🏆 Personal Records:\n"
            for pr in session.prsHit {
                text += "• \(pr)\n"
            }
        }
        
        text += "\n#Thrustr #Lifting #Strength"
        
        return text
    }
    
    // MARK: - Edit Methods
    private func initializeDurationEdit() {
        let totalSeconds = Int(session.duration)
        editHours = totalSeconds / 3600
        editMinutes = (totalSeconds % 3600) / 60
        editSeconds = totalSeconds % 60
    }
    
    private func saveDurationEdit() {
        let newDuration = TimeInterval(editHours * 3600 + editMinutes * 60 + editSeconds)
        
        if newDuration != session.duration {
            // Duration is computed from startDate and endDate, so we adjust endDate
            let newEndDate = session.startDate.addingTimeInterval(newDuration)
            session.endDate = newEndDate
            // Note: Volume, sets, reps are calculated from exercise results
            // Duration edit doesn't affect those
        }
        
        showingDurationEdit = false
    }
    
}

// MARK: - Lift Main Stat Card
struct LiftMainStatCard: View {
    @Environment(\.theme) private var theme
    let icon: String
    let value: String
    let label: String
    let color: Color
    let onEdit: (() -> Void)?
    
    init(icon: String, value: String, label: String, color: Color, onEdit: (() -> Void)? = nil) {
        self.icon = icon
        self.value = value
        self.label = label
        self.color = color
        self.onEdit = onEdit
    }
    
    var body: some View {
        VStack(spacing: theme.spacing.s) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                if let onEdit = onEdit {
                    Spacer()
                    Button(action: onEdit) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title3)
                            .foregroundColor(theme.colors.accent)
                    }
                }
            }
            
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(theme.colors.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text(label)
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(theme.spacing.m)
        .background(theme.colors.backgroundSecondary)
        .cornerRadius(theme.radius.m)
    }
}

// MARK: - Exercise Result Row
struct ExerciseResultRow: View {
    @Environment(\.theme) private var theme
    let result: LiftExerciseResult
    let unitSettings: UnitSettings
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(result.exercise?.exerciseName ?? "Unknown Exercise")
                    .font(theme.typography.body)
                    .fontWeight(.medium)
                    .foregroundColor(theme.colors.textPrimary)
                
                Text("\(result.completedSets) sets • \(result.totalReps) reps")
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(UnitsFormatter.formatVolume(kg: result.totalVolume, system: unitSettings.unitSystem))
                    .font(theme.typography.body)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                
                if let maxWeight = result.maxWeight {
                    Text("Max: \(UnitsFormatter.formatWeight(kg: maxWeight, system: unitSettings.unitSystem))")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
        }
        .padding(.vertical, theme.spacing.xs)
    }
}

// MARK: - Duration Edit Sheet
struct LiftDurationEditSheet: View {
    @Environment(\.theme) private var theme
    @Binding var hours: Int
    @Binding var minutes: Int
    @Binding var seconds: Int
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: theme.spacing.l) {
                // Header
                VStack(spacing: theme.spacing.s) {
                    Image(systemName: "timer")
                        .font(.system(size: 40))
                        .foregroundColor(theme.colors.accent)
                    
                    Text("Edit Duration")
                        .font(theme.typography.title2)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Text("Adjust your workout duration")
                        .font(theme.typography.body)
                        .foregroundColor(theme.colors.textSecondary)
                }
                .padding(.top, theme.spacing.l)
                
                // Time Picker
                VStack(spacing: theme.spacing.m) {
                    Text("Duration")
                        .font(theme.typography.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    HStack(spacing: theme.spacing.m) {
                        // Hours
                        VStack(spacing: theme.spacing.xs) {
                            Text("Hour")
                                .font(theme.typography.caption)
                                .foregroundColor(theme.colors.textSecondary)
                            
                            Picker("Hours", selection: $hours) {
                                ForEach(0..<24, id: \.self) { hour in
                                    Text("\(hour)")
                                        .tag(hour)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 60, height: 120)
                        }
                        
                        Text(":")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(theme.colors.textPrimary)
                        
                        // Minutes
                        VStack(spacing: theme.spacing.xs) {
                            Text("Min")
                                .font(theme.typography.caption)
                                .foregroundColor(theme.colors.textSecondary)
                            
                            Picker("Minutes", selection: $minutes) {
                                ForEach(0..<60, id: \.self) { minute in
                                    Text(String(format: "%02d", minute))
                                        .tag(minute)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 60, height: 120)
                        }
                        
                        Text(":")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(theme.colors.textPrimary)
                        
                        // Seconds
                        VStack(spacing: theme.spacing.xs) {
                            Text("Sec")
                                .font(theme.typography.caption)
                                .foregroundColor(theme.colors.textSecondary)
                            
                            Picker("Seconds", selection: $seconds) {
                                ForEach(0..<60, id: \.self) { second in
                                    Text(String(format: "%02d", second))
                                        .tag(second)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 60, height: 120)
                        }
                    }
                }
                .cardStyle()
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: theme.spacing.m) {
                    Button(action: onSave) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                            Text("Save")
                                .font(theme.typography.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(theme.spacing.l)
                        .background(theme.colors.accent)
                        .cornerRadius(theme.radius.m)
                    }
                    
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(theme.typography.body)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }
            }
            .padding(theme.spacing.m)
            .navigationTitle("Edit Duration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel", action: onCancel)
                }
            }
        }
    }
}

// MARK: - Share Sheet
struct LiftShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
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

