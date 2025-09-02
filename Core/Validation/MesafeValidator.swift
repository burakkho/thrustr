import Foundation

// MARK: - Distance Validation Rules
class MesafeValidator: ValidationRule {
    private let minDistance: Double = 0.01 // 10 metres
    private let maxDistance: Double = 100.0 // 100 km
    
    func validate(_ input: String) -> ValidationResult {
        // Check if input is empty
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .invalid(message: LocalizationKeys.Validation.distanceRequired.localized)
        }
        
        // Try to parse as Double
        guard let distance = Double(input.replacingOccurrences(of: ",", with: ".")) else {
            return .invalid(message: LocalizationKeys.Validation.distanceInvalidFormat.localized)
        }
        
        // Check if distance is positive
        guard distance > 0 else {
            return .invalid(message: LocalizationKeys.Validation.distanceMustBePositive.localized)
        }
        
        // Check minimum distance (10 metres = 0.01 km)
        guard distance >= minDistance else {
            return .invalid(message: LocalizationKeys.Validation.distanceMinimum.localized)
        }
        
        // Check maximum distance (100 km for ultra marathons and long cycling)
        guard distance <= maxDistance else {
            return .invalid(message: LocalizationKeys.Validation.distanceMaximum.localized)
        }
        
        // Check for reasonable decimal places (max 3 decimal places = 1 metre precision)
        let components = input.replacingOccurrences(of: ",", with: ".").components(separatedBy: ".")
        if components.count > 1 {
            let decimalPart = components[1]
            guard decimalPart.count <= 3 else {
                return .invalid(message: LocalizationKeys.Validation.distancePrecision.localized)
            }
        }
        
        return .valid
    }
}

// MARK: - Convenience Extensions
extension MesafeValidator {
    static func validateDistance(_ input: String) -> (isValid: Bool, distance: Double?, errorMessage: String?) {
        let validator = MesafeValidator()
        let result = validator.validate(input)
        
        let distance: Double?
        if result.isValid {
            distance = Double(input.replacingOccurrences(of: ",", with: "."))
        } else {
            distance = nil
        }
        
        return (result.isValid, distance, result.errorMessage)
    }
    
    static func formatDistance(_ distance: Double) -> String {
        if distance >= 1.0 {
            return String(format: "%.2f km", distance)
        } else {
            return String(format: "%.0f m", distance * 1000)
        }
    }
}