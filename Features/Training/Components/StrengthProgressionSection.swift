import SwiftUI
import SwiftData

struct TrainingStrengthProgressionSection: View {
    let liftResults: [LiftExerciseResult]
    @Environment(\.theme) private var theme
    @Environment(UnitSettings.self) var unitSettings

    var body: some View {
        VStack(spacing: theme.spacing.m) {
            // Section header
            HStack {
                Text(LocalizationKeys.Training.Analytics.strength_progression.localized)
                    .font(theme.typography.headline)
                    .fontWeight(.semibold)
                Spacer()
                NavigationLink(destination: StrengthProgressionDetailView()) {
                    Text(LocalizationKeys.Common.view_all.localized)
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.accent)
                }
            }

            if exerciseMaxes.isEmpty {
                EmptyStateView(
                    icon: "chart.bar.fill",
                    title: LocalizationKeys.Training.Analytics.no_strength_data_title.localized,
                    message: LocalizationKeys.Training.Analytics.no_strength_data_desc.localized,
                    actionTitle: nil,
                    action: nil
                )
                .padding(.vertical, theme.spacing.l)
            } else {
                // Use ActionableStatCard for each exercise progression
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 16) {
                    ForEach(Array(exerciseMaxes.enumerated()), id: \.offset) { index, exerciseData in
                        ActionableStatCard(
                            icon: getExerciseIcon(exerciseData.name),
                            title: exerciseData.name,
                            dailyValue: Units.formatWeight(kg: exerciseData.currentMax, system: unitSettings.unitSystem),
                            weeklyValue: formatTrendValue(exerciseData.improvement, trend: exerciseData.trend),
                            monthlyValue: calculateMonthlyProgress(for: exerciseData.name),
                            dailySubtitle: LocalizationKeys.Training.Analytics.current_max.localized,
                            weeklySubtitle: LocalizationKeys.Training.Analytics.recent_change.localized,
                            monthlySubtitle: LocalizationKeys.Training.Analytics.monthly_progress.localized,
                            progress: calculateProgressPercentage(exerciseData.improvement),
                            color: getTrendColor(exerciseData.trend),
                            onNavigate: {
                                // Navigate to exercise detail
                                print("Navigate to \(exerciseData.name) details")
                            }
                        )
                    }
                }
            }
        }
        .padding(theme.spacing.l)
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.l)
        .cardStyle()
    }

    // MARK: - Computed Properties

    private var exerciseMaxes: [(name: String, currentMax: Double, trend: TrendDirection, improvement: Double)] {
        TrainingAnalyticsService.calculateExerciseMaxes(from: liftResults)
    }

    // MARK: - Helper Methods

    private func getExerciseIcon(_ exerciseName: String) -> String {
        let lowercaseName = exerciseName.lowercased()
        if lowercaseName.contains("squat") { return "figure.strengthtraining.traditional" }
        if lowercaseName.contains("bench") { return "figure.wrestling" }
        if lowercaseName.contains("deadlift") { return "figure.strengthtraining.functional" }
        if lowercaseName.contains("press") { return "figure.strengthtraining.functional" }
        if lowercaseName.contains("curl") { return "figure.strengthtraining.traditional" }
        if lowercaseName.contains("row") { return "figure.rowing" }
        return "dumbbell.fill"
    }

    private func formatTrendValue(_ improvement: Double, trend: TrendDirection) -> String {
        if improvement == 0 {
            return "--"
        }

        let prefix = trend == .increasing ? "+" : (trend == .decreasing ? "-" : "")
        return "\(prefix)\(Units.formatWeight(kg: improvement, system: unitSettings.unitSystem))"
    }

    private func calculateMonthlyProgress(for exerciseName: String) -> String {
        let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        let twoMonthsAgo = Calendar.current.date(byAdding: .month, value: -2, to: Date()) ?? Date()

        let exerciseResults = liftResults.filter {
            $0.exercise?.exerciseName == exerciseName
        }

        let recentMax = exerciseResults
            .filter { $0.performedAt >= oneMonthAgo }
            .compactMap { $0.maxWeight }
            .max() ?? 0

        let previousMax = exerciseResults
            .filter { $0.performedAt >= twoMonthsAgo && $0.performedAt < oneMonthAgo }
            .compactMap { $0.maxWeight }
            .max() ?? 0

        let improvement = recentMax - previousMax
        if improvement <= 0 { return "--" }

        return "+\(Units.formatWeight(kg: improvement, system: unitSettings.unitSystem))"
    }

    private func calculateProgressPercentage(_ improvement: Double) -> Double? {
        // Convert improvement to a 0-1 scale for progress bar
        if improvement <= 0 { return nil }
        return min(1.0, improvement / 10.0) // Assume 10kg improvement = 100%
    }

    private func getTrendColor(_ trend: TrendDirection) -> Color {
        switch trend {
        case .increasing: return .green
        case .decreasing: return .red
        case .stable: return .blue
        }
    }
}

// MARK: - Enhanced Version with More Features

struct TrainingEnhancedStrengthProgressionSection: View {
    let liftResults: [LiftExerciseResult]
    @Environment(\.theme) private var theme
    @Environment(UnitSettings.self) var unitSettings

    var body: some View {
        VStack(spacing: theme.spacing.l) {
            // Standard progression section
            TrainingStrengthProgressionSection(liftResults: liftResults)

            // Additional insights using existing StatItem components
            VStack(alignment: .leading, spacing: theme.spacing.m) {
                Text(LocalizationKeys.Training.Analytics.strength_insights.localized)
                    .font(theme.typography.subheadline)
                    .fontWeight(.medium)

                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    StatItem(
                        title: LocalizationKeys.Training.Analytics.strongest_lift.localized,
                        value: strongestLiftValue,
                        subtitle: strongestLiftName,
                        color: .purple
                    )

                    StatItem(
                        title: LocalizationKeys.Training.Analytics.total_volume.localized,
                        value: totalVolumeValue,
                        subtitle: LocalizationKeys.Training.Analytics.this_month.localized,
                        color: .orange
                    )
                }
            }
            .padding(.horizontal, theme.spacing.l)
        }
    }

    // MARK: - Computed Properties

    private var strongestLiftValue: String {
        let exerciseMaxes = TrainingAnalyticsService.calculateExerciseMaxes(from: liftResults)
        guard let strongest = exerciseMaxes.max(by: { $0.currentMax < $1.currentMax }) else {
            return "--"
        }
        return Units.formatWeight(kg: strongest.currentMax, system: unitSettings.unitSystem)
    }

    private var strongestLiftName: String {
        let exerciseMaxes = TrainingAnalyticsService.calculateExerciseMaxes(from: liftResults)
        return exerciseMaxes.max(by: { $0.currentMax < $1.currentMax })?.name ?? "--"
    }

    private var totalVolumeValue: String {
        let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        let recentResults = liftResults.filter { $0.performedAt >= oneMonthAgo }
        let totalVolume = recentResults.compactMap { $0.maxWeight }.reduce(0, +)

        if totalVolume == 0 { return "--" }
        return Units.formatWeight(kg: totalVolume, system: unitSettings.unitSystem)
    }
}

#Preview {
    VStack(spacing: 20) {
        TrainingStrengthProgressionSection(liftResults: [])
        TrainingEnhancedStrengthProgressionSection(liftResults: [])
    }
    .environment(\.theme, DefaultLightTheme())
    .environment(UnitSettings.shared)
}