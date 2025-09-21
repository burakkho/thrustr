import SwiftUI

struct AnalyticsPriorityInsightsSection: View {
    let insights: [HealthInsight]
    let onInsightTapped: (HealthInsight) -> Void
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Modern Section Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.title3)
                        .foregroundColor(.yellow)

                    Text(LocalizationKeys.Health.Intelligence.priority_insights.localized)
                        .font(theme.typography.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.colors.textPrimary)
                }

                Spacer()

                if insights.count > 2 {
                    Button(action: {
                        // Navigate to all insights
                    }) {
                        Text(LocalizationKeys.Common.view_all.localized)
                            .font(.caption)
                            .foregroundColor(theme.colors.accent)
                    }
                }
            }
            .padding(.horizontal, 4)

            // ActionableStatCard Grid - Showcase Style
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 16) {
                ForEach(insights.prefix(4), id: \.id) { insight in
                    AnalyticsActionableInsightCard(insight: insight) {
                        onInsightTapped(insight)
                    }
                }
            }
        }
    }
}

struct AnalyticsKeyMetricsRow: View {
    let report: HealthReport
    @Environment(\.theme) private var theme

    var body: some View {
        // Enhanced metrics grid using QuickStatCard
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 16) {

            // Recovery Score
            QuickStatCard(
                icon: "heart.fill",
                title: LocalizationKeys.Health.Intelligence.metrics_recovery.localized,
                value: "\(Int(report.recoveryScore.overallScore))",
                subtitle: "/100 " + report.recoveryScore.category.rawValue,
                color: getRecoveryColor()
            )

            // Fitness Level
            QuickStatCard(
                icon: "figure.strengthtraining.traditional",
                title: LocalizationKeys.Health.Intelligence.metrics_fitness.localized,
                value: report.fitnessAssessment.overallLevel.rawValue.capitalized,
                subtitle: LocalizationKeys.Health.fitness_level.localized,
                color: .blue
            )

            // Insights Count
            QuickStatCard(
                icon: "lightbulb.fill",
                title: LocalizationKeys.Health.Intelligence.metrics_insights.localized,
                value: "\(report.insights.count)",
                subtitle: LocalizationKeys.Health.Intelligence.metrics_insights_unit.localized,
                color: .purple
            )
        }
        .padding(.horizontal, 4)
    }

    private func getRecoveryColor() -> Color {
        switch report.recoveryScore.overallScore {
        case 80...100: return .green
        case 60..<80: return .blue
        case 40..<60: return .orange
        default: return .red
        }
    }
}

struct AnalyticsQuickActionsRow: View {
    let report: HealthReport
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizationKeys.Health.Intelligence.quick_actions.localized)
                .font(theme.typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(theme.colors.textPrimary)
                .padding(.horizontal, 4)

            HStack(spacing: 12) {
                QuickActionButton(
                    title: LocalizationKeys.Health.Intelligence.suggest_workout.localized,
                    icon: "figure.run",
                    style: .secondary,
                    size: .medium,
                    action: {
                        // Navigate to workout suggestions based on recovery score
                        if report.recoveryScore.overallScore > 70 {
                            // High recovery - suggest intense workout
                            print("🏋️ Suggesting high intensity workout")
                        } else {
                            // Low recovery - suggest light activity
                            print("🚶 Suggesting light activity")
                        }
                    }
                )

                QuickActionButton(
                    title: LocalizationKeys.Health.Intelligence.nutrition_advice.localized,
                    icon: "leaf.fill",
                    style: .secondary,
                    size: .medium,
                    action: {
                        // Navigate to nutrition insights
                        print("🥗 Opening nutrition recommendations")
                        // This could navigate to NutritionView with specific recommendations
                    }
                )

                if report.recoveryScore.overallScore < 60 {
                    QuickActionButton(
                        title: LocalizationKeys.Health.Intelligence.rest_recommendation.localized,
                        icon: "moon.fill",
                        style: .secondary,
                        size: .medium,
                        action: {
                            // Navigate to recovery/rest recommendations
                            print("😴 Opening rest and recovery guide")
                            // This could show sleep tips, meditation, etc.
                        }
                    )
                }
            }
        }
    }
}

#Preview {
    let mockInsights = [
        HealthInsight(
            type: .recovery,
            title: "Poor Sleep Quality",
            message: "Sleep duration below optimal for 3 nights",
            priority: .high,
            date: Date(),
            actionable: true,
            action: "Try earlier bedtime"
        ),
        HealthInsight(
            type: .workout,
            title: "Inconsistent Training",
            message: "Workout frequency dropped last week",
            priority: .medium,
            date: Date(),
            actionable: true,
            action: "Schedule 3 sessions"
        )
    ]

    let mockReport = HealthReport(
        recoveryScore: RecoveryScore(
            overallScore: 75.0,
            hrvScore: 70.0,
            sleepScore: 80.0,
            workoutLoadScore: 75.0,
            restingHeartRateScore: 75.0,
            date: Date()
        ),
        insights: mockInsights,
        fitnessAssessment: FitnessLevelAssessment(
            overallLevel: FitnessLevelAssessment.FitnessLevel.intermediate,
            cardioLevel: FitnessLevelAssessment.FitnessLevel.intermediate,
            strengthLevel: FitnessLevelAssessment.FitnessLevel.beginner,
            consistencyScore: 75.0,
            progressTrend: TrendDirection.increasing,
            assessmentDate: Date()
        ),
        generatedDate: Date()
    )

    VStack(spacing: 20) {
        AnalyticsPriorityInsightsSection(insights: mockInsights) { insight in
            print("Tapped: \(insight.title)")
        }

        AnalyticsKeyMetricsRow(report: mockReport)

        AnalyticsQuickActionsRow(report: mockReport)
    }
    .padding()
    .environment(\.theme, DefaultLightTheme())
}