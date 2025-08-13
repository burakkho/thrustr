import Foundation
import SwiftData

@Model
final class Workout {
    var id: UUID
    var name: String?
    var date: Date
    var startTime: Date
    var endTime: Date?
    var notes: String?
    var isCompleted: Bool
    var isTemplate: Bool

    // Relationships
    var parts: [WorkoutPart] = []

    init(name: String? = nil, isTemplate: Bool = false) {
        self.id = UUID()
        self.name = name
        self.date = Date()
        self.startTime = Date()
        self.endTime = nil
        self.notes = nil
        self.isCompleted = false
        self.isTemplate = isTemplate
        self.parts = []
    }

    // Computed
    var durationInMinutes: Int {
        guard let endTime else { return 0 }
        return max(0, Int(endTime.timeIntervalSince(startTime)) / 60)
    }

    var totalVolume: Double {
        parts.reduce(0) { $0 + $1.totalVolume }
    }

    var totalSets: Int {
        parts.reduce(0) { $0 + $1.totalSets }
    }

    var isActive: Bool {
        endTime == nil && !isCompleted
    }

    // Methods
    func finishWorkout() {
        endTime = Date()
        isCompleted = true
    }

    func addPart(name: String, type: WorkoutPartType) -> WorkoutPart {
        let part = WorkoutPart(name: name, type: type, orderIndex: parts.count)
        part.workout = self
        parts.append(part)
        return part
    }
}

