import SwiftUI

// 📈 ENHANCED HEALTH TRENDS SECTION
struct AnalyticsEnhancedHealthTrendsSection: View {
    @State private var viewModel: HealthTrendsViewModel?
    @State private var healthKitService = HealthKitService.shared
    @Environment(\.theme) private var theme
    @Environment(UnitSettings.self) var unitSettings

    var body: some View {
        VStack(spacing: 20) {
            // Section Header
            HStack {
                Text(CommonKeys.Analytics.healthTrends.localized)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)

                Spacer()

                NavigationLink(destination: HealthTrendsView()) {
                    Text(CommonKeys.Analytics.viewCharts.localized)
                        .font(.caption)
                        .foregroundColor(theme.colors.accent)
                }
            }
            .padding(.horizontal, 4)

            // Enhanced Trend Cards
            VStack(spacing: 12) {
                EnhancedTrendCard(
                    icon: "figure.walk",
                    title: "Steps Trend",
                    currentValue: Int(healthKitService.todaySteps),
                    unit: "steps",
                    trendData: healthKitService.stepsHistory.map { $0.value },
                    color: .blue,
                    trend: .stable // Trend calculation handled by component
                )

                EnhancedTrendCard(
                    icon: "scalemass.fill",
                    title: "Weight Trend",
                    currentValue: Int(healthKitService.currentWeight ?? 0),
                    unit: unitSettings.unitSystem == .metric ? "kg" : "lb",
                    trendData: healthKitService.weightHistory.map { $0.value },
                    color: .green,
                    trend: .stable // Trend calculation handled by component
                )

                EnhancedTrendCard(
                    icon: "heart.fill",
                    title: "Heart Rate Trend",
                    currentValue: Int(healthKitService.restingHeartRate ?? 0),
                    unit: "bpm",
                    trendData: healthKitService.heartRateHistory.map { $0.value },
                    color: .red,
                    trend: .stable // Trend calculation handled by component
                )
            }
        }
    }

    // MARK: - Trend Calculations

    private func calculateStepsTrend() -> TrendDirection {
        let recentAvg = healthKitService.stepsHistory.suffix(3).map { $0.value }.reduce(0, +) / 3
        let previousAvg = healthKitService.stepsHistory.prefix(4).map { $0.value }.reduce(0, +) / 4

        if recentAvg > previousAvg * 1.1 { return .increasing }
        if recentAvg < previousAvg * 0.9 { return .decreasing }
        return .stable
    }

    private func calculateWeightTrend() -> TrendDirection {
        guard healthKitService.weightHistory.count >= 2 else { return .stable }
        let recent = healthKitService.weightHistory.suffix(2).map { $0.value }
        let change = recent.last! - recent.first!

        if abs(change) < 0.5 { return .stable }
        return change > 0 ? .increasing : .decreasing
    }

    private func calculateHeartRateTrend() -> TrendDirection {
        guard healthKitService.heartRateHistory.count >= 3 else { return .stable }
        let recentAvg = healthKitService.heartRateHistory.suffix(3).map { $0.value }.reduce(0, +) / 3
        let previousAvg = healthKitService.heartRateHistory.prefix(4).map { $0.value }.reduce(0, +) / 4

        if recentAvg < previousAvg - 2 { return .decreasing } // Lower HR is better
        if recentAvg > previousAvg + 2 { return .increasing }
        return .stable
    }
}

#Preview {
    AnalyticsEnhancedHealthTrendsSection()
        .environment(UnitSettings.shared)
        .environment(ThemeManager())
        .padding()
}