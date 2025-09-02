import Foundation

// MARK: - Heart Rate Validation Rules
class HeartRateValidator: ValidationRule {
    private let minHeartRate: Int = 30  // Minimum viable heart rate
    private let maxHeartRate: Int = 220 // Theoretical maximum heart rate
    
    func validate(_ input: String) -> ValidationResult {
        // Check if input is empty
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .invalid(message: LocalizationKeys.Validation.heartRateRequired.localized)
        }
        
        // Try to parse as Integer
        guard let heartRate = Int(input) else {
            return .invalid(message: LocalizationKeys.Validation.heartRateInvalidFormat.localized)
        }
        
        // Check minimum heart rate
        guard heartRate >= minHeartRate else {
            return .invalid(message: LocalizationKeys.Validation.heartRateMinimum.localized)
        }
        
        // Check maximum heart rate
        guard heartRate <= maxHeartRate else {
            return .invalid(message: LocalizationKeys.Validation.heartRateMaximum.localized)
        }
        
        return .valid
    }
}

// MARK: - Age-Based Heart Rate Validator
class AgeBasedHeartRateValidator: ValidationRule {
    private let userAge: Int
    private let minHeartRate: Int = 30
    
    init(userAge: Int) {
        self.userAge = userAge
    }
    
    func validate(_ input: String) -> ValidationResult {
        // First run basic validation
        let basicValidator = HeartRateValidator()
        let basicResult = basicValidator.validate(input)
        
        guard basicResult.isValid else {
            return basicResult
        }
        
        guard let heartRate = Int(input) else {
            return .invalid(message: LocalizationKeys.Validation.heartRateInvalidFormat.localized)
        }
        
        // Calculate age-specific maximum heart rate
        let ageMaxHeartRate = 220 - userAge
        
        // Warning if heart rate is above age-specific maximum
        if heartRate > ageMaxHeartRate {
            return .invalid(message: LocalizationKeys.Validation.heartRateAgeWarning.localized)
        }
        
        // Warning if heart rate seems too low for exercise
        if heartRate < 60 {
            // This is a soft warning - still valid but inform user
            return .valid // Could add warning result type if needed
        }
        
        return .valid
    }
}

// MARK: - Convenience Extensions
extension HeartRateValidator {
    static func validateHeartRate(_ input: String, userAge: Int? = nil) -> (isValid: Bool, heartRate: Int?, errorMessage: String?) {
        let validator: ValidationRule
        
        if let age = userAge {
            validator = AgeBasedHeartRateValidator(userAge: age)
        } else {
            validator = HeartRateValidator()
        }
        
        let result = validator.validate(input)
        
        let heartRate: Int?
        if result.isValid {
            heartRate = Int(input)
        } else {
            heartRate = nil
        }
        
        return (result.isValid, heartRate, result.errorMessage)
    }
    
    static func getHeartRateZone(_ heartRate: Int, userAge: Int) -> (zone: String, percentage: Double) {
        let maxHR = 220 - userAge
        let restingHR = 60 // Default resting HR
        
        let hrReserve = maxHR - restingHR
        let intensity = Double(heartRate - restingHR) / Double(hrReserve)
        
        let zone: String
        switch intensity {
        case ..<0.5:
            zone = LocalizationKeys.HeartRate.zone1.localized // Recovery
        case 0.5..<0.6:
            zone = LocalizationKeys.HeartRate.zone2.localized // Aerobic Base
        case 0.6..<0.7:
            zone = LocalizationKeys.HeartRate.zone3.localized // Aerobic
        case 0.7..<0.8:
            zone = LocalizationKeys.HeartRate.zone4.localized // Lactate Threshold
        case 0.8...:
            zone = LocalizationKeys.HeartRate.zone5.localized // VO2 Max
        default:
            zone = LocalizationKeys.HeartRate.unknown.localized
        }
        
        return (zone: zone, percentage: intensity * 100)
    }
}