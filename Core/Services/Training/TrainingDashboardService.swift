import Foundation
import SwiftData

/**
 * Business logic service for Training Dashboard functionality.
 *
 * Handles all business operations for dashboard including session processing,
 * statistics calculations, cache management, and data aggregation.
 * Separates business logic from UI presentation for better maintainability.
 *
 * Features:
 * - Recent sessions computation and caching
 * - Weekly statistics calculations
 * - Streak calculations
 * - Data aggregation from multiple workout types
 * - Performance-optimized session filtering
 */
struct TrainingDashboardService: Sendable {

    // MARK: - Session Management

    /**
     * Computes recent workout sessions from all training types.
     *
     * - Parameters:
     *   - liftSessions: Array of lift sessions
     *   - cardioSessions: Array of cardio sessions
     *   - wodResults: Array of WOD results (optional)
     * - Returns: Array of recent WorkoutSessions sorted by date
     */
    static func computeRecentSessions(
        liftSessions: [LiftSession],
        cardioSessions: [CardioSession],
        wodResults: [WODResult] = []
    ) -> [any WorkoutSession] {
        var allSessions: [any WorkoutSession] = []

        // Add completed lift sessions
        allSessions.append(contentsOf: liftSessions.filter { $0.isCompleted })

        // Add completed cardio sessions
        allSessions.append(contentsOf: cardioSessions.filter { $0.isCompleted })

        // Sort by completion date and take recent 5
        return allSessions
            .sorted { session1, session2 in
                let date1 = session1.completedAt ?? session1.startDate
                let date2 = session2.completedAt ?? session2.startDate
                return date1 > date2
            }
            .prefix(5)
            .map { $0 }
    }

    /**
     * Filters sessions for current week.
     *
     * - Parameter sessions: Array of workout sessions
     * - Returns: Sessions completed this week
     */
    static func getThisWeekSessions(from sessions: [any WorkoutSession]) -> [any WorkoutSession] {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()

        return sessions.filter { session in
            let sessionDate = session.completedAt ?? session.startDate
            return sessionDate >= startOfWeek
        }
    }

    // MARK: - Statistics Calculations

    /**
     * Calculates weekly training statistics.
     *
     * - Parameter sessions: Array of recent workout sessions
     * - Returns: TrainingWeeklyStats with workouts, time, and streak data
     */
    static func calculateWeeklyStats(from sessions: [any WorkoutSession]) -> TrainingWeeklyStats {
        let thisWeekSessions = getThisWeekSessions(from: sessions)

        let totalWorkouts = thisWeekSessions.count
        let totalTime = thisWeekSessions.reduce(0) { total, session in
            total + session.sessionDuration
        }
        let streak = calculateWorkoutStreak(from: sessions)

        return TrainingWeeklyStats(
            workouts: totalWorkouts,
            totalTime: totalTime,
            streak: streak
        )
    }

    /**
     * Calculates workout streak (consecutive days with workouts).
     *
     * - Parameter sessions: Array of recent workout sessions
     * - Returns: Number of consecutive days with workouts
     */
    static func calculateWorkoutStreak(from sessions: [any WorkoutSession]) -> Int {
        let calendar = Calendar.current
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())

        // Check up to 30 days for performance
        while streak < 30 {
            let hasWorkout = sessions.contains { session in
                let sessionDate = calendar.startOfDay(for: session.completedAt ?? session.startDate)
                return sessionDate == currentDate
            }

            if hasWorkout {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }

        return streak
    }

    // MARK: - Formatting Utilities

    /**
     * Formats duration in human-readable format.
     *
     * - Parameter duration: Duration in seconds
     * - Returns: Formatted duration string (e.g., "1h 30m", "45m")
     */
    static func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    /**
     * Formats short duration for compact display.
     *
     * - Parameter duration: Duration in seconds
     * - Returns: Short formatted duration (e.g., "45m")
     */
    static func formatShortDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        return "\(minutes)m"
    }

    /**
     * Formats date relative to current time.
     *
     * - Parameter date: Date to format
     * - Returns: Relative date string (e.g., "2 days ago", "Yesterday")
     */
    static func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    /**
     * Formats date in abbreviated relative format.
     *
     * - Parameter date: Date to format
     * - Returns: Abbreviated relative date string
     */
    static func formatAbbreviatedRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    // MARK: - Workout Type Utilities

    /**
     * Gets appropriate icon for workout session type.
     *
     * - Parameter session: WorkoutSession to analyze
     * - Returns: SF Symbol name for the workout type
     */
    static func getWorkoutTypeIcon(for session: any WorkoutSession) -> String {
        if session is LiftSession { return "dumbbell.fill" }
        if session is CardioSession { return "heart.fill" }
        return "flame.fill" // Default for WOD or unknown types
    }

    /**
     * Gets appropriate color for workout session type.
     *
     * - Parameter session: WorkoutSession to analyze
     * - Returns: Color enum for the workout type
     */
    static func getWorkoutTypeColor(for session: any WorkoutSession) -> WorkoutTypeColor {
        if session is LiftSession { return .strength }
        if session is CardioSession { return .cardio }
        return .wod
    }

    // MARK: - Quick Workout Creation

    /**
     * Creates a quick lift workout template.
     *
     * - Returns: Configured LiftWorkout for immediate use
     */
    static func createQuickLiftWorkout() -> LiftWorkout {
        return LiftWorkout(
            name: "Quick Lift",
            isTemplate: false,
            isCustom: true
        )
    }

    // MARK: - Performance Optimization

    /**
     * Checks if session data needs refresh based on last update time.
     *
     * - Parameter lastUpdateTime: Timestamp of last cache update
     * - Returns: Boolean indicating if refresh is needed
     */
    static func shouldRefreshSessionData(lastUpdateTime: Date?) -> Bool {
        guard let lastUpdate = lastUpdateTime else { return true }

        // Refresh if data is older than 5 minutes
        let refreshInterval: TimeInterval = 300 // 5 minutes
        return Date().timeIntervalSince(lastUpdate) > refreshInterval
    }
}

// MARK: - Supporting Types

/**
 * Weekly training statistics model.
 */
struct TrainingWeeklyStats {
    let workouts: Int
    let totalTime: TimeInterval
    let streak: Int
}

/**
 * Workout type color enumeration for consistent theming.
 */
enum WorkoutTypeColor {
    case strength
    case cardio
    case wod
}