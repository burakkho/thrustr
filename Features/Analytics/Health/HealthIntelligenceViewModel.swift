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

    var stepsHistory: [Double] {
        healthKitService.stepsHistory.map { $0.value }
    }

    var todaySteps: Int {
        Int(healthKitService.todaySteps)
    }

    var weightHistory: [Double] {
        healthKitService.weightHistory.map { $0.value }
    }

    var currentWeight: Double? {
        healthKitService.currentWeight
    }

    var heartRateHistory: [Double] {
        healthKitService.heartRateHistory.map { $0.value }
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

// MARK: - Intelligence Tab Definition

enum IntelligenceTab: CaseIterable {
    case overview, recovery, fitness, trends

    var title: String {
        switch self {
        case .overview: return "analytics.overview".localized
        case .recovery: return "analytics.recovery".localized
        case .fitness: return "analytics.fitness".localized
        case .trends: return "analytics.trends".localized
        }
    }

    var icon: String {
        switch self {
        case .overview: return "brain.head.profile"
        case .recovery: return "heart.fill"
        case .fitness: return "figure.strengthtraining.traditional"
        case .trends: return "chart.line.uptrend.xyaxis"
        }
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