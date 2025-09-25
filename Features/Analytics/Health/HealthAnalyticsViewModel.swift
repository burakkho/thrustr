import SwiftUI
import SwiftData
import Foundation

/**
 * ViewModel for HealthAnalyticsView with clean separation of concerns.
 *
 * Manages health data processing, HealthKit integration, and user analytics.
 * Coordinates with HealthKitService for data access.
 */
@MainActor
@Observable
class HealthAnalyticsViewModel {

    // MARK: - State
    var currentUser: User?
    var isLoading = false
    var errorMessage: String?
    var healthDataLoaded = false

    // MARK: - Dependencies
    private let healthKitService: HealthKitService

    // MARK: - Computed Properties

    /**
     * Whether health data is available for analytics.
     */
    var hasHealthData: Bool {
        return healthKitService.isAuthorized && healthDataLoaded
    }

    /**
     * Current step count for today.
     */
    var todaySteps: Int {
        return Int(healthKitService.todaySteps)
    }

    /**
     * Current active calories for today.
     */
    var todayActiveCalories: Double {
        return healthKitService.todayActiveCalories
    }

    /**
     * Current heart rate if available.
     */
    var currentHeartRate: Double? {
        return healthKitService.currentHeartRate
    }

    /**
     * VO2 Max value if available.
     */
    var vo2Max: Double? {
        return healthKitService.vo2Max
    }

    /**
     * Weight history for trends.
     */
    var weightHistory: [Double] {
        return healthKitService.weightHistory.map { $0.value }
    }

    /**
     * Steps history for trends.
     */
    var stepsHistory: [Double] {
        return healthKitService.stepsHistory.map { $0.value }
    }

    // MARK: - Initialization

    init(healthKitService: HealthKitService? = nil) {
        self.healthKitService = healthKitService ?? HealthKitService.shared
    }

    // MARK: - Public Methods

    /**
     * Updates user data.
     */
    func updateUser(_ user: User?) {
        currentUser = user
    }

    /**
     * Loads today's health data from HealthKit.
     */
    func loadTodaysHealthData() async {
        isLoading = true
        errorMessage = nil

        await healthKitService.readTodaysData()
        healthDataLoaded = true

        isLoading = false
    }

    /**
     * Generates health intelligence report.
     */
    func generateHealthIntelligence() async -> HealthReport? {
        return await HealthAnalyticsService.generateHealthIntelligence()
    }

    /**
     * Gets priority insights from a health report.
     */
    func getPriorityInsights(from insights: [HealthInsight]) -> [HealthInsight] {
        return HealthAnalyticsService.getPriorityInsights(from: insights)
    }

    /**
     * Gets trend insights from a health report.
     */
    func getTrendInsights(from insights: [HealthInsight]) -> [HealthInsight] {
        return HealthAnalyticsService.getTrendInsights(from: insights)
    }

    /**
     * Refreshes all health data.
     */
    func refreshHealthData() async {
        await loadTodaysHealthData()
    }

    /**
     * Checks if HealthKit is authorized.
     */
    var isHealthKitAuthorized: Bool {
        return healthKitService.isAuthorized
    }

    /**
     * Gets formatted step count.
     */
    func formattedStepCount() -> String {
        return "\(todaySteps)"
    }

    /**
     * Gets formatted active calories.
     */
    func formattedActiveCalories() -> String {
        return "\(Int(todayActiveCalories))"
    }

    /**
     * Gets formatted heart rate if available.
     */
    func formattedHeartRate() -> String {
        guard let heartRate = currentHeartRate else { return "--" }
        return "\(Int(heartRate))"
    }

    /**
     * Gets health score based on current metrics.
     */
    func calculateHealthScore() -> Double {
        guard hasHealthData else { return 0.0 }

        // Simple health score calculation based on available metrics
        var score = 0.0
        var factors = 0

        // Steps factor (target: 10,000 steps)
        if todaySteps > 0 {
            score += min(Double(todaySteps) / 10000.0 * 100, 100)
            factors += 1
        }

        // Active calories factor (target: 500 calories)
        if todayActiveCalories > 0 {
            score += min(todayActiveCalories / 500.0 * 100, 100)
            factors += 1
        }

        // Heart rate factor (if available)
        if let heartRate = currentHeartRate, heartRate > 0 {
            // Assuming resting heart rate between 60-80 is good
            let normalizedHR = max(0, min(100, 100 - abs(heartRate - 70) * 2))
            score += normalizedHR
            factors += 1
        }

        return factors > 0 ? score / Double(factors) : 0.0
    }

    // MARK: - Health Rings Calculations

    /**
     * Steps progress percentage (0.0 to 1.0)
     */
    var stepsProgress: Double {
        min(healthKitService.todaySteps / 10000.0, 1.0)
    }

    /**
     * Calories progress percentage (0.0 to 1.0)
     */
    var caloriesProgress: Double {
        guard let user = currentUser else { return 0 }
        return min(healthKitService.todayActiveCalories / user.dailyCalorieGoal, 1.0)
    }

    /**
     * Formats steps count with k notation
     */
    func formatSteps(_ steps: Double) -> String {
        if steps >= 1000 {
            return String(format: "%.1fk", steps / 1000)
        }
        return String(format: "%.0f", steps)
    }

    /**
     * Formats calories count
     */
    func formatCalories(_ calories: Double) -> String {
        String(format: "%.0f", calories)
    }

    /**
     * Formats calorie goal with k notation
     */
    func formatCalorieGoal() -> String {
        guard let user = currentUser else { return "2000" }
        if user.dailyCalorieGoal >= 1000 {
            return String(format: "%.1fk", user.dailyCalorieGoal / 1000)
        }
        return String(format: "%.0f", user.dailyCalorieGoal)
    }

    /**
     * Calculates recovery score based on multiple health factors
     */
    func calculateRecoveryScore() -> Int {
        let heartRate = healthKitService.restingHeartRate ?? 70
        let steps = healthKitService.todaySteps
        let activeCalories = healthKitService.todayActiveCalories

        var score = 50 // Base score

        // Heart Rate Assessment (30 points)
        let heartRateScore: Int
        switch heartRate {
        case 0..<50: heartRateScore = 30 // Athletic level
        case 50..<60: heartRateScore = 25 // Excellent
        case 60..<70: heartRateScore = 20 // Good
        case 70..<80: heartRateScore = 15 // Average
        case 80..<90: heartRateScore = 10 // Below average
        default: heartRateScore = 5 // Poor
        }
        score += heartRateScore

        // Activity Balance Assessment (20 points)
        let activityScore: Int
        if steps >= 12000 && activeCalories >= 600 {
            activityScore = 20 // Optimal activity
        } else if steps >= 8000 && activeCalories >= 400 {
            activityScore = 15 // Good activity
        } else if steps >= 5000 && activeCalories >= 200 {
            activityScore = 10 // Moderate activity
        } else if steps < 2000 && activeCalories < 100 {
            activityScore = 20 // Complete rest (good for recovery)
        } else {
            activityScore = 5 // Poor balance
        }
        score += activityScore

        return max(10, min(score, 100)) // Ensure score is between 10-100
    }
}