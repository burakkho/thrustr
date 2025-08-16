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
    // Persist minimal metadata for custom WODs (lightweight migration-safe)
    var wodTypeRaw: String?
    var wodMovementsText: String?
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
        self.wodTypeRaw = nil
        self.wodMovementsText = nil
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
        // FIXED: Improved volume calculation with better edge case handling
        exerciseSets.reduce(0.0) { total, set in
            // Only count completed sets for volume calculation
            guard set.isCompleted else { return total }
            
            // Handle different exercise types
            if let weight = set.weight, let reps = set.reps, weight > 0, reps > 0 {
                // Traditional weight x reps for strength training
                return total + (weight * Double(reps))
            } else if let distance = set.distance, distance > 0 {
                // For cardio: use distance as volume (in meters)
                return total + distance
            } else if let duration = set.duration, duration > 0 {
                // For time-based exercises: convert duration to volume (seconds/60 for minutes)
                return total + (Double(duration) / 60.0)
            }
            return total  // Skip sets without measurable volume
        }
    }

    var workoutPartType: WorkoutPartType {
        WorkoutPartType.from(rawOrLegacy: type)
    }

    // Convenience for custom WOD metadata
    var wodTypeEnum: WODType? {
        get { wodTypeRaw.flatMap { WODType(rawValue: $0) } }
        set { wodTypeRaw = newValue?.rawValue }
    }
    var wodMovements: [String] {
        let text = (wodMovementsText ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? [] : text.components(separatedBy: "\n").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }
}

