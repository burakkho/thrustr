import Foundation
import SwiftData

struct TrainingAnalyticsService {

    // MARK: - Exercise Progression Analysis

    static func calculateExerciseMaxes(from liftResults: [LiftExerciseResult]) -> [(name: String, currentMax: Double, trend: TrendDirection, improvement: Double)] {
        let exerciseGroups = Dictionary(grouping: liftResults) { result in
            result.exercise?.exerciseName ?? "Unknown"
        }

        return exerciseGroups.compactMap { (exerciseName, results) in
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

            return (exerciseName, currentMax, trend, abs(improvement))
        }.prefix(3).map { $0 } // Show top 3 exercises
    }

    // MARK: - Workout Frequency Analysis

    static func calculateWorkoutFrequency(liftResults: [LiftExerciseResult], cardioResults: [CardioResult]) -> (thisWeek: Int, lastWeek: Int, trend: TrendDirection) {
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()

        let thisWeekLift = liftResults.filter { $0.performedAt >= oneWeekAgo }.count
        let thisWeekCardio = cardioResults.filter { $0.completedAt >= oneWeekAgo }.count
        let thisWeekTotal = thisWeekLift + thisWeekCardio

        let lastWeekLift = liftResults.filter { $0.performedAt >= twoWeeksAgo && $0.performedAt < oneWeekAgo }.count
        let lastWeekCardio = cardioResults.filter { $0.completedAt >= twoWeeksAgo && $0.completedAt < oneWeekAgo }.count
        let lastWeekTotal = lastWeekLift + lastWeekCardio

        let trend: TrendDirection = {
            if thisWeekTotal > lastWeekTotal { return .increasing }
            if thisWeekTotal < lastWeekTotal { return .decreasing }
            return .stable
        }()

        return (thisWeekTotal, lastWeekTotal, trend)
    }

    // MARK: - Training Patterns Analysis

    static func calculateMostActiveTimeRange(liftResults: [LiftExerciseResult], cardioResults: [CardioResult]) -> String {
        let liftDates = liftResults.map { $0.performedAt }
        let cardioDates = cardioResults.map { $0.completedAt }
        let allDates = liftDates + cardioDates

        guard !allDates.isEmpty else { return "No data" }

        let hourCounts = Dictionary(grouping: allDates) { date in
            Calendar.current.component(.hour, from: date)
        }.mapValues { $0.count }

        guard let mostActiveHour = hourCounts.max(by: { $0.value < $1.value })?.key else {
            return "No data"
        }

        let endHour = (mostActiveHour + 2) % 24
        return String(format: "%02d:00-%02d:00", mostActiveHour, endHour)
    }

    static func calculateFavoriteExerciseType(liftResults: [LiftExerciseResult]) -> String {
        let exerciseTypes = Dictionary(grouping: liftResults) { result in
            extractExerciseCategory(from: result.exercise?.exerciseName ?? "Unknown")
        }.mapValues { $0.count }

        return exerciseTypes.max(by: { $0.value < $1.value })?.key ?? "Mixed"
    }

    static func calculateAverageSessionDuration(liftSessions: [LiftSession]) -> TimeInterval {
        guard !liftSessions.isEmpty else { return 0 }

        let totalDuration = liftSessions.compactMap { session in
            session.endDate?.timeIntervalSince(session.startDate)
        }.reduce(0, +)

        return totalDuration / Double(liftSessions.count)
    }

    // MARK: - Weekly Performance Summary

    static func calculateWeeklyPerformanceSummary(liftResults: [LiftExerciseResult], cardioResults: [CardioResult]) -> (
        totalWorkouts: Int,
        totalVolume: Double,
        averageIntensity: Double,
        consistencyScore: Double
    ) {
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()

        let recentLiftResults = liftResults.filter { $0.performedAt >= oneWeekAgo }
        let recentCardioResults = cardioResults.filter { $0.completedAt >= oneWeekAgo }

        let totalWorkouts = recentLiftResults.count + recentCardioResults.count

        // Calculate total volume (simplified)
        let totalVolume = recentLiftResults.compactMap { $0.maxWeight }.reduce(0, +)

        // Calculate average intensity (based on RPE)
        let rpeValues = recentLiftResults.compactMap { result in
            calculateAverageRPE(from: result.sets)
        }
        let averageIntensity = rpeValues.isEmpty ? 0 : rpeValues.reduce(0, +) / Double(rpeValues.count)

        // Calculate consistency score (workouts distributed across days)
        let workoutDays = Set(recentLiftResults.map { Calendar.current.startOfDay(for: $0.performedAt) } +
                            recentCardioResults.map { Calendar.current.startOfDay(for: $0.completedAt) })
        let consistencyScore = Double(workoutDays.count) / 7.0 * 100

        return (totalWorkouts, totalVolume, averageIntensity, consistencyScore)
    }

    // MARK: - Progress Insights

    static func generateProgressInsights(liftResults: [LiftExerciseResult]) -> [String] {
        var insights: [String] = []

        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let recentResults = liftResults.filter { $0.performedAt >= thirtyDaysAgo }

        if recentResults.isEmpty {
            insights.append("Start logging workouts to track progress")
            return insights
        }

        // Check for consistent improvement
        let exerciseMaxes = calculateExerciseMaxes(from: recentResults)
        let improvingExercises = exerciseMaxes.filter { $0.trend == .increasing }

        if improvingExercises.count > exerciseMaxes.count / 2 {
            insights.append("Great progress! Most exercises are improving")
        }

        // Check workout frequency
        let weeklyWorkouts = recentResults.count / 4
        if weeklyWorkouts >= 3 {
            insights.append("Excellent consistency with \(weeklyWorkouts) workouts per week")
        } else if weeklyWorkouts < 2 {
            insights.append("Try to increase workout frequency for better results")
        }

        return insights
    }

    // MARK: - Helper Methods

    private static func extractExerciseCategory(from exerciseName: String) -> String {
        let name = exerciseName.lowercased()

        if name.contains("squat") || name.contains("lunge") {
            return "Legs"
        } else if name.contains("bench") || name.contains("press") || name.contains("fly") {
            return "Chest"
        } else if name.contains("deadlift") || name.contains("row") || name.contains("pullup") || name.contains("pulldown") {
            return "Back"
        } else if name.contains("curl") || name.contains("tricep") {
            return "Arms"
        } else if name.contains("shoulder") || name.contains("lateral") || name.contains("overhead") {
            return "Shoulders"
        } else if name.contains("plank") || name.contains("crunch") || name.contains("abs") {
            return "Core"
        }

        return "Mixed"
    }

    private static func calculateAverageRPE(from sets: [SetData]) -> Double? {
        let rpeValues = sets.compactMap { $0.rpe }
        guard !rpeValues.isEmpty else { return nil }
        return Double(rpeValues.reduce(0, +)) / Double(rpeValues.count)
    }

    // MARK: - Formatting Methods

    /**
     * Formats weight value according to unit system.
     *
     * - Parameters:
     *   - weightInKg: Weight value in kilograms
     *   - unitSystem: User's preferred unit system
     * - Returns: Formatted weight string with unit
     */
    static func formatWeight(_ weightInKg: Double, unitSystem: UnitSystem) -> String {
        if unitSystem == .metric {
            return String(format: "%.1f kg", weightInKg)
        } else {
            let weightInLbs = weightInKg * 2.20462
            return String(format: "%.1f lb", weightInLbs)
        }
    }

    /**
     * Formats weight difference with trend indication.
     *
     * - Parameters:
     *   - diffInKg: Weight difference in kilograms
     *   - trend: Trend direction for formatting
     *   - unitSystem: User's preferred unit system
     * - Returns: Formatted weight difference string
     */
    static func formatWeightDifference(_ diffInKg: Double, trend: TrendDirection, unitSystem: UnitSystem) -> String {
        if diffInKg == 0 {
            return "No change"
        }

        let diffValue: Double
        let unit: String

        if unitSystem == .metric {
            diffValue = diffInKg
            unit = "kg"
        } else {
            diffValue = diffInKg * 2.20462
            unit = "lb"
        }

        let prefix = trend == .increasing ? "+" : (trend == .decreasing ? "-" : "")
        return String(format: "%@%.1f %@", prefix, abs(diffValue), unit)
    }
}

// MARK: - Supporting Types

struct WorkoutMetrics {
    let totalWorkouts: Int
    let totalVolume: Double
    let averageIntensity: Double
    let consistencyScore: Double
    let mostActiveTimeRange: String
    let favoriteExerciseType: String
    let averageSessionDuration: TimeInterval
}