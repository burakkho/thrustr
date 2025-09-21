import Foundation
import SwiftData

/**
 * Business logic service for LiftSession management.
 *
 * Handles all session-related operations including creation, completion,
 * exercise management, and progress tracking. Integrates with existing
 * services to avoid duplication and maintain consistency.
 *
 * Features:
 * - Session lifecycle management (create, start, complete)
 * - Exercise and set tracking
 * - Personal record detection
 * - HealthKit integration
 * - Activity logging
 * - Progress calculations
 */
struct LiftSessionService: Sendable {

    // MARK: - Dependencies
    private static let healthCalculator = HealthCalculator.self
    private static let activityLogger = ActivityLoggerService.shared
    private static let healthKitService = HealthKitService.shared
    private static let dashboardService = TrainingDashboardService.self

    // MARK: - Session Management

    /**
     * Creates a new LiftSession with proper initialization.
     *
     * - Parameters:
     *   - workout: The workout template to use
     *   - user: User performing the workout
     *   - programExecution: Optional program context
     *   - modelContext: SwiftData context for persistence
     * - Returns: Result with created LiftSession or error
     */
    static func createSession(
        workout: LiftWorkout,
        user: User,
        programExecution: ProgramExecution? = nil,
        modelContext: ModelContext
    ) async -> Result<LiftSession, LiftSessionError> {

        do {
            // Create the session
            let session = LiftSession(
                workout: workout,
                user: user,
                programExecution: programExecution
            )

            // Initialize exercise results from workout template
            if let workoutExercises = workout.exercises {
                for liftExercise in workoutExercises {
                    let exerciseResult = LiftExerciseResult(
                        exercise: liftExercise,
                        session: session
                    )

                    // Initialize with target sets
                    exerciseResult.initializeWithTargetSets()
                    session.addExerciseResult(exerciseResult)
                }
            }

            // Persist to database
            modelContext.insert(session)
            try modelContext.save()

            Logger.info("✅ LiftSession created successfully: \(workout.localizedName)")
            return .success(session)

        } catch {
            Logger.error("❌ Failed to create LiftSession: \(error)")
            return .failure(.sessionCreationFailed(error))
        }
    }

    /**
     * Completes a LiftSession with full business logic.
     *
     * - Parameters:
     *   - session: Session to complete
     *   - user: User completing the session
     *   - modelContext: SwiftData context
     * - Returns: Result indicating success or failure
     */
    static func completeSession(
        _ session: LiftSession,
        user: User,
        modelContext: ModelContext
    ) async -> Result<Void, LiftSessionError> {

        do {
            // Validate session can be completed
            guard !session.isCompleted else {
                return .failure(.sessionAlreadyCompleted)
            }

            // Calculate session metrics
            let metrics = calculateSessionMetrics(session)

            // Mark session as completed
            session.complete()

            // Save to database
            try modelContext.save()

            // Check for Personal Records
            let personalRecords = await checkPersonalRecords(session: session, user: user, modelContext: modelContext)
            // Note: prsHit is a computed property, PRs are tracked via isPersonalRecord in exercise results

            // Log activity with proper context
            await logSessionActivity(session: session, user: user, modelContext: modelContext)

            // Sync to HealthKit
            await syncToHealthKit(session: session, user: user)

            Logger.success("✅ LiftSession completed successfully")
            return .success(())

        } catch {
            Logger.error("❌ Failed to complete LiftSession: \(error)")
            return .failure(.sessionCompletionFailed(error))
        }
    }

    // MARK: - Exercise Management

    /**
     * Adds a new exercise to an active session.
     *
     * - Parameters:
     *   - exercise: Exercise to add
     *   - session: Target session
     *   - modelContext: SwiftData context
     * - Returns: Result with created ExerciseResult or error
     */
    static func addExercise(
        _ exercise: Exercise,
        to session: LiftSession,
        modelContext: ModelContext
    ) -> Result<LiftExerciseResult, LiftSessionError> {

        guard !session.isCompleted else {
            return .failure(.sessionAlreadyCompleted)
        }

        do {
            // Create LiftExercise from Exercise
            let liftExercise = LiftExercise(
                exerciseId: exercise.id,
                exerciseName: exercise.nameEN
            )

            // Create exercise result
            let exerciseResult = LiftExerciseResult(
                exercise: liftExercise,
                session: session
            )

            // Initialize with default set
            exerciseResult.initializeWithTargetSets()
            session.addExerciseResult(exerciseResult)

            // Save changes
            try modelContext.save()

            Logger.info("✅ Exercise added to session: \(exercise.nameEN)")
            return .success(exerciseResult)

        } catch {
            Logger.error("❌ Failed to add exercise: \(error)")
            return .failure(.exerciseAdditionFailed(error))
        }
    }

    /**
     * Updates set data for an exercise result.
     *
     * - Parameters:
     *   - exerciseResult: Target exercise result
     *   - setIndex: Index of set to update
     *   - weight: New weight value
     *   - reps: New reps value
     *   - modelContext: SwiftData context
     * - Returns: Result indicating success or failure
     */
    static func updateSet(
        exerciseResult: LiftExerciseResult,
        setIndex: Int,
        weight: Double?,
        reps: Int,
        modelContext: ModelContext
    ) -> Result<Void, LiftSessionError> {

        guard setIndex < exerciseResult.sets.count else {
            return .failure(.invalidSetIndex)
        }

        do {
            // Update the set
            var updatedSets = exerciseResult.sets
            updatedSets[setIndex].weight = weight
            updatedSets[setIndex].reps = reps
            updatedSets[setIndex].timestamp = Date()

            exerciseResult.sets = updatedSets

            // Save changes
            try modelContext.save()

            Logger.info("✅ Set updated successfully")
            return .success(())

        } catch {
            Logger.error("❌ Failed to update set: \(error)")
            return .failure(.setUpdateFailed(error))
        }
    }

    /**
     * Completes a set and marks it as finished.
     *
     * - Parameters:
     *   - exerciseResult: Target exercise result
     *   - setIndex: Index of set to complete
     *   - modelContext: SwiftData context
     * - Returns: Result indicating success or failure
     */
    static func completeSet(
        exerciseResult: LiftExerciseResult,
        setIndex: Int,
        modelContext: ModelContext
    ) -> Result<Void, LiftSessionError> {

        guard setIndex < exerciseResult.sets.count else {
            return .failure(.invalidSetIndex)
        }

        do {
            // Mark set as completed
            var updatedSets = exerciseResult.sets
            updatedSets[setIndex].isCompleted = true
            updatedSets[setIndex].timestamp = Date()

            exerciseResult.sets = updatedSets

            // Update exercise completion status
            exerciseResult.updateCompletionStatus()

            // Save changes
            try modelContext.save()

            Logger.info("✅ Set completed successfully")
            return .success(())

        } catch {
            Logger.error("❌ Failed to complete set: \(error)")
            return .failure(.setCompletionFailed(error))
        }
    }

    // MARK: - Progress Tracking

    /**
     * Gets previous performance data for an exercise.
     *
     * - Parameters:
     *   - exerciseId: Exercise identifier
     *   - user: User context
     *   - modelContext: SwiftData context
     * - Returns: Previous sets data or nil if none found
     */
    static func getPreviousPerformance(
        for exerciseId: String,
        user: User,
        modelContext: ModelContext
    ) -> [SetData]? {

        // Query for previous completed sessions with this exercise
        let descriptor = FetchDescriptor<LiftSession>(
            predicate: #Predicate<LiftSession> { session in
                session.isCompleted == true && session.user?.id == user.id
            },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )

        do {
            let previousSessions = try modelContext.fetch(descriptor)

            // Find the most recent session with this exercise
            for session in previousSessions {
                if let exerciseResults = session.exerciseResults {
                    for result in exerciseResults {
                        if result.exercise?.exerciseId.uuidString == exerciseId {
                            return result.sets.filter { $0.isCompleted }
                        }
                    }
                }
            }

        } catch {
            Logger.error("Failed to fetch previous performance: \(error)")
        }

        return nil
    }

    // MARK: - Private Helper Methods

    /**
     * Calculates comprehensive session metrics.
     */
    private static func calculateSessionMetrics(_ session: LiftSession) -> SessionMetrics {
        guard let exerciseResults = session.exerciseResults else {
            return SessionMetrics(totalVolume: 0, totalSets: 0, totalReps: 0)
        }

        let totalVolume = exerciseResults.reduce(0) { total, result in
            total + result.totalVolume
        }

        let totalSets = exerciseResults.reduce(0) { total, result in
            total + result.completedSets
        }

        let totalReps = exerciseResults.reduce(0) { total, result in
            total + result.totalReps
        }

        return SessionMetrics(
            totalVolume: totalVolume,
            totalSets: totalSets,
            totalReps: totalReps
        )
    }

    /**
     * Checks for personal records in the session.
     */
    private static func checkPersonalRecords(
        session: LiftSession,
        user: User,
        modelContext: ModelContext
    ) async -> [String] {
        var personalRecords: [String] = []

        guard let exerciseResults = session.exerciseResults else {
            return personalRecords
        }

        for exerciseResult in exerciseResults {
            guard let exercise = exerciseResult.exercise else { continue }

            // Get max weight from this session
            let maxWeightThisSession = exerciseResult.sets
                .filter { $0.isCompleted && $0.reps > 0 }
                .compactMap { $0.weight }
                .max() ?? 0

            if maxWeightThisSession > 0 {
                // Get previous best
                let previousBest = getPreviousBest(for: exercise, user: user, modelContext: modelContext)

                // Check if it's a PR
                if maxWeightThisSession > previousBest {
                    personalRecords.append(exercise.exerciseName)

                    // Log the PR
                    await MainActor.run {
                        activityLogger.setModelContext(modelContext)
                        activityLogger.logPersonalRecord(
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

        return personalRecords
    }

    /**
     * Gets previous best weight for an exercise.
     */
    private static func getPreviousBest(
        for exercise: LiftExercise,
        user: User,
        modelContext: ModelContext
    ) -> Double {
        var descriptor = FetchDescriptor<LiftSession>(
            predicate: #Predicate<LiftSession> { session in
                session.isCompleted && session.user?.id == user.id
            },
            sortBy: [SortDescriptor(\LiftSession.startDate, order: .reverse)]
        )

        descriptor.fetchLimit = 20

        do {
            let recentSessions = try modelContext.fetch(descriptor)
            var maxWeight: Double = 0

            for session in recentSessions {
                for result in session.exerciseResults ?? [] {
                    if result.exercise?.exerciseName == exercise.exerciseName {
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
            Logger.error("Error fetching previous best: \(error)")
            return 0
        }
    }

    /**
     * Logs session completion activity.
     */
    private static func logSessionActivity(
        session: LiftSession,
        user: User,
        modelContext: ModelContext
    ) async {
        await MainActor.run {
            activityLogger.setModelContext(modelContext)
            activityLogger.logWorkoutCompleted(
                workoutType: session.workout?.localizedName ?? "Lift Workout",
                duration: session.duration,
                volume: session.totalVolume,
                sets: session.totalSets,
                reps: session.totalReps,
                user: user
            )
        }
    }

    /**
     * Syncs completed session to HealthKit.
     */
    private static func syncToHealthKit(
        session: LiftSession,
        user: User
    ) async {
        // Calculate estimated calories using existing service
        let estimatedCalories = healthCalculator.estimateStrengthTrainingCalories(
            duration: session.duration,
            bodyWeight: user.currentWeight,
            intensity: .moderate
        )

        // Sync to HealthKit
        let success = await healthKitService.saveLiftWorkout(
            duration: session.duration,
            caloriesBurned: estimatedCalories,
            startDate: session.startDate,
            endDate: session.endDate ?? Date(),
            totalVolume: session.totalVolume
        )

        if success {
            Logger.info("✅ Lift workout successfully synced to HealthKit")
        } else {
            Logger.warning("⚠️ Failed to sync lift workout to HealthKit")
        }
    }
}

// MARK: - Supporting Types

/**
 * Session metrics calculation result.
 */
struct SessionMetrics {
    let totalVolume: Double
    let totalSets: Int
    let totalReps: Int
}

/**
 * LiftSession service specific errors.
 */
enum LiftSessionError: LocalizedError, Sendable {
    case sessionCreationFailed(Error)
    case sessionCompletionFailed(Error)
    case sessionAlreadyCompleted
    case exerciseAdditionFailed(Error)
    case setUpdateFailed(Error)
    case setCompletionFailed(Error)
    case invalidSetIndex
    case userNotFound
    case workoutNotFound

    var errorDescription: String? {
        switch self {
        case .sessionCreationFailed(let error):
            return "Failed to create session: \(error.localizedDescription)"
        case .sessionCompletionFailed(let error):
            return "Failed to complete session: \(error.localizedDescription)"
        case .sessionAlreadyCompleted:
            return "Session is already completed"
        case .exerciseAdditionFailed(let error):
            return "Failed to add exercise: \(error.localizedDescription)"
        case .setUpdateFailed(let error):
            return "Failed to update set: \(error.localizedDescription)"
        case .setCompletionFailed(let error):
            return "Failed to complete set: \(error.localizedDescription)"
        case .invalidSetIndex:
            return "Invalid set index"
        case .userNotFound:
            return "User not found"
        case .workoutNotFound:
            return "Workout not found"
        }
    }
}

// MARK: - Extensions for Model Integration

extension LiftExerciseResult {
    /**
     * Initializes exercise result with target sets.
     */
    func initializeWithTargetSets() {
        let targetSets = self.exercise?.targetSets ?? 3
        let targetReps = self.exercise?.targetReps ?? 10
        let targetWeight = self.exercise?.targetWeight

        var newSets: [SetData] = []
        for i in 1...targetSets {
            let setData = SetData(
                setNumber: i,
                weight: targetWeight,
                reps: targetReps,
                isWarmup: i == 1, // First set is warmup
                isCompleted: false
            )
            newSets.append(setData)
        }

        self.sets = newSets
    }

    /**
     * Updates completion status based on completed sets.
     */
    func updateCompletionStatus() {
        let targetSets = self.exercise?.targetSets ?? 3
        let completedSets = self.sets.filter { $0.isCompleted }.count
        // Mark as completed if at least 70% of target sets are done
        self.isCompleted = Double(completedSets) / Double(targetSets) >= 0.7
    }
}