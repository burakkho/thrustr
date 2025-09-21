import SwiftUI
import SwiftData

struct TrainingStoryHeroCard: View {
    let liftResults: [LiftExerciseResult]
    @Environment(\.theme) private var theme
    @Environment(UnitSettings.self) var unitSettings
    @State private var animateGradient = false

    var body: some View {
        VStack(spacing: 0) {
            // Hero section with gradient background
            VStack(spacing: 16) {
                // Animated strength icon
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.8)],
                            startPoint: animateGradient ? .topLeading : .bottomTrailing,
                            endPoint: animateGradient ? .bottomTrailing : .topLeading
                        )
                    )
                    .scaleEffect(animateGradient ? 1.05 : 0.95)
                    .animation(
                        Animation.easeInOut(duration: 3.0).repeatForever(autoreverses: true),
                        value: animateGradient
                    )

                VStack(spacing: 8) {
                    Text(storyTitle)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text(storySubtitle)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.vertical, 32)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [theme.colors.accent, theme.colors.accent.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

            // Story metrics using existing QuickStatCard components
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 16) {
                QuickStatCard(
                    icon: "calendar.badge.clock",
                    title: LocalizationKeys.Training.Analytics.sessions_this_month.localized,
                    value: "\(monthlySessionCount)",
                    subtitle: LocalizationKeys.Training.Analytics.sessions.localized,
                    color: .blue
                )

                QuickStatCard(
                    icon: "trophy.fill",
                    title: LocalizationKeys.Training.Analytics.personal_records.localized,
                    value: "\(personalRecordCount)",
                    subtitle: LocalizationKeys.Training.Analytics.total_prs.localized,
                    color: .orange
                )

                QuickStatCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: LocalizationKeys.Training.Analytics.strength_trend.localized,
                    value: strengthTrendValue,
                    subtitle: strengthTrendSubtitle,
                    color: strengthTrendColor
                )
            }
            .padding(20)
            .background(theme.colors.cardBackground)
        }
        .cornerRadius(20)
        .shadow(color: theme.colors.accent.opacity(0.2), radius: 12, x: 0, y: 6)
        .onAppear {
            animateGradient = true
        }
    }

    // MARK: - Computed Properties

    private var storyTitle: String {
        if liftResults.isEmpty {
            return LocalizationKeys.Training.Analytics.journey_begins.localized
        } else if personalRecordCount > 0 {
            return LocalizationKeys.Training.Analytics.strength_growing.localized
        } else {
            return LocalizationKeys.Training.Analytics.building_strength.localized
        }
    }

    private var storySubtitle: String {
        if liftResults.isEmpty {
            return LocalizationKeys.Training.Analytics.start_tracking_message.localized
        } else {
            return String(format: LocalizationKeys.Training.Analytics.sessions_completed.localized, monthlySessionCount)
        }
    }

    private var monthlySessionCount: Int {
        let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        return liftResults.filter { $0.performedAt >= oneMonthAgo }.count
    }

    private var personalRecordCount: Int {
        let prs = PRCalculationService.calculatePersonalRecords(from: liftResults)
        return prs.count
    }

    private var strengthTrendValue: String {
        let exerciseMaxes = TrainingAnalyticsService.calculateExerciseMaxes(from: liftResults)
        let improvingCount = exerciseMaxes.filter { $0.trend == .increasing }.count
        let totalCount = exerciseMaxes.count

        if totalCount == 0 { return "--" }

        let percentage = Double(improvingCount) / Double(totalCount) * 100
        return "\(Int(percentage))%"
    }

    private var strengthTrendSubtitle: String {
        let exerciseMaxes = TrainingAnalyticsService.calculateExerciseMaxes(from: liftResults)
        let improvingCount = exerciseMaxes.filter { $0.trend == .increasing }.count
        return LocalizationKeys.Training.Analytics.exercises_improving.localized
    }

    private var strengthTrendColor: Color {
        let exerciseMaxes = TrainingAnalyticsService.calculateExerciseMaxes(from: liftResults)
        let improvingCount = exerciseMaxes.filter { $0.trend == .increasing }.count
        let totalCount = exerciseMaxes.count

        if totalCount == 0 { return .gray }

        let percentage = Double(improvingCount) / Double(totalCount)
        if percentage >= 0.7 { return .green }
        if percentage >= 0.4 { return .blue }
        return .orange
    }
}

#Preview {
    TrainingStoryHeroCard(liftResults: [])
        .environment(\.theme, DefaultLightTheme())
        .environment(UnitSettings.shared)
}