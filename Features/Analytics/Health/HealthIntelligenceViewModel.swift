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

    private let healthAnalyticsService: HealthAnalyticsServiceProtocol
    private let healthKitService = HealthKitService.shared

    // MARK: - Computed Properties

    var vo2Max: Double? {
        healthKitService.vo2Max
    }

    var stepsHistory: [Double] {
        healthKitService.stepsHistory
    }

    var todaySteps: Int {
        healthKitService.todaySteps
    }

    var weightHistory: [Double] {
        healthKitService.weightHistory
    }

    var currentWeight: Double? {
        healthKitService.currentWeight
    }

    var heartRateHistory: [Double] {
        healthKitService.heartRateHistory
    }

    // MARK: - Initialization

    init() {
        self.healthAnalyticsService = HealthAnalyticsService()
    }

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
        case .overview: return LocalizationKeys.Health.Intelligence.tab_overview.localized
        case .recovery: return LocalizationKeys.Health.Intelligence.tab_recovery.localized
        case .fitness: return LocalizationKeys.Health.Intelligence.tab_fitness.localized
        case .trends: return LocalizationKeys.Health.Intelligence.tab_trends.localized
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