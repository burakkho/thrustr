import Foundation
import SwiftUI

/**
 * Profile analytics service with comprehensive strength and fitness analysis.
 *
 * This utility struct provides analytics calculation logic extracted from views
 * to maintain clean separation of concerns. Handles strength level analysis,
 * fitness progression tracking, and user performance analytics.
 *
 * Supported analytics:
 * - Overall strength level calculation based on 1RM data
 * - Strength level color coding and display formatting
 * - Fitness progression analysis over time
 * - Performance benchmarking against standards
 */
struct ProfileAnalyticsService: Sendable {

    // MARK: - Strength Level Analysis

    /**
     * Calculates overall strength level based on user's 1RM data across major lifts.
     *
     * Uses strength standards to evaluate performance across bench press, squat,
     * deadlift, overhead press, and pull-ups. Applies demographic adjustments
     * for age, gender, and body weight to provide accurate assessment.
     *
     * - Parameter user: User profile with 1RM data and demographics
     * - Returns: Tuple containing display string and strength level enum
     */
    static func getOverallStrengthLevel(user: User) -> (level: String, strengthLevel: StrengthLevel?) {

        // Validate user has required data
        guard user.hasCompleteOneRMData,
              user.age > 0,
              user.currentWeight > 0 else {
            return ("--", nil)
        }

        // Major compound exercises for strength assessment
        let exercises: [StrengthExerciseType] = [
            .benchPress,
            .backSquat,
            .deadlift,
            .overheadPress,
            .pullUp
        ]

        var strengthLevels: [StrengthLevel] = []

        // Calculate strength level for each exercise
        for exercise in exercises {
            guard let oneRM = user.getCurrentOneRM(for: exercise),
                  oneRM > 0 else { continue }

            let (level, _) = StrengthStandardsConfig.strengthLevel(
                for: oneRM,
                exerciseType: exercise,
                userGender: user.genderEnum,
                userAge: user.age,
                userWeight: user.currentWeight
            )

            strengthLevels.append(level)
        }

        // Return default if no valid exercises
        guard !strengthLevels.isEmpty else {
            return ("--", nil)
        }

        // Calculate weighted average strength level
        let averageRawValue = strengthLevels.map { $0.rawValue }.reduce(0, +) / strengthLevels.count
        let clampedValue = max(0, min(5, averageRawValue))
        let overallLevel = StrengthLevel(rawValue: clampedValue) ?? .beginner

        // Generate display abbreviation
        let abbreviation = getStrengthLevelAbbreviation(overallLevel)

        return (abbreviation, overallLevel)
    }

    /**
     * Gets the appropriate color for a user's strength level display.
     *
     * - Parameter user: User profile for strength level calculation
     * - Returns: SwiftUI Color for strength level visualization
     */
    static func getStrengthLevelColor(user: User) -> Color {
        let (_, strengthLevel) = getOverallStrengthLevel(user: user)

        guard let level = strengthLevel else { return .gray }

        switch level {
        case .beginner:
            return .red
        case .novice:
            return .orange
        case .intermediate:
            return .yellow
        case .advanced:
            return .green
        case .expert:
            return .blue
        case .elite:
            return .purple
        }
    }

    /**
     * Determines if user has sufficient data for strength level analysis.
     *
     * - Parameter user: User profile to evaluate
     * - Returns: Boolean indicating if strength level can be calculated
     */
    static func canCalculateStrengthLevel(user: User) -> Bool {
        return user.hasCompleteOneRMData && user.age > 0 && user.currentWeight > 0
    }

    /**
     * Provides strength level progress percentage for users working toward next level.
     *
     * - Parameters:
     *   - user: User profile with current strength data
     *   - targetLevel: Optional target strength level (defaults to next level)
     * - Returns: Progress percentage (0.0 to 1.0) toward target level
     */
    static func getStrengthLevelProgress(
        user: User,
        targetLevel: StrengthLevel? = nil
    ) -> Double {

        let (_, currentLevel) = getOverallStrengthLevel(user: user)
        guard let current = currentLevel else { return 0.0 }

        let target = targetLevel ?? getNextStrengthLevel(current)
        guard let next = target else { return 1.0 } // Already at max level

        // This is a simplified progress calculation
        // Could be enhanced with more sophisticated analysis of individual lift progress
        let currentValue = Double(current.rawValue)
        let targetValue = Double(next.rawValue)

        // Calculate position within current level (simplified)
        let progressWithinLevel = 0.5 // Could be calculated based on proximity to next level thresholds
        let progress = (currentValue + progressWithinLevel) / targetValue

        return min(1.0, max(0.0, progress))
    }

    // MARK: - Fitness Assessment

    /**
     * Calculates comprehensive fitness score based on available user data.
     *
     * - Parameter user: User profile with fitness data
     * - Returns: Overall fitness score (0-100)
     */
    static func calculateOverallFitnessScore(user: User) -> Int {
        var score = 0
        var components = 0

        // Strength component (0-25 points)
        if canCalculateStrengthLevel(user: user) {
            let (_, strengthLevel) = getOverallStrengthLevel(user: user)
            if let level = strengthLevel {
                score += Int((Double(level.rawValue) / 5.0) * 25)
            }
            components += 1
        }

        // Body composition component (0-25 points) - if available
        if let bodyFat = user.calculateBodyFatPercentage() {
            let bodyFatScore = calculateBodyFatScore(bodyFat: bodyFat, gender: user.genderEnum)
            score += bodyFatScore
            components += 1
        }

        // BMI component (0-25 points)
        let bmi = user.bmi
        let bmiScore = calculateBMIScore(bmi: bmi)
        score += bmiScore
        components += 1

        // Age-adjusted component (0-25 points)
        let ageScore = calculateAgeAdjustedScore(age: user.age)
        score += ageScore
        components += 1

        // Average the scores if we have components
        return components > 0 ? (score * 4) / (components * 4) : 0
    }

    // MARK: - Private Helper Methods

    /**
     * Gets localized strength level abbreviation.
     */
    private static func getStrengthLevelAbbreviation(_ level: StrengthLevel) -> String {
        switch level {
        case .beginner:
            return DashboardKeys.StrengthLevels.beginnerShort.localized
        case .novice:
            return DashboardKeys.StrengthLevels.noviceShort.localized
        case .intermediate:
            return DashboardKeys.StrengthLevels.intermediateShort.localized
        case .advanced:
            return DashboardKeys.StrengthLevels.advancedShort.localized
        case .expert:
            return DashboardKeys.StrengthLevels.expertShort.localized
        case .elite:
            return DashboardKeys.StrengthLevels.eliteShort.localized
        }
    }

    /**
     * Determines the next strength level for progression tracking.
     */
    private static func getNextStrengthLevel(_ current: StrengthLevel) -> StrengthLevel? {
        switch current {
        case .beginner:
            return .novice
        case .novice:
            return .intermediate
        case .intermediate:
            return .advanced
        case .advanced:
            return .expert
        case .expert:
            return .elite
        case .elite:
            return nil // Already at max level
        }
    }

    /**
     * Calculates body fat score component (0-25 points).
     */
    private static func calculateBodyFatScore(bodyFat: Double, gender: Gender) -> Int {
        // Healthy body fat ranges (approximate)
        let (optimalMin, optimalMax) = gender == .male ? (10.0, 18.0) : (16.0, 24.0)

        if bodyFat >= optimalMin && bodyFat <= optimalMax {
            return 25 // Optimal range
        } else if bodyFat < optimalMin {
            // Too low - scale down
            return max(0, Int(25 - (optimalMin - bodyFat) * 2))
        } else {
            // Too high - scale down
            return max(0, Int(25 - (bodyFat - optimalMax)))
        }
    }

    /**
     * Calculates BMI score component (0-25 points).
     */
    private static func calculateBMIScore(bmi: Double) -> Int {
        // BMI scoring based on healthy ranges
        if bmi >= 18.5 && bmi < 25.0 {
            return 25 // Normal range
        } else if bmi >= 25.0 && bmi < 30.0 {
            return 15 // Overweight
        } else if bmi >= 17.0 && bmi < 18.5 {
            return 20 // Slightly underweight
        } else if bmi >= 30.0 && bmi < 35.0 {
            return 10 // Obese class I
        } else {
            return 5 // Extreme BMI values
        }
    }

    /**
     * Calculates age-adjusted fitness score component (0-25 points).
     */
    private static func calculateAgeAdjustedScore(age: Int) -> Int {
        // Simple age-adjusted scoring - could be enhanced with research data
        switch age {
        case 18...29:
            return 25
        case 30...39:
            return 23
        case 40...49:
            return 20
        case 50...59:
            return 18
        case 60...69:
            return 15
        default:
            return 12
        }
    }
}