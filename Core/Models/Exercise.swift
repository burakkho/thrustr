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
    var isFavorite: Bool
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
        self.isFavorite = false
        self.isActive = true
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

