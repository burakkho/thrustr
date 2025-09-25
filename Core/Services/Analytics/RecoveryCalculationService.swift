import Foundation

/// Service responsible for recovery-related calculations and analysis
struct RecoveryCalculationService {

    // MARK: - Recovery Trend Calculations

    /**
     * Calculates recovery score for a specific day based on historical data
     *
     * - Parameters:
     *   - daysBack: Number of days back from today
     *   - baseRecoveryScore: Base recovery score to adjust from
     *   - healthKitService: Health service for sleep and workout data
     * - Returns: Calculated recovery score for that day (20-100 range)
     */
    @MainActor
    static func calculateRecoveryForDay(
        daysBack: Int,
        baseRecoveryScore: RecoveryScore,
        healthKitService: HealthKitService
    ) async -> Double {
        let targetDate = Calendar.current.date(byAdding: .day, value: -daysBack, to: Date()) ?? Date()

        // Start with base recovery score
        var dayRecoveryScore = baseRecoveryScore.overallScore

        // Adjust based on sleep data if available
        let lastNightSleep = healthKitService.lastNightSleep
        if lastNightSleep > 0 {
            let sleepAdjustment = calculateSleepScoreAdjustment(sleepHours: lastNightSleep)
            dayRecoveryScore = (dayRecoveryScore * 0.7) + (sleepAdjustment * 0.3)
        }

        // Adjust based on workout load for that day
        let workoutAdjustment = calculateWorkoutLoadAdjustment(for: targetDate)
        dayRecoveryScore = (dayRecoveryScore * 0.8) + (workoutAdjustment * 0.2)

        return max(20, min(100, dayRecoveryScore)) // Keep within reasonable bounds
    }

    /**
     * Calculates sleep score adjustment based on hours of sleep
     *
     * - Parameter sleepHours: Number of hours slept
     * - Returns: Sleep quality score (0-100)
     */
    static func calculateSleepScoreAdjustment(sleepHours: Double) -> Double {
        switch sleepHours {
        case 7...9: return 85.0 // Optimal sleep
        case 6..<7, 9..<10: return 75.0 // Good sleep
        case 5..<6, 10..<11: return 60.0 // Adequate sleep
        default: return 40.0 // Poor sleep
        }
    }

    /**
     * Calculates workout load adjustment for a specific date
     *
     * - Parameter date: The date to calculate workout load for
     * - Returns: Workout load score adjustment (0-100)
     */
    static func calculateWorkoutLoadAdjustment(for date: Date) -> Double {
        let calendar = Calendar.current
        _ = calendar.startOfDay(for: date)

        // Check if there was intense workout on this day
        // This is a simplified version - could be enhanced with actual workout intensity data
        let hasIntenseWorkout = calendar.component(.weekday, from: date) != 1 &&
                               calendar.component(.weekday, from: date) != 7 // Weekdays more likely to have workouts

        return hasIntenseWorkout ? 70.0 : 80.0
    }

    // MARK: - VO2 Max Analysis

    /**
     * Gets VO2 Max color based on value
     *
     * - Parameter vo2Max: VO2 Max value
     * - Returns: Appropriate color for the VO2 Max level
     */
    static func getVO2MaxColor(for vo2Max: Double) -> String {
        switch vo2Max {
        case 50...: return "green"
        case 40..<50: return "blue"
        case 30..<40: return "orange"
        default: return "red"
        }
    }

    /**
     * Gets VO2 Max category description
     *
     * - Parameter vo2Max: VO2 Max value
     * - Returns: Category string (Excellent, Good, Fair, Poor)
     */
    static func getVO2MaxCategory(for vo2Max: Double) -> String {
        switch vo2Max {
        case 50...: return "Excellent"
        case 40..<50: return "Good"
        case 30..<40: return "Fair"
        default: return "Poor"
        }
    }

    /**
     * Gets VO2 Max description text
     *
     * - Parameter vo2Max: VO2 Max value
     * - Returns: Descriptive text for the VO2 Max level
     */
    static func getVO2MaxDescription(for vo2Max: Double) -> String {
        switch vo2Max {
        case 50...: return "Top athlete level"
        case 40..<50: return "Above average fitness"
        case 30..<40: return "Average fitness"
        default: return "Below average"
        }
    }

    /**
     * Determines if a VO2 Max value falls within a specific range
     *
     * - Parameters:
     *   - vo2Max: VO2 Max value to check
     *   - range: Range to check against
     * - Returns: Boolean indicating if value is in range
     */
    static func isVO2MaxInRange(_ vo2Max: Double, range: VO2MaxRange) -> Bool {
        switch range {
        case .poor: return vo2Max < 30
        case .fair: return vo2Max >= 30 && vo2Max < 40
        case .good: return vo2Max >= 40 && vo2Max < 50
        case .excellent: return vo2Max >= 50
        }
    }

    // MARK: - Score Color Helpers

    /**
     * Gets color for any score value (0-100)
     *
     * - Parameter score: Score value
     * - Returns: Color string for the score
     */
    static func getScoreColor(for score: Double) -> String {
        switch score {
        case 80...100: return "green"
        case 60..<80: return "blue"
        case 40..<60: return "orange"
        case 20..<40: return "orange"
        default: return "red"
        }
    }
}

