import SwiftUI

struct AnalyticsRecoveryScoreCard: View {
    let recoveryScore: RecoveryScore
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizationKeys.Common.HealthKit.recoveryScoreTitle.localized)
                        .font(theme.typography.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.colors.textPrimary)

                    Text(LocalizationKeys.Common.HealthKit.recoveryScoreSubtitle.localized)
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(recoveryScore.overallScore))")
                        .font(theme.typography.display1)
                        .fontWeight(.bold)
                        .foregroundColor(Color(recoveryScore.category.color))

                    Text("/100")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                }
            }

            // Progress Ring
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: recoveryScore.overallScore / 100)
                    .stroke(
                        Color(recoveryScore.category.color),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 4) {
                    Image(systemName: recoveryScore.category.icon)
                        .font(.title2)
                        .foregroundColor(Color(recoveryScore.category.color))

                    Text(recoveryScore.category.rawValue)
                        .font(theme.typography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(theme.colors.textPrimary)
                }
            }

            // Recommendation
            Text(recoveryScore.recommendation)
                .font(theme.typography.body)
                .foregroundColor(theme.colors.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Detailed Scores
            VStack(spacing: 8) {
                ScoreDetailRow(title: LocalizationKeys.Common.HealthKit.sleepScore.localized, score: recoveryScore.sleepScore)
                ScoreDetailRow(title: LocalizationKeys.Common.HealthKit.hrvScore.localized, score: recoveryScore.hrvScore)
                ScoreDetailRow(title: LocalizationKeys.Common.HealthKit.workloadScore.localized, score: recoveryScore.workoutLoadScore)
                ScoreDetailRow(title: LocalizationKeys.Common.HealthKit.restingHRScore.localized, score: recoveryScore.restingHeartRateScore)
            }
            .padding(.top, 8)
        }
        .padding(20)
        .background(theme.colors.cardBackground)
        .cornerRadius(12)
        .shadow(color: theme.shadows.card.opacity(0.05), radius: 2)
    }
}

struct AnalyticsRecoveryFactorRow: View {
    let title: String
    let score: Double
    let icon: String
    @Environment(\.theme) private var theme

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(theme.colors.accent)
                .frame(width: 20)

            Text(title)
                .font(theme.typography.body)
                .foregroundColor(theme.colors.textPrimary)

            Spacer()

            Text("\(Int(score))%")
                .font(theme.typography.body)
                .fontWeight(.medium)
                .foregroundColor(getScoreColor(score))
        }
    }

    private func getScoreColor(_ score: Double) -> Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .blue
        case 40..<60: return .orange
        default: return .red
        }
    }
}

struct AnalyticsEnhancedRecoveryScoreCard: View {
    let recoveryScore: RecoveryScore
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: theme.spacing.l) {
            // Enhanced version of existing RecoveryScoreCard
            RecoveryScoreCard(recoveryScore: recoveryScore)

            // Recovery factors breakdown
            VStack(alignment: .leading, spacing: theme.spacing.s) {
                Text(LocalizationKeys.Health.Recovery.factors_title.localized)
                    .font(theme.typography.subheadline)
                    .fontWeight(.medium)

                AnalyticsRecoveryFactorRow(title: LocalizationKeys.Health.Recovery.sleep_quality.localized, score: recoveryScore.sleepScore, icon: "bed.double.fill")
                AnalyticsRecoveryFactorRow(title: LocalizationKeys.Health.Recovery.hrv.localized, score: recoveryScore.hrvScore, icon: "waveform.path.ecg")
                AnalyticsRecoveryFactorRow(title: LocalizationKeys.Health.Recovery.workout_load.localized, score: recoveryScore.workoutLoadScore, icon: "figure.strengthtraining.traditional")
            }
            .padding(.top, theme.spacing.m)
        }
        .padding(theme.spacing.l)
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.l)
        .cardStyle()
    }
}

#Preview {
    let mockRecoveryScore = RecoveryScore(
        overallScore: 75.0,
        hrvScore: 70.0,
        sleepScore: 80.0,
        workoutLoadScore: 75.0,
        restingHeartRateScore: 75.0,
        date: Date()
    )

    VStack(spacing: 20) {
        AnalyticsRecoveryScoreCard(recoveryScore: mockRecoveryScore)
        AnalyticsEnhancedRecoveryScoreCard(recoveryScore: mockRecoveryScore)
    }
    .padding()
    .environment(\.theme, DefaultLightTheme())
}