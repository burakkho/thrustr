import Foundation
import SwiftData

@Model
final class WorkoutPart {
    var id: UUID
    var name: String
    var type: String // WorkoutPartType.rawValue
    var orderIndex: Int
    var wodTemplateId: UUID?
    var wodResult: String?
    var notes: String?
    var isCompleted: Bool
    var createdAt: Date

    // Relationships
    var workout: Workout?
    var exerciseSets: [ExerciseSet]

    init(name: String, type: WorkoutPartType, orderIndex: Int) {
        self.id = UUID()
        self.name = name
        self.type = type.rawValue
        self.orderIndex = orderIndex
        self.wodTemplateId = nil
        self.wodResult = nil
        self.notes = nil
        self.isCompleted = false
        self.createdAt = Date()
        self.exerciseSets = []
    }
}

// MARK: - Computed
extension WorkoutPart {
    var totalSets: Int { exerciseSets.count }

    var completedSets: Int {
        exerciseSets.filter { $0.isCompleted }.count
    }

    var totalVolume: Double {
        exerciseSets.compactMap { set in
            guard let weight = set.weight, let reps = set.reps else { return nil }
            return weight * Double(reps)
        }.reduce(0, +)
    }

    var workoutPartType: WorkoutPartType {
        WorkoutPartType(rawValue: type) ?? .strength
    }
}

