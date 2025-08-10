import Foundation
import SwiftData

@Model
final class Exercise {
    var id: UUID
    var nameEN: String
    var nameTR: String
    var category: String
    var equipment: String
    var supportsWeight: Bool
    var supportsReps: Bool
    var supportsTime: Bool
    var supportsDistance: Bool
    var instructions: String?
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date
    
    init(nameEN: String, nameTR: String, category: String, equipment: String = "") {
        self.id = UUID()
        self.nameEN = nameEN
        self.nameTR = nameTR
        self.category = category
        self.equipment = equipment
        self.supportsWeight = true
        self.supportsReps = true
        self.supportsTime = false
        self.supportsDistance = false
        self.instructions = nil
        self.isActive = true
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Exercise Categories
extension Exercise {
    enum Category: String, CaseIterable {
        case push = "push"
        case pull = "pull"
        case legs = "legs"
        case core = "core"
        case cardio = "cardio"
        case olympic = "olympic"
        case functional = "functional"
        case isolation = "isolation"
        
        var displayName: String {
            switch self {
            case .push: return "Push (Göğüs/Omuz/Tricep)"
            case .pull: return "Pull (Sırt/Bicep)"
            case .legs: return "Legs (Bacak)"
            case .core: return "Core (Karın)"
            case .cardio: return "Cardio"
            case .olympic: return "Olympic Lifts"
            case .functional: return "Functional"
            case .isolation: return "İzolasyon"
            }
        }
    }
}
