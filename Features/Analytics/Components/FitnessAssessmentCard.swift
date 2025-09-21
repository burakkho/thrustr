import SwiftUI

struct AnalyticsFitnessLevelRow: View {
    let title: String
    let level: FitnessLevelAssessment.FitnessLevel
    let icon: String
    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Color(level.color))
                .frame(width: 24)

            Text(title)
                .font(theme.typography.body)
                .foregroundColor(theme.colors.textPrimary)

            Spacer()

            Text(level.rawValue)
                .font(theme.typography.body)
                .fontWeight(.medium)
                .foregroundColor(Color(level.color))
        }
        .padding(.vertical, 4)
    }
}

struct AnalyticsFitnessAssessmentCard: View {
    let assessment: FitnessLevelAssessment
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationKeys.Common.HealthKit.fitnessLevelTitle.localized)
                .font(theme.typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(theme.colors.textPrimary)

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizationKeys.Common.HealthKit.overallLevelTitle.localized)
                        .font(theme.typography.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(theme.colors.textPrimary)

                    Text(assessment.overallLevel.rawValue)
                        .font(theme.typography.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color(assessment.overallLevel.color))

                    Text(assessment.overallLevel.description)
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: assessment.progressTrend.icon)
                            .font(.caption)
                            .foregroundColor(assessment.progressTrend.swiftUIColor)

                        Text(assessment.progressTrend.displayText)
                            .font(theme.typography.caption)
                            .fontWeight(.medium)
                            .foregroundColor(assessment.progressTrend.swiftUIColor)
                    }

                    Text("\(LocalizationKeys.Common.HealthKit.consistencyTitle.localized): \(Int(assessment.consistencyScore))%")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                }
            }

            // Detailed breakdown
            VStack(spacing: 12) {
                AnalyticsFitnessLevelRow(
                    title: LocalizationKeys.Common.HealthKit.cardioTitle.localized,
                    level: assessment.cardioLevel,
                    icon: "heart.fill"
                )

                AnalyticsFitnessLevelRow(
                    title: LocalizationKeys.Common.HealthKit.strengthTitle.localized,
                    level: assessment.strengthLevel,
                    icon: "dumbbell.fill"
                )
            }
        }
        .padding(20)
        .background(theme.colors.cardBackground)
        .cornerRadius(12)
        .shadow(color: theme.shadows.card.opacity(0.05), radius: 2)
    }
}

struct AnalyticsSuggestionRow: View {
    let icon: String
    let title: String
    let suggestion: String
    let color: Color
    @Environment(\.theme) private var theme

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(theme.typography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.colors.textPrimary)

                Text(suggestion)
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }

            Spacer()
        }
    }
}

struct AnalyticsEnhancedFitnessAssessmentCard: View {
    let assessment: FitnessLevelAssessment
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: theme.spacing.l) {
            // Enhanced version of existing FitnessAssessmentCard
            AnalyticsFitnessAssessmentCard(assessment: assessment)

            // Fitness improvement suggestions
            VStack(alignment: .leading, spacing: theme.spacing.s) {
                Text(LocalizationKeys.Health.Fitness.improvement_areas.localized)
                    .font(theme.typography.subheadline)
                    .fontWeight(.medium)

                if assessment.cardioLevel.rawValue != "excellent" {
                    AnalyticsSuggestionRow(
                        icon: "heart.fill",
                        title: LocalizationKeys.Health.Fitness.cardio_training.localized,
                        suggestion: LocalizationKeys.Health.Fitness.cardio_suggestion.localized,
                        color: .red
                    )
                }

                if assessment.strengthLevel.rawValue != "excellent" {
                    AnalyticsSuggestionRow(
                        icon: "dumbbell.fill",
                        title: LocalizationKeys.Health.Fitness.strength_training.localized,
                        suggestion: LocalizationKeys.Health.Fitness.strength_suggestion.localized,
                        color: .blue
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

#Preview {
    let mockAssessment = FitnessLevelAssessment(
        overallLevel: FitnessLevelAssessment.FitnessLevel.intermediate,
        cardioLevel: FitnessLevelAssessment.FitnessLevel.intermediate,
        strengthLevel: FitnessLevelAssessment.FitnessLevel.beginner,
        consistencyScore: 75.0,
        progressTrend: TrendDirection.increasing,
        assessmentDate: Date()
    )

    VStack(spacing: 20) {
        AnalyticsFitnessAssessmentCard(assessment: mockAssessment)
        AnalyticsEnhancedFitnessAssessmentCard(assessment: mockAssessment)
    }
    .padding()
    .environment(\.theme, DefaultLightTheme())
}