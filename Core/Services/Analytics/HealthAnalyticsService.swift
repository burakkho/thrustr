import Foundation
import SwiftData

struct HealthAnalyticsService {

    // MARK: - Health Intelligence Generation

    @MainActor
    static func generateHealthIntelligence() async -> HealthReport? {
        let healthKitService = HealthKitService.shared

        // Check if HealthKit is authorized
        guard healthKitService.isAuthorized else {
            return nil
        }

        // Use HealthKitService's existing method which already handles all the complexity
        return await healthKitService.generateComprehensiveHealthReport()
    }

    // MARK: - Data Refresh

    // MARK: - Helper Methods for Future Enhancement

    @MainActor
    static func refreshHealthData() async {
        // Trigger HealthKit data refresh by reloading all historical data
        let healthKitService = HealthKitService.shared
        await healthKitService.loadAllHistoricalData()
    }

    @MainActor
    static func calculateHealthScore() async -> Double {
        guard let report = await generateHealthIntelligence() else {
            return 0.0
        }

        // Composite health score based on multiple factors
        let recoveryWeight = 0.4
        let fitnessWeight = 0.3
        let consistencyWeight = 0.3

        let recoveryScore = report.recoveryScore.overallScore
        let fitnessScore = fitnessLevelToScore(report.fitnessAssessment.overallLevel)
        let consistencyScore = report.fitnessAssessment.consistencyScore

        return (recoveryScore * recoveryWeight) +
               (fitnessScore * fitnessWeight) +
               (consistencyScore * consistencyWeight)
    }

    private static func fitnessLevelToScore(_ level: FitnessLevelAssessment.FitnessLevel) -> Double {
        switch level {
        case .beginner: return 25.0
        case .intermediate: return 50.0
        case .advanced: return 75.0
        case .elite: return 100.0
        }
    }

    // MARK: - Insight Filtering

    /**
     * Filters recovery-related insights from health report.
     *
     * - Parameter insights: All insights from health report
     * - Returns: Filtered array of recovery and sleep insights
     */
    static func getRecoveryInsights(from insights: [HealthInsight]) -> [HealthInsight] {
        return insights.filter { $0.type == .recovery || $0.type == .sleep }
    }

    /**
     * Filters workout-related insights from health report.
     *
     * - Parameter insights: All insights from health report
     * - Returns: Filtered array of workout insights
     */
    static func getWorkoutInsights(from insights: [HealthInsight]) -> [HealthInsight] {
        return insights.filter { $0.type == .workout }
    }

    /**
     * Filters trend-related insights from health report.
     *
     * - Parameter insights: All insights from health report
     * - Returns: Filtered array of trend insights (steps, weight, heart health)
     */
    static func getTrendInsights(from insights: [HealthInsight]) -> [HealthInsight] {
        return insights.filter { $0.type == .steps || $0.type == .weight || $0.type == .heartHealth }
    }

    /**
     * Gets priority insights (first 3) from health report.
     *
     * - Parameter insights: All insights from health report
     * - Returns: Array of top 3 priority insights
     */
    static func getPriorityInsights(from insights: [HealthInsight]) -> [HealthInsight] {
        return Array(insights.prefix(3))
    }
}

