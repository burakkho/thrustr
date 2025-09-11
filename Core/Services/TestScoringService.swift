import Foundation

/**
 * Service for calculating strength test scores and managing test logic.
 * 
 * Handles test result calculations, personal record tracking, and
 * provides recommendations based on test outcomes.
 */
@MainActor
@Observable
class TestScoringService {
    
    // MARK: - Singleton Instance
    static let shared = TestScoringService()
    
    private init() {}
    
    // MARK: - Test Scoring Methods
    
    /**
     * Scores a single exercise performance and returns detailed result.
     */
    func scoreExercise(
        exerciseType: StrengthExerciseType,
        value: Double,
        userGender: Gender,
        userAge: Int,
        userWeight: Double,
        isWeighted: Bool = false,
        additionalWeight: Double = 0,
        previousBest: Double? = nil
    ) -> StrengthTestResult {
        
        // Calculate strength level and percentile
        let (level, percentile) = StrengthStandardsConfig.strengthLevel(
            for: value,
            exerciseType: exerciseType,
            userGender: userGender,
            userAge: userAge,
            userWeight: userWeight
        )
        
        // Check if this is a personal record
        let isPersonalRecord = previousBest.map { value > $0 } ?? true
        
        // Create result
        let result = StrengthTestResult(
            exerciseType: exerciseType,
            value: value,
            strengthLevel: level,
            percentileScore: percentile,
            isWeighted: isWeighted,
            additionalWeight: additionalWeight > 0 ? additionalWeight : nil,
            bodyWeightAtTest: userWeight,
            testDate: Date(),
            isPersonalRecord: isPersonalRecord
        )
        
        return result
    }
    
    /**
     * Calculates overall test score and strength profile.
     */
    func calculateOverallScore(from results: [StrengthTestResult]) -> (score: Double, profile: String) {
        guard !results.isEmpty else { return (0.0, "incomplete") }
        
        // Calculate weighted overall score
        let totalScore = results.map { result in
            // Weight pull-ups slightly higher as they're more challenging
            let weight = result.exerciseTypeEnum == .pullUp ? 1.2 : 1.0
            return result.percentileScore * weight
        }.reduce(0.0, +)
        
        let totalWeight = results.map { result in
            result.exerciseTypeEnum == .pullUp ? 1.2 : 1.0
        }.reduce(0.0, +)
        
        let overallScore = totalScore / totalWeight
        
        // Determine strength profile
        let profile = calculateStrengthProfile(from: results)
        
        return (overallScore, profile)
    }
    
    /**
     * Analyzes results to determine strength profile.
     */
    private func calculateStrengthProfile(from results: [StrengthTestResult]) -> String {
        let upperBodyExercises: Set<StrengthExerciseType> = [.benchPress, .overheadPress, .pullUp]
        let lowerBodyExercises: Set<StrengthExerciseType> = [.backSquat, .deadlift]
        
        let upperResults = results.filter { upperBodyExercises.contains($0.exerciseTypeEnum) }
        let lowerResults = results.filter { lowerBodyExercises.contains($0.exerciseTypeEnum) }
        
        guard !upperResults.isEmpty && !lowerResults.isEmpty else { return "incomplete" }
        
        let upperAverage = upperResults.map { $0.percentileScore }.reduce(0, +) / Double(upperResults.count)
        let lowerAverage = lowerResults.map { $0.percentileScore }.reduce(0, +) / Double(lowerResults.count)
        
        let difference = abs(upperAverage - lowerAverage)
        let threshold: Double = 0.15 // 15% difference threshold
        
        if difference < threshold {
            return "balanced"
        } else if upperAverage > lowerAverage {
            return "upper_dominant"
        } else {
            return "lower_dominant"
        }
    }
    
    // MARK: - Recommendation Methods
    
    /**
     * Generates training recommendations based on test results.
     */
    func generateRecommendations(for strengthTest: StrengthTest) -> [String] {
        guard strengthTest.isCompleted else { return [] }
        
        var recommendations: [String] = []
        
        // Analyze individual exercise weaknesses
        let sortedResults = (strengthTest.results ?? []).sorted { $0.percentileScore < $1.percentileScore }
        
        if let weakest = sortedResults.first {
            let exerciseName = weakest.exerciseTypeEnum.name
            recommendations.append("strength.recommendations.focusOn".localized.replacingOccurrences(of: "{exercise}", with: exerciseName))
        }
        
        // Profile-based recommendations
        switch strengthTest.strengthProfile {
        case "upper_dominant":
            recommendations.append("strength.recommendations.lowerBodyFocus".localized)
        case "lower_dominant":
            recommendations.append("strength.recommendations.upperBodyFocus".localized)
        case "balanced":
            recommendations.append("strength.recommendations.maintainBalance".localized)
        default:
            break
        }
        
        // Level-based recommendations
        let averageLevel = strengthTest.averageStrengthLevel
        switch averageLevel {
        case .beginner, .novice:
            recommendations.append("strength.recommendations.beginnerProgram".localized)
        case .intermediate:
            recommendations.append("strength.recommendations.intermediateProgram".localized)
        case .advanced, .expert, .elite:
            recommendations.append("strength.recommendations.advancedProgram".localized)
        }
        
        return recommendations
    }
    
    /**
     * Suggests next test date based on current level and progress.
     */
    func suggestNextTestDate(from lastTest: StrengthTest) -> Date {
        let averageLevel = lastTest.averageStrengthLevel
        
        let weeksUntilRetest: Int = switch averageLevel {
        case .beginner, .novice:
            4 // Rapid progress expected
        case .intermediate:
            6 // Moderate progress
        case .advanced, .expert, .elite:
            8 // Slower progress
        }
        
        return Calendar.current.date(byAdding: .weekOfYear, value: weeksUntilRetest, to: lastTest.testDate) ?? Date()
    }
    
    /**
     * Calculates training weights based on test results.
     */
    func calculateTrainingWeights(from strengthTest: StrengthTest) -> [String: [String: Double]] {
        var trainingWeights: [String: [String: Double]] = [:]
        
        for result in strengthTest.results ?? [] {
            let exerciseKey = result.exerciseTypeEnum.rawValue
            let oneRM = result.value
            
            // Skip reps-based exercises
            guard !result.exerciseTypeEnum.isRepetitionBased else { continue }
            
            // Calculate training percentages
            trainingWeights[exerciseKey] = [
                "warmup_light": oneRM * 0.4,    // 40% for warm-up
                "warmup_moderate": oneRM * 0.6,  // 60% for warm-up
                "working_light": oneRM * 0.7,    // 70% for higher rep work
                "working_moderate": oneRM * 0.8, // 80% for moderate work
                "working_heavy": oneRM * 0.9,    // 90% for heavy singles
                "opener": oneRM * 0.85,          // 85% for competition opener
                "target": oneRM * 1.02           // 102% target for next attempt
            ]
        }
        
        return trainingWeights
    }
    
    /**
     * Formats test summary for sharing or export.
     */
    func formatTestSummary(_ strengthTest: StrengthTest, includeRecommendations: Bool = true) -> String {
        guard strengthTest.isCompleted else {
            return "strength.summary.incomplete".localized
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        var summary = "🏋️ \("strength.test.title".localized) - \(dateFormatter.string(from: strengthTest.testDate))\n\n"
        
        // Overall metrics
        summary += "📊 \("strength.summary.overallLevel".localized): \(strengthTest.averageStrengthLevel.emoji) \(strengthTest.averageStrengthLevel.name)\n"
        summary += "💪 \("strength.summary.profile".localized): \(strengthTest.strengthProfile.capitalized)\n"
        summary += "🎯 \("strength.summary.score".localized): \(String(format: "%.1f%%", strengthTest.overallScore * 100))\n\n"
        
        // Individual results
        summary += "📋 \("strength.summary.results".localized):\n"
        let sortedResults = (strengthTest.results ?? []).sorted { $0.exerciseTypeEnum.rawValue < $1.exerciseTypeEnum.rawValue }
        for result in sortedResults {
            summary += "• \(result.formattedSummary())\n"
        }
        
        // Recommendations
        if includeRecommendations {
            let recommendations = generateRecommendations(for: strengthTest)
            if !recommendations.isEmpty {
                summary += "\n💡 \("strength.summary.recommendations".localized):\n"
                for recommendation in recommendations {
                    summary += "• \(recommendation)\n"
                }
            }
        }
        
        summary += "\n🤖 Generated with Thrustr"
        
        return summary
    }
    
    /**
     * Validates test input values.
     */
    func validateTestInput(
        exerciseType: StrengthExerciseType,
        value: Double,
        userWeight: Double,
        additionalWeight: Double = 0
    ) -> (isValid: Bool, errorMessage: String?) {
        
        // Basic range validation
        guard value > 0 else {
            return (false, "strength.validation.positiveValue".localized)
        }
        
        // Exercise-specific validation
        switch exerciseType {
        case .pullUp:
            guard value <= 100 else {
                return (false, "strength.validation.pullUpMax".localized)
            }
        case .benchPress, .overheadPress, .backSquat, .deadlift:
            guard value <= 500 else {
                return (false, "strength.validation.weightMax".localized)
            }
            guard value >= 5 else {
                return (false, "strength.validation.weightMin".localized)
            }
        }
        
        // Sanity checks
        if exerciseType == .overheadPress && value > userWeight * 2 {
            return (false, "strength.validation.ohpSanity".localized)
        }
        
        if exerciseType == .benchPress && value > userWeight * 3 {
            return (false, "strength.validation.benchSanity".localized)
        }
        
        return (true, nil)
    }
}