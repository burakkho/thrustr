import Foundation
import SwiftData

/**
 * WOD Display Service for formatting and filtering logic.
 *
 * Handles all business logic for WOD display, formatting, and filtering.
 * Follows clean architecture principles by separating business logic from UI.
 */
struct WODDisplayService: Sendable {

    // MARK: - WOD Filtering

    /**
     * Filters WODs based on category and search text.
     *
     * - Parameters:
     *   - customWODs: Custom WODs collection
     *   - benchmarkWODs: Benchmark WODs collection
     *   - category: Selected category filter
     *   - searchText: Search query text
     * - Returns: Filtered array of WODs with performance limits
     */
    static func filterWODs(
        customWODs: [WOD],
        benchmarkWODs: [WOD],
        category: WODCategory,
        searchText: String
    ) -> [WOD] {
        // History is handled separately - return empty for WOD list
        guard category != .history else { return [] }

        let categoryWODs: [WOD]

        switch category {
        case .custom:
            categoryWODs = customWODs
        case .girls, .heroes, .opens:
            categoryWODs = benchmarkWODs.filter { wod in
                wod.category == category.rawValue
            }
        case .history:
            categoryWODs = []
        }

        guard !searchText.isEmpty else {
            return Array(categoryWODs.prefix(20))
        }

        let searchResults = categoryWODs.filter { wod in
            wod.name.localizedCaseInsensitiveContains(searchText) ||
            (wod.movements?.contains { $0.name.localizedCaseInsensitiveContains(searchText) } ?? false)
        }

        return Array(searchResults.prefix(15))
    }

    // MARK: - WOD Type Formatting

    /**
     * Formats WOD type with time cap information.
     *
     * - Parameter wod: WOD to format
     * - Returns: Formatted WOD type string
     */
    static func formatWODType(_ wod: WOD) -> String {
        switch wod.wodType {
        case .forTime:
            if let timeCap = wod.timeCap {
                return String(format: TrainingKeys.WorkoutTypes.forTimeWithCap.localized, "\(timeCap)")
            }
            return TrainingKeys.WorkoutTypes.forTime.localized
        case .amrap:
            return String(format: TrainingKeys.WorkoutTypes.amrapMinutes.localized, "\(wod.timeCap ?? 20)")
        case .emom:
            return String(format: TrainingKeys.WorkoutTypes.emomMinutes.localized, "\(wod.timeCap ?? 10)")
        case .custom:
            return TrainingKeys.WorkoutTypes.customFormat.localized
        }
    }

    // MARK: - Movement Formatting

    /**
     * Formats WOD movements for display with truncation.
     *
     * - Parameter wod: WOD with movements to format
     * - Returns: Formatted movements string
     */
    static func formatMovements(_ wod: WOD) -> String {
        guard let movements = wod.movements, !movements.isEmpty else {
            return "No movements"
        }

        let limitedMovements = Array(movements.prefix(3))
        let movementNames = limitedMovements.map { $0.name }.joined(separator: ", ")

        if movements.count > 3 {
            return "\(movementNames) +\(movements.count - 3) more"
        }

        return movementNames
    }

    // MARK: - Statistics Building

    /**
     * Builds comprehensive WOD statistics for display.
     *
     * - Parameters:
     *   - wod: WOD to build stats for
     *   - wodResults: All WOD results for PR calculation
     * - Returns: Array of formatted workout statistics
     */
    static func buildWODStats(for wod: WOD, wodResults: [WODResult]) -> [WorkoutStat] {
        var stats: [WorkoutStat] = []

        // Movement count
        stats.append(WorkoutStat(
            label: TrainingKeys.WOD.movements.localized,
            value: "\(wod.movements?.count ?? 0)",
            icon: "figure.strengthtraining.traditional"
        ))

        // Time/Rounds
        if let timeCap = wod.timeCap {
            stats.append(WorkoutStat(
                label: wod.wodType == .amrap ? TrainingKeys.Cardio.duration.localized : TrainingKeys.WOD.forTime.localized,
                value: "\(timeCap) \(TrainingKeys.Units.minutes.localized)",
                icon: "clock"
            ))
        } else if let rounds = wod.rounds {
            stats.append(WorkoutStat(
                label: TrainingKeys.WOD.rounds.localized,
                value: "\(rounds)",
                icon: "repeat"
            ))
        }

        // Personal Record
        if let bestResult = wodResults.filter({ $0.wodId == wod.id }).sorted(by: { $0.score > $1.score }).first {
            stats.append(WorkoutStat(
                label: TrainingKeys.TestResults.personalRecord.localized,
                value: formatScore(bestResult.score, type: wod.wodType),
                icon: "trophy.fill"
            ))
        }

        return stats
    }

    // MARK: - Secondary Info Building

    /**
     * Builds secondary information array for WOD display.
     *
     * - Parameters:
     *   - wod: WOD to build info for
     *   - wodResults: All WOD results for last session calculation
     * - Returns: Array of secondary information strings
     */
    static func buildSecondaryInfo(for wod: WOD, wodResults: [WODResult]) -> [String] {
        var info: [String] = []

        // Difficulty
        if let difficulty = wod.difficulty {
            info.append(difficulty.capitalized)
        }

        // Last performed
        if let lastResult = wodResults.filter({ $0.wodId == wod.id }).sorted(by: { $0.completedAt > $1.completedAt }).first {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .short
            info.append("\(TrainingKeys.Cardio.lastSession.localized): \(formatter.localizedString(for: lastResult.completedAt, relativeTo: Date()))")
        }

        // Category
        if !wod.isCustom {
            info.append(wod.category.capitalized)
        }

        return info
    }

    // MARK: - Score Formatting

    /**
     * Formats score based on WOD type.
     *
     * - Parameters:
     *   - score: Raw score value
     *   - type: WOD type for formatting
     * - Returns: Formatted score string
     */
    static func formatScore(_ score: Double, type: WODType) -> String {
        switch type {
        case .forTime:
            let minutes = Int(score) / 60
            let seconds = Int(score) % 60
            return String(format: "%d:%02d", minutes, seconds)
        case .amrap:
            return "\(Int(score)) \(TrainingKeys.WOD.rounds.localized)"
        default:
            return "\(Int(score))"
        }
    }

    // MARK: - WOD Start Logic

    /**
     * Prepares WOD for starting by setting default weights.
     *
     * - Parameters:
     *   - wod: WOD to prepare
     *   - userGender: User's gender for RX weight calculation
     * - Returns: Result indicating success or failure
     */
    static func prepareWODForStart(wod: WOD, userGender: String?) -> Result<Void, WODStartError> {
        guard let movements = wod.movements else {
            return .failure(.noMovements)
        }

        for movement in movements {
            if let rxWeight = movement.rxWeight(for: userGender) {
                // Parse weight value from string (e.g., "43kg" -> 43)
                let numbers = rxWeight.filter { "0123456789.".contains($0) }
                if let weight = Double(numbers) {
                    movement.userWeight = weight
                    movement.isRX = true
                }
            }
        }

        return .success(())
    }
}

// MARK: - Supporting Types

/**
 * Errors that can occur when starting a WOD.
 */
enum WODStartError: LocalizedError {
    case noMovements
    case invalidWeights

    var errorDescription: String? {
        switch self {
        case .noMovements:
            return "WOD has no movements defined"
        case .invalidWeights:
            return "Failed to set default weights"
        }
    }
}