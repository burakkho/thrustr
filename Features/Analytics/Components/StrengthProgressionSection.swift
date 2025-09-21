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
                Text("Strength Progression")
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
                    title: "No Strength Data",
                    message: "Start tracking your strength workouts to see progress",
                    primaryTitle: "Start Training",
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
                            monthlySubtitle: "Monthly Progress",
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
                Text("Strength Insights")
                    .font(theme.typography.subheadline)
                    .fontWeight(.medium)

                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    AnalyticsStatItem(
                        title: "Strongest Lift",
                        value: viewModel?.strongestLiftValue ?? "--",
                        subtitle: viewModel?.strongestLiftName ?? "--",
                        color: .purple
                    )

                    AnalyticsStatItem(
                        title: "Total Volume",
                        value: viewModel?.totalVolumeValue ?? "--",
                        subtitle: "This Month",
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