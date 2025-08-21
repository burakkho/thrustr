import Foundation
import SwiftData

// MARK: - WarmUp Session Model
@Model
final class WarmUpSession {
    var id: UUID
    var startDate: Date
    var endDate: Date?
    var duration: Int // in seconds
    var isCompleted: Bool
    var completionRate: Double // 0.0 to 1.0 (percentage of exercises completed)
    var notes: String?
    var feeling: String? // "energized", "ready", "tired", "good"
    
    // Completed exercises tracking
    var completedExerciseIds: [UUID]
    var exerciseCompletionData: String? // JSON with detailed completion data
    
    // Relationships
    var template: WarmUpTemplate?
    var user: User?
    
    init(
        template: WarmUpTemplate,
        user: User
    ) {
        self.id = UUID()
        self.startDate = Date()
        self.endDate = nil
        self.duration = 0
        self.isCompleted = false
        self.completionRate = 0.0
        self.notes = nil
        self.feeling = nil
        self.completedExerciseIds = []
        self.exerciseCompletionData = nil
        self.template = template
        self.user = user
    }
}

// MARK: - Computed Properties
extension WarmUpSession {
    var formattedDuration: String {
        let minutes = duration / 60
        let seconds = duration % 60
        
        if minutes > 0 {
            return "\(minutes):\(String(format: "%02d", seconds))"
        } else {
            return "\(seconds)s"
        }
    }
    
    var completedAt: Date? {
        guard isCompleted else { return nil }
        return endDate ?? startDate
    }
    
    var exercisesCompleted: Int {
        completedExerciseIds.count
    }
    
    var totalExercises: Int {
        template?.exerciseIds.count ?? 0
    }
    
    var progressText: String {
        guard totalExercises > 0 else { return "0/0" }
        return "\(exercisesCompleted)/\(totalExercises)"
    }
    
    var feelingEmoji: String {
        switch feeling?.lowercased() {
        case "energized": return "⚡"
        case "ready": return "💪"
        case "tired": return "😴"
        case "good": return "😊"
        default: return "😐"
        }
    }
}

// MARK: - Methods
extension WarmUpSession {
    func markExerciseCompleted(exerciseId: UUID) {
        if !completedExerciseIds.contains(exerciseId) {
            completedExerciseIds.append(exerciseId)
            updateCompletionRate()
        }
    }
    
    func markExerciseIncomplete(exerciseId: UUID) {
        completedExerciseIds.removeAll { $0 == exerciseId }
        updateCompletionRate()
    }
    
    func completeSession(feeling: String? = nil, notes: String? = nil) {
        self.endDate = Date()
        self.duration = Int(Date().timeIntervalSince(startDate))
        self.isCompleted = true
        self.feeling = feeling
        self.notes = notes
        updateCompletionRate()
        
        // Update user stats if available
        if let user = user {
            user.addWarmUpStats(duration: TimeInterval(duration))
        }
    }
    
    func cancelSession() {
        self.endDate = Date()
        self.duration = Int(Date().timeIntervalSince(startDate))
        self.isCompleted = false
        updateCompletionRate()
    }
    
    private func updateCompletionRate() {
        guard totalExercises > 0 else {
            completionRate = 0.0
            return
        }
        completionRate = Double(exercisesCompleted) / Double(totalExercises)
    }
    
    func isExerciseCompleted(_ exerciseId: UUID) -> Bool {
        completedExerciseIds.contains(exerciseId)
    }
    
    func getCompletionPercentage() -> Int {
        Int(completionRate * 100)
    }
}

// MARK: - User Extension for WarmUp Stats
extension User {
    func addWarmUpStats(duration: TimeInterval) {
        // Add to existing workout stats for now
        // Could be extended with specific warm-up tracking
        lastActiveDate = Date()
    }
}

// MARK: - Session Feelings
enum WarmUpFeeling: String, CaseIterable {
    case energized = "energized"
    case ready = "ready"
    case good = "good"
    case tired = "tired"
    case skip = "skip"
    
    var displayName: String {
        switch self {
        case .energized: return "Energized"
        case .ready: return "Ready"
        case .good: return "Good"
        case .tired: return "Tired"
        case .skip: return "Skip"
        }
    }
    
    var emoji: String {
        switch self {
        case .energized: return "⚡"
        case .ready: return "💪"
        case .good: return "😊"
        case .tired: return "😴"
        case .skip: return "⏭️"
        }
    }
    
    var color: String {
        switch self {
        case .energized: return "yellow"
        case .ready: return "green"
        case .good: return "blue"
        case .tired: return "orange"
        case .skip: return "gray"
        }
    }
}