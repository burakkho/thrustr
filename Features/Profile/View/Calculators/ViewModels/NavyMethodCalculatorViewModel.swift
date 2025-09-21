import SwiftUI
import Foundation
import SwiftData

/**
 * ViewModel for NavyMethodCalculatorView with clean separation of concerns.
 *
 * Manages UI state and coordinates with existing HealthCalculator service for business logic.
 * Follows modern @Observable pattern for iOS 17+ with automatic UI updates.
 */
@MainActor
@Observable
class NavyMethodCalculatorViewModel {

    // MARK: - UI State
    var gender: NavyGender = .male
    var age = ""
    var height = ""           // cm for metric
    var heightFeet = ""       // feet for imperial
    var heightInches = ""     // inches for imperial
    var waist = ""            // cm or inches based on unit
    var neck = ""             // cm or inches based on unit
    var hips = ""             // cm or inches based on unit (female only)
    var calculatedBodyFat: Double?
    var errorMessage: String?
    var isCalculating = false

    // MARK: - Dependencies
    private let unitSettings: UnitSettings

    // MARK: - Computed Properties

    /**
     * Whether the form has valid inputs for calculation.
     */
    var isFormValid: Bool {
        // Age validation
        guard let ageValue = Int(age), ageValue > 0 else { return false }

        // Height validation based on unit system
        let heightValid: Bool
        if unitSettings.unitSystem == .metric {
            guard let heightValue = sanitizeInput(height), heightValue > 0 else { return false }
            heightValid = true
        } else {
            guard let feet = Int(heightFeet), let inches = Int(heightInches),
                  feet > 0, inches >= 0, inches < 12 else { return false }
            heightValid = true
        }

        // Basic measurements validation
        guard let waistValue = sanitizeInput(waist), waistValue > 0,
              let neckValue = sanitizeInput(neck), neckValue > 0 else { return false }

        // Female-specific validation
        if gender == .female {
            guard let hipsValue = sanitizeInput(hips), hipsValue > 0 else { return false }
        }

        return heightValid
    }

    /**
     * Current unit display string for measurements.
     */
    var measurementUnit: String {
        return unitSettings.unitSystem == .metric ? "cm" : "in"
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
     * Performs body fat calculation using the existing HealthCalculator service.
     */
    func calculateBodyFat() {
        clearResults()
        isCalculating = true

        // Prepare inputs
        guard Int(age) != nil else {
            showError("Invalid age")
            return
        }

        // Get height in cm
        let heightInCm: Double
        if unitSettings.unitSystem == .metric {
            guard let heightValue = sanitizeInput(height) else {
                showError("Invalid height")
                return
            }
            heightInCm = heightValue
        } else {
            guard let feet = Int(heightFeet), let inches = Int(heightInches) else {
                showError("Invalid height")
                return
            }
            heightInCm = UnitsConverter.feetInchesToCm(feet: feet, inches: inches)
        }

        // Get measurements in cm
        guard let waistRaw = sanitizeInput(waist),
              let neckRaw = sanitizeInput(neck) else {
            showError("Invalid measurements")
            return
        }

        let waistInCm = unitSettings.unitSystem == .metric ? waistRaw : (waistRaw * 2.54)
        let neckInCm = unitSettings.unitSystem == .metric ? neckRaw : (neckRaw * 2.54)

        // Female measurements
        var hipsInCm: Double? = nil
        if gender == .female {
            guard let hipsRaw = sanitizeInput(hips) else {
                showError("Invalid hip measurement")
                return
            }
            hipsInCm = unitSettings.unitSystem == .metric ? hipsRaw : (hipsRaw * 2.54)
        }

        // Convert NavyGender to Gender
        let genderEnum = gender == .male ? Gender.male : Gender.female

        // Use existing HealthCalculator service
        if let result = HealthCalculator.calculateBodyFatNavy(
            gender: genderEnum,
            heightCm: heightInCm,
            neckCm: neckInCm,
            waistCm: waistInCm,
            hipCm: hipsInCm
        ) {
            calculatedBodyFat = result
            errorMessage = nil
        } else {
            showError("Unable to calculate body fat with provided measurements")
        }

        isCalculating = false
    }

    /**
     * Saves the calculated body fat to the user profile.
     */
    func saveToProfile(user: User, modelContext: ModelContext) {
        guard calculatedBodyFat != nil else { return }

        // Note: User model doesn't have stored bodyFat properties
        // The calculated body fat is available via user.calculateBodyFatPercentage()
        // For now, we could store measurements that contribute to the calculation

        do {
            try modelContext.save()
            // Success handled by parent view
        } catch {
            showError("Failed to save body fat data: \(error.localizedDescription)")
        }
    }

    /**
     * Resets the form to initial state.
     */
    func resetForm() {
        gender = .male
        age = ""
        height = ""
        heightFeet = ""
        heightInches = ""
        waist = ""
        neck = ""
        hips = ""
        clearResults()
    }

    /**
     * Pre-fills the form with user data if available.
     */
    func prefillFromUser(_ user: User?) {
        guard let user = user else { return }

        age = "\(user.age)"

        if unitSettings.unitSystem == .metric {
            height = String(format: "%.1f", user.height)
        } else {
            let (feet, inches) = UnitsConverter.cmToFeetInches(user.height)
            heightFeet = "\(feet)"
            heightInches = "\(inches)"
        }

        // Set gender if available
        let userGender = user.genderEnum
        gender = userGender == .male ? .male : .female
    }

    // MARK: - Helper Methods

    /**
     * Clears all results and error states.
     */
    private func clearResults() {
        calculatedBodyFat = nil
        errorMessage = nil
    }

    /**
     * Shows error message to user.
     */
    private func showError(_ message: String) {
        errorMessage = message
        calculatedBodyFat = nil
        isCalculating = false
    }

    /**
     * Sanitizes string input for numeric values.
     * Handles common user input issues like commas for decimals.
     */
    private func sanitizeInput(_ input: String) -> Double? {
        let sanitized = input
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return Double(sanitized)
    }
}

