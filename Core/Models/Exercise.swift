import Foundation
import SwiftData

/**
 * Core exercise model that defines individual exercises with localization and tracking capabilities.
 * 
 * This model stores exercise information including multilingual names, categories, equipment requirements,
 * and supported tracking metrics. Exercises are seeded from CSV files and serve as the foundation for
 * all workout tracking throughout the app.
 * 
 * Supported tracking types:
 * - Weight-based exercises (strength training)
 * - Rep-based exercises (bodyweight, calisthenics)
 * - Time-based exercises (planks, holds)
 * - Distance-based exercises (cardio activities)
 */
@Model
final class Exercise {
    var id: UUID = UUID()
    var nameEN: String = ""
    var nameTR: String = ""
    var category: String = ""
    var equipment: String = ""
    var supportsWeight: Bool = true
    var supportsReps: Bool = true
    var supportsTime: Bool = false
    var supportsDistance: Bool = false
    var instructions: String?
    var isFavorite: Bool = false
    var isActive: Bool = true
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
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
    
    // MARK: - Computed Properties
    var displayName: String {
        return nameTR.isEmpty ? nameEN : nameTR
    }
}

