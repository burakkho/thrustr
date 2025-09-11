import SwiftData
import Foundation

/**
 * Complete strength test session containing all 5 exercise results.
 * 
 * Represents a full strength assessment with calculated overall metrics
 * and integration points for user profile updates.
 */
@Model
final class StrengthTest {
    // MARK: - Core Properties
    var testDate: Date = Date()
    var isCompleted: Bool = false
    var overallScore: Double = 0.0 // Averaged percentile across exercises
    var strengthProfile: String = "unknown" // "balanced", "upper_dominant", "lower_dominant"
    var testDuration: TimeInterval = 0.0 // Time to complete test
    
    // MARK: - Test Results
    @Relationship(deleteRule: .cascade) var results: [StrengthTestResult]?
    
    // MARK: - User Context
    var userAge: Int = 25
    var userGender: String = "male" // Gender rawValue
    var userWeight: Double = 70.0 // kg at time of test
    
    // MARK: - Metadata
    var notes: String?
    var testEnvironment: String? // "gym", "home", etc.
    var wasNewOverallPR: Bool = false // If overall score improved
    
    // MARK: - Computed Properties
    
    var userGenderEnum: Gender {
        get { Gender(rawValue: userGender) ?? .male }
        set { userGender = newValue.rawValue }
    }
    
    var resultsByExercise: [StrengthExerciseType: StrengthTestResult] {
        var dict: [StrengthExerciseType: StrengthTestResult] = [:]
        for result in results ?? [] {
            dict[result.exerciseTypeEnum] = result
        }
        return dict
    }
    
    var completedExercises: [StrengthExerciseType] {
        return results?.map { $0.exerciseTypeEnum } ?? []
    }
    
    var remainingExercises: [StrengthExerciseType] {
        let completed = Set(completedExercises)
        return StrengthExerciseType.allCases.filter { !completed.contains($0) }
    }
    
    var completionPercentage: Double {
        return Double(results?.count ?? 0) / Double(StrengthExerciseType.allCases.count)
    }
    
    var averageStrengthLevel: StrengthLevel {
        guard let results = results, !results.isEmpty else {
            return .beginner
        }
        
        // Safely map strength levels and validate each one
        let validStrengthLevels = results.compactMap { result -> Int? in
            let level = result.strengthLevel
            if level >= 0 && level <= 5 {
                return level
            } else {
                return nil
            }
        }
        
        guard !validStrengthLevels.isEmpty else {
            return .beginner
        }
        
        // Use proper floating point division and round to nearest integer
        let sum = validStrengthLevels.reduce(0, +)
        let averageFloat = Double(sum) / Double(validStrengthLevels.count)
        let averageLevel = Int(averageFloat.rounded())
        
        // Clamp to valid range and create enum safely
        let clampedLevel = max(0, min(5, averageLevel))
        return StrengthLevel(rawValue: clampedLevel) ?? .beginner
    }
    
    var strengthProfileEmoji: String {
        switch strengthProfile {
        case "balanced":
            return "⚖️"
        case "upper_dominant":
            return "💪"
        case "lower_dominant":
            return "🦵"
        default:
            return "❓"
        }
    }
    
    // MARK: - Initialization
    
    init(
        userAge: Int,
        userGender: Gender,
        userWeight: Double,
        testEnvironment: String? = nil,
        notes: String? = nil
    ) {
        self.testDate = Date()
        self.isCompleted = false
        self.overallScore = 0.0
        self.strengthProfile = "unknown"
        self.testDuration = 0
        self.results = nil
        self.userAge = userAge
        self.userGender = userGender.rawValue
        self.userWeight = userWeight
        self.notes = notes
        self.testEnvironment = testEnvironment
        self.wasNewOverallPR = false
    }
    
    // MARK: - Methods
    
    /**
     * Adds a test result for a specific exercise.
     */
    func addResult(_ result: StrengthTestResult) {
        // Initialize results array if needed
        if results == nil {
            results = []
        }
        
        // Remove existing result for same exercise if present
        results!.removeAll { $0.exerciseTypeEnum == result.exerciseTypeEnum }
        
        // Add new result
        results!.append(result)
        
        // Update completion status
        if results!.count == StrengthExerciseType.allCases.count {
            completeTest()
        }
    }
    
    /**
     * Calculates and finalizes the test when all exercises are completed.
     */
    private func completeTest() {
        isCompleted = true
        calculateOverallMetrics()
    }
    
    /**
     * Calculates overall test metrics and strength profile.
     */
    private func calculateOverallMetrics() {
        guard let results = results, !results.isEmpty else { return }
        
        // Calculate overall score as average percentile
        let totalScore = results.map { $0.percentileScore }.reduce(0, +)
        overallScore = totalScore / Double(results.count)
        
        // Determine strength profile
        strengthProfile = calculateStrengthProfile()
    }
    
    /**
     * Analyzes results to determine user's strength profile.
     */
    private func calculateStrengthProfile() -> String {
        guard let results = results else { return "incomplete" }
        
        let upperBodyExercises: [StrengthExerciseType] = [.benchPress, .overheadPress, .pullUp]
        let lowerBodyExercises: [StrengthExerciseType] = [.backSquat, .deadlift]
        
        let upperResults = results.filter { upperBodyExercises.contains($0.exerciseTypeEnum) }
        let lowerResults = results.filter { lowerBodyExercises.contains($0.exerciseTypeEnum) }
        
        guard !upperResults.isEmpty && !lowerResults.isEmpty else { return "incomplete" }
        
        let upperAverage = upperResults.map { $0.percentileScore }.reduce(0, +) / Double(upperResults.count)
        let lowerAverage = lowerResults.map { $0.percentileScore }.reduce(0, +) / Double(lowerResults.count)
        
        let difference = abs(upperAverage - lowerAverage)
        
        if difference < 0.15 { // Within 15% considered balanced
            return "balanced"
        } else if upperAverage > lowerAverage {
            return "upper_dominant"
        } else {
            return "lower_dominant"
        }
    }
    
    /**
     * Gets the result for a specific exercise type.
     */
    func result(for exerciseType: StrengthExerciseType) -> StrengthTestResult? {
        return results?.first { $0.exerciseTypeEnum == exerciseType }
    }
    
    /**
     * Formats test summary for display or sharing.
     */
    func formattedSummary() -> String {
        guard isCompleted else { return "Test in progress..." }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        var summary = "🏋️ Kuvvet Testi - \(dateFormatter.string(from: testDate))\n"
        summary += "💪 Genel Seviye: \(averageStrengthLevel.emoji) \(averageStrengthLevel.name)\n"
        summary += "📊 Profil: \(strengthProfile.capitalized)\n\n"
        
        for result in (results ?? []).sorted(by: { $0.exerciseTypeEnum.rawValue < $1.exerciseTypeEnum.rawValue }) {
            summary += result.formattedSummary() + "\n"
        }
        
        return summary
    }
    
    /**
     * Exports 1RM values for integration with User model.
     */
    func exportOneRMValues() -> [String: Double] {
        var oneRMs: [String: Double] = [:]
        
        for result in results ?? [] {
            let key = result.exerciseTypeEnum.rawValue
            oneRMs[key] = result.value
        }
        
        return oneRMs
    }
}