import Foundation

/**
 * Session management service for Cardio Live Tracking.
 *
 * Handles session formatting, split management, and workout data processing
 * utilities. Provides clean separation between UI logic and session calculations.
 *
 * Features:
 * - Time and pace formatting
 * - Split time calculations
 * - Session validation
 * - Performance metrics formatting
 * - Unit system conversions
 */
struct CardioSessionService: Sendable {

    // MARK: - Time Formatting

    /**
     * Formats split time in MM:SS format.
     *
     * - Parameter time: Time interval in seconds
     * - Returns: Formatted time string (e.g., "04:32")
     */
    static func formatSplitTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /**
     * Formats workout duration in HH:MM:SS format.
     *
     * - Parameter duration: Total duration in seconds
     * - Returns: Formatted duration string
     */
    static func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    /**
     * Formats pace with proper unit system.
     *
     * - Parameters:
     *   - pace: Pace in minutes per kilometer
     *   - unitSystem: Unit system for conversion
     * - Returns: Formatted pace string
     */
    static func formatPace(_ pace: Double, unitSystem: UnitSystem) -> String {
        return UnitsFormatter.formatDetailedPace(minPerKm: pace, system: unitSystem)
    }

    // MARK: - Split Management

    /**
     * Validates if split data is complete and valid.
     *
     * - Parameter split: Split data to validate
     * - Returns: Boolean indicating if split is valid for display
     */
    static func isValidSplit(_ split: Any) -> Bool {
        // This would validate split has required data
        // Implementation depends on split data structure
        return true // Placeholder
    }

    /**
     * Calculates split pace from distance and time.
     *
     * - Parameters:
     *   - distance: Split distance in meters
     *   - time: Split time in seconds
     * - Returns: Pace in minutes per kilometer
     */
    static func calculateSplitPace(distance: Double, time: TimeInterval) -> Double {
        guard distance > 0 && time > 0 else { return 0.0 }
        let distanceKm = distance / 1000.0
        let timeMinutes = time / 60.0
        return timeMinutes / distanceKm
    }

    /**
     * Formats split distance with unit system.
     *
     * - Parameters:
     *   - splitNumber: Split sequence number (1-based)
     *   - unitSystem: Unit system for formatting
     * - Returns: Formatted split distance string
     */
    static func formatSplitDistance(splitNumber: Int, unitSystem: UnitSystem) -> String {
        return UnitsFormatter.formatSplitDistance(splitNumber: splitNumber, system: unitSystem)
    }

    // MARK: - Performance Analysis

    /**
     * Calculates average pace for multiple splits.
     *
     * - Parameter splits: Array of split data with pace information
     * - Returns: Average pace in minutes per kilometer
     */
    static func calculateAveragePace(splits: [(pace: Double, distance: Double)]) -> Double {
        guard !splits.isEmpty else { return 0.0 }

        let totalDistance = splits.reduce(0.0) { $0 + $1.distance }
        let weightedPaceSum = splits.reduce(0.0) { result, split in
            result + (split.pace * split.distance)
        }

        guard totalDistance > 0 else { return 0.0 }
        return weightedPaceSum / totalDistance
    }

    /**
     * Identifies if a split represents a personal record.
     *
     * - Parameters:
     *   - currentPace: Current split pace
     *   - historicalPaces: Historical pace data for comparison
     * - Returns: Boolean indicating if this is a PR
     */
    static func isPersonalRecord(currentPace: Double, historicalPaces: [Double]) -> Bool {
        guard !historicalPaces.isEmpty else { return true } // First attempt is always PR
        let bestPace = historicalPaces.min() ?? Double.greatestFiniteMagnitude
        return currentPace < bestPace
    }

    // MARK: - Data Validation

    /**
     * Validates session data completeness.
     *
     * - Parameters:
     *   - duration: Session duration
     *   - distance: Total distance (optional for indoor)
     *   - calories: Calories burned
     * - Returns: Boolean indicating if session data is valid
     */
    static func isValidSessionData(duration: TimeInterval, distance: Double?, calories: Int) -> Bool {
        // Minimum 30 seconds for a valid session
        guard duration >= 30 else { return false }

        // Calories should be reasonable (not negative or extremely high)
        guard calories >= 0 && calories <= 5000 else { return false }

        // Distance validation for outdoor workouts
        if let distance = distance {
            guard distance >= 0 && distance <= 100000 else { return false } // Max 100km
        }

        return true
    }

    /**
     * Sanitizes session data for storage.
     *
     * - Parameters:
     *   - duration: Raw duration value
     *   - distance: Raw distance value
     *   - calories: Raw calories value
     * - Returns: Sanitized session data tuple
     */
    static func sanitizeSessionData(
        duration: TimeInterval,
        distance: Double?,
        calories: Int
    ) -> (duration: TimeInterval, distance: Double?, calories: Int) {
        let cleanDuration = max(0, min(86400, duration)) // 0 to 24 hours
        let cleanDistance = distance.map { max(0, min(100000, $0)) } // 0 to 100km
        let cleanCalories = max(0, min(5000, calories)) // 0 to 5000 kcal

        return (cleanDuration, cleanDistance, cleanCalories)
    }

    // MARK: - Session Creation Helpers

    /**
     * Generates session summary for display.
     *
     * - Parameters:
     *   - duration: Session duration
     *   - distance: Total distance
     *   - calories: Calories burned
     *   - averagePace: Average pace
     *   - unitSystem: Unit system for formatting
     * - Returns: Formatted session summary
     */
    static func generateSessionSummary(
        duration: TimeInterval,
        distance: Double?,
        calories: Int,
        averagePace: Double?,
        unitSystem: UnitSystem
    ) -> SessionSummary {
        return SessionSummary(
            formattedDuration: formatDuration(duration),
            formattedDistance: distance.map { UnitsFormatter.formatDistance(meters: $0, system: unitSystem) },
            formattedCalories: "\(calories)",
            formattedAveragePace: averagePace.map { formatPace($0, unitSystem: unitSystem) },
            isValid: isValidSessionData(duration: duration, distance: distance, calories: calories)
        )
    }

    // MARK: - Utility Methods

    /**
     * Calculates session intensity based on heart rate data.
     *
     * - Parameters:
     *   - averageHeartRate: Average heart rate during session
     *   - maxHeartRate: User's maximum heart rate
     * - Returns: Intensity percentage (0.0 to 1.0)
     */
    static func calculateSessionIntensity(averageHeartRate: Int, maxHeartRate: Int) -> Double {
        guard maxHeartRate > 0 && averageHeartRate > 0 else { return 0.0 }
        let intensity = Double(averageHeartRate) / Double(maxHeartRate)
        return max(0.0, min(1.0, intensity))
    }

    /**
     * Estimates calories per minute based on activity type and intensity.
     *
     * - Parameters:
     *   - activityType: Type of cardio activity
     *   - intensity: Session intensity (0.0 to 1.0)
     *   - userWeight: User weight in kg
     * - Returns: Estimated calories per minute
     */
    static func estimateCaloriesPerMinute(
        activityType: String,
        intensity: Double,
        userWeight: Double
    ) -> Double {
        // Base metabolic equivalent (MET) values for different activities
        let baseMET: Double = switch activityType.lowercased() {
        case "running": 8.0
        case "cycling": 6.0
        case "swimming": 7.0
        case "rowing": 7.0
        default: 5.0 // Generic cardio
        }

        let adjustedMET = baseMET * (0.5 + intensity * 0.5) // Scale by intensity
        return (adjustedMET * userWeight * 3.5) / 200.0 // Standard MET calculation
    }
}

// MARK: - Supporting Types

/**
 * Session summary data structure for display.
 */
struct SessionSummary {
    let formattedDuration: String
    let formattedDistance: String?
    let formattedCalories: String
    let formattedAveragePace: String?
    let isValid: Bool
}

/**
 * Split performance data for analysis.
 */
struct SplitPerformance {
    let splitNumber: Int
    let distance: Double
    let time: TimeInterval
    let pace: Double
    let isPersonalRecord: Bool
    let heartRate: Int?
}

/**
 * Session analysis result for comprehensive feedback.
 */
struct SessionAnalysis {
    let summary: SessionSummary
    let intensity: Double
    let estimatedCaloriesPerMinute: Double
    let personalRecords: [SplitPerformance]
    let recommendations: [String]
}