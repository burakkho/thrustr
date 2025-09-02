import Foundation

// MARK: - Validation Result
enum ValidationResult {
    case valid
    case invalid(message: String)
    
    var isValid: Bool {
        switch self {
        case .valid:
            return true
        case .invalid:
            return false
        }
    }
    
    var errorMessage: String? {
        switch self {
        case .valid:
            return nil
        case .invalid(let message):
            return message
        }
    }
}

// MARK: - Validation Rule Protocol
protocol ValidationRule {
    func validate(_ input: String) -> ValidationResult
}

// MARK: - Input Validator
class InputValidator {
    private var rules: [ValidationRule] = []
    
    func addRule(_ rule: ValidationRule) {
        rules.append(rule)
    }
    
    func validate(_ input: String) -> ValidationResult {
        for rule in rules {
            let result = rule.validate(input)
            if !result.isValid {
                return result
            }
        }
        return .valid
    }
    
    func validateAndShowError(_ input: String) -> (isValid: Bool, errorMessage: String?) {
        let result = validate(input)
        return (result.isValid, result.errorMessage)
    }
}