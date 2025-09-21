import Foundation

// MARK: - Calories Validation Rules
class CaloriesValidator: ValidationRule {
    private let minCalories: Int = 1    // 1 calorie minimum
    private let maxCalories: Int = 5000 // 5000 calories maximum (extreme cases)

    func validate(_ input: String) -> ValidationResult {
        // Check if input is empty
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .invalid(message: LocalizationKeys.Validation.caloriesRequired.localized)
        }

        // Try to parse as Integer
        guard let calories = Int(input) else {
            return .invalid(message: LocalizationKeys.Validation.caloriesInvalidFormat.localized)
        }

        // Check if calories is positive
        guard calories > 0 else {
            return .invalid(message: LocalizationKeys.Validation.caloriesMustBePositive.localized)
        }

        // Check minimum calories
        guard calories >= minCalories else {
            return .invalid(message: LocalizationKeys.Validation.caloriesMinimum.localized)
        }

        // Check maximum calories
        guard calories <= maxCalories else {
            return .invalid(message: LocalizationKeys.Validation.caloriesMaximum.localized)
        }

        return .valid
    }
}

// MARK: - Workout-Specific Calories Validator
class WorkoutCaloriesValidator: ValidationRule {
    private let workoutDurationMinutes: Int
    private let userWeight: Double?

    init(workoutDurationMinutes: Int, userWeight: Double? = nil) {
        self.workoutDurationMinutes = workoutDurationMinutes
        self.userWeight = userWeight
    }

    func validate(_ input: String) -> ValidationResult {
        // First run basic validation
        let basicValidator = CaloriesValidator()
        let basicResult = basicValidator.validate(input)

        guard basicResult.isValid else {
            return basicResult
        }

        guard let calories = Int(input) else {
            return .invalid(message: LocalizationKeys.Validation.caloriesInvalidFormat.localized)
        }

        // Calculate realistic calorie range based on workout duration
        let estimatedCalories = estimateCaloriesForWorkout()
        let lowerBound = Int(Double(estimatedCalories) * 0.3) // 30% of estimate
        let upperBound = Int(Double(estimatedCalories) * 3.0) // 300% of estimate

        // Soft validation - warn if calories seem unrealistic
        if calories < lowerBound {
            // Could return a warning type if needed
            return .valid // For now, just accept but could add warning
        }

        if calories > upperBound {
            return .invalid(message: LocalizationKeys.Validation.caloriesUnrealistic.localized)
        }

        return .valid
    }

    private func estimateCaloriesForWorkout() -> Int {
        // Basic estimation: 5-15 calories per minute depending on intensity
        let baseCaloriesPerMinute = 8.0
        let estimatedCalories = Double(workoutDurationMinutes) * baseCaloriesPerMinute

        // Adjust for user weight if available
        if let weight = userWeight {
            let weightFactor = weight / 70.0 // Normalize to 70kg
            return Int(estimatedCalories * weightFactor)
        }

        return Int(estimatedCalories)
    }
}

// MARK: - Convenience Extensions
extension CaloriesValidator {
    static func validateCalories(_ input: String, workoutDurationMinutes: Int? = nil, userWeight: Double? = nil) -> (isValid: Bool, calories: Int?, errorMessage: String?) {
        let validator: ValidationRule

        if let duration = workoutDurationMinutes {
            validator = WorkoutCaloriesValidator(workoutDurationMinutes: duration, userWeight: userWeight)
        } else {
            validator = CaloriesValidator()
        }

        let result = validator.validate(input)

        let calories: Int?
        if result.isValid {
            calories = Int(input)
        } else {
            calories = nil
        }

        return (result.isValid, calories, result.errorMessage)
    }

    static func estimateCaloriesForCardio(durationMinutes: Int, averageHeartRate: Int? = nil, userWeight: Double? = nil) -> Int {
        // Basic MET calculation
        var met: Double = 6.0 // Default moderate intensity

        // Adjust MET based on heart rate if available
        if let hr = averageHeartRate {
            switch hr {
            case ..<100:
                met = 3.5 // Light intensity
            case 100..<140:
                met = 6.0 // Moderate intensity
            case 140..<170:
                met = 8.5 // Vigorous intensity
            case 170...:
                met = 11.0 // Very vigorous intensity
            default:
                met = 6.0
            }
        }

        // Calculate calories: METs × weight (kg) × time (hours)
        let weight = userWeight ?? 70.0 // Default to 70kg
        let hours = Double(durationMinutes) / 60.0
        let calories = met * weight * hours

        return Int(calories)
    }

    static func formatCalories(_ calories: Int) -> String {
        if calories < 1000 {
            return "\(calories) \(CommonKeys.Units.calories.localized)"
        } else {
            let rounded = Double(calories) / 1000.0
            return String(format: "%.1f k\(CommonKeys.Units.calories.localized)", rounded)
        }
    }
}