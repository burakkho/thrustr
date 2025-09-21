import Foundation
import SwiftUI

@MainActor
@Observable
class HealthTrendsViewModel {

    // MARK: - Published State

    var isLoading = false
    var selectedMetric: HealthMetric = .steps
    var hasError = false
    var errorMessage = ""

    // MARK: - Initialization

    init() {
        // No dependencies needed - using static service calls
    }

    // MARK: - Public Methods

    func loadHealthTrendsData() async {
        isLoading = true
        hasError = false
        errorMessage = ""

        defer {
            isLoading = false
        }

        await HealthAnalyticsService.refreshHealthData()
    }

    func getDataPointsForMetric(_ metric: HealthMetric) -> [HealthDataPoint] {
        let healthKitAnalytics = HealthKitAnalyticsService.shared

        switch metric {
        case .steps:
            return healthKitAnalytics.stepsHistory
        case .weight:
            return healthKitAnalytics.weightHistory
        case .heartRate:
            return healthKitAnalytics.heartRateHistory
        }
    }

    func changeMetric(to metric: HealthMetric) {
        selectedMetric = metric
    }

    // MARK: - Helper Methods

    func getWorkoutTrends() -> WorkoutTrends? {
        let healthKitService = HealthKitService.shared
        return healthKitService.workoutTrends
    }

    func getHealthStats() -> HealthStats {
        let healthKitService = HealthKitService.shared

        return HealthStats(
            todaySteps: healthKitService.todaySteps,
            todayCalories: healthKitService.todayCalories,
            currentWeight: healthKitService.currentWeight ?? 0.0,
            restingHeartRate: healthKitService.restingHeartRate ?? 0.0
        )
    }

    // MARK: - Private Methods

    private func handleError(_ error: Error) {
        hasError = true
        errorMessage = error.localizedDescription
    }
}

// MARK: - Supporting Types

struct HealthStats {
    let todaySteps: Double
    let todayCalories: Double
    let currentWeight: Double
    let restingHeartRate: Double
}