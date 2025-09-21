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
    private let healthKitService = HealthKitService.shared

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
        return healthKitService.todaySteps
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
        return healthKitService.weightHistory
    }

    /**
     * Steps history for trends.
     */
    var stepsHistory: [Double] {
        return healthKitService.stepsHistory
    }

    // MARK: - Initialization

    init() {
        // No additional initialization needed
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

        do {
            await healthKitService.readTodaysData()
            healthDataLoaded = true
        } catch {
            errorMessage = "Failed to load health data: \(error.localizedDescription)"
        }

        isLoading = false
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
}