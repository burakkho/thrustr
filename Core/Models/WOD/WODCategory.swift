import Foundation

enum WODCategory: String, CaseIterable {
    case custom = "custom"
    case girls = "girls"
    case heroes = "heroes"
    case opens = "opens"
    
    var displayName: String {
        switch self {
        case .custom:
            return "My WODs"
        case .girls:
            return "The Girls"
        case .heroes:
            return "Hero WODs"
        case .opens:
            return "Open WODs"
        }
    }
    
    var icon: String {
        switch self {
        case .custom:
            return "person.fill"
        case .girls:
            return "figure.strengthtraining.traditional"
        case .heroes:
            return "star.fill"
        case .opens:
            return "trophy.fill"
        }
    }
    
    var description: String {
        switch self {
        case .custom:
            return "Your custom workouts"
        case .girls:
            return "Classic benchmark WODs"
        case .heroes:
            return "Hero tribute workouts"
        case .opens:
            return "CrossFit Open workouts"
        }
    }
}