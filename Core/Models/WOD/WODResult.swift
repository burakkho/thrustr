import Foundation
import SwiftData

@Model
final class WODResult {
    var id: UUID = UUID()
    var totalTime: Int? // seconds for "For Time" WODs
    var rounds: Int? // completed rounds for AMRAP
    var extraReps: Int? // extra reps in incomplete round for AMRAP
    var splits: String? // JSON string for round/movement splits
    var notes: String?
    var isRX: Bool = false
    var completedAt: Date = Date()
    
    // Relationships
    var wod: WOD?
    var wodId: UUID? // For easier querying
    var user: User?
    
    init(
        totalTime: Int? = nil,
        rounds: Int? = nil,
        extraReps: Int? = nil,
        isRX: Bool = false
    ) {
        self.id = UUID()
        self.totalTime = totalTime
        self.rounds = rounds
        self.extraReps = extraReps
        self.splits = nil
        self.notes = nil
        self.isRX = isRX
        self.completedAt = Date()
    }
}

// MARK: - Computed Properties
extension WODResult {
    // Calculate score based on WOD type
    var score: Double {
        if let totalTime = totalTime {
            return Double(totalTime)
        } else if let rounds = rounds {
            return Double(rounds * 100 + (extraReps ?? 0))
        }
        return 0
    }
    
    // Format time for display
    var formattedTime: String? {
        guard let totalTime = totalTime else { return nil }
        let minutes = totalTime / 60
        let seconds = totalTime % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
    
    // Format AMRAP score
    var amrapScore: String? {
        guard let rounds = rounds else { return nil }
        var score = "\(rounds) rounds"
        if let extraReps = extraReps, extraReps > 0 {
            score += " + \(extraReps) reps"
        }
        return score
    }
    
    // Get display score based on WOD type
    var displayScore: String {
        if let wod = wod {
            switch wod.wodType {
            case .forTime:
                return formattedTime ?? "DNF"
            case .amrap:
                return amrapScore ?? "0 rounds"
            case .emom:
                if let rounds = rounds {
                    return "\(rounds) rounds completed"
                }
                return "Not completed"
            case .custom:
                return notes ?? "Completed"
            }
        }
        
        // Fallback if no WOD reference
        if let time = formattedTime {
            return time
        } else if let score = amrapScore {
            return score
        }
        return "Completed"
    }
    
    // Check if this is a PR compared to other results
    func isPR(among results: [WODResult]) -> Bool {
        guard let wod = wod else { return false }
        
        switch wod.wodType {
        case .forTime:
            guard let myTime = totalTime else { return false }
            return results.filter { $0.id != self.id }
                .compactMap { $0.totalTime }
                .allSatisfy { $0 > myTime }
            
        case .amrap:
            let myScore = (rounds ?? 0) * 100 + (extraReps ?? 0)
            return results.filter { $0.id != self.id }
                .map { ($0.rounds ?? 0) * 100 + ($0.extraReps ?? 0) }
                .allSatisfy { $0 < myScore }
            
        default:
            return false
        }
    }
}