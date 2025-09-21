import SwiftUI
import SwiftData
import Foundation

/**
 * ViewModel for LiftResultEntryView with complex state management.
 *
 * Manages exercise results, calculations, and coordinates with LiftSessionService.
 * Follows modern @Observable pattern for iOS 17+ with automatic UI updates.
 */
@MainActor
@Observable
class LiftResultEntryViewModel {

    // MARK: - State
    var exerciseResults: [UUID: ExerciseResult] = [:]
    var totalWeight: Double = 0
    var bestSetWeight: Double = 0
    var notes: String = ""
    var showingSaveConfirmation = false
    var errorMessage: String?
    var isLoading = false

    // MARK: - Dependencies
    private let unitSettings: UnitSettings

    // MARK: - Computed Properties

    /**
     * Whether there are any valid results to save.
     */
    var hasValidResults: Bool {
        return totalWeight > 0
    }

    /**
     * Current total number of completed reps.
     */
    var totalReps: Int {
        calculateTotalReps()
    }

    /**
     * Current total number of completed sets.
     */
    var totalSets: Int {
        calculateCompletedSets()
    }

    // MARK: - Initialization

    init(unitSettings: UnitSettings = UnitSettings.shared) {
        self.unitSettings = unitSettings
    }

    // MARK: - Initialization Methods

    /**
     * Initializes exercise results for the given lift.
     */
    func initializeExerciseResults(for lift: Lift) {
        exerciseResults.removeAll()

        for exercise in lift.exercises ?? [] {
            var result = ExerciseResult()
            for _ in 0..<lift.sets {
                result.sets.append(ExerciseResult.SetResult(
                    weight: exercise.targetWeight ?? 0,
                    reps: lift.reps,
                    isCompleted: false
                ))
            }
            exerciseResults[exercise.id] = result
        }

        updateTotals()
    }

    // MARK: - Calculation Methods

    /**
     * Updates all totals based on current exercise results.
     */
    func updateTotals() {
        var total: Double = 0
        var bestSet: Double = 0

        for result in exerciseResults.values {
            for set in result.sets where set.isCompleted {
                let setVolume = set.weight * Double(set.reps)
                total += setVolume
                bestSet = max(bestSet, set.weight)
            }
        }

        totalWeight = total
        bestSetWeight = bestSet
    }

    /**
     * Calculates total completed reps across all exercises.
     */
    private func calculateTotalReps() -> Int {
        var total = 0
        for result in exerciseResults.values {
            for set in result.sets where set.isCompleted {
                total += set.reps
            }
        }
        return total
    }

    /**
     * Calculates total completed sets across all exercises.
     */
    private func calculateCompletedSets() -> Int {
        var total = 0
        for result in exerciseResults.values {
            total += result.sets.filter { $0.isCompleted }.count
        }
        return total
    }

    // MARK: - Save Operations

    /**
     * Saves the lift result using LiftSessionService.
     */
    func saveResult(for lift: Lift, user: User?, modelContext: ModelContext) -> Result<LiftResult, LiftResultError> {
        guard hasValidResults else {
            return .failure(.noValidResults)
        }

        guard let user = user else {
            return .failure(.noUser)
        }

        isLoading = true
        errorMessage = nil

        // Create lift result
        let result = LiftResult(
            totalWeight: totalWeight,
            bestSet: bestSetWeight,
            totalReps: totalReps,
            totalSets: totalSets,
            notes: notes.isEmpty ? nil : notes
        )

        result.lift = lift
        result.user = user

        // Save using ModelContext
        modelContext.insert(result)

        do {
            try modelContext.save()
            Logger.success("Lift result saved successfully")
            showingSaveConfirmation = true
            isLoading = false
            return .success(result)
        } catch {
            Logger.error("Failed to save lift result: \(error)")
            errorMessage = "Failed to save result: \(error.localizedDescription)"
            isLoading = false
            return .failure(.saveFailed(error))
        }
    }

    /**
     * Checks if the result includes a new personal record.
     */
    func isNewPersonalRecord(for lift: Lift) -> Bool {
        guard let currentPR = lift.personalRecord?.bestSet else {
            // If no previous PR exists, any completed set is a new record
            return bestSetWeight > 0
        }

        return bestSetWeight > currentPR
    }

    // MARK: - Formatting Methods

    /**
     * Formats total volume for display.
     */
    func formattedTotalVolume() -> String {
        return UnitsFormatter.formatVolume(kg: totalWeight, system: unitSettings.unitSystem)
    }

    /**
     * Formats best set weight for display.
     */
    func formattedBestSetWeight() -> String {
        return UnitsFormatter.formatWeight(kg: bestSetWeight, system: unitSettings.unitSystem)
    }

    /**
     * Formats current PR for display if available.
     */
    func formattedCurrentPR(for lift: Lift) -> String? {
        guard let pr = lift.personalRecord?.bestSet else { return nil }
        return UnitsFormatter.formatWeight(kg: pr, system: unitSettings.unitSystem)
    }

    // MARK: - Helper Methods

    /**
     * Resets all state to initial values.
     */
    func reset() {
        exerciseResults.removeAll()
        totalWeight = 0
        bestSetWeight = 0
        notes = ""
        showingSaveConfirmation = false
        errorMessage = nil
        isLoading = false
    }

    /**
     * Gets exercise result binding for a specific exercise.
     */
    func exerciseResultBinding(for exerciseId: UUID) -> Binding<ExerciseResult> {
        return Binding(
            get: { self.exerciseResults[exerciseId] ?? ExerciseResult() },
            set: {
                self.exerciseResults[exerciseId] = $0
                self.updateTotals()
            }
        )
    }
}

// MARK: - Supporting Types

/**
 * Exercise result data structure.
 */
struct ExerciseResult {
    var sets: [SetResult] = []

    struct SetResult {
        var weight: Double = 0
        var reps: Int = 0
        var isCompleted: Bool = false
    }
}

/**
 * Errors that can occur during lift result operations.
 */
enum LiftResultError: LocalizedError {
    case noValidResults
    case noUser
    case saveFailed(Error)

    var errorDescription: String? {
        switch self {
        case .noValidResults:
            return "No valid exercise results to save"
        case .noUser:
            return "User information not available"
        case .saveFailed(let error):
            return "Failed to save result: \(error.localizedDescription)"
        }
    }
}