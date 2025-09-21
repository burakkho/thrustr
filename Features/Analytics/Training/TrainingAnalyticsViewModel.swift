import SwiftUI
import SwiftData
import Foundation

/**
 * ViewModel for TrainingAnalyticsView with clean separation of concerns.
 *
 * Manages training data processing, strength progression analytics, and PR tracking.
 * Handles all business logic for training analytics dashboard.
 */
@MainActor
@Observable
class TrainingAnalyticsViewModel {

    // MARK: - State
    var exerciseMaxes: [(name: String, currentMax: Double, trend: TrendDirection, improvement: Double)] = []
    var recentLiftResults: [LiftExerciseResult] = []
    var strengthProgressionData: [StrengthProgressionData] = []
    var isLoading = false
    var errorMessage: String?

    // MARK: - Computed Properties

    /**
     * Whether there is sufficient data to show analytics.
     */
    var hasAnalyticsData: Bool {
        return !recentLiftResults.isEmpty
    }

    /**
     * Total workouts in the last 30 days.
     */
    var totalWorkouts: Int {
        let uniqueSessions = Set(recentLiftResults.map { $0.sessionId })
        return uniqueSessions.count
    }

    /**
     * Average workouts per week.
     */
    var averageWorkoutsPerWeek: Double {
        return Double(totalWorkouts) * 7.0 / 30.0
    }

    // MARK: - Initialization

    init() {
        // No dependencies needed
    }

    // MARK: - Public Methods

    /**
     * Updates data with new lift exercise results.
     */
    func updateData(_ allLiftResults: [LiftExerciseResult]) {
        // Filter to last 30 days
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        recentLiftResults = allLiftResults.filter { result in
            result.performedAt >= thirtyDaysAgo
        }

        // Calculate analytics
        calculateExerciseMaxes()
        calculateStrengthProgression()
    }

    /**
     * Refreshes analytics data.
     */
    func refreshAnalytics(_ allLiftResults: [LiftExerciseResult]) {
        updateData(allLiftResults)
    }

    // MARK: - Private Methods

    private func calculateExerciseMaxes() {
        let exerciseGroups = Dictionary(grouping: recentLiftResults) { result in
            result.exercise?.exerciseName ?? "Unknown"
        }

        exerciseMaxes = exerciseGroups.compactMap { (exerciseName, results) in
            guard !results.isEmpty else { return nil }

            // Find current max (best set from all results)
            let currentMax = results.compactMap { $0.maxWeight }.max() ?? 0.0

            // Calculate trend (compare last 2 weeks vs previous 2 weeks)
            let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
            let fourWeeksAgo = Calendar.current.date(byAdding: .day, value: -28, to: Date()) ?? Date()

            let recentResults = results.filter { $0.performedAt >= twoWeeksAgo }
            let previousResults = results.filter { $0.performedAt >= fourWeeksAgo && $0.performedAt < twoWeeksAgo }

            let recentMax = recentResults.compactMap { $0.maxWeight }.max() ?? 0.0
            let previousMax = previousResults.compactMap { $0.maxWeight }.max() ?? 0.0

            let improvement = recentMax - previousMax
            let trend: TrendDirection = {
                if improvement > 2.5 { return .increasing }
                if improvement < -2.5 { return .decreasing }
                return .stable
            }()

            return (name: exerciseName, currentMax: currentMax, trend: trend, improvement: improvement)
        }
        .sorted { $0.currentMax > $1.currentMax }
        .prefix(6)
        .map { $0 }
    }

    private func calculateStrengthProgression() {
        // Group by exercise and calculate progression over time
        let exerciseGroups = Dictionary(grouping: recentLiftResults) { result in
            result.exercise?.exerciseName ?? "Unknown"
        }

        strengthProgressionData = exerciseGroups.compactMap { (exerciseName, results) in
            guard !results.isEmpty else { return nil }

            let sortedResults = results.sorted { $0.performedAt < $1.performedAt }
            let progressionPoints = sortedResults.compactMap { result -> ProgressionPoint? in
                guard let maxWeight = result.maxWeight else { return nil }
                return ProgressionPoint(date: result.performedAt, weight: maxWeight)
            }

            guard !progressionPoints.isEmpty else { return nil }

            return StrengthProgressionData(
                exerciseName: exerciseName,
                progressionPoints: progressionPoints,
                currentMax: progressionPoints.map { $0.weight }.max() ?? 0.0
            )
        }
        .sorted { $0.currentMax > $1.currentMax }
    }
}

// MARK: - Supporting Types

struct StrengthProgressionData {
    let exerciseName: String
    let progressionPoints: [ProgressionPoint]
    let currentMax: Double
}

struct ProgressionPoint {
    let date: Date
    let weight: Double
}

enum TrendDirection {
    case increasing, decreasing, stable

    var color: Color {
        switch self {
        case .increasing: return .green
        case .decreasing: return .red
        case .stable: return .orange
        }
    }

    var icon: String {
        switch self {
        case .increasing: return "arrow.up.right"
        case .decreasing: return "arrow.down.right"
        case .stable: return "arrow.right"
        }
    }
}