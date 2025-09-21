import Foundation
import SwiftData

// Explicit import to resolve SessionFeeling ambiguity
// SessionFeeling is in Shared/Models, referring to the shared enum

// MARK: - Lift Session View Model
@MainActor
@Observable
final class LiftSessionViewModel {
    // MARK: - Published Properties
    var exercises: [ExerciseResultData] = []
    var isLoading = false
    var expandedExerciseId: UUID?
    var isEditingOrder = false
    var errorMessage: String?
    var successMessage: String?

    // Session state
    var currentSession: LiftSession?
    var currentUser: User?
    var programExecution: ProgramExecution?
    var isSessionReady: Bool { currentSession != nil && currentUser != nil }

    // Progress tracking
    var sessionProgress: SessionProgressData?

    // MARK: - Private Properties
    private var modelContext: ModelContext?

    // MARK: - Services - Using new service layer
    private let liftSessionService = LiftSessionService.self
    private let programExecutionService = ProgramExecutionService.self

    // MARK: - Initialization
    init() {}

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadCurrentUser()
    }

    /// Load current user from database
    private func loadCurrentUser() {
        guard let modelContext = modelContext else { return }

        let descriptor = FetchDescriptor<User>()
        do {
            let users = try modelContext.fetch(descriptor)
            currentUser = users.first
        } catch {
            Logger.error("Failed to load current user: \(error)")
            errorMessage = "Failed to load user profile"
        }
    }
    
    // MARK: - Session Management

    /// Starts a workout session with current user
    func startWorkoutSession(
        workout: LiftWorkout,
        programExecution: ProgramExecution? = nil
    ) async {
        guard let user = currentUser else {
            errorMessage = "No user profile found"
            return
        }

        await createSession(
            workout: workout,
            user: user,
            programExecution: programExecution
        )

        // Auto-expand first incomplete exercise for better UX
        await MainActor.run {
            expandFirstIncompleteExercise()
        }
    }

    /// Creates a new session using the service layer
    func createSession(
        workout: LiftWorkout,
        user: User,
        programExecution: ProgramExecution? = nil
    ) async {
        guard let modelContext = modelContext else {
            errorMessage = "Database context not available"
            return
        }

        isLoading = true
        defer { isLoading = false }

        let result = await Task {
            return await liftSessionService.createSession(
                workout: workout,
                user: user,
                programExecution: programExecution,
                modelContext: modelContext
            )
        }.value

        switch result {
        case .success(let session):
            loadSession(session)
            currentSession = session
            currentUser = user
            self.programExecution = programExecution
            successMessage = "Session created successfully"
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    /// Load exercises from SwiftData session into DTO format
    func loadSession(_ session: LiftSession) {
        self.currentSession = session

        isLoading = true
        defer { isLoading = false }

        // Convert SwiftData models to DTOs
        exercises = session.exerciseResults?.compactMap { exerciseResult -> ExerciseResultData? in
            ExerciseResultData(from: exerciseResult)
        } ?? []

        // Update progress tracking
        updateSessionProgress()

        Logger.info("Loaded \(exercises.count) exercises for session")
    }
    
    /// Updates exercise using DTO pattern
    func updateExercise(_ exerciseData: ExerciseResultData) {
        // Update DTO in local state
        if let index = exercises.firstIndex(where: { $0.id == exerciseData.id }) {
            exercises[index] = exerciseData
        }

        // Sync to SwiftData model
        syncExerciseToModel(exerciseData)

        // Update progress
        updateSessionProgress()
    }
    
    /// Add new set to exercise using service layer
    func addSet(to exerciseId: UUID) {
        guard let exerciseIndex = exercises.firstIndex(where: { $0.id == exerciseId }),
              let session = currentSession,
              let _ = session.exerciseResults?.first(where: { $0.id == exerciseId }),
              let _ = modelContext else {
            errorMessage = "Failed to add set - session context not available"
            return
        }

        // Add set to DTO
        exercises[exerciseIndex].addNewSet()

        // Sync to model and save
        syncExerciseToModel(exercises[exerciseIndex])
        updateSessionProgress()
    }
    
    /// Complete a set using service layer
    func completeSet(exerciseId: UUID, setIndex: Int) {
        guard let exerciseIndex = exercises.firstIndex(where: { $0.id == exerciseId }),
              let session = currentSession,
              let exerciseResult = session.exerciseResults?.first(where: { $0.id == exerciseId }),
              let modelContext = modelContext else {
            errorMessage = "Failed to complete set - session context not available"
            return
        }

        // Use service to complete set
        let result = liftSessionService.completeSet(
            exerciseResult: exerciseResult,
            setIndex: setIndex,
            modelContext: modelContext
        )

        switch result {
        case .success():
            // Update DTO to reflect changes
            exercises[exerciseIndex].completeSet(at: setIndex)
            updateSessionProgress()

        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
    
    /// Toggle exercise expansion
    func toggleExpansion(for exerciseId: UUID) {
        expandedExerciseId = expandedExerciseId == exerciseId ? nil : exerciseId
    }
    
    /// Start/stop editing order
    func toggleEditingOrder() {
        isEditingOrder.toggle()
        if isEditingOrder {
            expandedExerciseId = nil // Collapse all when editing
        }
    }
    
    /// Move exercises (for reordering)
    func moveExercises(from source: IndexSet, to destination: Int) {
        exercises.move(fromOffsets: source, toOffset: destination)
        
        // Update order in SwiftData
        updateExerciseOrder()
    }
    
    /// Calculate session totals
    func calculateSessionTotals() -> (volume: Double, sets: Int, reps: Int) {
        let volume = exercises.reduce(0) { $0 + $1.totalVolume }
        let sets = exercises.reduce(0) { $0 + $1.completedSets }
        let reps = exercises.reduce(0) { $0 + $1.totalReps }

        return (volume: volume, sets: sets, reps: reps)
    }

    /// Computed property for session totals
    var sessionTotals: (volume: Double, sets: Int, reps: Int) {
        return calculateSessionTotals()
    }
    
    /// Get previous sets for comparison using service layer
    func getPreviousSets(for exerciseId: String) -> [SetData]? {
        guard let user = currentUser,
              let modelContext = modelContext else { return nil }

        return liftSessionService.getPreviousPerformance(
            for: exerciseId,
            user: user,
            modelContext: modelContext
        )
    }

    /// Complete session using service layer
    func completeSession() async {
        guard let session = currentSession,
              let user = currentUser,
              let modelContext = modelContext else {
            errorMessage = "Session context not available"
            return
        }

        isLoading = true
        defer { isLoading = false }

        // Use service to complete session
        let result = await liftSessionService.completeSession(
            session,
            user: user,
            modelContext: modelContext
        )

        switch result {
        case .success():
            successMessage = "Workout completed successfully!"

            // Handle program advancement if needed
            if let programExecution = programExecution {
                await advanceProgram(programExecution)
            }

        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    /// Advance program execution after session completion
    private func advanceProgram(_ execution: ProgramExecution) async {
        guard let modelContext = modelContext else { return }

        let result = await programExecutionService.advanceProgram(
            execution,
            modelContext: modelContext
        )

        switch result {
        case .success(let advancement):
            switch advancement {
            case .dayAdvanced(let day):
                successMessage = "Advanced to Day \(day)"
            case .weekAdvanced(let week):
                successMessage = "🎉 Week \(week - 1) completed! Starting Week \(week)"
            case .programCompleted:
                successMessage = "🏆 Program completed! Congratulations!"
            }

        case .failure(let error):
            errorMessage = "Failed to advance program: \(error.localizedDescription)"
        }
    }
    /// Add exercise to current session
    func addExercise(_ exercise: Exercise) {
        guard let session = currentSession,
              let modelContext = modelContext else {
            errorMessage = "Session context not available"
            return
        }

        let result = liftSessionService.addExercise(
            exercise,
            to: session,
            modelContext: modelContext
        )

        switch result {
        case .success(let exerciseResult):
            // Add to DTO array
            let exerciseData = ExerciseResultData(from: exerciseResult)
            exercises.append(exerciseData)
            updateSessionProgress()
            successMessage = "Exercise added successfully"

        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    /// Clear error and success states
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
    
    // MARK: - Progress Tracking

    /// Updates session progress data
    private func updateSessionProgress() {
        let totals = calculateSessionTotals()
        let completedExercises = exercises.filter { $0.isCompleted }.count
        let progressPercentage = exercises.isEmpty ? 0 : Double(completedExercises) / Double(exercises.count)

        sessionProgress = SessionProgressData(
            totalVolume: totals.volume,
            totalSets: totals.sets,
            totalReps: totals.reps,
            completedExercises: completedExercises,
            totalExercises: exercises.count,
            progressPercentage: progressPercentage
        )
    }

    // MARK: - Private Methods

    /// Sync DTO changes back to SwiftData model
    private func syncExerciseToModel(_ exerciseData: ExerciseResultData) {
        guard let session = currentSession,
              let exerciseResult = session.exerciseResults?.first(where: { $0.id == exerciseData.id }) else {
            Logger.warning("Could not find exercise result to sync")
            return
        }

        exerciseData.updateModel(exerciseResult)

        do {
            try modelContext?.save()
            Logger.info("Successfully synced exercise \(exerciseData.exerciseName)")
        } catch {
            Logger.error("Failed to sync exercise: \(error)")
            errorMessage = "Failed to save changes"
        }
    }
    
    /// Update exercise order in SwiftData
    private func updateExerciseOrder() {
        guard let session = currentSession else { return }

        for (index, exerciseData) in exercises.enumerated() {
            if let exerciseResult = session.exerciseResults?.first(where: { $0.id == exerciseData.id }) {
                exerciseResult.exercise?.orderIndex = index
            }
        }

        do {
            try modelContext?.save()
            Logger.info("Updated exercise order")
        } catch {
            Logger.error("Failed to update exercise order: \(error)")
            errorMessage = "Failed to update exercise order"
        }
    }
}

// MARK: - Helper Extensions
extension LiftSessionViewModel {
    var hasExercises: Bool {
        !exercises.isEmpty
    }

    var completedExercisesCount: Int {
        exercises.filter { $0.isCompleted }.count
    }

    var totalExercisesCount: Int {
        exercises.count
    }

    var sessionCompletionPercentage: Double {
        guard totalExercisesCount > 0 else { return 0 }
        return Double(completedExercisesCount) / Double(totalExercisesCount)
    }

    var canCompleteSession: Bool {
        hasExercises && sessionCompletionPercentage >= 0.5 // At least 50% exercises completed
    }

    var isSessionInProgress: Bool {
        guard let session = currentSession else { return false }
        return !session.isCompleted
    }

    // MARK: - Session Completion & Save

    /**
     * Saves the session with feeling, notes, and handles HealthKit integration
     */
    func saveSession(
        feeling: SessionFeeling,
        notes: String,
        onCompletion: @escaping () -> Void
    ) async {
        guard let session = currentSession,
              let user = currentUser,
              let modelContext = modelContext else {
            errorMessage = "Session or context not available"
            return
        }

        isLoading = true
        defer { isLoading = false }

        // Convert feeling to Int for LiftSession
        session.feeling = feelingToInt(feeling)
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
            let success = await saveToHealthKit(session: session)

            if success {
                Logger.info("Lift workout successfully synced to HealthKit")
            }

            successMessage = "Session saved successfully!"
            await MainActor.run {
                onCompletion()
            }

        } catch {
            Logger.error("Failed to save lift session: \(error)")
            errorMessage = "Failed to save session: \(error.localizedDescription)"
        }
    }

    /**
     * Auto-expands first incomplete exercise for better UX
     */
    func expandFirstIncompleteExercise() {
        if let firstIncompleteData = exercises.first(where: { !$0.isCompleted }) {
            toggleExpansion(for: firstIncompleteData.id)
        } else if let firstExercise = exercises.first {
            toggleExpansion(for: firstExercise.id)
        }
    }

    // MARK: - Private Helper Methods

    private func feelingToInt(_ feeling: SessionFeeling) -> Int {
        switch feeling {
        case .exhausted: return 1
        case .tired: return 2
        case .okay: return 3
        case .good: return 4
        case .great: return 5
        }
    }

    private func saveToHealthKit(session: LiftSession) async -> Bool {
        let healthKitService = HealthKitService.shared

        return await healthKitService.saveLiftWorkout(
            duration: session.duration,
            startDate: session.startDate,
            endDate: session.endDate ?? Date(),
            totalVolume: session.totalVolume
        )
    }
}

// MARK: - Supporting Types

/**
 * Session progress tracking data.
 */
struct SessionProgressData {
    let totalVolume: Double
    let totalSets: Int
    let totalReps: Int
    let completedExercises: Int
    let totalExercises: Int
    let progressPercentage: Double
}
