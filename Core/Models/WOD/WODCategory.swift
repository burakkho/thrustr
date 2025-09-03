import Foundation

enum WODCategory: String, CaseIterable {
    case custom = "custom"
    case girls = "girls"
    case heroes = "heroes"
    case opens = "opens"
    case history = "history"
    
    var displayName: String {
        switch self {
        case .custom:
            return TrainingKeys.WOD.myWODs.localized
        case .girls:
            return TrainingKeys.WOD.theGirls.localized
        case .heroes:
            return TrainingKeys.WOD.heroWODs.localized
        case .opens:
            return TrainingKeys.WOD.openWODs.localized
        case .history:
            return TrainingKeys.WOD.history.localized
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
        case .history:
            return "clock.fill"
        }
    }
    
    var description: String {
        switch self {
        case .custom:
            return TrainingKeys.WOD.customDesc.localized
        case .girls:
            return TrainingKeys.WOD.girlsDesc.localized
        case .heroes:
            return TrainingKeys.WOD.heroesDesc.localized
        case .opens:
            return TrainingKeys.WOD.opensDesc.localized
        case .history:
            return TrainingKeys.WOD.historyDesc.localized
        }
    }
}