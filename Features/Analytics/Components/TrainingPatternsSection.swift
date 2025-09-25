import SwiftUI
import SwiftData
import Foundation

struct TrainingPatternsSection: View {
    let liftResults: [LiftExerciseResult]
    let cardioResults: [CardioResult]
    let liftSessions: [LiftSession]
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: theme.spacing.m) {
            // Section header
            HStack {
                Text("training_patterns")
                    .font(theme.typography.headline)
                    .fontWeight(.semibold)
                Spacer()
            }

            // Pattern insights using existing AnalyticsStatItem components
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 16) {
                AnalyticsStatItem(
                    title: "most_active_time",
                    value: mostActiveTimeRange,
                    color: .blue
                )

                AnalyticsStatItem(
                    title: "favorite_exercise_type",
                    value: favoriteExerciseType,
                    color: .purple
                )

                AnalyticsStatItem(
                    title: "avg_session_duration",
                    value: averageSessionDurationText,
                    subtitle: "per_workout",
                    color: .green
                )

                AnalyticsStatItem(
                    title: "rest_day_pattern",
                    value: restDayPattern,
                    subtitle: "typical_schedule",
                    color: .orange
                )
            }

            // Additional insights
            if !patternInsights.isEmpty {
                VStack(alignment: .leading, spacing: theme.spacing.s) {
                    Text("pattern_insights")
                        .font(theme.typography.subheadline)
                        .fontWeight(.medium)

                    ForEach(Array(patternInsights.enumerated()), id: \.offset) { index, insight in
                        PatternInsightRow(insight: insight)
                    }
                }
                .padding(.top, theme.spacing.s)
            }
        }
        .padding(theme.spacing.l)
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.l)
        .cardStyle()
    }

    // MARK: - Computed Properties

    private var mostActiveTimeRange: String {
        TrainingAnalyticsService.calculateMostActiveTimeRange(
            liftResults: liftResults,
            cardioResults: cardioResults
        )
    }

    private var favoriteExerciseType: String {
        TrainingAnalyticsService.calculateFavoriteExerciseType(liftResults: liftResults)
    }

    private var averageSessionDurationText: String {
        let avgDuration = TrainingAnalyticsService.calculateAverageSessionDuration(liftSessions: liftSessions)
        if avgDuration == 0 { return "--" }

        let minutes = Int(avgDuration / 60)
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)h \(remainingMinutes)m"
        }
    }

    private var restDayPattern: String {
        let allDates = liftResults.map { $0.performedAt } + cardioResults.map { $0.completedAt }
        guard !allDates.isEmpty else { return "--" }

        let workoutDays = Set(allDates.map { Calendar.current.component(.weekday, from: $0) })
        let restDays = Set(1...7).subtracting(workoutDays)

        if restDays.isEmpty {
            return "no_rest_days"
        } else if restDays.count == 1 {
            return getDayName(restDays.first!)
        } else if restDays.count == 2 {
            let sortedDays = restDays.sorted()
            return "\(getDayName(sortedDays[0])), \(getDayName(sortedDays[1]))"
        } else {
            return String(format: "multiple_rest_days", restDays.count)
        }
    }

    private var patternInsights: [String] {
        var insights: [String] = []

        // Check for consistency patterns
        let workoutDays = Set((liftResults.map { $0.performedAt } + cardioResults.map { $0.completedAt })
            .map { Calendar.current.component(.weekday, from: $0) })

        if workoutDays.count >= 5 {
            insights.append("insight_very_consistent")
        } else if workoutDays.count <= 2 {
            insights.append("insight_limited_days")
        }

        // Check for weekend vs weekday patterns
        let weekendDays = workoutDays.intersection([1, 7]) // Sunday = 1, Saturday = 7
        let weekDays = workoutDays.subtracting([1, 7])

        if weekendDays.count > 0 && weekDays.count == 0 {
            insights.append("insight_weekend_warrior")
        } else if weekDays.count > 0 && weekendDays.count == 0 {
            insights.append("insight_weekday_focused")
        }

        // Check for time consistency
        if mostActiveTimeRange != "No data" && !mostActiveTimeRange.isEmpty {
            insights.append(String(format: "insight_time_consistent", mostActiveTimeRange))
        }

        return insights
    }

    // MARK: - Helper Methods

    private func getDayName(_ weekday: Int) -> String {
        switch weekday {
        case 1: return "Sun"
        case 2: return "Mon"
        case 3: return "Tue"
        case 4: return "Wed"
        case 5: return "Thu"
        case 6: return "Fri"
        case 7: return "Sat"
        default: return ""
        }
    }
}

// MARK: - Pattern Insight Row Component

struct PatternInsightRow: View {
    let insight: String
    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "lightbulb.fill")
                .font(.caption)
                .foregroundColor(.yellow)

            Text(insight)
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textSecondary)
                .lineLimit(2)

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Enhanced Training Insights Grid

struct TrainingInsightsGridSection: View {
    let liftResults: [LiftExerciseResult]
    let cardioResults: [CardioResult]
    let liftSessions: [LiftSession]
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: theme.spacing.l) {
            // Training patterns section
            TrainingPatternsSection(
                liftResults: liftResults,
                cardioResults: cardioResults,
                liftSessions: liftSessions
            )

            // Additional performance insights using QuickStatCard
            VStack(alignment: .leading, spacing: theme.spacing.m) {
                Text("performance_insights")
                    .font(theme.typography.headline)
                    .fontWeight(.semibold)
                    .padding(.horizontal, theme.spacing.l)

                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 16) {
                    QuickStatCard(
                        icon: "chart.bar.fill",
                        title: "total_volume",
                        value: totalVolumeText,
                        subtitle: "this_month",
                        color: .blue
                    )

                    QuickStatCard(
                        icon: "speedometer",
                        title: "avg_intensity",
                        value: averageIntensityText,
                        subtitle: "effort_level",
                        color: .red
                    )

                    QuickStatCard(
                        icon: "target",
                        title: "consistency",
                        value: "\(Int(weeklyPerformance.consistencyScore))%",
                        subtitle: "weekly_distribution",
                        color: .green
                    )
                }
                .padding(.horizontal, theme.spacing.l)
            }
        }
    }

    // MARK: - Computed Properties

    private var weeklyPerformance: (totalWorkouts: Int, totalVolume: Double, averageIntensity: Double, consistencyScore: Double) {
        TrainingAnalyticsService.calculateWeeklyPerformanceSummary(
            liftResults: liftResults,
            cardioResults: cardioResults
        )
    }

    private var totalVolumeText: String {
        let volume = weeklyPerformance.totalVolume
        if volume == 0 { return "--" }
        return UnitsFormatter.formatWeight(kg: volume, system: UnitSettings.shared.unitSystem)
    }

    private var averageIntensityText: String {
        let intensity = weeklyPerformance.averageIntensity
        if intensity == 0 { return "--" }
        return String(format: "%.1f/10", intensity)
    }
}

struct TrainingPatternsSection_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            TrainingPatternsSection(liftResults: [], cardioResults: [], liftSessions: [])
            TrainingInsightsGridSection(liftResults: [], cardioResults: [], liftSessions: [])
        }
        .environment(\.theme, DefaultLightTheme())
    }
}