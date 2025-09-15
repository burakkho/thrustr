import SwiftUI
import Foundation

/**
 * ViewModel for OneRMCalculatorView with clean separation of concerns.
 *
 * Manages UI state and coordinates with OneRMCalculator service for business logic.
 * Follows modern @Observable pattern for iOS 17+ with automatic UI updates.
 */
@MainActor
@Observable
class OneRMCalculatorViewModel {

    // MARK: - UI State
    var weight = ""
    var reps = ""
    var selectedFormula: RMFormula = .brzycki
    var calculatedRM: OneRMResult?
    var errorMessage: String?
    var isCalculating = false

    // MARK: - Dependencies
    private let unitSettings: UnitSettings

    // MARK: - Computed Properties

    /**
     * Whether the form has valid inputs for calculation.
     */
    var isFormValid: Bool {
        guard let weightValue = OneRMCalculator.sanitizeWeightInput(weight),
              let repsValue = OneRMCalculator.sanitizeRepsInput(reps) else {
            return false
        }

        // Use service validation
        let weightKg = OneRMCalculator.convertToKilograms(weight: weightValue, unitSystem: unitSettings.unitSystem)
        let validation = OneRMCalculator.validateInputs(weight: weightKg, reps: repsValue)

        switch validation {
        case .valid:
            return true
        case .invalid:
            return false
        }
    }

    /**
     * Current unit display string for weight input.
     */
    var weightUnit: String {
        return unitSettings.unitSystem == .metric ? "kg" : "lb"
    }

    /**
     * Placeholder text for weight input based on unit system.
     */
    var weightPlaceholder: String {
        return unitSettings.unitSystem == .metric ? "70" : "155"
    }

    // MARK: - Initialization

    init(unitSettings: UnitSettings = UnitSettings.shared) {
        self.unitSettings = unitSettings
    }

    // Default initializer for @State initialization
    init() {
        self.unitSettings = UnitSettings.shared
    }

    // MARK: - Actions

    /**
     * Performs 1RM calculation using the service layer.
     */
    func calculateOneRM() {
        // Clear previous state
        clearResults()
        isCalculating = true

        // Perform calculation using service
        let result = OneRMCalculator.calculateFromStrings(
            weightInput: weight,
            repsInput: reps,
            formula: selectedFormula,
            unitSystem: unitSettings.unitSystem
        )

        // Update UI state based on result
        switch result {
        case .success(let oneRMResult):
            calculatedRM = oneRMResult
            errorMessage = nil
        case .failure(let error):
            calculatedRM = nil
            errorMessage = error.localizedDescription
        }

        isCalculating = false
    }

    /**
     * Clears all results and error states.
     */
    func clearResults() {
        calculatedRM = nil
        errorMessage = nil
    }

    /**
     * Resets the form to initial state.
     */
    func resetForm() {
        weight = ""
        reps = ""
        selectedFormula = .brzycki
        clearResults()
    }

    /**
     * Updates unit settings and recalculates if needed.
     */
    func updateUnitSettings(_ newSettings: UnitSettings) {
        // If we have a current result and units changed, recalculate
        if calculatedRM != nil && newSettings.unitSystem != unitSettings.unitSystem {
            // Note: UnitSettings is injected, so this would be handled externally
            // This method exists for future extensibility
            calculateOneRM()
        }
    }

    // MARK: - Helper Methods

    /**
     * Provides the current result value for external callbacks.
     * Used by OneRMSetupView for auto-filling fields.
     */
    func getCurrentResultValue() -> Double? {
        return calculatedRM?.value
    }

    /**
     * Gets formatted result string for display.
     */
    func getFormattedResult() -> String? {
        guard let result = calculatedRM else { return nil }
        return result.formattedValue
    }

    /**
     * Gets training percentages for the current result.
     */
    func getTrainingPercentages() -> [(percentage: Int, weight: Double)] {
        guard let result = calculatedRM else { return [] }
        return result.trainingPercentages
    }

    /**
     * Pre-fills the form with existing values.
     * Useful for editing existing 1RM calculations.
     */
    func prefillForm(weight: Double, reps: Int, formula: RMFormula = .brzycki) {
        self.weight = String(format: "%.1f", weight)
        self.reps = "\(reps)"
        self.selectedFormula = formula
        clearResults()
    }
}

// MARK: - Validation Extension

extension ValidationResult: Equatable {
    static func == (lhs: ValidationResult, rhs: ValidationResult) -> Bool {
        switch (lhs, rhs) {
        case (.valid, .valid):
            return true
        case (.invalid(let lhsError), .invalid(let rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }
}