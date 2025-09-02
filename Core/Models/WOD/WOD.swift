import Foundation
import SwiftData

/**
 * Workout of the Day (WOD) model for CrossFit-style workouts.
 * 
 * This model defines structured workouts with various time domains and movement patterns.
 * Supports multiple workout types including AMRAP, For Time, EMOM, Tabata, and custom formats.
 * WODs can be benchmark workouts (Girls, Heroes) or user-created custom workouts.
 * 
 * Key features:
 * - Flexible rep scheme system for different workout structures
 * - Time cap and round specifications for various WOD types
 * - Difficulty scaling for different fitness levels
 * - QR code sharing for workout distribution
 * - Integration with movement library for exercise selection
 */
@Model
final class WOD {
    var id: UUID
    var name: String
    var type: String // WODType raw value
    var category: String // WODCategory raw value (girls, heroes, opens, custom)
    private var repSchemeData: String // JSON serialized [Int] array
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
        self.repSchemeData = Self.encodeIntArray(repScheme)
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
    var repScheme: [Int] {
        get {
            Self.decodeIntArray(repSchemeData)
        }
        set {
            repSchemeData = Self.encodeIntArray(newValue)
        }
    }
    
    // MARK: - Array Serialization Helpers
    private static func encodeIntArray(_ array: [Int]) -> String {
        do {
            let data = try JSONEncoder().encode(array)
            return String(data: data, encoding: .utf8) ?? "[]"
        } catch {
            return "[]"
        }
    }
    
    private static func decodeIntArray(_ string: String) -> [Int] {
        guard let data = string.data(using: .utf8) else { return [] }
        do {
            return try JSONDecoder().decode([Int].self, from: data)
        } catch {
            return []
        }
    }
}
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