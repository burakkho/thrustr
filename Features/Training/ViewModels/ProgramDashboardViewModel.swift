import Foundation
import SwiftData

@MainActor
@Observable
final class ProgramDashboardViewModel {
    var errorMessage: String?

    private weak var modelContext: ModelContext?

    init() {}

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Business Logic Methods (Using Services)

    /// Calculate total volume from all completed workouts in the program
    func totalVolume(execution: ProgramExecution) -> Double {
        guard let completedWorkouts = execution.completedWorkouts else { return 0.0 }

        let totalVolumeFromSessions = completedWorkouts
            .compactMap { $0.liftSession?.totalVolume }
            .reduce(0, +)

        return totalVolumeFromSessions
    }

    /// Calculate personal records achieved this week
    func prsThisWeek(execution: ProgramExecution) -> Int {
        guard let completedWorkouts = execution.completedWorkouts else { return 0 }

        // Gather all exercise results from this week's sessions
        let thisWeekResults = getThisWeekExerciseResults(from: completedWorkouts, currentWeek: execution.currentWeek)

        // Calculate PRs manually - check for personal records this week
        return calculatePRsFromResults(thisWeekResults)
    }

    /// Calculate PRs from exercise results
    private func calculatePRsFromResults(_ results: [LiftExerciseResult]) -> Int {
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()

        // Count results marked as personal records within last week
        return results.filter { result in
            result.isPersonalRecord == true && result.performedAt >= oneWeekAgo
        }.count
    }

    /// Get exercise results from this week's workouts
    private func getThisWeekExerciseResults(from completedWorkouts: [CompletedWorkout], currentWeek: Int) -> [LiftExerciseResult] {
        let calendar = Calendar.current
        let currentDate = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: currentDate)?.start ?? currentDate

        let thisWeekWorkouts = completedWorkouts.filter { workout in
            workout.completedAt >= startOfWeek &&
            workout.weekNumber == currentWeek &&
            !workout.isSkipped
        }

        var allResults: [LiftExerciseResult] = []
        for workout in thisWeekWorkouts {
            if let exerciseResults = workout.liftSession?.exerciseResults {
                allResults.append(contentsOf: exerciseResults)
            }
        }
        return allResults
    }

    /// Calculate average session duration
    func averageSessionDuration(execution: ProgramExecution) -> TimeInterval {
        guard let completedWorkouts = execution.completedWorkouts else { return 0 }

        let durations = completedWorkouts
            .compactMap { $0.liftSession?.duration }
            .filter { $0 > 0 }

        guard !durations.isEmpty else { return 0 }
        return durations.reduce(0, +) / Double(durations.count)
    }

    /// Calculate total sets completed in program
    func totalSetsCompleted(execution: ProgramExecution) -> Int {
        guard let completedWorkouts = execution.completedWorkouts else { return 0 }

        return completedWorkouts
            .compactMap { $0.liftSession?.totalSets }
            .reduce(0, +)
    }

    /// Calculate total reps completed in program
    func totalRepsCompleted(execution: ProgramExecution) -> Int {
        guard let completedWorkouts = execution.completedWorkouts else { return 0 }

        return completedWorkouts
            .compactMap { $0.liftSession?.totalReps }
            .reduce(0, +)
    }

    /// Get current week's workout completion percentage
    func weeklyCompletionPercentage(execution: ProgramExecution) -> Double {
        guard let program = execution.program else { return 0.0 }

        let targetWorkoutsThisWeek = program.daysPerWeek
        let completedWorkoutsThisWeek = execution.completedWorkoutsThisWeek

        return Double(completedWorkoutsThisWeek) / Double(targetWorkoutsThisWeek)
    }

    /// Format duration in human readable format
    func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration.truncatingRemainder(dividingBy: 3600)) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    /// Get program intensity score based on recent performance
    func programIntensityScore(execution: ProgramExecution) -> Double {
        guard let completedWorkouts = execution.completedWorkouts else { return 0.0 }

        // Get recent 5 workouts for intensity calculation
        let recentWorkouts = completedWorkouts
            .filter { !$0.isSkipped }
            .sorted { $0.completedAt > $1.completedAt }
            .prefix(5)

        let totalRatings = recentWorkouts
            .compactMap { $0.liftSession?.rating }
            .reduce(0, +)

        let workoutCount = recentWorkouts.count
        guard workoutCount > 0 else { return 0.0 }

        return Double(totalRatings) / Double(workoutCount)
    }

    // MARK: - Error Handling

    func clearErrors() {
        errorMessage = nil
    }
}