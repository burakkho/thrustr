import Foundation

/**
 * Strength test exercise types with their characteristics and standards.
 * 
 * This enum defines the 5 core strength test exercises with their muscle groups,
 * baseline standards, and display properties for consistent UI rendering.
 */
enum StrengthExerciseType: String, CaseIterable, Identifiable, Sendable {
    case benchPress = "bench_press"
    case overheadPress = "overhead_press"
    case pullUp = "pull_up"
    case backSquat = "back_squat"
    case deadlift = "deadlift"
    
    var id: String { rawValue }
    
    // MARK: - Display Properties
    
    var name: String {
        switch self {
        case .benchPress:
            return "strength.exercise.benchPress".localized
        case .overheadPress:
            return "strength.exercise.overheadPress".localized
        case .pullUp:
            return "strength.exercise.pullUp".localized
        case .backSquat:
            return "strength.exercise.backSquat".localized
        case .deadlift:
            return "strength.exercise.deadlift".localized
        }
    }
    
    var icon: String {
        switch self {
        case .benchPress:
            return "figure.strengthtraining.traditional"
        case .overheadPress:
            return "figure.arms.open"
        case .pullUp:
            return "figure.climbing"
        case .backSquat:
            return "figure.squat"
        case .deadlift:
            return "figure.strengthtraining.functional"
        }
    }
    
    var muscleGroup: MuscleGroup {
        switch self {
        case .benchPress:
            return .chest
        case .overheadPress:
            return .shoulders
        case .pullUp:
            return .back
        case .backSquat:
            return .legs
        case .deadlift:
            return .hips
        }
    }
    
    var isRepetitionBased: Bool {
        return self == .pullUp
    }
    
    var unit: String {
        return isRepetitionBased ? "strength.unit.reps".localized : "strength.unit.kg".localized
    }
    
    // MARK: - Strength Standards (Base: 80kg male, 25 years)
    
    /**
     * Base strength standards for 80kg, 25-year-old male.
     * Values represent: [Beginner, Novice, Intermediate, Advanced, Expert, Elite]
     */
    var baseStandards: [Double] {
        switch self {
        case .benchPress:
            return [40, 60, 80, 120, 140, 160] // kg
        case .overheadPress:
            return [20, 35, 50, 60, 75, 90] // kg
        case .pullUp:
            return [2, 5, 8, 12, 18, 25] // reps
        case .backSquat:
            return [60, 80, 100, 140, 160, 200] // kg
        case .deadlift:
            return [80, 100, 120, 160, 200, 240] // kg
        }
    }
    
    var instructions: String {
        switch self {
        case .benchPress:
            return "strength.instructions.benchPress".localized
        case .overheadPress:
            return "strength.instructions.overheadPress".localized
        case .pullUp:
            return "strength.instructions.pullUp".localized
        case .backSquat:
            return "strength.instructions.backSquat".localized
        case .deadlift:
            return "strength.instructions.deadlift".localized
        }
    }
    
    // MARK: - 1RM Calculation Methods
    
    /**
     * Calculates 1RM using exercise-specific formula adjustments.
     */
    func calculateOneRM(weight: Double, reps: Int) -> Double {
        switch self {
        case .benchPress, .backSquat, .deadlift:
            // Standard Epley formula for compound movements
            return RMFormula.epley.calculate(weight: weight, reps: reps)
            
        case .overheadPress:
            // More conservative for shoulder fatigue
            return weight * (1.0 + 0.025 * Double(reps))
            
        case .pullUp:
            // Pull-ups are repetition-based, return reps directly
            return Double(reps)
        }
    }
    
    /**
     * Returns the preferred 1RM formula for this exercise type.
     */
    var preferredFormula: RMFormula {
        switch self {
        case .benchPress, .backSquat, .deadlift:
            return .epley
        case .overheadPress:
            return .custom // Uses custom calculation
        case .pullUp:
            return .repetitionBased // Special case
        }
    }
}

// MARK: - 1RM Formula Enum

/**
 * Different 1RM calculation formulas with their implementations.
 */
enum RMFormula: String, CaseIterable, Sendable {
    case brzycki = "brzycki"
    case epley = "epley"
    case lander = "lander"
    case custom = "custom"
    case repetitionBased = "repetition_based"
    
    var displayName: String {
        switch self {
        case .brzycki: return "Brzycki"
        case .epley: return "Epley"
        case .lander: return "Lander"
        case .custom: return "Custom"
        case .repetitionBased: return "Repetition Based"
        }
    }
    
    /**
     * Calculates 1RM using the selected formula.
     */
    func calculate(weight: Double, reps: Int) -> Double {
        switch self {
        case .brzycki:
            // Brzycki: Weight × (36 / (37 - Reps))
            return weight * (36.0 / (37.0 - Double(reps)))
        case .epley:
            // Epley: Weight × (1 + 0.0333 × Reps)
            return weight * (1.0 + 0.0333 * Double(reps))
        case .lander:
            // Lander: Weight × (100 / (101.3 - 2.67123 × Reps))
            return weight * (100.0 / (101.3 - 2.67123 * Double(reps)))
        case .custom, .repetitionBased:
            // These require specific handling in exercise types
            return weight
        }
    }
}

// MARK: - Supporting Enums

enum MuscleGroup: String, CaseIterable, Sendable {
    case chest = "chest"
    case shoulders = "shoulders"
    case back = "back"
    case legs = "legs"
    case hips = "hips"
    
    var emoji: String {
        switch self {
        case .chest: return "🫁"
        case .shoulders: return "💪"
        case .back: return "🔙"
        case .legs: return "🦵"
        case .hips: return "🍑"
        }
    }
    
    var name: String {
        switch self {
        case .chest:
            return "strength.muscleGroup.chest".localized
        case .shoulders:
            return "strength.muscleGroup.shoulders".localized
        case .back:
            return "strength.muscleGroup.back".localized
        case .legs:
            return "strength.muscleGroup.legs".localized
        case .hips:
            return "strength.muscleGroup.hips".localized
        }
    }
}

enum StrengthLevel: Int, CaseIterable, Sendable {
    case beginner = 0
    case novice = 1
    case intermediate = 2
    case advanced = 3
    case expert = 4
    case elite = 5
    
    var name: String {
        switch self {
        case .beginner:
            return "strength.level.beginner".localized
        case .novice:
            return "strength.level.novice".localized
        case .intermediate:
            return "strength.level.intermediate".localized
        case .advanced:
            return "strength.level.advanced".localized
        case .expert:
            return "strength.level.expert".localized
        case .elite:
            return "strength.level.elite".localized
        }
    }
    
    var color: String {
        switch self {
        case .beginner: return "red"
        case .novice: return "orange"
        case .intermediate: return "yellow"
        case .advanced: return "green"
        case .expert: return "blue"
        case .elite: return "purple"
        }
    }
    
    var emoji: String {
        switch self {
        case .beginner: return "🔴"
        case .novice: return "🟠"
        case .intermediate: return "🟡"
        case .advanced: return "🟢"
        case .expert: return "🔵"
        case .elite: return "🟣"
        }
    }
}