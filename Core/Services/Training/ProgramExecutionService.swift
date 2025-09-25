import Foundation
@preconcurrency import SwiftData

// MARK: - Swift 6 Sendable Conformance
extension ProgramExecution: @unchecked Sendable {}
extension LiftProgram: @unchecked Sendable {}

/**
 * Business logic service for ProgramExecution management.
 *
 * Handles program advancement, workout progression, and milestone tracking.
 * Integrates with existing services to maintain consistency and avoid duplication.
 *
 * Features:
 * - Program execution lifecycle
 * - Week and day advancement
 * - Workout progression logic
 * - Program completion handling
 * - Progress analytics
 * - Activity logging integration
 */
struct ProgramExecutionService: Sendable {

    // MARK: - Dependencies
    // No static dependencies to avoid main actor issues

    // MARK: - Program Execution Management

    /**
     * Creates a new program execution for a user.
     *
     * - Parameters:
     *   - program: The program to execute
     *   - user: User starting the program
     *   - modelContext: SwiftData context
     * - Returns: Result with created ProgramExecution or error
     */
    static func startProgram(
        _ program: LiftProgram,
        for user: User,
        modelContext: ModelContext
    ) async -> Result<ProgramExecution, ProgramExecutionError> {

        do {
            // Check if user already has an active program
            if let activeExecution = getActiveExecution(for: user, modelContext: modelContext) {
                return .failure(.userHasActiveProgram(activeExecution.program?.localizedName ?? "Unknown"))
            }

            // Create new execution
            let execution = ProgramExecution(program: program, user: user)
            modelContext.insert(execution)
            try modelContext.save()

            // Log program start activity
            await logProgramStart(execution: execution, user: user, modelContext: modelContext)

            Logger.success("✅ Program started: \(program.localizedName)")
            return .success(execution)

        } catch {
            Logger.error("❌ Failed to start program: \(error)")
            return .failure(.programStartFailed(error))
        }
    }

    /**
     * Advances program execution after workout completion.
     *
     * - Parameters:
     *   - execution: Program execution to advance
     *   - modelContext: SwiftData context
     * - Returns: Result indicating advancement success or program completion
     */
    static func advanceProgram(
        _ execution: ProgramExecution,
        modelContext: ModelContext
    ) async -> Result<ProgramAdvancementResult, ProgramExecutionError> {

        guard let program = execution.program else {
            return .failure(.programNotFound)
        }

        do {
            // Check if program is already completed
            if execution.isCompleted {
                return .failure(.programAlreadyCompleted)
            }

            // Advance to next workout
            let wasLastDayOfWeek = execution.currentDay == program.daysPerWeek
            let wasLastWeek = execution.currentWeek == program.weeks

            if wasLastDayOfWeek && wasLastWeek {
                // Program completed!
                await MainActor.run {
                    execution.completeProgram()
                }
                try modelContext.save()

                await logProgramCompletion(execution: execution, modelContext: modelContext)

                Logger.success("🎉 Program completed: \(program.localizedName)")
                return .success(.programCompleted)

            } else if wasLastDayOfWeek {
                // Move to next week
                execution.currentWeek += 1
                execution.currentDay = 1
                try modelContext.save()

                await logWeekCompletion(execution: execution, modelContext: modelContext)

                Logger.info("📅 Advanced to Week \(execution.currentWeek)")
                return .success(.weekAdvanced(execution.currentWeek))

            } else {
                // Move to next day
                execution.currentDay += 1
                try modelContext.save()

                Logger.info("➡️ Advanced to Day \(execution.currentDay)")
                return .success(.dayAdvanced(execution.currentDay))
            }

        } catch {
            Logger.error("❌ Failed to advance program: \(error)")
            return .failure(.programAdvancementFailed(error))
        }
    }

    /**
     * Pauses or resumes a program execution.
     *
     * - Parameters:
     *   - execution: Program execution to pause/resume
     *   - paused: Whether to pause or resume
     *   - modelContext: SwiftData context
     * - Returns: Result indicating success or failure
     */
    static func setProgramPaused(
        _ execution: ProgramExecution,
        paused: Bool,
        modelContext: ModelContext
    ) -> Result<Void, ProgramExecutionError> {

        do {
            execution.isPaused = paused
            try modelContext.save()

            let action = paused ? "paused" : "resumed"
            Logger.info("⏸️ Program \(action): \(execution.program?.localizedName ?? "Unknown")")
            return .success(())

        } catch {
            Logger.error("❌ Failed to update program pause state: \(error)")
            return .failure(.programUpdateFailed(error))
        }
    }

    /**
     * Completes a program execution manually.
     *
     * - Parameters:
     *   - execution: Program execution to complete
     *   - modelContext: SwiftData context
     * - Returns: Result indicating success or failure
     */
    static func completeProgram(
        _ execution: ProgramExecution,
        modelContext: ModelContext
    ) async -> Result<Void, ProgramExecutionError> {

        do {
            await MainActor.run {
                execution.completeProgram()
            }
            try modelContext.save()

            await logProgramCompletion(execution: execution, modelContext: modelContext)

            Logger.success("✅ Program completed manually: \(execution.program?.localizedName ?? "Unknown")")
            return .success(())

        } catch {
            Logger.error("❌ Failed to complete program: \(error)")
            return .failure(.programCompletionFailed(error))
        }
    }

    // MARK: - Program Analytics

    /**
     * Calculates program execution progress metrics.
     *
     * - Parameter execution: Program execution to analyze
     * - Returns: Progress metrics
     */
    static func calculateProgressMetrics(_ execution: ProgramExecution) -> ProgramProgressMetrics {
        guard let program = execution.program else {
            return ProgramProgressMetrics(
                progressPercentage: 0,
                currentStreak: 0,
                completedWorkoutsThisWeek: 0,
                remainingWeeks: 0,
                totalWorkouts: 0,
                completedWorkouts: 0
            )
        }

        // Calculate progress percentage
        let totalWorkouts = program.weeks * program.daysPerWeek
        let completedWorkouts = ((execution.currentWeek - 1) * program.daysPerWeek) + (execution.currentDay - 1)
        let progressPercentage = Double(completedWorkouts) / Double(totalWorkouts)

        // Calculate completed workouts this week
        let completedWorkoutsThisWeek = execution.currentDay - 1

        // Calculate remaining weeks
        let remainingWeeks = program.weeks - execution.currentWeek + 1

        // Calculate current streak (simplified for now)
        let currentStreak = execution.completedWorkouts?.count ?? 0

        return ProgramProgressMetrics(
            progressPercentage: progressPercentage,
            currentStreak: currentStreak,
            completedWorkoutsThisWeek: completedWorkoutsThisWeek,
            remainingWeeks: remainingWeeks,
            totalWorkouts: totalWorkouts,
            completedWorkouts: completedWorkouts
        )
    }

    /**
     * Gets the current workout for a program execution.
     *
     * - Parameter execution: Program execution
     * - Returns: Current workout to be performed
     */
    static func getCurrentWorkout(_ execution: ProgramExecution) -> LiftWorkout? {
        guard let program = execution.program,
              let workouts = program.workouts else {
            return nil
        }

        // For now, use simple cycling through workouts
        // This can be enhanced based on program structure
        let workoutIndex = (execution.currentDay - 1) % workouts.count
        return workouts[safe: workoutIndex]
    }

    /**
     * Gets all active program executions for a user.
     *
     * - Parameters:
     *   - user: User to query
     *   - modelContext: SwiftData context
     * - Returns: Array of active program executions
     */
    static func getActiveExecutions(
        for user: User,
        modelContext: ModelContext
    ) -> [ProgramExecution] {
        let userId = user.id
        let descriptor = FetchDescriptor<ProgramExecution>(
            predicate: #Predicate<ProgramExecution> { execution in
                execution.user?.id == userId && !execution.isCompleted
            },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            Logger.error("Failed to fetch active program executions: \(error)")
            return []
        }
    }

    /**
     * Gets the most recent active execution for a user.
     *
     * - Parameters:
     *   - user: User to query
     *   - modelContext: SwiftData context
     * - Returns: Active program execution or nil
     */
    static func getActiveExecution(
        for user: User,
        modelContext: ModelContext
    ) -> ProgramExecution? {
        return getActiveExecutions(for: user, modelContext: modelContext).first
    }

    // MARK: - Program Statistics

    /**
     * Calculates program dashboard statistics.
     *
     * - Parameter execution: Program execution to analyze
     * - Returns: Dashboard statistics
     */
    static func calculateDashboardStats(_ execution: ProgramExecution) -> ProgramDashboardStats {
        guard let completedWorkouts = execution.completedWorkouts else {
            return ProgramDashboardStats(
                totalVolume: 0,
                prsThisWeek: 0,
                averageSessionDuration: 0
            )
        }

        // Calculate total volume from completed workouts
        let totalVolume = completedWorkouts.reduce(into: 0.0) { total, workout in
            // CompletedWorkout doesn't have totalVolume, use estimated value
            total += Double(workout.duration ?? 0) * 0.5 // Estimate: 0.5kg per minute
        }

        // Calculate PRs this week (simplified)
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentWorkouts = completedWorkouts.filter { workout in
            workout.completedAt >= oneWeekAgo
        }
        let prsThisWeek = recentWorkouts.reduce(into: 0) { total, workout in
            // CompletedWorkout doesn't track PRs directly, estimate based on session
            total += workout.liftSession?.prsHit.count ?? 0
        }

        // Calculate average session duration
        let totalDuration = completedWorkouts.reduce(into: 0) { total, workout in
            total += workout.duration ?? 0
        }
        let averageSessionDuration = completedWorkouts.isEmpty ? 0 : TimeInterval(totalDuration) / TimeInterval(completedWorkouts.count)

        return ProgramDashboardStats(
            totalVolume: totalVolume,
            prsThisWeek: prsThisWeek,
            averageSessionDuration: averageSessionDuration
        )
    }

    // MARK: - Private Helper Methods

    /**
     * Logs program start activity.
     */
    private static func logProgramStart(
        execution: ProgramExecution,
        user: User,
        modelContext: ModelContext
    ) async {
        guard let program = execution.program else { return }
        let programName = program.localizedName

        Task { @MainActor in
            let activityLogger = ActivityLoggerService.shared
            activityLogger.setModelContext(modelContext)
            activityLogger.logWorkoutCompleted(
                workoutType: "Program Started: " + programName,
                duration: 0,
                volume: 0,
                user: user
            )
        }
    }

    /**
     * Logs program completion activity.
     */
    private static func logProgramCompletion(
        execution: ProgramExecution,
        modelContext: ModelContext
    ) async {
        guard let program = execution.program,
              let user = execution.user else { return }

        let programName = program.localizedName
        let duration = TimeInterval((execution.duration ?? 0) * 24 * 3600) // days to seconds
        let volume = Double(execution.completedWorkouts?.count ?? 0)

        Task { @MainActor in
            let activityLogger = ActivityLoggerService.shared
            activityLogger.setModelContext(modelContext)
            activityLogger.logWorkoutCompleted(
                workoutType: "Program Completed: " + programName,
                duration: duration,
                volume: volume,
                user: user
            )
        }
    }

    /**
     * Logs week completion milestone.
     */
    private static func logWeekCompletion(
        execution: ProgramExecution,
        modelContext: ModelContext
    ) async {
        guard let program = execution.program,
              let user = execution.user else { return }

        let programName = program.localizedName
        let currentWeek = execution.currentWeek

        Task { @MainActor in
            let activityLogger = ActivityLoggerService.shared
            activityLogger.setModelContext(modelContext)
            activityLogger.logWorkoutCompleted(
                workoutType: "Week \(currentWeek - 1) Completed - " + programName,
                duration: 0,
                volume: 0,
                user: user
            )
        }
    }
}

// MARK: - Supporting Types

/**
 * Program advancement result enum.
 */
enum ProgramAdvancementResult {
    case dayAdvanced(Int)
    case weekAdvanced(Int)
    case programCompleted
}

/**
 * Program progress metrics.
 */
struct ProgramProgressMetrics {
    let progressPercentage: Double
    let currentStreak: Int
    let completedWorkoutsThisWeek: Int
    let remainingWeeks: Int
    let totalWorkouts: Int
    let completedWorkouts: Int
}

/**
 * Program dashboard statistics.
 */
struct ProgramDashboardStats {
    let totalVolume: Double
    let prsThisWeek: Int
    let averageSessionDuration: TimeInterval
}

/**
 * Program execution service errors.
 */
enum ProgramExecutionError: LocalizedError, Sendable {
    case programStartFailed(Error)
    case programAdvancementFailed(Error)
    case programCompletionFailed(Error)
    case programUpdateFailed(Error)
    case programNotFound
    case programAlreadyCompleted
    case userHasActiveProgram(String)
    case userNotFound

    var errorDescription: String? {
        switch self {
        case .programStartFailed(let error):
            return "Failed to start program: \(error.localizedDescription)"
        case .programAdvancementFailed(let error):
            return "Failed to advance program: \(error.localizedDescription)"
        case .programCompletionFailed(let error):
            return "Failed to complete program: \(error.localizedDescription)"
        case .programUpdateFailed(let error):
            return "Failed to update program: \(error.localizedDescription)"
        case .programNotFound:
            return "Program not found"
        case .programAlreadyCompleted:
            return "Program is already completed"
        case .userHasActiveProgram(let programName):
            return "User already has an active program: \(programName)"
        case .userNotFound:
            return "User not found"
        }
    }
}

// MARK: - Extensions for Model Integration


extension Array {
    /**
     * Safe array subscript to avoid index out of bounds.
     */
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

