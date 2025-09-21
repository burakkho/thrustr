import SwiftUI
import SwiftData
import Foundation

struct WorkoutFrequencySection: View {
    let viewModel: TrainingAnalyticsViewModel
    let cardioResults: [CardioResult]
    @Environment(\.theme) private var theme

    var body: some View {
        let frequency = viewModel.calculateWeeklyFrequency(cardioResults: cardioResults)

        VStack(spacing: theme.spacing.m) {
            HStack {
                Text("analytics.workout_frequency".localized)
                    .font(theme.typography.headline)
                    .fontWeight(.semibold)
                Spacer()
            }

            if frequency.thisWeek == 0 && frequency.lastWeek == 0 {
                // Empty state
                VStack(spacing: theme.spacing.s) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.title2)
                        .foregroundColor(theme.colors.textSecondary)

                    Text("No workouts this week")
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.colors.textSecondary)

                    Text("Start training to see your workout frequency")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, theme.spacing.m)
            } else {
                HStack(spacing: theme.spacing.l) {
                    FrequencyMetric(
                        title: "This Week",
                        value: "\(frequency.thisWeek)",
                        subtitle: "workouts"
                    )

                    FrequencyMetric(
                        title: "Last Week",
                        value: "\(frequency.lastWeek)",
                        subtitle: "workouts"
                    )

                    FrequencyMetric(
                        title: "Avg Duration",
                        value: "45",
                        subtitle: "minutes"
                    )
                }
            }
        }
        .padding(theme.spacing.l)
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.l)
        .cardStyle()
    }
}

// MARK: - FrequencyMetric Helper Component
struct FrequencyMetric: View {
    let title: String
    let value: String
    let subtitle: String
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textSecondary)

            Text(value)
                .font(theme.typography.title2)
                .fontWeight(.bold)
                .foregroundColor(theme.colors.textPrimary)

            Text(subtitle)
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textTertiary)
        }
    }
}