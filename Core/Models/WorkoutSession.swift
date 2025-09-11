import Foundation

// MARK: - WorkoutSession Protocol (Shared across training modules)
protocol WorkoutSession {
    var id: UUID { get }
    var workoutName: String { get }
    var startDate: Date { get }
    var completedAt: Date? { get }
    var sessionDuration: TimeInterval { get }
    var isCompleted: Bool { get }
}

// MARK: - Extensions for existing models

extension LiftSession: WorkoutSession {
    var workoutName: String {
        workout?.name ?? "Unknown Workout"
    }
    
    var completedAt: Date? {
        endDate
    }
    
    var sessionDuration: TimeInterval {
        self.duration
    }
}

extension CardioSession: WorkoutSession {
    var sessionDuration: TimeInterval {
        TimeInterval(self.duration)
    }
}