import Foundation
import SwiftData

// MARK: - Lift Workout Model
@Model
final class LiftWorkout {
    var id: UUID
    var name: String
    var nameEN: String
    var nameTR: String
    var dayNumber: Int? // Day 1, Day 2, etc.
    var notes: String?
    var estimatedDuration: Int? // minutes
    var isTemplate: Bool
    var isCustom: Bool
    var isFavorite: Bool
    var createdAt: Date
    var updatedAt: Date
    
    // Relationships
    var program: LiftProgram?
    var exercises: [LiftExercise]
    var sessions: [LiftSession]
    
    init(
        name: String,
        nameEN: String? = nil,
        nameTR: String? = nil,
        dayNumber: Int? = nil,
        notes: String? = nil,
        estimatedDuration: Int? = nil,
        isTemplate: Bool = false,
        isCustom: Bool = false,
        isFavorite: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.nameEN = nameEN ?? name
        self.nameTR = nameTR ?? name
        self.dayNumber = dayNumber
        self.notes = notes
        self.estimatedDuration = estimatedDuration
        self.isTemplate = isTemplate
        self.isCustom = isCustom
        self.isFavorite = isFavorite
        self.createdAt = Date()
        self.updatedAt = Date()
        self.exercises = []
        self.sessions = []
    }
}

// MARK: - Computed Properties
extension LiftWorkout {
    var localizedName: String {
        // For now use English as default to avoid MainActor issues
        // TODO: Implement proper localization without MainActor
        return nameEN.isEmpty ? name : nameEN
    }
    
    var totalSets: Int {
        return exercises.reduce(0) { $0 + $1.targetSets }
    }
    
    var totalExercises: Int {
        return exercises.count
    }
    
    var muscleGroups: Set<String> {
        let groups = Set<String>()
        for _ in exercises {
            // This would map to actual muscle groups from Exercise model
            // For now, returning empty
        }
        return groups
    }
    
    var lastPerformed: Date? {
        return sessions
            .filter { $0.isCompleted }
            .sorted { $0.startDate > $1.startDate }
            .first?.startDate
    }
    
    var averageDuration: Int? {
        let completedSessions = sessions.filter { $0.isCompleted }
        guard !completedSessions.isEmpty else { return nil }
        
        let totalDuration = completedSessions.reduce(0.0) { total, session in
            total + session.duration
        }
        
        return Int(totalDuration / Double(completedSessions.count))
    }
    
    var isSuperset: Bool {
        // Check if any exercises are marked as superset
        for (index, exercise) in exercises.enumerated() {
            if index > 0 && exercise.restTime == 0 {
                return true
            }
        }
        return false
    }
}

// MARK: - Methods
extension LiftWorkout {
    func addExercise(_ exercise: LiftExercise) {
        exercise.orderIndex = exercises.count
        exercises.append(exercise)
        exercise.workout = self
        updatedAt = Date()
    }
    
    func removeExercise(_ exercise: LiftExercise) {
        exercises.removeAll { $0.id == exercise.id }
        // Reorder remaining exercises
        for (index, ex) in exercises.enumerated() {
            ex.orderIndex = index
        }
        updatedAt = Date()
    }
    
    func reorderExercises() {
        exercises.sort { $0.orderIndex < $1.orderIndex }
    }
    
    func duplicate() -> LiftWorkout {
        let newWorkout = LiftWorkout(
            name: name,
            nameEN: nameEN,
            nameTR: nameTR,
            dayNumber: dayNumber,
            notes: notes,
            estimatedDuration: estimatedDuration,
            isTemplate: true,
            isCustom: true
        )
        
        // Duplicate exercises
        for exercise in exercises {
            let newExercise = exercise.duplicate()
            newWorkout.addExercise(newExercise)
        }
        
        return newWorkout
    }
    
    func startSession(for user: User, programExecution: ProgramExecution? = nil) -> LiftSession {
        let session = LiftSession(
            workout: self,
            user: user,
            programExecution: programExecution
        )
        sessions.append(session)
        return session
    }
    
    func toggleFavorite() {
        isFavorite.toggle()
        updatedAt = Date()
    }
}

// MARK: - Workout Templates
extension LiftWorkout {
    static func createWorkoutA() -> LiftWorkout {
        let workout = LiftWorkout(
            name: "Workout A",
            nameEN: "Workout A",
            nameTR: "Antrenman A",
            dayNumber: 1,
            estimatedDuration: 45,
            isTemplate: true,
            isCustom: false
        )
        return workout
    }
    
    static func createWorkoutB() -> LiftWorkout {
        let workout = LiftWorkout(
            name: "Workout B",
            nameEN: "Workout B",
            nameTR: "Antrenman B",
            dayNumber: 2,
            estimatedDuration: 45,
            isTemplate: true,
            isCustom: false
        )
        return workout
    }
    
    static func createPushDay() -> LiftWorkout {
        let workout = LiftWorkout(
            name: "Push Day",
            nameEN: "Push Day",
            nameTR: "İtme Günü",
            estimatedDuration: 60,
            isTemplate: true,
            isCustom: false
        )
        return workout
    }
    
    static func createPullDay() -> LiftWorkout {
        let workout = LiftWorkout(
            name: "Pull Day",
            nameEN: "Pull Day",
            nameTR: "Çekme Günü",
            estimatedDuration: 60,
            isTemplate: true,
            isCustom: false
        )
        return workout
    }
    
    static func createLegDay() -> LiftWorkout {
        let workout = LiftWorkout(
            name: "Leg Day",
            nameEN: "Leg Day",
            nameTR: "Bacak Günü",
            estimatedDuration: 75,
            isTemplate: true,
            isCustom: false
        )
        return workout
    }
}