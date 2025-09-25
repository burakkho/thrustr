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

    // MARK: - Dependencies
    private let healthKitService: HealthKitService
    private let _unitSettings: UnitSettings

    // MARK: - Initialization
    init(healthKitService: HealthKitService? = nil, unitSettings: UnitSettings? = nil) {
        self.healthKitService = healthKitService ?? HealthKitService.shared
        self._unitSettings = unitSettings ?? UnitSettings.shared
    }

    // MARK: - Public Methods

    func loadHealthTrendsData() async {
        isLoading = true
        hasError = false
        errorMessage = ""

        defer {
            isLoading = false
        }

        await healthKitService.loadAllHistoricalData()
    }

    func getDataPointsForMetric(_ metric: HealthMetric) -> [HealthDataPoint] {
        switch metric {
        case .steps:
            return healthKitService.stepsHistory
        case .weight:
            return healthKitService.weightHistory
        case .heartRate:
            return healthKitService.heartRateHistory
        }
    }

    func changeMetric(to metric: HealthMetric) {
        selectedMetric = metric
    }

    // MARK: - Helper Methods

    func getWorkoutTrends() -> WorkoutTrends {
        return healthKitService.workoutTrends
    }

    func getHealthStats() -> HealthStats {
        return HealthStats(
            todaySteps: healthKitService.todaySteps,
            todayActiveCalories: healthKitService.todayActiveCalories,
            currentWeight: healthKitService.currentWeight ?? 0.0,
            restingHeartRate: healthKitService.restingHeartRate ?? 0.0
        )
    }

    // MARK: - Formatting Methods

    func formatWeight(_ kg: Double) -> String {
        switch _unitSettings.unitSystem {
        case .metric:
            return String(format: "%.1f", kg)
        case .imperial:
            let lbs = UnitsConverter.kgToLbs(kg)
            return String(format: "%.1f", lbs)
        }
    }

    var weightUnit: String {
        switch _unitSettings.unitSystem {
        case .metric: return "kg"
        case .imperial: return "lb"
        }
    }

    var unitSettings: UnitSettings {
        return _unitSettings
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
    let todayActiveCalories: Double
    let currentWeight: Double
    let restingHeartRate: Double
}