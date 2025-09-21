import SwiftUI
import SwiftData
import Foundation

/**
 * ViewModel for OneRMSetupView with multi-step form management.
 *
 * Manages complex setup flow state and coordinates with OneRMCalculator service.
 * Extends the functionality of OneRMCalculatorViewModel for setup-specific needs.
 */
@MainActor
@Observable
class OneRMSetupViewModel {

    // MARK: - Setup State
    var currentStep = 0
    var squatRM = ""
    var benchRM = ""
    var deadliftRM = ""
    var ohpRM = ""
    var calculatedWeights: [String: Double] = [:]
    var showingStartingWeights = false
    var showingCalculator = false
    var errorMessage: String?

    // MARK: - Dependencies
    private let unitSettings: UnitSettings

    // MARK: - Constants
    let exercises = [
        ("squat", "Squat", "figure.strengthtraining.traditional"),
        ("bench", "Bench Press", "figure.strengthtraining.traditional"),
        ("deadlift", "Deadlift", "figure.strengthtraining.functional"),
        ("ohp", "Overhead Press", "figure.arms.open")
    ]

    // MARK: - Computed Properties

    /**
     * Current exercise information for the active step.
     */
    var currentExercise: (key: String, name: String, icon: String)? {
        guard currentStep < exercises.count else { return nil }
        return exercises[currentStep]
    }

    /**
     * Whether the current step has valid input.
     */
    var isCurrentStepValid: Bool {
        let currentValue = currentRMBinding.wrappedValue
        return !currentValue.isEmpty &&
               OneRMCalculator.sanitizeWeightInput(currentValue) != nil &&
               (OneRMCalculator.sanitizeWeightInput(currentValue) ?? 0) > 0
    }

    /**
     * Binding for the current step's RM field.
     */
    var currentRMBinding: Binding<String> {
        switch currentStep {
        case 0: return Binding(get: { self.squatRM }, set: { self.squatRM = $0 })
        case 1: return Binding(get: { self.benchRM }, set: { self.benchRM = $0 })
        case 2: return Binding(get: { self.deadliftRM }, set: { self.deadliftRM = $0 })
        case 3: return Binding(get: { self.ohpRM }, set: { self.ohpRM = $0 })
        default: return Binding(get: { "" }, set: { _ in })
        }
    }

    /**
     * Whether all steps are completed.
     */
    var isSetupComplete: Bool {
        return currentStep >= exercises.count
    }

    // MARK: - Initialization

    init(unitSettings: UnitSettings = UnitSettings.shared) {
        self.unitSettings = unitSettings
    }

    // MARK: - Step Navigation

    /**
     * Proceeds to the next step or triggers calculation.
     */
    func nextStep() {
        guard isCurrentStepValid else { return }

        if currentStep < exercises.count - 1 {
            withAnimation {
                currentStep += 1
            }
        } else {
            // Calculate starting weights and show preview
            calculateStartingWeights()
            showingStartingWeights = true
        }
    }

    /**
     * Goes back to the previous step.
     */
    func previousStep() {
        withAnimation {
            currentStep = max(0, currentStep - 1)
        }
    }

    // MARK: - Calculation Logic

    /**
     * Calculates starting weights using OneRMCalculator service.
     */
    func calculateStartingWeights() {
        // Validate all inputs first
        guard let squat = OneRMCalculator.sanitizeWeightInput(squatRM),
              let bench = OneRMCalculator.sanitizeWeightInput(benchRM),
              let deadlift = OneRMCalculator.sanitizeWeightInput(deadliftRM),
              let ohp = OneRMCalculator.sanitizeWeightInput(ohpRM) else {
            errorMessage = "Invalid weight inputs"
            return
        }

        // Convert to kg if using imperial
        let squatKg = OneRMCalculator.convertToKilograms(weight: squat, unitSystem: unitSettings.unitSystem)
        let benchKg = OneRMCalculator.convertToKilograms(weight: bench, unitSystem: unitSettings.unitSystem)
        let deadliftKg = OneRMCalculator.convertToKilograms(weight: deadlift, unitSystem: unitSettings.unitSystem)
        let ohpKg = OneRMCalculator.convertToKilograms(weight: ohp, unitSystem: unitSettings.unitSystem)

        // Calculate starting weights (65% of 1RM for most exercises)
        let startingWeightsKg = [
            "squat": squatKg * 0.65,
            "bench": benchKg * 0.65,
            "row": benchKg * 0.80, // Row starts at 80% of bench
            "deadlift": deadliftKg * 0.65,
            "ohp": ohpKg * 0.65
        ]

        // Convert back to user's preferred unit system
        calculatedWeights = startingWeightsKg.mapValues { weightKg in
            OneRMCalculator.convertFromKilograms(resultKg: weightKg, unitSystem: unitSettings.unitSystem)
        }

        errorMessage = nil
    }

    /**
     * Saves 1RM data to user profile using OneRMCalculator service.
     */
    func saveAndStartProgram(user: User, modelContext: ModelContext) -> Result<Void, OneRMSetupError> {
        // Validate all inputs
        guard let squat = OneRMCalculator.sanitizeWeightInput(squatRM),
              let bench = OneRMCalculator.sanitizeWeightInput(benchRM),
              let deadlift = OneRMCalculator.sanitizeWeightInput(deadliftRM),
              let ohp = OneRMCalculator.sanitizeWeightInput(ohpRM) else {
            return .failure(.invalidInputs)
        }

        // Convert to kg for storage (internal storage is always metric)
        let squatKg = OneRMCalculator.convertToKilograms(weight: squat, unitSystem: unitSettings.unitSystem)
        let benchKg = OneRMCalculator.convertToKilograms(weight: bench, unitSystem: unitSettings.unitSystem)
        let deadliftKg = OneRMCalculator.convertToKilograms(weight: deadlift, unitSystem: unitSettings.unitSystem)
        let ohpKg = OneRMCalculator.convertToKilograms(weight: ohp, unitSystem: unitSettings.unitSystem)

        // Save to user model
        user.squatOneRM = squatKg
        user.benchPressOneRM = benchKg
        user.deadliftOneRM = deadliftKg
        user.overheadPressOneRM = ohpKg
        user.oneRMLastUpdated = Date()

        // Save to context
        do {
            try modelContext.save()
            Logger.success("1RM data saved successfully")
            return .success(())
        } catch {
            Logger.error("Failed to save 1RM data: \(error)")
            return .failure(.saveFailed)
        }
    }

    /**
     * Pre-fills form from user data if available.
     */
    func prefillFromUser(_ user: User?) {
        guard let user = user else { return }

        // Convert from kg (internal storage) to user's preferred unit
        if let squatOneRM = user.squatOneRM, squatOneRM > 0 {
            let squatInUserUnit = OneRMCalculator.convertFromKilograms(
                resultKg: squatOneRM,
                unitSystem: unitSettings.unitSystem
            )
            squatRM = String(format: "%.1f", squatInUserUnit)
        }

        if let benchPressOneRM = user.benchPressOneRM, benchPressOneRM > 0 {
            let benchInUserUnit = OneRMCalculator.convertFromKilograms(
                resultKg: benchPressOneRM,
                unitSystem: unitSettings.unitSystem
            )
            benchRM = String(format: "%.1f", benchInUserUnit)
        }

        if let deadliftOneRM = user.deadliftOneRM, deadliftOneRM > 0 {
            let deadliftInUserUnit = OneRMCalculator.convertFromKilograms(
                resultKg: deadliftOneRM,
                unitSystem: unitSettings.unitSystem
            )
            deadliftRM = String(format: "%.1f", deadliftInUserUnit)
        }

        if let overheadPressOneRM = user.overheadPressOneRM, overheadPressOneRM > 0 {
            let ohpInUserUnit = OneRMCalculator.convertFromKilograms(
                resultKg: overheadPressOneRM,
                unitSystem: unitSettings.unitSystem
            )
            ohpRM = String(format: "%.1f", ohpInUserUnit)
        }
    }

    /**
     * Resets the setup form to initial state.
     */
    func resetForm() {
        currentStep = 0
        squatRM = ""
        benchRM = ""
        deadliftRM = ""
        ohpRM = ""
        calculatedWeights = [:]
        showingStartingWeights = false
        showingCalculator = false
        errorMessage = nil
    }

    /**
     * Sets the current exercise's RM value (used by calculator callback).
     */
    func setCurrentExerciseRM(_ value: Double) {
        let formattedValue = String(format: "%.1f", value)
        currentRMBinding.wrappedValue = formattedValue
    }
}

// MARK: - Supporting Types

/**
 * Errors that can occur during OneRM setup.
 */
enum OneRMSetupError: LocalizedError {
    case invalidInputs
    case saveFailed
    case calculationFailed

    var errorDescription: String? {
        switch self {
        case .invalidInputs:
            return "One or more weight inputs are invalid"
        case .saveFailed:
            return "Failed to save 1RM data to profile"
        case .calculationFailed:
            return "Failed to calculate starting weights"
        }
    }
}