import SwiftUI

/**
 * Metrics grid component for Cardio Live Tracking.
 *
 * Displays workout metrics in a grid layout with automatic metric selection
 * based on workout type (indoor vs outdoor). Uses service-based configuration
 * for consistent metric presentation.
 *
 * Features:
 * - Automatic indoor/outdoor metric selection
 * - Service-based metric configuration
 * - Real-time metric updates
 * - Consistent styling and colors
 */
struct CardioMetricsGrid: View {
    @Environment(\.theme) private var theme
    @Environment(UnitSettings.self) private var unitSettings

    // Workout configuration
    let isOutdoor: Bool
    let viewModel: CardioTimerViewModel

    var body: some View {
        let metricKeys = CardioWorkoutDisplayService.shouldShowOutdoorMetrics(isOutdoor: isOutdoor)
            ? CardioWorkoutDisplayService.getOutdoorMetricKeys()
            : CardioWorkoutDisplayService.getIndoorMetricKeys()

        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: theme.spacing.m) {
            ForEach(metricKeys, id: \.self) { metricKey in
                createMetricCard(for: metricKey)
            }
        }
    }

    // MARK: - Metric Card Creation

    @ViewBuilder
    private func createMetricCard(for metricKey: String) -> some View {
        let config = MetricDisplayConfig(key: metricKey)

        switch metricKey {
        case "speed":
            QuickStatCard(
                icon: config.icon,
                title: TrainingKeys.Cardio.speed.localized,
                value: viewModel.formattedSpeed,
                subtitle: UnitsFormatter.formatSpeedUnit(system: unitSettings.unitSystem),
                color: config.color
            )
            .id(CardioWorkoutDisplayService.getMetricId(key: metricKey, value: viewModel.formattedSpeed))

        case "distance":
            QuickStatCard(
                icon: config.icon,
                title: TrainingKeys.Cardio.distance.localized,
                value: viewModel.formattedDistance,
                subtitle: "",
                color: config.color
            )
            .id(CardioWorkoutDisplayService.getMetricId(key: metricKey, value: viewModel.formattedDistance))

        case "calories":
            QuickStatCard(
                icon: config.icon,
                title: TrainingKeys.Cardio.calories.localized,
                value: "\(viewModel.currentCalories)",
                subtitle: "kcal",
                color: config.color
            )
            .id(CardioWorkoutDisplayService.getMetricId(key: metricKey, value: "\(viewModel.currentCalories)"))

        case "pace":
            QuickStatCard(
                icon: config.icon,
                title: TrainingKeys.Cardio.pace.localized,
                value: viewModel.formattedPace,
                subtitle: UnitsFormatter.formatPaceUnit(system: unitSettings.unitSystem),
                color: config.color
            )
            .id(CardioWorkoutDisplayService.getMetricId(key: metricKey, value: viewModel.formattedPace))

        case "heartRate":
            QuickStatCard(
                icon: config.icon,
                title: TrainingKeys.Cardio.heartRate.localized,
                value: viewModel.formattedHeartRate,
                subtitle: "BPM",
                color: config.color
            )
            .id(CardioWorkoutDisplayService.getMetricId(key: metricKey, value: viewModel.formattedHeartRate))

        case "effort":
            QuickStatCard(
                icon: config.icon,
                title: TrainingKeys.Cardio.effort.localized,
                value: viewModel.perceivedEffortLevel,
                subtitle: TrainingKeys.Cardio.rpe.localized,
                color: config.color
            )
            .id(CardioWorkoutDisplayService.getMetricId(key: metricKey, value: viewModel.perceivedEffortLevel))

        case "zone":
            QuickStatCard(
                icon: config.icon,
                title: TrainingKeys.Cardio.zone.localized,
                value: viewModel.heartRateZone,
                subtitle: "",
                color: viewModel.heartRateZoneColor
            )
            .id(CardioWorkoutDisplayService.getMetricId(key: metricKey, value: viewModel.heartRateZone))

        default:
            EmptyView()
        }
    }
}

// MARK: - Preview

#Preview("Outdoor Metrics") {
    CardioMetricsGrid(
        isOutdoor: true,
        viewModel: CardioTimerViewModel(
            activityType: .running,
            isOutdoor: true,
            user: User(
                name: "Test User",
                age: 30,
                gender: .male,
                height: 180,
                currentWeight: 75,
                fitnessGoal: .maintain,
                activityLevel: .moderate,
                selectedLanguage: "tr"
            )
        )
    )
    .environment(UnitSettings.shared)
    .padding()
}

