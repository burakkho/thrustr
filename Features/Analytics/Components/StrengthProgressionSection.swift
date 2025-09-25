import SwiftUI
import SwiftData
import Foundation

struct AnalyticsStrengthProgressionSection: View {
    let liftResults: [LiftExerciseResult]
    @State private var viewModel: StrengthProgressionSectionViewModel?
    @Environment(\.theme) private var theme
    @Environment(UnitSettings.self) var unitSettings

    var body: some View {
        VStack(spacing: theme.spacing.m) {
            // Section header
            HStack {
                Text(CommonKeys.Analytics.strengthProgression.localized)
                    .font(theme.typography.headline)
                    .fontWeight(.semibold)
                Spacer()
                NavigationLink(destination: StrengthProgressionDetailView()) {
                    Text(LocalizationKeys.Common.view_all.localized)
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.accent)
                }
            }

            if viewModel?.exerciseMaxes.isEmpty ?? true {
                EmptyStateView(
                    systemImage: "dumbbell.fill",
                    title: CommonKeys.Analytics.noStrengthData.localized,
                    message: CommonKeys.Analytics.noStrengthMessage.localized,
                    primaryTitle: CommonKeys.Analytics.startTraining.localized,
                    primaryAction: {
                        // Navigate to training section
                        print("Navigate to strength training")
                    }
                )
                .padding(.vertical, theme.spacing.l)
            } else {
                // Use ActionableStatCard for each exercise progression
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 16) {
                    ForEach(Array((viewModel?.exerciseMaxes ?? []).enumerated()), id: \.offset) { index, exerciseData in
                        ActionableStatCard(
                            icon: viewModel?.getExerciseIcon(exerciseData.name) ?? "dumbbell.fill",
                            title: exerciseData.name,
                            dailyValue: UnitsFormatter.formatWeight(kg: exerciseData.currentMax, system: unitSettings.unitSystem),
                            weeklyValue: viewModel?.formatTrendValue(exerciseData.improvement, trend: exerciseData.trend, unitSettings: unitSettings) ?? "--",
                            monthlyValue: viewModel?.calculateMonthlyProgress(for: exerciseData.name, liftResults: liftResults, unitSettings: unitSettings) ?? "--",
                            dailySubtitle: "Current Max",
                            weeklySubtitle: "Recent Change",
                            monthlySubtitle: CommonKeys.Analytics.thisMonth.localized,
                            progress: viewModel?.calculateProgressPercentage(exerciseData.improvement),
                            color: viewModel?.getTrendColor(exerciseData.trend) ?? .blue,
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
        .onAppear {
            if viewModel == nil {
                viewModel = StrengthProgressionSectionViewModel()
            }
            viewModel?.updateStrengthProgression(liftResults: liftResults, unitSettings: unitSettings)
        }
    }

}

// MARK: - Enhanced Version with More Features

struct AnalyticsEnhancedStrengthProgressionSection: View {
    let liftResults: [LiftExerciseResult]
    @State private var viewModel: StrengthProgressionSectionViewModel?
    @Environment(\.theme) private var theme
    @Environment(UnitSettings.self) var unitSettings

    var body: some View {
        VStack(spacing: theme.spacing.l) {
            // Standard progression section
            AnalyticsStrengthProgressionSection(liftResults: liftResults)

            // Additional insights using existing AnalyticsStatItem components
            VStack(alignment: .leading, spacing: theme.spacing.m) {
                Text(CommonKeys.Analytics.strengthInsights.localized)
                    .font(theme.typography.subheadline)
                    .fontWeight(.medium)

                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    AnalyticsStatItem(
                        title: CommonKeys.Analytics.strongestLift.localized,
                        value: viewModel?.strongestLiftValue ?? "--",
                        subtitle: viewModel?.strongestLiftName ?? "--",
                        color: .purple
                    )

                    AnalyticsStatItem(
                        title: CommonKeys.Analytics.totalVolume.localized,
                        value: viewModel?.totalVolumeValue ?? "--",
                        subtitle: CommonKeys.Analytics.thisMonth.localized,
                        color: .orange
                    )
                }
            }
            .padding(.horizontal, theme.spacing.l)
        }
        .onAppear {
            if viewModel == nil {
                viewModel = StrengthProgressionSectionViewModel()
            }
            viewModel?.updateStrengthProgression(liftResults: liftResults, unitSettings: unitSettings)
        }
    }

}

#Preview {
    VStack(spacing: 20) {
        AnalyticsStrengthProgressionSection(liftResults: [])
        AnalyticsEnhancedStrengthProgressionSection(liftResults: [])
    }
    .environment(\.theme, DefaultLightTheme())
    .environment(UnitSettings.shared)
}