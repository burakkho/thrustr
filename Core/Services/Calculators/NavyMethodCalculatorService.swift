import Foundation
import SwiftData

/**
 * Navy Method Body Fat Calculator Service with comprehensive business logic.
 *
 * This service handles all business logic for Navy Method body fat calculations,
 * including input validation, unit conversions, error handling, and integration
 * with the core HealthCalculator service. Follows clean architecture principles
 * by separating business logic from UI concerns.
 *
 * Key Features:
 * - Complete input validation and sanitization
 * - Automatic unit conversion (metric ↔ imperial)
 * - Gender-specific calculation handling
 * - Comprehensive error handling with typed errors
 * - Integration with existing HealthCalculator service
 * - Profile data pre-filling and saving capabilities
 */
struct NavyMethodCalculatorService: Sendable {

    // MARK: - Core Calculation

    /**
     * Performs Navy Method body fat calculation with comprehensive validation.
     *
     * Handles all input processing, validation, unit conversion, and delegates
     * actual calculation to HealthCalculator service. Returns typed result
     * with specific error information for UI feedback.
     *
     * - Parameters:
     *   - gender: NavyGender (male/female)
     *   - age: Age in years (for validation)
     *   - height: Height value (cm for metric, ignored for imperial)
     *   - heightFeet: Feet portion of height (imperial only)
     *   - heightInches: Inches portion of height (imperial only)
     *   - waist: Waist circumference (cm/inches based on unit system)
     *   - neck: Neck circumference (cm/inches based on unit system)
     *   - hips: Hip circumference (cm/inches, female only)
     *   - unitSystem: Metric or Imperial measurement system
     * - Returns: Result with calculated body fat percentage or specific error
     */
    static func calculateBodyFat(
        gender: NavyGender,
        age: Int,
        height: Double,
        heightFeet: Int?,
        heightInches: Int?,
        waist: Double,
        neck: Double,
        hips: Double?,
        unitSystem: UnitSystem
    ) -> Result<Double, NavyCalculationError> {

        // MARK: - Input Validation

        // Age validation
        guard age > 0, age < 150 else {
            return .failure(.invalidAge("Age must be between 1 and 149 years"))
        }

        // Height validation and conversion to cm
        let heightInCm: Double
        if unitSystem == .metric {
            guard height > 0, height >= 100, height <= 250 else {
                return .failure(.invalidHeight("Height must be between 100-250 cm"))
            }
            heightInCm = height
        } else {
            guard let feet = heightFeet, let inches = heightInches,
                  feet > 0, feet <= 8,
                  inches >= 0, inches < 12 else {
                return .failure(.invalidHeight("Height must be between 3'0\" and 8'11\""))
            }
            heightInCm = feetInchesToCm(feet: feet, inches: inches)
        }

        // Waist validation and conversion to cm
        let waistInCm: Double
        if unitSystem == .metric {
            guard waist > 0, waist >= 50, waist <= 200 else {
                return .failure(.invalidWaist("Waist must be between 50-200 cm"))
            }
            waistInCm = waist
        } else {
            guard waist > 0, waist >= 20, waist <= 80 else {
                return .failure(.invalidWaist("Waist must be between 20-80 inches"))
            }
            waistInCm = waist * 2.54
        }

        // Neck validation and conversion to cm
        let neckInCm: Double
        if unitSystem == .metric {
            guard neck > 0, neck >= 20, neck <= 60 else {
                return .failure(.invalidNeck("Neck must be between 20-60 cm"))
            }
            neckInCm = neck
        } else {
            guard neck > 0, neck >= 8, neck <= 24 else {
                return .failure(.invalidNeck("Neck must be between 8-24 inches"))
            }
            neckInCm = neck * 2.54
        }

        // Female-specific hip validation and conversion
        var hipsInCm: Double? = nil
        if gender == .female {
            guard let hipsValue = hips else {
                return .failure(.invalidHips("Hip measurement is required for females"))
            }

            if unitSystem == .metric {
                guard hipsValue > 0, hipsValue >= 60, hipsValue <= 200 else {
                    return .failure(.invalidHips("Hips must be between 60-200 cm"))
                }
                hipsInCm = hipsValue
            } else {
                guard hipsValue > 0, hipsValue >= 24, hipsValue <= 80 else {
                    return .failure(.invalidHips("Hips must be between 24-80 inches"))
                }
                hipsInCm = hipsValue * 2.54
            }
        }

        // MARK: - Business Logic Validation

        // Ensure measurements make physiological sense
        guard waistInCm > neckInCm else {
            return .failure(.invalidMeasurements("Waist measurement must be larger than neck measurement"))
        }

        if let hipsInCm = hipsInCm {
            guard hipsInCm >= waistInCm else {
                return .failure(.invalidMeasurements("Hip measurement should typically be larger than or equal to waist measurement"))
            }
        }

        // MARK: - Calculation

        // Convert NavyGender to core Gender enum
        let coreGender: Gender = (gender == .male) ? .male : .female

        // Delegate to existing HealthCalculator service
        guard let result = HealthCalculator.calculateBodyFatNavy(
            gender: coreGender,
            heightCm: heightInCm,
            neckCm: neckInCm,
            waistCm: waistInCm,
            hipCm: hipsInCm
        ) else {
            return .failure(.calculationFailed("Unable to calculate body fat with provided measurements. Please verify measurements are accurate."))
        }

        // Final validation of result
        guard result >= 2.0, result <= 50.0 else {
            return .failure(.calculationFailed("Calculated result is outside normal range. Please verify measurements."))
        }

        return .success(result)
    }

    // MARK: - User Profile Integration

    /**
     * Pre-fills calculation inputs from user profile data.
     *
     * - Parameters:
     *   - user: User profile with existing data
     *   - unitSystem: Current unit system preference
     * - Returns: Pre-filled calculation inputs
     */
    static func prefillFromUser(
        _ user: User,
        unitSystem: UnitSystem
    ) -> NavyCalculationInputs {

        let gender: NavyGender = (user.genderEnum == .male) ? .male : .female

        let (heightValue, heightFeet, heightInches) = convertHeightForDisplay(
            heightCm: user.height,
            unitSystem: unitSystem
        )

        return NavyCalculationInputs(
            gender: gender,
            age: user.age,
            height: heightValue,
            heightFeet: heightFeet,
            heightInches: heightInches,
            waist: 0.0, // User doesn't store body measurements
            neck: 0.0,  // User doesn't store body measurements
            hips: 0.0   // User doesn't store body measurements
        )
    }

    /**
     * Saves calculated body fat result to user profile.
     *
     * Note: Current User model doesn't have body fat storage.
     * This method is prepared for future enhancement.
     *
     * - Parameters:
     *   - bodyFat: Calculated body fat percentage
     *   - user: User to update
     *   - modelContext: SwiftData context
     * - Returns: Result indicating success or failure
     */
    static func saveToProfile(
        bodyFat: Double,
        user: User,
        modelContext: ModelContext
    ) -> Result<Void, NavyCalculationError> {

        // Store body fat in multiple ways for comprehensive tracking

        // 1. Create a BodyMeasurement entry for tracking history
        let bodyFatMeasurement = BodyMeasurement(
            type: "body_fat",
            value: bodyFat,
            date: Date(),
            notes: "Calculated using Navy Method"
        )
        bodyFatMeasurement.user = user
        modelContext.insert(bodyFatMeasurement)

        // 2. Also create a WeightEntry with body fat for weight tracking integration
        let weightEntry = WeightEntry(
            weight: user.currentWeight,
            date: Date(),
            notes: "Navy Method body fat measurement",
            bodyFat: bodyFat
        )
        weightEntry.user = user
        modelContext.insert(weightEntry)

        Logger.info("Saved Navy Method body fat calculation: \(bodyFat)% as BodyMeasurement and WeightEntry")

        do {
            try modelContext.save()
            return .success(())
        } catch {
            return .failure(.saveFailed("Failed to save body fat data: \(error.localizedDescription)"))
        }
    }

    // MARK: - Helper Methods

    /**
     * Sanitizes string input for numeric conversion.
     * Handles common user input issues like commas for decimals.
     */
    static func sanitizeNumericInput(_ input: String) -> Double? {
        let sanitized = input
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return Double(sanitized)
    }

    /**
     * Converts height from cm to appropriate display format based on unit system.
     */
    private static func convertHeightForDisplay(
        heightCm: Double,
        unitSystem: UnitSystem
    ) -> (height: Double, feet: Int?, inches: Int?) {

        if unitSystem == .metric {
            return (height: heightCm, feet: nil, inches: nil)
        } else {
            let (feet, inches) = cmToFeetInches(heightCm)
            return (height: 0.0, feet: feet, inches: inches)
        }
    }

    /**
     * Converts feet and inches to centimeters.
     */
    private static func feetInchesToCm(feet: Int, inches: Int) -> Double {
        let totalInches = Double(feet * 12 + inches)
        return totalInches * 2.54
    }

    /**
     * Converts centimeters to feet and inches.
     */
    private static func cmToFeetInches(_ cm: Double) -> (Int, Int) {
        let totalInches = cm / 2.54
        let feet = Int(totalInches / 12)
        let inches = Int(totalInches.truncatingRemainder(dividingBy: 12))
        return (feet, inches)
    }
}

// MARK: - Supporting Types

/**
 * Calculation input structure for Navy Method.
 */
struct NavyCalculationInputs: Sendable {
    let gender: NavyGender
    let age: Int
    let height: Double
    let heightFeet: Int?
    let heightInches: Int?
    let waist: Double
    let neck: Double
    let hips: Double
}

/**
 * Navy Method calculation error types with specific validation messages.
 */
enum NavyCalculationError: LocalizedError, Sendable {
    case invalidAge(String)
    case invalidHeight(String)
    case invalidWaist(String)
    case invalidNeck(String)
    case invalidHips(String)
    case invalidMeasurements(String)
    case calculationFailed(String)
    case saveFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidAge(let message),
             .invalidHeight(let message),
             .invalidWaist(let message),
             .invalidNeck(let message),
             .invalidHips(let message),
             .invalidMeasurements(let message),
             .calculationFailed(let message),
             .saveFailed(let message):
            return message
        }
    }

    var localizedDescription: String {
        return errorDescription ?? "Unknown calculation error"
    }
}