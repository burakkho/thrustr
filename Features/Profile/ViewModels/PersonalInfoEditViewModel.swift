import SwiftUI
import SwiftData
import Foundation

/**
 * ViewModel for PersonalInfoEditView with comprehensive form management and validation.
 *
 * Manages UI state for personal information editing while coordinating with UserService
 * and HealthCalculator for data persistence and metric calculations. Follows clean
 * architecture principles with proper separation of concerns.
 *
 * Responsibilities:
 * - Form state management and validation
 * - User data persistence coordination
 * - Calculated metrics preview (BMR, TDEE, etc.)
 * - Loading states and error handling
 */
@MainActor
@Observable
class PersonalInfoEditViewModel {

    // MARK: - Observable Properties

    var name: String = ""
    var age: String = ""
    var height: String = ""
    var currentWeight: String = ""
    var selectedGender: Gender = .male
    var selectedFitnessGoal: FitnessGoal = .maintain
    var selectedActivityLevel: ActivityLevel = .moderate

    var isLoading = false
    var showingSaveAlert = false
    var errorMessage: String?
    // MARK: - Dependencies

    private let userService = UserService()
    private let healthCalculator = HealthCalculator.self

    // MARK: - Computed Properties

    /**
     * Validates form data for completeness and correctness.
     */
    var isFormValid: Bool {
        guard !name.isEmpty,
              !age.isEmpty,
              !height.isEmpty,
              !currentWeight.isEmpty else {
            return false
        }

        guard let ageValue = Int(age), ageValue > 0,
              let heightValue = Double(height), heightValue > 0,
              let weightValue = Double(currentWeight), weightValue > 0 else {
            return false
        }

        return true
    }

    /**
     * Preview calculations for user feedback before saving.
     */
    var previewCalculations: PreviewCalculations? {
        guard isFormValid,
              let ageValue = Int(age),
              let heightValue = Double(height),
              let weightValue = Double(currentWeight) else {
            return nil
        }

        let bmr = healthCalculator.calculateBMR(
            gender: selectedGender,
            age: ageValue,
            heightCm: heightValue,
            weightKg: weightValue,
            bodyFatPercentage: nil
        )

        let tdee = healthCalculator.calculateTDEE(
            bmr: bmr,
            activityLevel: selectedActivityLevel
        )

        let dailyCalories = healthCalculator.calculateDailyCalories(
            tdee: tdee,
            goal: selectedFitnessGoal
        )

        let macros = healthCalculator.calculateMacros(
            weightKg: weightValue,
            dailyCalories: dailyCalories,
            goal: selectedFitnessGoal
        )

        return PreviewCalculations(
            bmr: bmr,
            tdee: tdee,
            dailyCalories: dailyCalories,
            protein: macros.protein,
            carbs: macros.carbs,
            fat: macros.fat
        )
    }

    // MARK: - User Data Management

    /**
     * Loads existing user data into form fields.
     *
     * - Parameter user: User profile to load data from
     */
    func loadUserData(_ user: User?) {
        guard let user = user else {
            clearForm()
            return
        }

        name = user.name
        age = String(user.age)
        height = String(Int(user.height))
        currentWeight = String(Int(user.currentWeight))
        selectedGender = user.genderEnum
        selectedFitnessGoal = user.fitnessGoalEnum
        selectedActivityLevel = user.activityLevelEnum
    }

    /**
     * Saves user data with validation and error handling.
     *
     * - Parameters:
     *   - user: User profile to update
     *   - modelContext: SwiftData context for persistence
     */
    func saveUserData(_ user: User?, modelContext: ModelContext) {
        guard let user = user, isFormValid else {
            showError("Invalid form data")
            return
        }

        isLoading = true
        clearError()

        // Validate input ranges
        guard let ageValue = Int(age),
              let heightValue = Double(height),
              let weightValue = Double(currentWeight) else {
            showError("Please enter valid numeric values")
            return
        }

        // Validate reasonable ranges
        guard ageValue >= 13 && ageValue <= 120 else {
            showError("Age must be between 13 and 120 years")
            return
        }

        guard heightValue >= 100 && heightValue <= 250 else {
            showError("Height must be between 100 and 250 cm")
            return
        }

        guard weightValue >= 30 && weightValue <= 300 else {
            showError("Weight must be between 30 and 300 kg")
            return
        }

        // Update user data
        user.name = name
        user.age = ageValue
        user.height = heightValue
        user.currentWeight = weightValue
        user.gender = selectedGender.rawValue
        user.fitnessGoal = selectedFitnessGoal.rawValue
        user.activityLevel = selectedActivityLevel.rawValue

        // Recalculate derived metrics
        user.calculateMetrics()

        // Save to database
        do {
            try modelContext.save()
            isLoading = false
            showingSaveAlert = true
        } catch {
            showError("Failed to save user data: \(error.localizedDescription)")
        }
    }

    // MARK: - Form Management

    /**
     * Clears all form fields to default values.
     */
    func clearForm() {
        name = ""
        age = ""
        height = ""
        currentWeight = ""
        selectedGender = .male
        selectedFitnessGoal = .maintain
        selectedActivityLevel = .moderate
        clearError()
    }

    /**
     * Validates individual field input as user types.
     *
     * - Parameters:
     *   - field: Field type being validated
     *   - value: Current field value
     * - Returns: Validation message or nil if valid
     */
    func validateField(_ field: FormField, value: String) -> String? {
        switch field {
        case .name:
            return value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Name cannot be empty" : nil

        case .age:
            guard let ageValue = Int(value) else {
                return "Please enter a valid age"
            }
            if ageValue < 13 || ageValue > 120 {
                return "Age must be between 13 and 120"
            }
            return nil

        case .height:
            guard let heightValue = Double(value) else {
                return "Please enter a valid height"
            }
            if heightValue < 100 || heightValue > 250 {
                return "Height must be between 100-250 cm"
            }
            return nil

        case .weight:
            guard let weightValue = Double(value) else {
                return "Please enter a valid weight"
            }
            if weightValue < 30 || weightValue > 300 {
                return "Weight must be between 30-300 kg"
            }
            return nil
        }
    }

    // MARK: - Error Handling

    /**
     * Shows error message to user.
     *
     * - Parameter message: Error message to display
     */
    private func showError(_ message: String) {
        errorMessage = message
        isLoading = false
    }

    /**
     * Clears current error state.
     */
    func clearError() {
        errorMessage = nil
    }

    // MARK: - Helper Methods

    /**
     * Formats preview values for display with proper units and formatting.
     */
    func formatPreviewValue(_ value: Double, type: PreviewValueType) -> String {
        switch type {
        case .calories:
            return "\(Int(value))"
        case .macroGrams:
            return String(format: "%.1f", value)
        case .percentage:
            return String(format: "%.1f%%", value)
        }
    }
}

// MARK: - Supporting Types

/**
 * Preview calculations structure for form display.
 */
struct PreviewCalculations {
    let bmr: Double
    let tdee: Double
    let dailyCalories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
}

/**
 * Form field types for validation.
 */
enum FormField {
    case name
    case age
    case height
    case weight
}

/**
 * Preview value formatting types.
 */
enum PreviewValueType {
    case calories
    case macroGrams
    case percentage
}