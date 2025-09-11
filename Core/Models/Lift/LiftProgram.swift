import Foundation
import SwiftData

// MARK: - Lift Program Model
@Model
final class LiftProgram {
    var id: UUID = UUID()
    var name: String = ""
    var nameEN: String = ""
    var nameTR: String = ""
    var nameDE: String = ""
    var nameES: String = ""
    var nameIT: String = ""
    var programDescription: String = ""
    var descriptionEN: String = ""
    var descriptionTR: String = ""
    var descriptionDE: String = ""
    var descriptionES: String = ""
    var descriptionIT: String = ""
    var weeks: Int = 4
    var daysPerWeek: Int = 3
    var level: String = "beginner" // beginner, intermediate, advanced
    var category: String = "strength" // strength, hypertrophy, powerlifting
    var isFavorite: Bool = false
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \LiftWorkout.program) var workouts: [LiftWorkout]?
    var creator: User?
    @Relationship(deleteRule: .cascade, inverse: \ProgramExecution.program) var executions: [ProgramExecution]?
    
    init(
        name: String,
        nameEN: String? = nil,
        nameTR: String? = nil,
        nameDE: String? = nil,
        nameES: String? = nil,
        nameIT: String? = nil,
        description: String = "",
        descriptionEN: String? = nil,
        descriptionTR: String? = nil,
        descriptionDE: String? = nil,
        descriptionES: String? = nil,
        descriptionIT: String? = nil,
        weeks: Int = 4,
        daysPerWeek: Int = 3,
        level: String = "beginner",
        category: String = "strength",
    ) {
        self.id = UUID()
        self.name = name
        self.nameEN = nameEN ?? name
        self.nameTR = nameTR ?? name
        self.nameDE = nameDE ?? name
        self.nameES = nameES ?? name
        self.nameIT = nameIT ?? name
        self.programDescription = description
        self.descriptionEN = descriptionEN ?? description
        self.descriptionTR = descriptionTR ?? description
        self.descriptionDE = descriptionDE ?? description
        self.descriptionES = descriptionES ?? description
        self.descriptionIT = descriptionIT ?? description
        self.weeks = weeks
        self.daysPerWeek = daysPerWeek
        self.level = level
        self.category = category
        self.isFavorite = false
        self.createdAt = Date()
        self.updatedAt = Date()
        self.workouts = []
    }
}

// MARK: - Computed Properties
extension LiftProgram {
    var localizedName: String {
        // Use device language preference for basic localization
        let preferredLanguage = Locale.current.language.languageCode?.identifier ?? "en"
        
        switch preferredLanguage {
        case "tr":
            if !nameTR.isEmpty { return nameTR }
            return !nameEN.isEmpty ? nameEN : name
        case "de":
            if !nameDE.isEmpty { return nameDE }
            return !nameEN.isEmpty ? nameEN : name
        case "es":
            if !nameES.isEmpty { return nameES }
            return !nameEN.isEmpty ? nameEN : name
        case "it":
            if !nameIT.isEmpty { return nameIT }
            return !nameEN.isEmpty ? nameEN : name
        default:
            return !nameEN.isEmpty ? nameEN : name
        }
    }
    
    var localizedDescription: String {
        // Use device language preference for basic localization  
        let preferredLanguage = Locale.current.language.languageCode?.identifier ?? "en"
        
        switch preferredLanguage {
        case "tr":
            if !descriptionTR.isEmpty { return descriptionTR }
            return !descriptionEN.isEmpty ? descriptionEN : programDescription
        case "de":
            if !descriptionDE.isEmpty { return descriptionDE }
            return !descriptionEN.isEmpty ? descriptionEN : programDescription
        case "es":
            if !descriptionES.isEmpty { return descriptionES }
            return !descriptionEN.isEmpty ? descriptionEN : programDescription
        case "it":
            if !descriptionIT.isEmpty { return descriptionIT }
            return !descriptionEN.isEmpty ? descriptionEN : programDescription
        default:
            return !descriptionEN.isEmpty ? descriptionEN : programDescription
        }
    }
    
    var totalWorkouts: Int {
        return weeks * daysPerWeek
    }
    
    var uniqueExercises: Set<String> {
        var exercises = Set<String>()
        for workout in workouts ?? [] {
            for exercise in workout.exercises ?? [] {
                exercises.insert(exercise.exerciseName)
            }
        }
        return exercises
    }
}

// MARK: - Methods
extension LiftProgram {
    func addWorkout(_ workout: LiftWorkout) {
        if workouts == nil { workouts = [] }
        workouts!.append(workout)
        workout.program = self
        updatedAt = Date()
    }
    
    func removeWorkout(_ workout: LiftWorkout) {
        workouts?.removeAll { $0.id == workout.id }
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
        )
        
        // Duplicate workouts
        for workout in workouts ?? [] {
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
            weeks: 4,
            daysPerWeek: 3,
            level: "beginner",
            category: "strength",
        )
        return program
    }
    
}
