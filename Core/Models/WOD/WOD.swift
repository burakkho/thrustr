import Foundation
import SwiftData

@Model
final class WOD {
    var id: UUID
    var name: String
    var type: String // WODType raw value
    var category: String // WODCategory raw value (girls, heroes, opens, custom)
    var repScheme: [Int] // [21, 15, 9] for 21-15-9 format
    var timeCap: Int? // in seconds
    var rounds: Int? // for EMOM, Tabata etc
    var difficulty: String? // beginner, intermediate, advanced
    var isCustom: Bool
    var isFavorite: Bool
    var createdAt: Date
    var updatedAt: Date
    
    // Relationships
    var movements: [WODMovement]
    var results: [WODResult]
    
    init(
        name: String,
        type: WODType,
        category: String = "custom",
        repScheme: [Int] = [],
        timeCap: Int? = nil,
        rounds: Int? = nil,
        difficulty: String? = nil,
        isCustom: Bool = true
    ) {
        self.id = UUID()
        self.name = name
        self.type = type.rawValue
        self.category = category
        self.repScheme = repScheme
        self.timeCap = timeCap
        self.rounds = rounds
        self.difficulty = difficulty
        self.isCustom = isCustom
        self.isFavorite = false
        self.createdAt = Date()
        self.updatedAt = Date()
        self.movements = []
        self.results = []
    }
}

// MARK: - Computed Properties
extension WOD {
    var wodType: WODType {
        WODType(rawValue: type) ?? .custom
    }
    
    var wodCategory: WODCategory {
        WODCategory(rawValue: category) ?? .custom
    }
    
    var formattedRepScheme: String {
        repScheme.map { String($0) }.joined(separator: "-")
    }
    
    var formattedTimeCap: String? {
        guard let timeCap = timeCap else { return nil }
        let minutes = timeCap / 60
        let seconds = timeCap % 60
        if minutes > 0 {
            return "\(minutes):\(String(format: "%02d", seconds))"
        }
        return "\(seconds)s"
    }
    
    // Get best result for this WOD
    var personalRecord: WODResult? {
        switch wodType {
        case .forTime:
            // Lowest time is best for "For Time" WODs
            return results
                .filter { $0.totalTime != nil }
                .min { ($0.totalTime ?? Int.max) < ($1.totalTime ?? Int.max) }
        case .amrap:
            // Most rounds/reps is best for AMRAP
            return results
                .filter { $0.rounds != nil }
                .max { 
                    let score1 = ($0.rounds ?? 0) * 100 + ($0.extraReps ?? 0)
                    let score2 = ($1.rounds ?? 0) * 100 + ($1.extraReps ?? 0)
                    return score1 < score2
                }
        default:
            return results.first
        }
    }
    
    var lastPerformed: Date? {
        results.map { $0.completedAt }.max()
    }
}