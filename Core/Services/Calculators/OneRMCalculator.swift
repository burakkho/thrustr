import Foundation

/**
 * One Rep Max (1RM) calculation utilities with comprehensive input validation.
 *
 * This utility struct provides scientifically-backed 1RM calculations using established
 * formulas (Brzycki, Epley, Lander) with proper input validation and unit conversion.
 * Integrates with existing RMFormula enum for calculation logic.
 *
 * Supported calculations:
 * - 1RM estimation using multiple formulas
 * - Input validation (weight, reps, formula selection)
 * - Unit conversion (metric ↔ imperial)
 * - Result formatting with proper bounds checking
 */
struct OneRMCalculator: Sendable {

    // MARK: - Validation Constants
    private static let minWeight: Double = 1.0        // Minimum 1kg/2.2lbs
    private static let maxWeight: Double = 500.0      // Maximum 500kg/1100lbs
    private static let minReps: Int = 1               // Minimum 1 rep
    private static let maxReps: Int = 15              // Maximum 15 reps (formula accuracy)
    private static let minResult: Double = 1.0        // Minimum result 1kg
    private static let maxResult: Double = 600.0      // Maximum result 600kg

    // MARK: - Input Validation

    /**
     * Validates 1RM calculation inputs for safety and accuracy.
     *
     * - Parameters:
     *   - weight: Weight lifted in kilograms (after unit conversion)
     *   - reps: Number of repetitions performed
     * - Returns: ValidationResult indicating success or specific error
     */
    static func validateInputs(weight: Double, reps: Int) -> OneRMValidationResult {
        // Weight validation
        guard weight >= minWeight else {
            return .invalid(.weightTooLow)
        }

        guard weight <= maxWeight else {
            return .invalid(.weightTooHigh)
        }

        // Reps validation
        guard reps >= minReps else {
            return .invalid(.repsTooLow)
        }

        guard reps <= maxReps else {
            return .invalid(.repsTooHigh)
        }

        return .valid
    }

    // MARK: - Unit Conversion

    /**
     * Converts weight from imperial to metric if needed.
     *
     * - Parameters:
     *   - weight: Weight value in user's preferred unit
     *   - unitSystem: Current unit system (metric or imperial)
     * - Returns: Weight in kilograms for calculation
     */
    static func convertToKilograms(weight: Double, unitSystem: UnitSystem) -> Double {
        switch unitSystem {
        case .metric:
            return weight  // Already in kg
        case .imperial:
            return UnitsConverter.lbsToKg(weight)
        }
    }

    /**
     * Converts result back to user's preferred unit system.
     *
     * - Parameters:
     *   - resultKg: 1RM result in kilograms
     *   - unitSystem: Target unit system for display
     * - Returns: Result in user's preferred unit
     */
    static func convertFromKilograms(resultKg: Double, unitSystem: UnitSystem) -> Double {
        switch unitSystem {
        case .metric:
            return resultKg  // Keep in kg
        case .imperial:
            return UnitsConverter.kgToLbs(resultKg)
        }
    }

    // MARK: - Input Sanitization

    /**
     * Sanitizes string input for weight values.
     * Handles common user input issues like commas for decimals.
     *
     * - Parameter input: Raw string input from user
     * - Returns: Sanitized double value or nil if invalid
     */
    static func sanitizeWeightInput(_ input: String) -> Double? {
        let sanitized = input
            .replacingOccurrences(of: ",", with: ".")  // Handle European decimal notation
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return Double(sanitized)
    }

    /**
     * Sanitizes string input for rep values.
     *
     * - Parameter input: Raw string input from user
     * - Returns: Sanitized integer value or nil if invalid
     */
    static func sanitizeRepsInput(_ input: String) -> Int? {
        let sanitized = input.trimmingCharacters(in: .whitespacesAndNewlines)
        return Int(sanitized)
    }

    // MARK: - Core Calculation

    /**
     * Calculates 1RM using the specified formula with full validation.
     *
     * - Parameters:
     *   - weight: Weight lifted in user's unit system
     *   - reps: Number of repetitions performed
     *   - formula: Selected RMFormula for calculation
     *   - unitSystem: User's preferred unit system
     * - Returns: CalculationResult with result or error details
     */
    static func calculateOneRM(
        weight: Double,
        reps: Int,
        formula: RMFormula,
        unitSystem: UnitSystem
    ) -> OneRMCalculationResult {
        // Convert to metric for calculation
        let weightKg = convertToKilograms(weight: weight, unitSystem: unitSystem)

        // Validate inputs
        let validation = validateInputs(weight: weightKg, reps: reps)
        if case .invalid(let error) = validation {
            return .failure(error)
        }

        // Perform calculation using existing RMFormula
        let resultKg = formula.calculate(weight: weightKg, reps: reps)

        // Validate result bounds
        guard resultKg >= minResult && resultKg <= maxResult else {
            return .failure(.resultOutOfBounds)
        }

        // Convert back to user's unit system
        let resultInUserUnits = convertFromKilograms(resultKg: resultKg, unitSystem: unitSystem)

        return .success(OneRMResult(
            value: resultInUserUnits,
            formula: formula,
            originalWeight: weight,
            originalReps: reps,
            unitSystem: unitSystem
        ))
    }

    // MARK: - Convenience Methods

    /**
     * Calculates 1RM from string inputs with automatic sanitization.
     *
     * - Parameters:
     *   - weightInput: Raw weight string from user input
     *   - repsInput: Raw reps string from user input
     *   - formula: Selected RMFormula for calculation
     *   - unitSystem: User's preferred unit system
     * - Returns: CalculationResult with result or error details
     */
    static func calculateFromStrings(
        weightInput: String,
        repsInput: String,
        formula: RMFormula,
        unitSystem: UnitSystem
    ) -> OneRMCalculationResult {
        // Sanitize inputs
        guard let weight = sanitizeWeightInput(weightInput) else {
            return .failure(.invalidWeightInput)
        }

        guard let reps = sanitizeRepsInput(repsInput) else {
            return .failure(.invalidRepsInput)
        }

        return calculateOneRM(weight: weight, reps: reps, formula: formula, unitSystem: unitSystem)
    }

    // MARK: - Result Formatting

    /**
     * Formats 1RM result for display with appropriate precision.
     *
     * - Parameters:
     *   - result: OneRMResult to format
     * - Returns: Formatted string with value and unit
     */
    static func formatResult(_ result: OneRMResult) -> String {
        let precision = result.unitSystem == .metric ? 1 : 0  // 1 decimal for kg, whole for lbs
        let unit = result.unitSystem == .metric ? "kg" : "lb"

        return String(format: "%.\(precision)f %@", result.value, unit)
    }

    /**
     * Generates percentage-based training recommendations.
     *
     * - Parameter oneRM: Calculated 1RM value
     * - Returns: Array of training percentages with recommended weights
     */
    static func generateTrainingPercentages(oneRM: Double) -> [(percentage: Int, weight: Double)] {
        let percentages = [95, 90, 85, 80, 75, 70, 65, 60]
        return percentages.map { percentage in
            (percentage: percentage, weight: oneRM * Double(percentage) / 100.0)
        }
    }
}

// MARK: - Supporting Types

/**
 * Result type for input validation.
 */
enum OneRMValidationResult {
    case valid
    case invalid(OneRMValidationError)
}

/**
 * Specific validation errors with user-friendly descriptions.
 */
enum OneRMValidationError: Error, LocalizedError {
    case weightTooLow
    case weightTooHigh
    case repsTooLow
    case repsTooHigh
    case invalidWeightInput
    case invalidRepsInput
    case resultOutOfBounds

    var errorDescription: String? {
        switch self {
        case .weightTooLow:
            return "Weight must be at least 1 kg (2.2 lbs)"
        case .weightTooHigh:
            return "Weight cannot exceed 500 kg (1100 lbs)"
        case .repsTooLow:
            return "Reps must be at least 1"
        case .repsTooHigh:
            return "Reps cannot exceed 15 for accurate 1RM calculation"
        case .invalidWeightInput:
            return "Please enter a valid weight"
        case .invalidRepsInput:
            return "Please enter a valid number of reps"
        case .resultOutOfBounds:
            return "Calculated result is outside reasonable bounds"
        }
    }
}

/**
 * Result type for 1RM calculations.
 */
enum OneRMCalculationResult {
    case success(OneRMResult)
    case failure(OneRMValidationError)
}

/**
 * Complete 1RM calculation result with context.
 */
struct OneRMResult: Sendable {
    let value: Double           // 1RM in user's preferred unit
    let formula: RMFormula      // Formula used for calculation
    let originalWeight: Double  // Original weight input
    let originalReps: Int       // Original reps input
    let unitSystem: UnitSystem  // Unit system used

    /**
     * Training percentages based on this 1RM.
     */
    var trainingPercentages: [(percentage: Int, weight: Double)] {
        return OneRMCalculator.generateTrainingPercentages(oneRM: value)
    }

    /**
     * Formatted display string for the result.
     */
    var formattedValue: String {
        return OneRMCalculator.formatResult(self)
    }
}