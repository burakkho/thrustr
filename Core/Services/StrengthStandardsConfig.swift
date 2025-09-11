import Foundation

/**
 * Configurable strength standards for different demographics.
 * 
 * Provides scaled strength standards based on user characteristics
 * including gender, age, and body weight adjustments.
 */
struct StrengthStandardsConfig: Sendable {
    
    // MARK: - Scaling Factors
    
    struct ScalingFactors: Sendable {
        static let femaleMultiplier: Double = 0.7
        static let ageGroup36_45Multiplier: Double = 0.95
        static let ageGroup45PlusMultiplier: Double = 0.9
    }
    
    // MARK: - Age Groups
    
    enum AgeGroup: Sendable {
        case young      // 18-35
        case middle     // 36-45
        case mature     // 45+
        
        static func from(age: Int) -> AgeGroup {
            switch age {
            case 18..<36:
                return .young
            case 36..<46:
                return .middle
            default:
                return .mature
            }
        }
        
        var multiplier: Double {
            switch self {
            case .young:
                return 1.0
            case .middle:
                return ScalingFactors.ageGroup36_45Multiplier
            case .mature:
                return ScalingFactors.ageGroup45PlusMultiplier
            }
        }
    }
    
    // MARK: - Weight Classes (for future body weight adjustments)
    
    struct WeightClass: Sendable {
        let minWeight: Double
        let maxWeight: Double
        let multiplier: Double
        
        static let classes: [WeightClass] = [
            WeightClass(minWeight: 0, maxWeight: 60, multiplier: 0.85),
            WeightClass(minWeight: 60, maxWeight: 75, multiplier: 0.95),
            WeightClass(minWeight: 75, maxWeight: 90, multiplier: 1.0),  // Base class
            WeightClass(minWeight: 90, maxWeight: 110, multiplier: 1.05),
            WeightClass(minWeight: 110, maxWeight: 200, multiplier: 1.1)
        ]
        
        static func multiplier(for weight: Double) -> Double {
            return classes.first { weight >= $0.minWeight && weight < $0.maxWeight }?.multiplier ?? 1.0
        }
    }
    
    // MARK: - Methods
    
    /**
     * Calculates adjusted strength standards for a specific user and exercise.
     */
    static func adjustedStandards(
        for exerciseType: StrengthExerciseType,
        userGender: Gender,
        userAge: Int,
        userWeight: Double
    ) -> [Double] {
        let baseStandards = exerciseType.baseStandards
        let ageGroup = AgeGroup.from(age: userAge)
        
        // Apply gender scaling
        let genderMultiplier = userGender == .female ? ScalingFactors.femaleMultiplier : 1.0
        
        // Apply age scaling
        let ageMultiplier = ageGroup.multiplier
        
        // Apply weight class scaling (currently disabled, but available)
        let weightMultiplier = 1.0 // WeightClass.multiplier(for: userWeight)
        
        // Calculate final multiplier
        let totalMultiplier = genderMultiplier * ageMultiplier * weightMultiplier
        
        // Apply scaling to all standards
        return baseStandards.map { $0 * totalMultiplier }
    }
    
    /**
     * Gets the strength level for a given performance value.
     */
    static func strengthLevel(
        for value: Double,
        exerciseType: StrengthExerciseType,
        userGender: Gender,
        userAge: Int,
        userWeight: Double
    ) -> (level: StrengthLevel, percentileInLevel: Double) {
        
        let standards = adjustedStandards(
            for: exerciseType,
            userGender: userGender,
            userAge: userAge,
            userWeight: userWeight
        )
        
        // Special handling for pull-ups with weighted option
        let effectiveValue = calculateEffectiveValue(
            value: value,
            exerciseType: exerciseType,
            userWeight: userWeight
        )
        
        // Find the appropriate level by checking each threshold
        for (index, threshold) in standards.enumerated() {
            if effectiveValue < threshold {
                // User is below this threshold, so they're at the previous level (or beginner if index == 0)
                if index == 0 {
                    // Below beginner threshold
                    let percentile = min(max(effectiveValue / threshold, 0.0), 0.99)
                    return (level: .beginner, percentileInLevel: percentile)
                } else {
                    // Between previous level and this threshold
                    let level = StrengthLevel(rawValue: index - 1) ?? .beginner
                    let previousThreshold = standards[index - 1]
                    let percentile = calculatePercentileInLevel(
                        value: effectiveValue,
                        threshold: previousThreshold,
                        nextThreshold: threshold
                    )
                    return (level: level, percentileInLevel: percentile)
                }
            }
        }
        
        // If we reach here, user exceeded the highest threshold (Elite level)
        let level = StrengthLevel(rawValue: standards.count - 1) ?? .elite
        let highestThreshold = standards.last ?? 1.0
        
        // For elite level, calculate how much above the threshold they are
        let percentile = min(0.5 + (effectiveValue - highestThreshold) / (highestThreshold * 0.5), 1.0)
        
        return (level: level, percentileInLevel: percentile)
    }
    
    /**
     * Calculates effective value for comparison, handling special cases like weighted pull-ups.
     */
    private static func calculateEffectiveValue(
        value: Double,
        exerciseType: StrengthExerciseType,
        userWeight: Double,
        additionalWeight: Double = 0
    ) -> Double {
        
        if exerciseType == .pullUp && additionalWeight > 0 {
            // For weighted pull-ups, calculate equivalent bodyweight reps
            let totalWeight = userWeight + additionalWeight
            return (totalWeight / userWeight) * value
        }
        
        return value
    }
    
    /**
     * Calculates position within a strength level (0.0 - 1.0).
     * Returns how far through the current level the user is.
     */
    private static func calculatePercentileInLevel(
        value: Double,
        threshold: Double,
        nextThreshold: Double
    ) -> Double {
        
        // Ensure we have valid thresholds
        guard threshold > 0, nextThreshold > threshold else {
            return 0.5 // Middle of level if invalid thresholds
        }
        
        // Calculate position within the level range
        let position = (value - threshold) / (nextThreshold - threshold)
        
        // Clamp to valid range and ensure minimum visibility
        let clampedPosition = max(0.0, min(1.0, position))
        
        // Ensure minimum 10% visibility even at level threshold
        return max(0.1, clampedPosition)
    }
    
    /**
     * Provides textual description of strength standards for educational purposes.
     */
    static func standardsDescription(for exerciseType: StrengthExerciseType) -> String {
        switch exerciseType {
        case .benchPress:
            return "strength.standards.benchPress.description".localized
        case .overheadPress:
            return "strength.standards.overheadPress.description".localized
        case .pullUp:
            return "strength.standards.pullUp.description".localized
        case .backSquat:
            return "strength.standards.backSquat.description".localized
        case .deadlift:
            return "strength.standards.deadlift.description".localized
        }
    }
    
    /**
     * Calculates target weights/reps for next strength level.
     */
    static func targetForNextLevel(
        currentValue: Double,
        exerciseType: StrengthExerciseType,
        userGender: Gender,
        userAge: Int,
        userWeight: Double
    ) -> Double? {
        
        let (currentLevel, _) = strengthLevel(
            for: currentValue,
            exerciseType: exerciseType,
            userGender: userGender,
            userAge: userAge,
            userWeight: userWeight
        )
        
        let standards = adjustedStandards(
            for: exerciseType,
            userGender: userGender,
            userAge: userAge,
            userWeight: userWeight
        )
        
        let nextLevelIndex = currentLevel.rawValue + 1
        
        guard nextLevelIndex < standards.count else {
            return nil // Already at highest level
        }
        
        return standards[nextLevelIndex]
    }
}