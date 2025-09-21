import SwiftUI
import SwiftData
import Foundation

struct AnalyticsTrainingStoryHeroCard: View {
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
                    title: "sessions_this_month",
                    value: "\(monthlySessionCount)",
                    subtitle: "sessions",
                    color: .blue
                )

                QuickStatCard(
                    icon: "trophy.fill",
                    title: "personal_records",
                    value: "\(personalRecordCount)",
                    subtitle: "total_prs",
                    color: .orange
                )

                QuickStatCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "strength_trend",
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
            return "journey_begins"
        } else if personalRecordCount > 0 {
            return "strength_growing"
        } else {
            return "building_strength"
        }
    }

    private var storySubtitle: String {
        if liftResults.isEmpty {
            return "start_tracking_message"
        } else {
            return String(format: "sessions_completed", monthlySessionCount)
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
        let _ = exerciseMaxes.filter { $0.trend == .increasing }.count
        return "exercises_improving"
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
    AnalyticsTrainingStoryHeroCard(liftResults: [])
        .environment(\.theme, DefaultLightTheme())
        .environment(UnitSettings.shared)
}