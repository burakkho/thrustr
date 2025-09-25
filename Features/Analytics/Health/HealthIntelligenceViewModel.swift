import Foundation
import SwiftUI

@MainActor
@Observable
class HealthIntelligenceViewModel {

    // MARK: - Published State

    var isLoading = false
    var healthReport: HealthReport?
    var selectedTab: IntelligenceTab = .overview
    var showingDetailedInsights = false
    var selectedInsight: HealthInsight?
    var animateCards = false
    var hasError = false
    var errorMessage = ""

    // MARK: - Dependencies

    private let healthKitService = HealthKitService.shared

    // MARK: - Computed Properties for Views

    var recoveryInsights: [HealthInsight] {
        guard let report = healthReport else { return [] }
        return HealthAnalyticsService.getRecoveryInsights(from: report.insights)
    }

    var workoutInsights: [HealthInsight] {
        guard let report = healthReport else { return [] }
        return HealthAnalyticsService.getWorkoutInsights(from: report.insights)
    }

    var trendInsights: [HealthInsight] {
        guard let report = healthReport else { return [] }
        return HealthAnalyticsService.getTrendInsights(from: report.insights)
    }

    var priorityInsights: [HealthInsight] {
        guard let report = healthReport else { return [] }
        return HealthAnalyticsService.getPriorityInsights(from: report.insights)
    }

    // MARK: - HealthKit Data (Direct Access for UI)

    var vo2Max: Double? {
        healthKitService.vo2Max
    }

    var stepsHistory: [HealthDataPoint] {
        healthKitService.stepsHistory
    }

    var todaySteps: Double {
        healthKitService.todaySteps
    }

    var weightHistory: [HealthDataPoint] {
        healthKitService.weightHistory
    }

    var currentWeight: Double? {
        healthKitService.currentWeight
    }

    var heartRateHistory: [HealthDataPoint] {
        healthKitService.heartRateHistory
    }

    // MARK: - VO2 Max Display Properties

    var vo2MaxColor: String {
        guard let vo2Max = vo2Max else { return "gray" }
        return RecoveryCalculationService.getVO2MaxColor(for: vo2Max)
    }

    var vo2MaxCategory: String {
        guard let vo2Max = vo2Max else { return "Unknown" }
        return RecoveryCalculationService.getVO2MaxCategory(for: vo2Max)
    }

    var vo2MaxDescription: String {
        guard let vo2Max = vo2Max else { return "No data available" }
        return RecoveryCalculationService.getVO2MaxDescription(for: vo2Max)
    }

    // MARK: - Recovery Trend Properties

    func recoveryScoreForDay(daysBack: Int) async -> Double {
        guard let report = healthReport else { return 50.0 }
        return await RecoveryCalculationService.calculateRecoveryForDay(
            daysBack: daysBack,
            baseRecoveryScore: report.recoveryScore,
            healthKitService: healthKitService
        )
    }

    func recoveryTrendData() async -> [(day: String, score: Double)] {
        let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        var results: [(day: String, score: Double)] = []

        for index in 0..<7 {
            let dayScore = await recoveryScoreForDay(daysBack: 6 - index)
            results.append((day: dayNames[index], score: dayScore))
        }

        return results
    }

    // MARK: - Date Formatting Properties

    func formatRelativeDate(_ date: Date) -> String {
        return DateFormatterService.formatRelativeDate(date)
    }

    func formatPRTimelineDate(_ date: Date) -> String {
        return DateFormatterService.formatPRTimelineDate(date)
    }

    // MARK: - Score Color Helpers

    func getScoreColor(for score: Double) -> String {
        return RecoveryCalculationService.getScoreColor(for: score)
    }

    // MARK: - Initialization

    init() {}

    // MARK: - Public Methods

    func loadHealthIntelligence() async {
        isLoading = true
        hasError = false
        errorMessage = ""

        defer {
            isLoading = false
        }

        let report = await HealthAnalyticsService.generateHealthIntelligence()
        healthReport = report

        // If no report generated but no error, it means HealthKit not authorized
        if report == nil && !hasError {
            handleNoHealthKitAuthorization()
        }
    }

    func refreshHealthData() async {
        await HealthAnalyticsService.refreshHealthData()
        await loadHealthIntelligence()
    }

    func startCardAnimations() {
        withAnimation(.easeInOut(duration: 0.6)) {
            animateCards = true
        }
    }

    func selectInsight(_ insight: HealthInsight) {
        selectedInsight = insight
        showingDetailedInsights = true
    }

    func changeTab(to tab: IntelligenceTab) {
        selectedTab = tab
    }

    // MARK: - Private Methods

    private func handleError(_ error: Error) {
        hasError = true
        errorMessage = error.localizedDescription
        healthReport = nil
    }

    private func handleNoHealthKitAuthorization() {
        // This case is handled by the View showing EmptyIntelligenceView
        // No specific error needed as it's an expected state
    }
}


// MARK: - Service Protocol for Dependency Injection

protocol HealthAnalyticsServiceProtocol {
    static func generateHealthIntelligence() async -> HealthReport?
    static func refreshHealthData() async
    static func calculateHealthScore() async -> Double
}

// MARK: - Protocol Conformance

extension HealthAnalyticsService: HealthAnalyticsServiceProtocol {}