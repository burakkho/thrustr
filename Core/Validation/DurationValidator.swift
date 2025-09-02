import Foundation

// MARK: - Duration Validation Rules
class DurationValidator: ValidationRule {
    private let minDurationMinutes: Int = 1     // 1 minute minimum
    private let maxDurationMinutes: Int = 600   // 10 hours maximum
    
    func validate(_ input: String) -> ValidationResult {
        // Check if input is empty
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .invalid(message: LocalizationKeys.Validation.durationRequired.localized)
        }
        
        // Try to parse as Integer (expecting minutes)
        guard let duration = Int(input) else {
            return .invalid(message: LocalizationKeys.Validation.durationInvalidFormat.localized)
        }
        
        // Check if duration is positive
        guard duration > 0 else {
            return .invalid(message: LocalizationKeys.Validation.durationMustBePositive.localized)
        }
        
        // Check minimum duration
        guard duration >= minDurationMinutes else {
            return .invalid(message: LocalizationKeys.Validation.durationMinimum.localized)
        }
        
        // Check maximum duration
        guard duration <= maxDurationMinutes else {
            return .invalid(message: LocalizationKeys.Validation.durationMaximum.localized)
        }
        
        return .valid
    }
}

// MARK: - Time Format Duration Validator (HH:MM or MM:SS)
class TimeFormatDurationValidator: ValidationRule {
    private let maxHours: Int = 10
    private let maxMinutes: Int = 59
    private let maxSeconds: Int = 59
    
    enum TimeFormat {
        case hoursMinutes   // HH:MM
        case minutesSeconds // MM:SS
    }
    
    private let format: TimeFormat
    
    init(format: TimeFormat = .minutesSeconds) {
        self.format = format
    }
    
    func validate(_ input: String) -> ValidationResult {
        // Check if input is empty
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .invalid(message: LocalizationKeys.Validation.timeRequired.localized)
        }
        
        // Check format (should contain exactly one colon)
        let components = input.components(separatedBy: ":")
        guard components.count == 2 else {
            let formatExample = format == .hoursMinutes ? "1:30" : "15:30"
            return .invalid(message: LocalizationKeys.Validation.timeInvalidFormat.localized + " (\(formatExample))")
        }
        
        // Parse components
        guard let first = Int(components[0].trimmingCharacters(in: .whitespaces)),
              let second = Int(components[1].trimmingCharacters(in: .whitespaces)) else {
            return .invalid(message: LocalizationKeys.Validation.timeInvalidNumbers.localized)
        }
        
        // Validate based on format
        switch format {
        case .hoursMinutes:
            // Validate hours and minutes
            guard first >= 0 && first <= maxHours else {
                return .invalid(message: LocalizationKeys.Validation.hoursRange.localized)
            }
            
            guard second >= 0 && second <= maxMinutes else {
                return .invalid(message: LocalizationKeys.Validation.minutesRange.localized)
            }
            
            // Check minimum duration (at least 1 minute)
            let totalMinutes = first * 60 + second
            guard totalMinutes >= 1 else {
                return .invalid(message: LocalizationKeys.Validation.durationMinimum.localized)
            }
            
        case .minutesSeconds:
            // Validate minutes and seconds
            guard first >= 0 && first <= 600 else { // Max 600 minutes = 10 hours
                return .invalid(message: LocalizationKeys.Validation.minutesRange.localized)
            }
            
            guard second >= 0 && second <= maxSeconds else {
                return .invalid(message: LocalizationKeys.Validation.secondsRange.localized)
            }
            
            // Check minimum duration (at least 1 second for intervals)
            let totalSeconds = first * 60 + second
            guard totalSeconds >= 1 else {
                return .invalid(message: LocalizationKeys.Validation.durationMinimum.localized)
            }
        }
        
        return .valid
    }
}

// MARK: - Convenience Extensions
extension DurationValidator {
    static func validateDurationMinutes(_ input: String) -> (isValid: Bool, minutes: Int?, errorMessage: String?) {
        let validator = DurationValidator()
        let result = validator.validate(input)
        
        let minutes: Int?
        if result.isValid {
            minutes = Int(input)
        } else {
            minutes = nil
        }
        
        return (result.isValid, minutes, result.errorMessage)
    }
    
    static func formatDuration(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) dk"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours) sa"
            } else {
                return "\(hours) sa \(remainingMinutes) dk"
            }
        }
    }
}

extension TimeFormatDurationValidator {
    static func validateTimeFormat(_ input: String, format: TimeFormat = .minutesSeconds) -> (isValid: Bool, totalSeconds: Int?, errorMessage: String?) {
        let validator = TimeFormatDurationValidator(format: format)
        let result = validator.validate(input)
        
        let totalSeconds: Int?
        if result.isValid {
            let components = input.components(separatedBy: ":")
            if let first = Int(components[0]), let second = Int(components[1]) {
                switch format {
                case .hoursMinutes:
                    totalSeconds = first * 3600 + second * 60
                case .minutesSeconds:
                    totalSeconds = first * 60 + second
                }
            } else {
                totalSeconds = nil
            }
        } else {
            totalSeconds = nil
        }
        
        return (result.isValid, totalSeconds, result.errorMessage)
    }
    
    static func formatTime(_ totalSeconds: Int, format: TimeFormat = .minutesSeconds) -> String {
        switch format {
        case .hoursMinutes:
            let hours = totalSeconds / 3600
            let minutes = (totalSeconds % 3600) / 60
            return String(format: "%d:%02d", hours, minutes)
        case .minutesSeconds:
            let minutes = totalSeconds / 60
            let seconds = totalSeconds % 60
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}