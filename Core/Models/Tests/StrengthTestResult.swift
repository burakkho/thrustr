import SwiftData
import Foundation

/**
 * Individual exercise result within a strength test.
 * 
 * Stores the performance data for a single exercise during a strength test session,
 * including the raw value and calculated strength level.
 */
@Model
final class StrengthTestResult {
    // MARK: - Core Properties
    var exerciseType: String // StrengthExerciseType rawValue
    var value: Double // Weight in kg or reps for pull-ups
    var strengthLevel: Int // StrengthLevel rawValue
    var percentileScore: Double // 0.0 - 1.0 (position within level)
    
    // MARK: - Additional Data
    var isWeighted: Bool // For pull-ups: bodyweight vs weighted
    var additionalWeight: Double? // Extra weight for weighted pull-ups
    var bodyWeightAtTest: Double? // User's body weight during test
    var notes: String?
    
    // MARK: - Metadata
    var testDate: Date
    var isPersonalRecord: Bool
    
    // MARK: - Computed Properties
    var exerciseTypeEnum: StrengthExerciseType {
        get { StrengthExerciseType(rawValue: exerciseType) ?? .benchPress }
        set { exerciseType = newValue.rawValue }
    }
    
    var strengthLevelEnum: StrengthLevel {
        get { 
            // Validate and clamp strengthLevel to prevent crashes
            let clampedLevel = max(0, min(5, strengthLevel))
            if strengthLevel != clampedLevel {
                print("❌ StrengthTestResult.strengthLevelEnum: Invalid strength level \(strengthLevel), clamping to \(clampedLevel)")
                // Auto-correct the invalid value
                strengthLevel = clampedLevel
            }
            return StrengthLevel(rawValue: clampedLevel) ?? .beginner
        }
        set { 
            // Ensure only valid values are stored
            let clampedValue = max(0, min(5, newValue.rawValue))
            strengthLevel = clampedValue
        }
    }
    
    var displayValue: String {
        if exerciseTypeEnum.isRepetitionBased {
            return String(format: "%.0f %@", value, exerciseTypeEnum.unit)
        } else {
            return String(format: "%.1f %@", value, exerciseTypeEnum.unit)
        }
    }
    
    var effectiveWeight: Double {
        // For pull-ups, calculate effective weight lifted
        if exerciseTypeEnum == .pullUp {
            let bodyWeight = bodyWeightAtTest ?? 80.0
            if isWeighted, let additional = additionalWeight {
                return (bodyWeight + additional) * value / bodyWeight
            } else {
                return value // Just reps for bodyweight pull-ups
            }
        }
        return value
    }
    
    // MARK: - Initialization
    init(
        exerciseType: StrengthExerciseType,
        value: Double,
        strengthLevel: StrengthLevel = .beginner,
        percentileScore: Double = 0.0,
        isWeighted: Bool = false,
        additionalWeight: Double? = nil,
        bodyWeightAtTest: Double? = nil,
        notes: String? = nil,
        testDate: Date = Date(),
        isPersonalRecord: Bool = false
    ) {
        self.exerciseType = exerciseType.rawValue
        
        // Validate and sanitize input values
        self.value = max(0.0, value.isFinite ? value : 0.0)
        
        // Ensure strength level is always valid (0-5 range)
        let clampedLevel = max(0, min(5, strengthLevel.rawValue))
        self.strengthLevel = clampedLevel
        
        // Validate percentile score (0.0-1.0 range)
        self.percentileScore = max(0.0, min(1.0, percentileScore.isFinite ? percentileScore : 0.0))
        
        self.isWeighted = isWeighted
        
        // Validate additional weight
        self.additionalWeight = additionalWeight?.isFinite == true ? additionalWeight : nil
        
        // Validate body weight
        self.bodyWeightAtTest = bodyWeightAtTest?.isFinite == true ? bodyWeightAtTest : nil
        
        self.notes = notes
        self.testDate = testDate
        self.isPersonalRecord = isPersonalRecord
        
        print("✅ StrengthTestResult: Created result for \(exerciseType.name) with level \(strengthLevel.name)")
    }
    
    // MARK: - Methods
    
    /**
     * Updates the result with new performance data and recalculates level.
     */
    func updateResult(
        newValue: Double,
        newLevel: StrengthLevel,
        newPercentile: Double,
        isWeighted: Bool = false,
        additionalWeight: Double? = nil
    ) {
        let wasNewPR = newValue > self.value
        
        self.value = newValue
        self.strengthLevelEnum = newLevel
        self.percentileScore = newPercentile
        self.isWeighted = isWeighted
        self.additionalWeight = additionalWeight
        self.testDate = Date()
        
        if wasNewPR {
            self.isPersonalRecord = true
        }
    }
    
    /**
     * Formats the result for sharing or display purposes.
     */
    func formattedSummary() -> String {
        let levelEmoji = strengthLevelEnum.emoji
        let muscleEmoji = exerciseTypeEnum.muscleGroup.emoji
        
        return "\(muscleEmoji) \(exerciseTypeEnum.name): \(displayValue) \(levelEmoji)"
    }
}