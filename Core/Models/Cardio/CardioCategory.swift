import Foundation

enum CardioCategory: String, CaseIterable {
    case exercise = "exercise"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .exercise:
            return LocalizationKeys.Training.Cardio.exerciseTypes.localized
        case .custom:
            return LocalizationKeys.Training.Cardio.customSessions.localized
        }
    }
    
    var icon: String {
        switch self {
        case .exercise:
            return "heart.text.square"
        case .custom:
            return "person.fill"
        }
    }
}