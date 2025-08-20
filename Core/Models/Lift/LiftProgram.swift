import Foundation
import SwiftData

// MARK: - Lift Program Model
@Model
final class LiftProgram {
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
    var category: String // strength, hypertrophy, powerlifting
    var isCustom: Bool
    var isFavorite: Bool
    var createdAt: Date
    var updatedAt: Date
    
    // Relationships
    var workouts: [LiftWorkout]
    var creator: User?
    
    init(
        name: String,
        nameEN: String? = nil,
        nameTR: String? = nil,
        description: String = "",
        descriptionEN: String? = nil,
        descriptionTR: String? = nil,
        weeks: Int = 12,
        daysPerWeek: Int = 3,
        level: String = "beginner",
        category: String = "strength",
        isCustom: Bool = false
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
        self.workouts = []
    }
}

// MARK: - Computed Properties
extension LiftProgram {
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
    
    var uniqueExercises: Set<String> {
        var exercises = Set<String>()
        for workout in workouts {
            for exercise in workout.exercises {
                exercises.insert(exercise.exerciseName)
            }
        }
        return exercises
    }
}

// MARK: - Methods
extension LiftProgram {
    func addWorkout(_ workout: LiftWorkout) {
        workouts.append(workout)
        workout.program = self
        updatedAt = Date()
    }
    
    func removeWorkout(_ workout: LiftWorkout) {
        workouts.removeAll { $0.id == workout.id }
        updatedAt = Date()
    }
    
    func duplicate() -> LiftProgram {
        let newProgram = LiftProgram(
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
            isCustom: true
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
extension LiftProgram {
    static func createStrongLifts5x5() -> LiftProgram {
        let program = LiftProgram(
            name: "StrongLifts 5x5",
            nameEN: "StrongLifts 5x5",
            nameTR: "StrongLifts 5x5",
            description: "Simple and effective strength program for beginners. Focus on compound movements with progressive overload.",
            descriptionEN: "Simple and effective strength program for beginners. Focus on compound movements with progressive overload.",
            descriptionTR: "Yeni başlayanlar için basit ve etkili güç programı. Artan yükle bileşik hareketlere odaklanır.",
            weeks: 12,
            daysPerWeek: 3,
            level: "beginner",
            category: "strength",
            isCustom: false
        )
        return program
    }
    
    static func createPPL() -> LiftProgram {
        let program = LiftProgram(
            name: "Push Pull Legs",
            nameEN: "Push Pull Legs",
            nameTR: "İtme Çekme Bacak",
            description: "Popular 6-day split focusing on movement patterns. Great for intermediate to advanced lifters.",
            descriptionEN: "Popular 6-day split focusing on movement patterns. Great for intermediate to advanced lifters.",
            descriptionTR: "Hareket kalıplarına odaklanan popüler 6 günlük program. Orta ve ileri seviye sporcular için idealdir.",
            weeks: 8,
            daysPerWeek: 6,
            level: "intermediate",
            category: "hypertrophy",
            isCustom: false
        )
        return program
    }
}