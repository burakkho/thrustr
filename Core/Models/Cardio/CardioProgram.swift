import Foundation
import SwiftData

// MARK: - Cardio Program Model
@Model
final class CardioProgram {
    var id: UUID
    var name: String
    var nameEN: String
    var nameTR: String
    var programDescription: String
    var descriptionEN: String
    var descriptionTR: String
    var weeks: Int
    var daysPerWeek: Int
    var level: String // beginner, intermediate, advanced
    var category: String // running, cycling, hiit, circuit
    var isCustom: Bool
    var isFavorite: Bool
    var createdAt: Date
    var updatedAt: Date
    
    // Cardio-specific properties
    var totalDistance: Double? // Total distance goal (in meters)
    var targetPace: Double? // Target pace (in minutes per km)
    var intensityLevel: String // low, moderate, high, mixed
    
    // Relationships
    var workouts: [CardioWorkout]
    var creator: User?
    
    init(
        name: String,
        nameEN: String? = nil,
        nameTR: String? = nil,
        description: String = "",
        descriptionEN: String? = nil,
        descriptionTR: String? = nil,
        weeks: Int = 8,
        daysPerWeek: Int = 3,
        level: String = "beginner",
        category: String = "running",
        isCustom: Bool = false,
        totalDistance: Double? = nil,
        targetPace: Double? = nil,
        intensityLevel: String = "moderate"
    ) {
        self.id = UUID()
        self.name = name
        self.nameEN = nameEN ?? name
        self.nameTR = nameTR ?? name
        self.programDescription = description
        self.descriptionEN = descriptionEN ?? description
        self.descriptionTR = descriptionTR ?? description
        self.weeks = weeks
        self.daysPerWeek = daysPerWeek
        self.level = level
        self.category = category
        self.isCustom = isCustom
        self.isFavorite = false
        self.createdAt = Date()
        self.updatedAt = Date()
        self.totalDistance = totalDistance
        self.targetPace = targetPace
        self.intensityLevel = intensityLevel
        self.workouts = []
    }
}

// MARK: - Computed Properties
extension CardioProgram {
    var localizedName: String {
        // For now use English as default to avoid MainActor issues
        // TODO: Implement proper localization without MainActor
        return nameEN.isEmpty ? name : nameEN
    }
    
    var localizedDescription: String {
        // For now use English as default to avoid MainActor issues
        // TODO: Implement proper localization without MainActor
        return descriptionEN.isEmpty ? programDescription : descriptionEN
    }
    
    var totalWorkouts: Int {
        return weeks * daysPerWeek
    }
    
    var estimatedDuration: String {
        switch category {
        case "running", "cycling":
            return "30-45 min"
        case "hiit":
            return "15-30 min"
        case "circuit":
            return "20-40 min"
        default:
            return "30 min"
        }
    }
    
    var difficultyIcon: String {
        switch level {
        case "beginner":
            return "tortoise.fill"
        case "intermediate":
            return "hare.fill"
        case "advanced":
            return "flame.fill"
        default:
            return "circle.fill"
        }
    }
    
    var categoryIcon: String {
        switch category {
        case "running":
            return "figure.run"
        case "cycling":
            return "bicycle"
        case "hiit":
            return "bolt.fill"
        case "circuit":
            return "arrow.triangle.2.circlepath"
        default:
            return "heart.fill"
        }
    }
}

// MARK: - Methods
extension CardioProgram {
    func addWorkout(_ workout: CardioWorkout) {
        workouts.append(workout)
        workout.program = self
        updatedAt = Date()
    }
    
    func removeWorkout(_ workout: CardioWorkout) {
        workouts.removeAll { $0.id == workout.id }
        updatedAt = Date()
    }
    
    func duplicate() -> CardioProgram {
        let newProgram = CardioProgram(
            name: "\(name) (Copy)",
            nameEN: "\(nameEN) (Copy)",
            nameTR: "\(nameTR) (Kopya)",
            description: programDescription,
            descriptionEN: descriptionEN,
            descriptionTR: descriptionTR,
            weeks: weeks,
            daysPerWeek: daysPerWeek,
            level: level,
            category: category,
            isCustom: true,
            totalDistance: totalDistance,
            targetPace: targetPace,
            intensityLevel: intensityLevel
        )
        
        // Duplicate workouts
        for workout in workouts {
            let newWorkout = workout.duplicate()
            newProgram.addWorkout(newWorkout)
        }
        
        return newProgram
    }
}

// MARK: - Program Templates
// Templates are now loaded from JSON files in Resources/Training/Programs/CardioPrograms/
// This allows for easier maintenance and addition of new programs without code changes