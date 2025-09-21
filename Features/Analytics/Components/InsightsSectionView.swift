import SwiftUI

struct AnalyticsInsightRow: View {
    let insight: HealthInsight
    let action: () -> Void
    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: action) {
            HStack(spacing: theme.spacing.m) {
                // Priority indicator
                Circle()
                    .fill(priorityColor)
                    .frame(width: 12, height: 12)

                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text(insight.title)
                        .font(theme.typography.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(theme.colors.textPrimary)
                        .multilineTextAlignment(.leading)

                    Text(insight.message)
                        .font(theme.typography.body)
                        .foregroundColor(theme.colors.textSecondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(theme.colors.textTertiary)
            }
            .padding(theme.spacing.m)
            .background(theme.colors.backgroundSecondary.opacity(0.5))
            .cornerRadius(theme.radius.m)
        }
        .buttonStyle(PressableStyle())
    }

    private var priorityColor: Color {
        switch insight.priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }
}

struct AnalyticsInsightsSectionView: View {
    let title: String
    let insights: [HealthInsight]
    let onInsightTapped: (HealthInsight) -> Void
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            Text(title)
                .font(theme.typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(theme.colors.textPrimary)

            if insights.isEmpty {
                EmptyInsightsView()
            } else {
                LazyVStack(spacing: theme.spacing.s) {
                    ForEach(insights, id: \.id) { insight in
                        AnalyticsInsightRow(insight: insight) {
                            onInsightTapped(insight)
                        }
                    }
                }
            }
        }
        .padding(theme.spacing.l)
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.l)
        .cardStyle()
    }
}

struct AnalyticsInsightDetailView: View {
    let insight: HealthInsight
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: theme.spacing.l) {
                    // Priority badge
                    HStack {
                        Text(insight.priority.rawValue.capitalized)
                            .font(theme.typography.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, theme.spacing.s)
                            .padding(.vertical, theme.spacing.xs)
                            .background(priorityColor)
                            .cornerRadius(theme.radius.s)

                        Spacer()
                    }

                    // Title and message
                    VStack(alignment: .leading, spacing: theme.spacing.m) {
                        Text(insight.title)
                            .font(theme.typography.title1)
                            .fontWeight(.bold)
                            .foregroundColor(theme.colors.textPrimary)

                        Text(insight.message)
                            .font(theme.typography.body)
                            .foregroundColor(theme.colors.textPrimary)
                            .lineSpacing(4)
                    }

                    // Action recommendations
                    if let recommendedAction = insight.action, !recommendedAction.isEmpty {
                        VStack(alignment: .leading, spacing: theme.spacing.m) {
                            Text(LocalizationKeys.Health.Intelligence.recommended_action.localized)
                                .font(theme.typography.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(theme.colors.textPrimary)

                            Text(recommendedAction)
                                .font(theme.typography.body)
                                .foregroundColor(theme.colors.textSecondary)
                                .padding(theme.spacing.m)
                                .background(theme.colors.backgroundSecondary)
                                .cornerRadius(theme.radius.m)
                        }
                    }

                    Spacer(minLength: 100)
                }
                .padding(theme.spacing.l)
            }
            .navigationTitle(LocalizationKeys.Health.Intelligence.insight_details.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizationKeys.Common.done.localized) {
                        dismiss()
                    }
                }
            }
        }
    }

    private var priorityColor: Color {
        switch insight.priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }
}

#Preview {
    let mockInsights = [
        HealthInsight(
            type: .recovery,
            title: "Ready to unlock insights",
            message: "Your sleep duration was below optimal for 3 consecutive nights. This can significantly impact recovery and performance.",
            priority: .high,
            date: Date(),
            actionable: true,
            action: "Try going to bed 30 minutes earlier tonight and maintain consistent bedtime routine"
        ),
        HealthInsight(
            type: .workout,
            title: AnalyticsKeys.Insights.training_insights.localized,
            message: "Your training frequency has decreased by 40% compared to last month.",
            priority: .medium,
            date: Date(),
            actionable: true,
            action: "Schedule 3 workout sessions this week to get back on track"
        )
    ]

    VStack(spacing: 20) {
        AnalyticsInsightsSectionView(
            title: AnalyticsKeys.Insights.recovery_insights.localized,
            insights: mockInsights
        ) { insight in
            print("Tapped: \(insight.title)")
        }

        AnalyticsInsightDetailView(insight: mockInsights[0])
    }
    .environment(\.theme, DefaultLightTheme())
}