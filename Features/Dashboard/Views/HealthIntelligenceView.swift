import SwiftUI

struct HealthIntelligenceView: View {
    @StateObject private var healthKitService = HealthKitService.shared
    @Environment(\.theme) private var theme
    @StateObject private var unitSettings = UnitSettings.shared
    @State private var isLoading = true
    @State private var healthReport: HealthReport?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if isLoading {
                        HealthLoadingView()
                    } else if let report = healthReport {
                        // MARK: - Recovery Score Section
                        RecoveryScoreCard(recoveryScore: report.recoveryScore)
                        
                        // MARK: - Fitness Assessment Section
                        FitnessAssessmentCard(assessment: report.fitnessAssessment)
                        
                        // MARK: - Health Insights Section
                        HealthInsightsSection(insights: report.insights)
                    } else {
                        EmptyIntelligenceView()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
            .navigationTitle(CommonKeys.HealthKit.healthIntelligenceTitle.localized)
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await loadHealthIntelligence()
            }
        }
        .onAppear {
            Task {
                await loadHealthIntelligence()
            }
        }
    }
    
    private func loadHealthIntelligence() async {
        isLoading = true
        defer { isLoading = false }
        
        let report = await healthKitService.generateComprehensiveHealthReport()
        await MainActor.run {
            healthReport = report
        }
    }
}

// MARK: - Recovery Score Card
struct RecoveryScoreCard: View {
    let recoveryScore: RecoveryScore
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(CommonKeys.HealthKit.recoveryScoreTitle.localized)
                        .font(theme.typography.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Text(CommonKeys.HealthKit.recoveryScoreSubtitle.localized)
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
                ScoreDetailRow(title: CommonKeys.HealthKit.sleepScore.localized, score: recoveryScore.sleepScore)
                ScoreDetailRow(title: CommonKeys.HealthKit.hrvScore.localized, score: recoveryScore.hrvScore)
                ScoreDetailRow(title: CommonKeys.HealthKit.workloadScore.localized, score: recoveryScore.workoutLoadScore)
                ScoreDetailRow(title: CommonKeys.HealthKit.restingHRScore.localized, score: recoveryScore.restingHeartRateScore)
            }
            .padding(.top, 8)
        }
        .padding(20)
        .background(theme.colors.cardBackground)
        .cornerRadius(12)
        .shadow(color: theme.shadows.card.opacity(0.05), radius: 2)
    }
}

struct ScoreDetailRow: View {
    let title: String
    let score: Double
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack {
            Text(title)
                .font(theme.typography.body)
                .foregroundColor(theme.colors.textPrimary)
            
            Spacer()
            
            HStack(spacing: 8) {
                ProgressView(value: score, total: 100)
                    .progressViewStyle(LinearProgressViewStyle(tint: getScoreColor(score)))
                    .frame(width: 60)
                
                Text("\(Int(score))")
                    .font(theme.typography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.colors.textPrimary)
                    .frame(width: 30)
            }
        }
    }
    
    private func getScoreColor(_ score: Double) -> Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .blue
        case 40..<60: return .yellow
        case 20..<40: return .orange
        default: return .red
        }
    }
}

// MARK: - Fitness Assessment Card
struct FitnessAssessmentCard: View {
    let assessment: FitnessLevelAssessment
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(CommonKeys.HealthKit.fitnessLevelTitle.localized)
                .font(theme.typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(theme.colors.textPrimary)
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(CommonKeys.HealthKit.overallLevelTitle.localized)
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
                            .foregroundColor(Color(assessment.progressTrend.color))
                        
                        Text(assessment.progressTrend.displayText)
                            .font(theme.typography.caption)
                            .fontWeight(.medium)
                            .foregroundColor(Color(assessment.progressTrend.color))
                    }
                    
                    Text("\(CommonKeys.HealthKit.consistencyTitle.localized): \(Int(assessment.consistencyScore))%")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
            
            // Detailed breakdown
            VStack(spacing: 12) {
                FitnessLevelRow(
                    title: CommonKeys.HealthKit.cardioTitle.localized,
                    level: assessment.cardioLevel,
                    icon: "heart.fill"
                )
                
                FitnessLevelRow(
                    title: CommonKeys.HealthKit.strengthTitle.localized,
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

struct FitnessLevelRow: View {
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

// MARK: - Health Insights Section
struct HealthInsightsSection: View {
    let insights: [HealthInsight]
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(CommonKeys.HealthKit.healthInsightsTitle.localized)
                .font(theme.typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(theme.colors.textPrimary)
            
            if insights.isEmpty {
                EmptyInsightsView()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(insights, id: \.id) { insight in
                        HealthInsightCard(insight: insight)
                    }
                }
            }
        }
        .padding(20)
        .background(theme.colors.cardBackground)
        .cornerRadius(12)
        .shadow(color: theme.shadows.card.opacity(0.05), radius: 2)
    }
}

struct HealthInsightCard: View {
    let insight: HealthInsight
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Priority indicator
            Circle()
                .fill(Color(insight.priority.color))
                .frame(width: 8, height: 8)
                .padding(.top, 6)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(insight.title)
                        .font(theme.typography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Spacer()
                    
                    Text(insight.type.rawValue)
                        .font(theme.typography.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(theme.colors.backgroundSecondary)
                        .foregroundColor(theme.colors.textSecondary)
                        .cornerRadius(8)
                }
                
                Text(insight.message)
                    .font(theme.typography.body)
                    .foregroundColor(theme.colors.textSecondary)
                
                if insight.actionable, let action = insight.action {
                    HStack(spacing: 6) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        
                        Text(action)
                            .font(theme.typography.caption)
                            .fontWeight(.medium)
                            .foregroundColor(theme.colors.textPrimary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.yellow.opacity(0.1))
                    .cornerRadius(6)
                }
            }
        }
        .padding(12)
        .background(theme.colors.backgroundSecondary)
        .cornerRadius(8)
    }
}

// MARK: - Empty States
struct EmptyIntelligenceView: View {
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 48))
                .foregroundColor(theme.colors.textSecondary)
            
            Text(CommonKeys.HealthKit.unavailableTitle.localized)
                .font(theme.typography.title2)
                .fontWeight(.semibold)
                .foregroundColor(theme.colors.textPrimary)
            
            Text(CommonKeys.HealthKit.unavailableMessage.localized)
                .font(theme.typography.body)
                .foregroundColor(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical, 40)
    }
}

struct EmptyInsightsView: View {
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title)
                .foregroundColor(.green)
            
            Text(CommonKeys.HealthKit.noInsightsTitle.localized)
                .font(theme.typography.subheadline)
                .fontWeight(.medium)
                .foregroundColor(theme.colors.textPrimary)
            
            Text(CommonKeys.HealthKit.noInsightsMessage.localized)
                .font(theme.typography.body)
                .foregroundColor(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 20)
    }
}

struct HealthLoadingView: View {
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text(CommonKeys.HealthKit.loadingMessage.localized)
                .font(theme.typography.body)
                .foregroundColor(theme.colors.textSecondary)
        }
        .frame(height: 200)
    }
}

#Preview {
    HealthIntelligenceView()
        .environment(\.theme, DefaultLightTheme())
}