import SwiftUI

struct AISummaryCard: View {
    let report: HealthReport
    @Environment(\.theme) private var theme
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 0) {
            // Hero header - Prominent AI Intelligence Branding
            VStack(spacing: 16) {
                // Animated AI Brain Icon with Gradient
                ZStack {
                    // Background gradient circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [statusColor.opacity(0.2), statusColor.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .scaleEffect(isAnimating ? 1.1 : 0.95)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimating)

                    // AI Brain icon
                    Image(systemName: "brain.head.profile.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [statusColor, statusColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(isAnimating ? 1.05 : 0.98)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
                }

                // Title with Status Indicator
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Text(LocalizationKeys.Health.Intelligence.ai_summary.localized)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(theme.colors.textPrimary)

                        // Status Badge
                        Text(statusMessage)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(statusColor))
                    }

                    // Subtitle
                    Text(LocalizationKeys.Health.Intelligence.ai_powered_insights.localized)
                        .font(.caption)
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
            .padding(.top, 24)
            .padding(.horizontal, 20)

            // Story content - Narrative-driven health summary
            VStack(alignment: .leading, spacing: 16) {
                // Main Story Message
                Text(generateStoryMessage())
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(theme.colors.textPrimary)
                    .lineSpacing(4)
                    .multilineTextAlignment(.leading)

                // Key Insights Preview (if any high priority)
                if report.insights.filter({ $0.priority == .high }).count > 0 {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundColor(.orange)

                            Text(LocalizationKeys.Health.Intelligence.key_focus_areas.localized)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(theme.colors.textSecondary)
                        }

                        Text(generateKeyFocusMessage())
                            .font(.caption)
                            .foregroundColor(theme.colors.textSecondary)
                            .padding(.leading, 16)
                    }
                    .padding(12)
                    .background(theme.colors.backgroundSecondary.opacity(0.5))
                    .cornerRadius(8)
                }
            }
            .padding(.top, 20)
            .padding(.horizontal, 20)

            // Metrics summary - Visual health overview
            HStack(spacing: 20) {
                // Recovery Score Visual
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .stroke(statusColor.opacity(0.2), lineWidth: 3)
                            .frame(width: 40, height: 40)

                        Circle()
                            .trim(from: 0, to: CGFloat(report.recoveryScore.overallScore / 100))
                            .stroke(statusColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: 40, height: 40)
                            .rotationEffect(.degrees(-90))

                        Text("\(Int(report.recoveryScore.overallScore))")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(statusColor)
                    }

                    Text(LocalizationKeys.Health.Recovery.title.localized)
                        .font(.caption2)
                        .foregroundColor(theme.colors.textSecondary)
                }

                Divider()
                    .frame(height: 30)

                // Insights Count
                VStack(spacing: 4) {
                    Text("\(report.insights.count)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.textPrimary)

                    Text(LocalizationKeys.Health.Intelligence.insights_title.localized)
                        .font(.caption2)
                        .foregroundColor(theme.colors.textSecondary)
                }

                Spacer()

                // Last Update with improved styling
                VStack(alignment: .trailing, spacing: 2) {
                    Text(LocalizationKeys.Common.updated.localized)
                        .font(.caption2)
                        .foregroundColor(theme.colors.textSecondary)

                    Text(report.generatedDate, style: .time)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(theme.colors.textPrimary)
                }
            }
            .padding(.top, 16)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(theme.colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(statusColor.opacity(0.1), lineWidth: 1)
                )
        )
        .shadow(color: statusColor.opacity(0.1), radius: 12, x: 0, y: 6)
        .shadow(color: theme.shadows.card.opacity(0.05), radius: 4, x: 0, y: 2)
        .onAppear {
            isAnimating = true
        }
    }

    // MARK: - Computed Properties

    private var statusColor: Color {
        switch report.recoveryScore.overallScore {
        case 80...100: return .green
        case 60..<80: return .blue
        case 40..<60: return .orange
        default: return .red
        }
    }

    private var statusMessage: String {
        switch report.recoveryScore.overallScore {
        case 80...100: return LocalizationKeys.Health.Intelligence.status_optimal.localized
        case 60..<80: return LocalizationKeys.Health.Intelligence.status_good.localized
        case 40..<60: return LocalizationKeys.Health.Intelligence.status_caution.localized
        default: return LocalizationKeys.Health.Intelligence.status_focus.localized
        }
    }

    // MARK: - Story-Driven Messages

    private func generateStoryMessage() -> String {
        let recoveryScore = Int(report.recoveryScore.overallScore)
        let fitnessLevel = report.fitnessAssessment.overallLevel.localizedName
        let priorityInsights = report.insights.filter { $0.priority == .high }.count

        // Story-driven, personalized narrative approach
        if recoveryScore > 80 {
            return String(format: LocalizationKeys.Health.Intelligence.summary_excellent.localized, recoveryScore, fitnessLevel)
        } else if recoveryScore > 60 {
            return String(format: LocalizationKeys.Health.Intelligence.summary_good.localized, recoveryScore, fitnessLevel, priorityInsights)
        } else if recoveryScore > 40 {
            return String(format: LocalizationKeys.Health.Intelligence.summary_caution.localized, recoveryScore, priorityInsights)
        } else {
            return String(format: LocalizationKeys.Health.Intelligence.summary_focus.localized, recoveryScore, priorityInsights)
        }
    }

    private func generateKeyFocusMessage() -> String {
        let highPriorityInsights = report.insights.filter { $0.priority == .high }

        if highPriorityInsights.isEmpty {
            return LocalizationKeys.Health.Intelligence.no_critical_areas.localized
        }

        let topInsights = highPriorityInsights.prefix(3)
        let categories = topInsights.map { $0.type.rawValue.capitalized }

        switch categories.count {
        case 1:
            return String(format: LocalizationKeys.Health.Intelligence.primary_focus.localized, categories[0])
        case 2:
            return String(format: LocalizationKeys.Health.Intelligence.key_areas_two.localized, categories[0], categories[1])
        default:
            return String(format: LocalizationKeys.Health.Intelligence.focus_areas_multiple.localized, categories[0], categories[1], categories.count - 2)
        }
    }
}

#Preview {
    let mockReport = HealthReport(
        recoveryScore: RecoveryScore(
            overallScore: 75.0,
            hrvScore: 70.0,
            sleepScore: 80.0,
            workoutLoadScore: 75.0,
            restingHeartRateScore: 75.0,
            date: Date()
        ),
        insights: [],
        fitnessAssessment: FitnessLevelAssessment(
            overallLevel: FitnessLevelAssessment.FitnessLevel.intermediate,
            cardioLevel: FitnessLevelAssessment.FitnessLevel.intermediate,
            strengthLevel: FitnessLevelAssessment.FitnessLevel.beginner,
            consistencyScore: 75.0,
            progressTrend: TrendDirection.increasing,
            assessmentDate: Date()
        ),
        generatedDate: Date()
    )

    AISummaryCard(report: mockReport)
        .padding()
        .environment(\.theme, DefaultLightTheme())
}