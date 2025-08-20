import Foundation
import SwiftData

@Model
final class Lift {
    var id: UUID
    var name: String
    var nameEN: String
    var nameTR: String
    var nameES: String
    var nameDE: String
    var type: String // strength, powerlifting, olympic
    var category: String // benchmark, custom
    var liftDescription: String
    var descriptionTR: String
    var descriptionES: String
    var descriptionDE: String
    var sets: Int
    var reps: Int
    var isCustom: Bool
    var isFavorite: Bool
    var shareCode: String?
    var createdAt: Date
    var updatedAt: Date
    
    // Relationships
    var exercises: [LiftExercise]
    var results: [LiftResult]
    
    init(
        name: String,
        nameEN: String = "",
        nameTR: String = "",
        nameES: String = "",
        nameDE: String = "",
        type: String = "strength",
        category: String = "custom",
        description: String = "",
        descriptionTR: String = "",
        descriptionES: String = "",
        descriptionDE: String = "",
        sets: Int = 5,
        reps: Int = 5,
        isCustom: Bool = true
    ) {
        self.id = UUID()
        self.name = name
        self.nameEN = nameEN.isEmpty ? name : nameEN
        self.nameTR = nameTR.isEmpty ? name : nameTR
        self.nameES = nameES.isEmpty ? name : nameES
        self.nameDE = nameDE.isEmpty ? name : nameDE
        self.type = type
        self.category = category
        self.liftDescription = description
        self.descriptionTR = descriptionTR
        self.descriptionES = descriptionES
        self.descriptionDE = descriptionDE
        self.sets = sets
        self.reps = reps
        self.isCustom = isCustom
        self.isFavorite = false
        self.createdAt = Date()
        self.updatedAt = Date()
        self.exercises = []
        self.results = []
    }
}

// MARK: - Computed Properties
extension Lift {
    @MainActor
    var localizedName: String {
        let languageCode = LanguageManager.shared.currentLanguage.rawValue
        switch languageCode {
        case "tr": return nameTR
        case "es": return nameES
        case "de": return nameDE
        default: return nameEN
        }
    }
    
    @MainActor
    var localizedDescription: String {
        let languageCode = LanguageManager.shared.currentLanguage.rawValue
        switch languageCode {
        case "tr": return descriptionTR
        case "es": return descriptionES
        case "de": return descriptionDE
        default: return liftDescription
        }
    }
    
    // Get best result (highest weight)
    var personalRecord: LiftResult? {
        results.max { ($0.totalWeight ?? 0) < ($1.totalWeight ?? 0) }
    }
    
    var lastPerformed: Date? {
        results.map { $0.completedAt }.max()
    }
    
    var totalVolume: Double {
        results.reduce(0) { $0 + ($1.totalWeight ?? 0) }
    }
}

// MARK: - LiftResult Model
@Model
final class LiftResult {
    var id: UUID
    var completedAt: Date
    var totalWeight: Double?
    var bestSet: Double? // Heaviest single set
    var totalReps: Int
    var totalSets: Int
    var notes: String?
    
    // Relationship
    var lift: Lift?
    var user: User?
    
    init(
        totalWeight: Double? = nil,
        bestSet: Double? = nil,
        totalReps: Int = 0,
        totalSets: Int = 0,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.completedAt = Date()
        self.totalWeight = totalWeight
        self.bestSet = bestSet
        self.totalReps = totalReps
        self.totalSets = totalSets
        self.notes = notes
    }
}

// MARK: - Lift Types
enum LiftType: String, CaseIterable {
    case strength = "strength"
    case powerlifting = "powerlifting"
    case olympic = "olympic"
    case bodybuilding = "bodybuilding"
    
    var displayName: String {
        switch self {
        case .strength: return "Strength"
        case .powerlifting: return "Powerlifting"
        case .olympic: return "Olympic"
        case .bodybuilding: return "Bodybuilding"
        }
    }
    
    var icon: String {
        switch self {
        case .strength: return "dumbbell.fill"
        case .powerlifting: return "figure.strengthtraining.traditional"
        case .olympic: return "bolt.circle.fill"
        case .bodybuilding: return "figure.arms.open"
        }
    }
}

enum LiftCategory: String, CaseIterable {
    case benchmark = "benchmark"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .benchmark: return "Benchmark"
        case .custom: return "Custom"
        }
    }
}