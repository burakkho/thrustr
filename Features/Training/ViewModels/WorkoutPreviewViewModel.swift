import SwiftUI
import SwiftData
import Foundation

/**
 * ViewModel for WorkoutPreviewView with clean separation of concerns.
 *
 * Manages workout preview data, previous session analytics, and data formatting.
 * Coordinates with LiftSessionService for business logic.
 */
@MainActor
@Observable
class WorkoutPreviewViewModel {

    // MARK: - State
    var previousSessions: [LiftSession] = []
    var isLoading = false
    var errorMessage: String?
    var showingWarmupTips = false
    
    // MARK: - Dependencies
    private let unitSettings: UnitSettings
    
    // MARK: - Private Properties
    private var currentWorkout: LiftWorkout?
    private var modelContext: ModelContext?
    
    // MARK: - Computed Properties
    
    /**
     * Total sets across all exercises in the workout.
     */
    var totalSets: Int {
        guard let workout = currentWorkout else { return 0 }
        return (workout.exercises ?? []).reduce(0) { $0 + $1.targetSets }
    }
    
    /**
     * Whether there are any previous sessions for this workout.
     */
    var hasPreviousSessions: Bool {
        !previousSessions.isEmpty
    }
    
    /**
     * Most recent session if available.
     */
    var lastSession: LiftSession? {
        previousSessions.first
    }
    
    /**
     * Previous sessions count for display.
     */
    var previousSessionsCount: Int {
        previousSessions.count
    }
    
    // MARK: - Initialization
    
    init(unitSettings: UnitSettings = UnitSettings.shared) {
        self.unitSettings = unitSettings
    }
    
    // MARK: - Public Methods
    
    /**
     * Sets the workout context and loads previous sessions.
     */
    func setWorkout(_ workout: LiftWorkout, modelContext: ModelContext) {
        self.currentWorkout = workout
        self.modelContext = modelContext
        loadPreviousSessions()
    }
    
    /**
     * Toggles warmup tips visibility.
     */
    func toggleWarmupTips() {
        showingWarmupTips.toggle()
    }
    
    /**
     * Refreshes previous sessions data.
     */
    func refreshPreviousSessions() {
        loadPreviousSessions()
    }
    
    /**
     * Gets formatted workout duration estimate.
     */
    func getFormattedDuration() -> String {
        guard let workout = currentWorkout else { return "0 min" }
        return "\(workout.estimatedDuration ?? 45) min"
    }
    
    /**
     * Gets exercise count for display.
     */
    func getExerciseCount() -> String {
        guard let workout = currentWorkout else { return "0" }
        return "\((workout.exercises ?? []).count)"
    }
    
    /**
     * Gets formatted total sets for display.
     */
    func getFormattedTotalSets() -> String {
        return "\(totalSets)"
    }
    
    /**
     * Gets formatted last session duration.
     */
    func getFormattedLastSessionDuration() -> String? {
        guard let session = lastSession else { return nil }
        return formatDuration(TimeInterval(session.duration))
    }
    
    /**
     * Gets formatted last session volume.
     */
    func getFormattedLastSessionVolume() -> String? {
        guard let session = lastSession else { return nil }
        return UnitsFormatter.formatWeight(kg: session.totalVolume, system: unitSettings.unitSystem)
    }
    
    /**
     * Gets formatted relative date for last session.
     */
    func getFormattedLastSessionDate() -> String? {
        guard let session = lastSession else { return nil }
        return formatRelativeDate(session.completedAt ?? session.startDate)
    }
    
    /**
     * Gets formatted previous sessions count.
     */
    func getFormattedSessionsCount() -> String {
        return "\(previousSessionsCount)"
    }
    
    /**
     * Resets all state.
     */
    func reset() {
        previousSessions.removeAll()
        isLoading = false
        errorMessage = nil
        showingWarmupTips = false
        currentWorkout = nil
        modelContext = nil
    }
    
    // MARK: - Private Methods
    
    private func loadPreviousSessions() {
        guard let workout = currentWorkout,
              let modelContext = modelContext else {
            Logger.warning("Cannot load previous sessions: missing workout or context")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let workoutName = workout.name
        let descriptor = FetchDescriptor<LiftSession>(
            predicate: #Predicate<LiftSession> { session in
                session.workoutName == workoutName && session.isCompleted == true
            },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        
        do {
            previousSessions = try modelContext.fetch(descriptor)
            Logger.info("Loaded \(previousSessions.count) previous sessions for workout: \(workoutName)")
        } catch {
            Logger.error("Failed to load previous sessions: \(error)")
            errorMessage = "Failed to load workout history"
            previousSessions = []
        }
        
        isLoading = false
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Performance Metrics Extension

extension WorkoutPreviewViewModel {
    
    /**
     * Gets performance comparison with previous session.
     */
    func getPerformanceComparison() -> PerformanceComparison? {
        guard previousSessions.count >= 2 else { return nil }
        
        let current = previousSessions[0]
        let previous = previousSessions[1]
        
        let volumeChange = current.totalVolume - previous.totalVolume
        let durationChange = current.duration - previous.duration
        
        return PerformanceComparison(
            volumeChange: volumeChange,
            durationChange: TimeInterval(durationChange),
            isImprovement: volumeChange > 0
        )
    }
    
    /**
     * Gets workout frequency insights.
     */
    func getWorkoutFrequency() -> WorkoutFrequency? {
        guard previousSessions.count >= 2 else { return nil }
        
        let sessions = Array(previousSessions.prefix(5)) // Last 5 sessions
        let dates = sessions.compactMap { $0.completedAt ?? $0.startDate }
        
        guard dates.count >= 2 else { return nil }
        
        let intervals = zip(dates.dropFirst(), dates).map { $0.timeIntervalSince($1) }
        let averageInterval = intervals.reduce(0, +) / Double(intervals.count)
        let averageDays = averageInterval / (24 * 60 * 60)
        
        return WorkoutFrequency(
            averageDaysBetween: averageDays,
            totalSessions: sessions.count,
            lastSessionDate: dates.first ?? Date()
        )
    }
}

// MARK: - Supporting Types

/**
 * Performance comparison data.
 */
struct PerformanceComparison {
    let volumeChange: Double
    let durationChange: TimeInterval
    let isImprovement: Bool
    
    var formattedVolumeChange: String {
        let sign = volumeChange > 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", volumeChange))kg"
    }
    
    var formattedDurationChange: String {
        let minutes = Int(abs(durationChange)) / 60
        let sign = durationChange > 0 ? "+" : "-"
        return "\(sign)\(minutes)m"
    }
}

/**
 * Workout frequency insights.
 */
struct WorkoutFrequency {
    let averageDaysBetween: Double
    let totalSessions: Int
    let lastSessionDate: Date
    
    var frequency: String {
        switch averageDaysBetween {
        case 0..<2:
            return "Very Frequent"
        case 2..<4:
            return "Frequent"
        case 4..<7:
            return "Regular"
        case 7..<14:
            return "Weekly"
        default:
            return "Occasional"
        }
    }
    
    var formattedFrequency: String {
        if averageDaysBetween < 1 {
            return "Daily"
        } else {
            return "Every \(Int(averageDaysBetween.rounded())) days"
        }
    }
}