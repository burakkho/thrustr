import SwiftUI
import SwiftData

struct TrainingGoalsMotivationSection: View {
    let liftResults: [LiftExerciseResult]
    @Environment(\.theme) private var theme
    @Environment(UnitSettings.self) var unitSettings
    @Query private var user: [User]

    var body: some View {
        VStack(spacing: theme.spacing.l) {
            // Goals section header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "target")
                        .font(.title3)
                        .foregroundColor(.blue)

                    Text(LocalizationKeys.Training.Analytics.goals_motivation.localized)
                        .font(theme.typography.headline)
                        .fontWeight(.semibold)
                }
                Spacer()
            }
            .padding(.horizontal, theme.spacing.l)

            // Next PR predictions using ActionableStatCard
            if !nextPRPredictions.isEmpty {
                VStack(alignment: .leading, spacing: theme.spacing.m) {
                    Text(LocalizationKeys.Training.Analytics.next_pr_targets.localized)
                        .font(theme.typography.subheadline)
                        .fontWeight(.medium)
                        .padding(.horizontal, theme.spacing.l)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(Array(nextPRPredictions.enumerated()), id: \.offset) { index, prediction in
                                PRPredictionCard(prediction: prediction, unitSettings: unitSettings)
                            }
                        }
                        .padding(.horizontal, theme.spacing.l)
                    }
                }
            }

            // Motivation insights using existing components
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 16) {
                MotivationCard(
                    title: LocalizationKeys.Training.Analytics.streak_title.localized,
                    value: "\(currentStreak)",
                    subtitle: currentStreak == 1 ? LocalizationKeys.Training.Analytics.day.localized : LocalizationKeys.Training.Analytics.days.localized,
                    icon: "flame.fill",
                    color: .orange,
                    celebrationType: currentStreak >= 7 ? .fire : .none
                )

                MotivationCard(
                    title: LocalizationKeys.Training.Analytics.monthly_progress.localized,
                    value: "\(monthlyWorkoutCount)",
                    subtitle: LocalizationKeys.Training.Analytics.workouts_completed.localized,
                    icon: "calendar.badge.clock",
                    color: .green,
                    celebrationType: monthlyWorkoutCount >= 12 ? .celebration : .none
                )
            }
            .padding(.horizontal, theme.spacing.l)

            // Progress insights
            if !progressInsights.isEmpty {
                VStack(alignment: .leading, spacing: theme.spacing.s) {
                    Text(LocalizationKeys.Training.Analytics.progress_insights.localized)
                        .font(theme.typography.subheadline)
                        .fontWeight(.medium)
                        .padding(.horizontal, theme.spacing.l)

                    ForEach(Array(progressInsights.enumerated()), id: \.offset) { index, insight in
                        HStack(spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)

                            Text(insight)
                                .font(theme.typography.caption)
                                .foregroundColor(theme.colors.textSecondary)
                                .lineLimit(2)

                            Spacer()
                        }
                        .padding(.horizontal, theme.spacing.l)
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding(.vertical, theme.spacing.l)
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.l)
        .cardStyle()
    }

    // MARK: - Computed Properties

    private var nextPRPredictions: [PRCalculationService.PRPrediction] {
        let exerciseMaxes = TrainingAnalyticsService.calculateExerciseMaxes(from: liftResults)

        return exerciseMaxes.prefix(3).compactMap { exerciseData in
            PRCalculationService.predictNextPRMilestone(for: exerciseData.name, from: liftResults)
        }
    }

    private var currentStreak: Int {
        // Calculate current workout streak
        let calendar = Calendar.current
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())

        let workoutDates = Set(liftResults.map { calendar.startOfDay(for: $0.performedAt) })

        // Count backwards from today
        while workoutDates.contains(currentDate) {
            streak += 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        }

        return streak
    }

    private var monthlyWorkoutCount: Int {
        let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        return liftResults.filter { $0.performedAt >= oneMonthAgo }.count
    }

    private var progressInsights: [String] {
        TrainingAnalyticsService.generateProgressInsights(liftResults: liftResults)
    }
}

// MARK: - PR Prediction Card

struct PRPredictionCard: View {
    let prediction: PRCalculationService.PRPrediction
    let unitSettings: UnitSettings
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 12) {
            // Exercise name and icon
            VStack(spacing: 4) {
                Image(systemName: "target")
                    .font(.title2)
                    .foregroundColor(.blue)

                Text(prediction.exercise)
                    .font(theme.typography.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
            }

            // Current vs target
            VStack(spacing: 8) {
                VStack(spacing: 2) {
                    Text(LocalizationKeys.Training.Analytics.current.localized)
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)

                    Text(Units.formatWeight(kg: prediction.currentWeight, system: unitSettings.unitSystem))
                        .font(theme.typography.headline)
                        .fontWeight(.bold)
                }

                Image(systemName: "arrow.down")
                    .font(.caption)
                    .foregroundColor(theme.colors.textSecondary)

                VStack(spacing: 2) {
                    Text(LocalizationKeys.Training.Analytics.target.localized)
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)

                    Text(Units.formatWeight(kg: prediction.nextMilestone, system: unitSettings.unitSystem))
                        .font(theme.typography.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
            }

            // Time prediction
            VStack(spacing: 2) {
                Text(LocalizationKeys.Training.Analytics.estimated_time.localized)
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textSecondary)

                Text(timeEstimateText)
                    .font(theme.typography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
            }

            // Confidence indicator
            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { index in
                    Circle()
                        .fill(index < confidenceStars ? .yellow : .gray.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
            }
        }
        .frame(width: 140, height: 160)
        .padding(theme.spacing.m)
        .background(theme.colors.backgroundSecondary)
        .cornerRadius(theme.radius.m)
    }

    private var timeEstimateText: String {
        let days = prediction.estimatedTimeInDays
        if days <= 7 {
            return String(format: LocalizationKeys.Training.Analytics.days_estimate.localized, days)
        } else if days <= 30 {
            let weeks = days / 7
            return String(format: LocalizationKeys.Training.Analytics.weeks_estimate.localized, weeks)
        } else {
            let months = days / 30
            return String(format: LocalizationKeys.Training.Analytics.months_estimate.localized, months)
        }
    }

    private var confidenceStars: Int {
        Int(prediction.confidence / 20) // Convert 0-100 to 0-5 stars
    }
}

// MARK: - Motivation Card

struct MotivationCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    let celebrationType: CelebrationType
    @Environment(\.theme) private var theme
    @State private var animateCelebration = false


    var body: some View {
        VStack(spacing: 12) {
            // Icon with celebration animation
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .scaleEffect(animateCelebration && celebrationType != .none ? 1.1 : 1.0)

                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .scaleEffect(animateCelebration && celebrationType != .none ? 1.05 : 1.0)
            }
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: animateCelebration)

            VStack(spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textPrimary)

                Text(title)
                    .font(theme.typography.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.colors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }

            // Celebration indicator
            if celebrationType != .none {
                HStack(spacing: 4) {
                    Image(systemName: celebrationType.icon)
                        .font(.caption)
                        .foregroundColor(celebrationType.color)
                        .scaleEffect(animateCelebration ? 1.2 : 1.0)

                    Text(celebrationText)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(celebrationType.color)
                }
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: animateCelebration)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(theme.spacing.m)
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.m)
        .onAppear {
            if celebrationType != .none {
                animateCelebration = true
            }
        }
    }

    private var celebrationText: String {
        switch celebrationType {
        case .celebration: return LocalizationKeys.Training.Analytics.great_job.localized
        case .progress: return LocalizationKeys.Training.Analytics.keep_going.localized
        case .fire: return LocalizationKeys.Training.Analytics.on_fire.localized
        case .none: return ""
        }
    }
}

#Preview {
    TrainingGoalsMotivationSection(liftResults: [])
        .environment(\.theme, DefaultLightTheme())
        .environment(UnitSettings.shared)
}