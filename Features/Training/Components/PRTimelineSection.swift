import SwiftUI
import SwiftData

struct PRTimelineSection: View {
    let liftResults: [LiftExerciseResult]
    @Environment(\.theme) private var theme
    @Environment(UnitSettings.self) var unitSettings

    var body: some View {
        VStack(spacing: theme.spacing.m) {
            // Section header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "trophy.fill")
                        .font(.title3)
                        .foregroundColor(.orange)

                    Text(LocalizationKeys.Training.Analytics.personal_records.localized)
                        .font(theme.typography.headline)
                        .fontWeight(.semibold)
                }

                Spacer()

                if !recentPRs.isEmpty {
                    NavigationLink(destination: PRDetailView()) {
                        Text(LocalizationKeys.Common.view_all.localized)
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.accent)
                    }
                }
            }

            if recentPRs.isEmpty {
                EmptyStateView(
                    icon: "trophy",
                    title: LocalizationKeys.Training.Analytics.no_prs_title.localized,
                    message: LocalizationKeys.Training.Analytics.no_prs_message.localized,
                    actionTitle: LocalizationKeys.Training.Analytics.start_lifting.localized,
                    action: {
                        print("Navigate to lift training")
                    }
                )
                .padding(.vertical, theme.spacing.l)
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(recentPRs.enumerated()), id: \.offset) { index, pr in
                        PRTimelineRow(
                            personalRecord: pr,
                            unitSettings: unitSettings
                        )
                    }
                }
            }
        }
        .padding(theme.spacing.l)
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.l)
        .cardStyle()
    }

    // MARK: - Computed Properties

    private var recentPRs: [PRCalculationService.PersonalRecord] {
        PRCalculationService.calculatePersonalRecords(from: liftResults, limit: 5)
    }
}

// MARK: - PR Timeline Row Component

struct PRTimelineRow: View {
    let personalRecord: PRCalculationService.PersonalRecord
    let unitSettings: UnitSettings
    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: 12) {
            // PR Achievement Badge
            ZStack {
                Circle()
                    .fill(personalRecord.isNew ? Color.orange.opacity(0.2) : theme.colors.backgroundSecondary)
                    .frame(width: 44, height: 44)

                Image(systemName: "trophy.fill")
                    .font(.title3)
                    .foregroundColor(personalRecord.isNew ? .orange : theme.colors.textSecondary)
                    .scaleEffect(personalRecord.isNew ? 1.1 : 1.0)
            }

            // Exercise info
            VStack(alignment: .leading, spacing: 4) {
                Text(personalRecord.exercise)
                    .font(theme.typography.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.colors.textPrimary)

                Text(formatRelativeDate(personalRecord.date))
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }

            Spacer()

            // Weight and improvement info
            VStack(alignment: .trailing, spacing: 4) {
                Text(Units.formatWeight(kg: personalRecord.weight, system: unitSettings.unitSystem))
                    .font(theme.typography.headline)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textPrimary)

                if personalRecord.isNew {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.caption2)
                            .foregroundColor(.orange)

                        Text(LocalizationKeys.Training.Analytics.new_pr.localized)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }
                } else if let improvement = personalRecord.improvement, improvement > 0 {
                    Text("+\(Units.formatWeight(kg: improvement, system: unitSettings.unitSystem))")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            // Navigate to exercise detail
            print("Tapped PR for \(personalRecord.exercise)")
        }
    }

    private func formatRelativeDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day], from: date, to: now)

        if let days = components.day {
            switch days {
            case 0:
                return LocalizationKeys.Common.Time.today.localized
            case 1:
                return LocalizationKeys.Common.Time.yesterday.localized
            case 2...6:
                return String(format: LocalizationKeys.Common.Time.days_ago.localized, days)
            case 7...13:
                return LocalizationKeys.Common.Time.week_ago.localized
            case 14...20:
                return LocalizationKeys.Common.Time.weeks_ago.localized
            case 21...27:
                return LocalizationKeys.Common.Time.weeks_ago_3.localized
            default:
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                return formatter.string(from: date)
            }
        }
        return ""
    }
}

// MARK: - Enhanced PR Timeline with Statistics

struct EnhancedPRTimelineSection: View {
    let liftResults: [LiftExerciseResult]
    @Environment(\.theme) private var theme
    @Environment(UnitSettings.self) var unitSettings

    var body: some View {
        VStack(spacing: theme.spacing.l) {
            // PR Statistics using existing QuickStatCard
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 16) {
                QuickStatCard(
                    icon: "trophy.fill",
                    title: LocalizationKeys.Training.Analytics.total_prs.localized,
                    value: "\(prStatistics.totalPRs)",
                    subtitle: LocalizationKeys.Training.Analytics.all_time.localized,
                    color: .orange
                )

                QuickStatCard(
                    icon: "flame.fill",
                    title: LocalizationKeys.Training.Analytics.new_prs.localized,
                    value: "\(prStatistics.newPRsThisWeek)",
                    subtitle: LocalizationKeys.Training.Analytics.this_week.localized,
                    color: .red
                )

                QuickStatCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: LocalizationKeys.Training.Analytics.avg_improvement.localized,
                    value: averageImprovementText,
                    subtitle: LocalizationKeys.Training.Analytics.per_pr.localized,
                    color: .green
                )
            }
            .padding(.horizontal, theme.spacing.l)

            // Regular PR Timeline
            PRTimelineSection(liftResults: liftResults)
        }
    }

    // MARK: - Computed Properties

    private var prStatistics: (totalPRs: Int, newPRsThisWeek: Int, averageImprovement: Double, strongestLift: PRCalculationService.PersonalRecord?) {
        let allPRs = PRCalculationService.calculatePersonalRecords(from: liftResults, limit: 100)
        return PRCalculationService.calculatePRStatistics(from: allPRs)
    }

    private var averageImprovementText: String {
        let avgImprovement = prStatistics.averageImprovement
        if avgImprovement <= 0 { return "--" }
        return Units.formatWeight(kg: avgImprovement, system: unitSettings.unitSystem)
    }
}

#Preview {
    VStack(spacing: 20) {
        PRTimelineSection(liftResults: [])
        EnhancedPRTimelineSection(liftResults: [])
    }
    .environment(\.theme, DefaultLightTheme())
    .environment(UnitSettings.shared)
}