import Foundation
import SwiftData

@Model
final class ExerciseSet {
    var id: UUID
    var setNumber: Int16
    var weight: Double?
    var reps: Int16?
    var distance: Double? // meters
    var duration: Int32?  // seconds
    var rpe: Int16?       // 1-10 scale
    var isCompleted: Bool
    var notes: String?
    var createdAt: Date

    // Relationships
    var exercise: Exercise?
    var workoutPart: WorkoutPart?

    init(setNumber: Int16,
         weight: Double? = nil,
         reps: Int16? = nil,
         duration: Int32? = nil,
         distance: Double? = nil,
         rpe: Int16? = nil,
         isCompleted: Bool = false) {

        self.id = UUID()
        self.setNumber = setNumber
        self.weight = weight
        self.reps = reps
        self.duration = duration
        self.distance = distance
        self.rpe = rpe
        self.isCompleted = isCompleted
        self.notes = nil
        self.createdAt = Date()
    }

    // Uyum için
    convenience init(exercise: Exercise, setNumber: Int) {
        self.init(setNumber: Int16(setNumber))
        self.exercise = exercise
    }
}

extension ExerciseSet {
    var displayText: String {
        var components: [String] = []

        if let weight, weight > 0 {
            // Display in user's preferred unit (weight only; sets store kg)
            let system = UnitSettings().unitSystem
            if system == .imperial {
                let lbs = UnitsConverter.kgToLbs(weight)
                components.append("\(Int(lbs))lb")
            } else {
                components.append("\(Int(weight))kg")
            }
        }
        if let reps, reps > 0 {
            components.append("\(reps) reps")
        }
        if let duration, duration > 0 {
            let minutes = duration / 60
            let seconds = duration % 60
            if minutes > 0 {
                components.append("\(minutes):\(String(format: "%02d", Int(seconds)))")
            } else {
                components.append("\(seconds)s")
            }
        }
        if let distance, distance > 0 {
            if distance >= 1000 {
                components.append(String(format: "%.1fkm", distance / 1000))
            } else {
                components.append("\(Int(distance))m")
            }
        }
        if let rpe, rpe > 0 {
            components.append("RPE \(rpe)")
        }
        return components.isEmpty ? "No data" : components.joined(separator: " × ")
    }

    var hasValidData: Bool {
        (weight ?? 0) > 0 ||
        (reps ?? 0) > 0 ||
        (duration ?? 0) > 0 ||
        (distance ?? 0) > 0
    }
}

