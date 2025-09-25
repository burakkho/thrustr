import SwiftUI

struct HealthIntelligenceView: View {
    @State private var viewModel = HealthIntelligenceViewModel()
    @Environment(\.theme) private var theme
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom Tab Bar
                IntelligenceTabBar(selectedTab: $viewModel.selectedTab)

                ScrollView {
                    LazyVStack(spacing: 20) {
                        if viewModel.isLoading {
                            AnalyticsEnhancedHealthLoadingView()
                        } else if let report = viewModel.healthReport {
                            switch viewModel.selectedTab {
                            case .overview:
                                overviewSection(report: report)
                            case .recovery:
                                recoverySection(report: report)
                            case .fitness:
                                fitnessSection(report: report)
                            case .trends:
                                trendsSection(report: report)
                            }
                        } else {
                            EmptyIntelligenceView()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.selectedTab)
                }
            }
            .navigationTitle("health.intelligence.title".localized)
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.loadHealthIntelligence()
            }
            .sheet(item: $viewModel.selectedInsight) { insight in
                HealthIntelligenceInsightDetailView(insight: insight)
            }
        }
        .onAppear {
            Task {
                await viewModel.loadHealthIntelligence()
                viewModel.startCardAnimations()
            }
        }
    }
    
    // MARK: - Section Views
    
    @ViewBuilder
    private func overviewSection(report: HealthReport) -> some View {
        // AI Summary Card
        AISummaryCard(report: report)
            .scaleEffect(viewModel.animateCards ? 1.0 : 0.95)
            .opacity(viewModel.animateCards ? 1.0 : 0.6)
            .animation(.easeInOut(duration: 0.4).delay(0.1), value: viewModel.animateCards)

        // Key Metrics Row
        KeyMetricsRow(report: report)
            .scaleEffect(viewModel.animateCards ? 1.0 : 0.95)
            .opacity(viewModel.animateCards ? 1.0 : 0.6)
            .animation(.easeInOut(duration: 0.4).delay(0.2), value: viewModel.animateCards)
        
        // Priority Insights
        HealthIntelligencePriorityInsightsSection(
            insights: HealthAnalyticsService.getPriorityInsights(from: report.insights),
            onInsightTapped: { viewModel.selectInsight($0) }
        )
        .scaleEffect(viewModel.animateCards ? 1.0 : 0.95)
        .opacity(viewModel.animateCards ? 1.0 : 0.6)
        .animation(.easeInOut(duration: 0.4).delay(0.3), value: viewModel.animateCards)

        // Quick Actions
        QuickActionsRow(report: report)
            .scaleEffect(viewModel.animateCards ? 1.0 : 0.95)
            .opacity(viewModel.animateCards ? 1.0 : 0.6)
            .animation(.easeInOut(duration: 0.4).delay(0.4), value: viewModel.animateCards)
    }
    
    @ViewBuilder
    private func recoverySection(report: HealthReport) -> some View {
        // Enhanced Recovery Score Card with breakdown
        AnalyticsEnhancedRecoveryScoreCard(recoveryScore: report.recoveryScore)
        
        // Recovery Trend Chart (if historical data available)
        AnalyticsRecoveryTrendChart(recoveryScore: report.recoveryScore)
        
        // Recovery Insights filtered
        let recoveryInsights = HealthAnalyticsService.getRecoveryInsights(from: report.insights)
        if !recoveryInsights.isEmpty {
            InsightsSectionView(
                title: "health.intelligence.recovery_insights".localized,
                insights: recoveryInsights,
                onInsightTapped: { viewModel.selectInsight($0) }
            )
        }
    }
    
    @ViewBuilder
    private func fitnessSection(report: HealthReport) -> some View {
        // Enhanced Fitness Assessment
        FitnessAssessmentCard(assessment: report.fitnessAssessment)
        
        // VO2 Max Visualization (if available)
        if let vo2Max = viewModel.vo2Max {
            VO2MaxVisualizationCard(vo2Max: vo2Max, viewModel: viewModel)
        }
        
        // Workout insights
        let workoutInsights = HealthAnalyticsService.getWorkoutInsights(from: report.insights)
        if !workoutInsights.isEmpty {
            InsightsSectionView(
                title: "health.intelligence.training_insights".localized,
                insights: workoutInsights,
                onInsightTapped: { viewModel.selectInsight($0) }
            )
        }
    }
    
    @ViewBuilder
    private func trendsSection(report: HealthReport) -> some View {
        // Steps Trend Chart
        AnalyticsStepsTrendChart(stepsHistory: viewModel.stepsHistory, todaySteps: viewModel.todaySteps)

        // Weight Trend Chart (if available)
        if !viewModel.weightHistory.isEmpty {
            AnalyticsWeightTrendChart(weightHistory: viewModel.weightHistory, currentWeight: viewModel.currentWeight)
        }

        // Heart Rate Trend (if available)
        if !viewModel.heartRateHistory.isEmpty {
            AnalyticsHeartRateTrendChart(heartRateHistory: viewModel.heartRateHistory)
        }
        
        // Trend insights
        let trendInsights = HealthAnalyticsService.getTrendInsights(from: report.insights)
        if !trendInsights.isEmpty {
            InsightsSectionView(
                title: "health.intelligence.trend_analysis".localized,
                insights: trendInsights,
                onInsightTapped: { viewModel.selectInsight($0) }
            )
        }
    }
}

// MARK: - Recovery Score Card
// MARK: - Duplicate RecoveryScoreCard removed - use AnalyticsRecoveryScoreCard instead

// MARK: - ScoreDetailRow removed - use service methods for color logic

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
                            .foregroundColor(assessment.progressTrend.swiftUIColor)
                        
                        Text(assessment.progressTrend.displayText)
                            .font(theme.typography.caption)
                            .fontWeight(.medium)
                            .foregroundColor(assessment.progressTrend.swiftUIColor)
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

// MARK: - Empty States

// MARK: - Feature Bullet Point
struct FeatureBullet: View {
    let icon: String
    let text: String
    let color: Color
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
                .frame(width: 16)
            
            Text(text)
                .font(.caption)
                .foregroundColor(theme.colors.textSecondary)
            
            Spacer()
        }
    }
}


// MARK: - Positive Indicator
struct PositiveIndicator: View {
    let text: String
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle")
                .font(.caption2)
                .foregroundColor(.green)
            
            Text(text)
                .font(.caption2)
                .foregroundColor(theme.colors.textSecondary)
            
            Spacer()
        }
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

// MARK: - Enhanced UI Components



struct KeyMetricsRow: View {
    let report: HealthReport
    @Environment(\.theme) private var theme
    
    var body: some View {
        // Enhanced metrics grid using QuickStatCard
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 16) {
            
            // Recovery Score
            QuickStatCard(
                icon: "heart.fill",
                title: "health.intelligence.metrics.recovery".localized,
                value: "\(Int(report.recoveryScore.overallScore))",
                subtitle: "/100 " + report.recoveryScore.category.rawValue,
                color: getRecoveryColor(),
                borderlessLight: false
            )
            
            // Fitness Level
            QuickStatCard(
                icon: "figure.strengthtraining.traditional",
                title: "health.intelligence.metrics.fitness".localized,
                value: report.fitnessAssessment.overallLevel.rawValue.capitalized,
                subtitle: "health.fitness.level".localized,
                color: .blue,
                borderlessLight: false
            )
            
            // Insights Count
            QuickStatCard(
                icon: "lightbulb.fill", 
                title: "health.intelligence.metrics.insights".localized,
                value: "\(report.insights.count)",
                subtitle: "health.intelligence.metrics.insights_unit".localized,
                color: .purple,
                borderlessLight: false
            )
        }
        .padding(.horizontal, 4)
    }
    
    private func getRecoveryColor() -> Color {
        switch report.recoveryScore.overallScore {
        case 80...100: return .green
        case 60..<80: return .blue
        case 40..<60: return .orange
        default: return .red
        }
    }
}


struct HealthIntelligencePriorityInsightsSection: View {
    let insights: [HealthInsight]
    let onInsightTapped: (HealthInsight) -> Void
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Modern Section Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.title3)
                        .foregroundColor(.yellow)
                    
                    Text("health.intelligence.priority_insights".localized)
                        .font(theme.typography.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.colors.textPrimary)
                }
                
                Spacer()
                
                if insights.count > 2 {
                    Button(action: {
                        // Navigate to all insights
                    }) {
                        Text("common.view_all".localized)
                            .font(.caption)
                            .foregroundColor(theme.colors.accent)
                    }
                }
            }
            .padding(.horizontal, 4)
            
            // ActionableStatCard Grid - Showcase Style
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 16) {
                ForEach(insights.prefix(4), id: \.id) { insight in
                    AnalyticsActionableInsightCard(insight: insight) {
                        onInsightTapped(insight)
                    }
                }
            }
        }
    }
}


// MARK: - Legacy Compact Card (kept for compatibility)
struct CompactInsightCard: View {
    let insight: HealthInsight
    let action: () -> Void
    @Environment(\.theme) private var theme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Circle()
                    .fill(priorityColor.opacity(0.2))
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .fill(priorityColor)
                            .frame(width: 4, height: 4)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(insight.title)
                        .font(theme.typography.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(theme.colors.textPrimary)
                        .lineLimit(1)
                    
                    Text(insight.message)
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(theme.colors.textTertiary)
            }
            .padding(12)
            .background(theme.colors.backgroundSecondary)
            .cornerRadius(8)
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

struct QuickActionsRow: View {
    let report: HealthReport
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("health.intelligence.quick_actions".localized)
                .font(theme.typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(theme.colors.textPrimary)
                .padding(.horizontal, 4)
            
            HStack(spacing: 12) {
                QuickActionButton(
                    title: "health.intelligence.suggest_workout".localized,
                    icon: "figure.run",
                    style: .secondary,
                    action: { 
                        // Navigate to workout suggestions based on recovery score
                        if report.recoveryScore.overallScore > 70 {
                            // High recovery - suggest intense workout
                            print("🏋️ Suggesting high intensity workout")
                        } else {
                            // Low recovery - suggest light activity
                            print("🚶 Suggesting light activity")
                        }
                    }
                )
                
                QuickActionButton(
                    title: "health.intelligence.nutrition_advice".localized,
                    icon: "leaf.fill",
                    style: .secondary,
                    action: { 
                        // Navigate to nutrition insights
                        print("🥗 Opening nutrition recommendations")
                        // This could navigate to NutritionView with specific recommendations
                    }
                )
                
                if report.recoveryScore.overallScore < 60 {
                    QuickActionButton(
                        title: "health.intelligence.rest_recommendation".localized,
                        icon: "moon.fill",
                        style: .secondary,
                        action: { 
                            // Navigate to recovery/rest recommendations
                            print("😴 Opening rest and recovery guide")
                            // This could show sleep tips, meditation, etc.
                        }
                    )
                }
            }
        }
    }
}


struct EnhancedHealthLoadingView: View {
    @State private var animateGradient = false
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 24) {
            // Animated brain icon
            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [theme.colors.accent, theme.colors.accent.opacity(0.6)],
                        startPoint: animateGradient ? .topLeading : .bottomTrailing,
                        endPoint: animateGradient ? .bottomTrailing : .topLeading
                    )
                )
                .scaleEffect(animateGradient ? 1.1 : 1.0)
                .animation(
                    Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                    value: animateGradient
                )
            
            VStack(spacing: 8) {
                Text("health.intelligence.loading.title".localized)
                    .font(theme.typography.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                
                Text("health.intelligence.loading.subtitle".localized)
                    .font(theme.typography.body)
                    .foregroundColor(theme.colors.textSecondary)
            }
            
            // Progress steps
            VStack(alignment: .leading, spacing: 8) {
                LoadingStep(text: "health.intelligence.loading.step.reading_data".localized, isActive: true)
                LoadingStep(text: "health.intelligence.loading.step.recovery_analysis".localized, isActive: animateGradient)
                LoadingStep(text: "health.intelligence.loading.step.fitness_assessment".localized, isActive: false)
                LoadingStep(text: "health.intelligence.loading.step.generating_insights".localized, isActive: false)
            }
            .padding(.top, 16)
        }
        .frame(height: 300)
        .onAppear {
            animateGradient = true
        }
    }
}

struct LoadingStep: View {
    let text: String
    let isActive: Bool
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(isActive ? theme.colors.accent : theme.colors.backgroundSecondary)
                .frame(width: 8, height: 8)
                .scaleEffect(isActive ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: isActive)
            
            Text(text)
                .font(theme.typography.caption)
                .foregroundColor(isActive ? theme.colors.textPrimary : theme.colors.textSecondary)
        }
    }
}

// Placeholder views for new components (to be implemented)
struct EnhancedRecoveryScoreCard: View {
    let recoveryScore: RecoveryScore
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: theme.spacing.l) {
            // Enhanced version of existing RecoveryScoreCard
            AnalyticsRecoveryScoreCard(recoveryScore: recoveryScore)
            
            // Recovery factors breakdown
            VStack(alignment: .leading, spacing: theme.spacing.s) {
                Text(CommonKeys.Analytics.recoveryFactors.localized)
                    .font(theme.typography.subheadline)
                    .fontWeight(.medium)
                
                RecoveryFactorRow(title: "Sleep Quality", score: recoveryScore.sleepScore, icon: "bed.double.fill")
                RecoveryFactorRow(title: "HRV", score: recoveryScore.hrvScore, icon: "waveform.path.ecg")
                RecoveryFactorRow(title: "Workout Load", score: recoveryScore.workoutLoadScore, icon: "figure.strengthtraining.traditional")
            }
            .padding(.top, theme.spacing.m)
        }
        .padding(theme.spacing.l)
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.l)
        .cardStyle()
    }
}

struct RecoveryFactorRow: View {
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

// MARK: - Removed duplicate RecoveryTrendChart - using AnalyticsRecoveryTrendChart instead

// MARK: - Removed duplicate EnhancedFitnessAssessmentCard and SuggestionRow
// Use existing FitnessAssessmentCard from Analytics components

struct VO2MaxVisualizationCard: View {
    let vo2Max: Double
    let viewModel: HealthIntelligenceViewModel
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            Text("VO2 Max Fitness")
                .font(theme.typography.headline)
                .fontWeight(.semibold)
            
            HStack {
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text("\(Int(vo2Max))")
                        .font(theme.typography.display1)
                        .fontWeight(.bold)
                        .foregroundColor(Color(viewModel.vo2MaxColor))
                    
                    Text("ml/kg/min")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: theme.spacing.xs) {
                    Text(viewModel.vo2MaxCategory)
                        .font(theme.typography.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color(viewModel.vo2MaxColor))
                    
                    Text(viewModel.vo2MaxDescription)
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                        .multilineTextAlignment(.trailing)
                }
            }
            
            // VO2 Max scale visualization
            HStack {
                ForEach(VO2MaxRange.allCases, id: \.self) { range in
                    Rectangle()
                        .fill(range.color.opacity(isCurrentRange(range) ? 1.0 : 0.3))
                        .frame(height: 8)
                        .cornerRadius(2)
                }
            }
        }
        .padding(theme.spacing.l)
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.l)
        .cardStyle()
    }

    private func isCurrentRange(_ range: VO2MaxRange) -> Bool {
        return RecoveryCalculationService.isVO2MaxInRange(vo2Max, range: range)
    }
}

enum VO2MaxRange: CaseIterable {
    case poor, fair, good, excellent
    
    var color: Color {
        switch self {
        case .poor: return .red
        case .fair: return .orange
        case .good: return .blue
        case .excellent: return .green
        }
    }
}

// MARK: - Legacy Components (kept for now - will be replaced by Analytics components)

struct WeightTrendChart: View {
    let weightHistory: [HealthDataPoint]
    let currentWeight: Double?
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            HStack {
                Text("health.weight".localized)
                    .font(theme.typography.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("analytics.this_month".localized)
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }
            
            // Real health trend line
            Path { path in
                let points = (0..<7).map { index in
                    let dayWeight = currentWeight ?? 70.0
                    let normalizedY = CGFloat(max(20, min(60, (dayWeight - 60) * 2 + 40))) // Normalize weight to chart height
                    return CGPoint(x: CGFloat(index) * 40, y: normalizedY)
                }
                
                if let firstPoint = points.first {
                    path.move(to: firstPoint)
                    for point in points.dropFirst() {
                        path.addLine(to: point)
                    }
                }
            }
            .stroke(Color.green, lineWidth: 3)
            .frame(height: 80)
        }
        .padding(theme.spacing.l)
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.l)
        .cardStyle()
    }
}

struct HeartRateTrendChart: View {
    let heartRateHistory: [HealthDataPoint]
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            HStack {
                Text("health.heart_rate".localized)
                    .font(theme.typography.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("analytics.this_week".localized)
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }
            
            // Heart rate zones
            VStack(spacing: 8) {
                HStack {
                    Circle().fill(Color.red).frame(width: 8, height: 8)
                    Text("Resting: 65 bpm")
                        .font(theme.typography.body)
                    Spacer()
                }
                
                HStack {
                    Circle().fill(Color.orange).frame(width: 8, height: 8)
                    Text("Active: 120 bpm")
                        .font(theme.typography.body)
                    Spacer()
                }
            }
        }
        .padding(theme.spacing.l)
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.l)
        .cardStyle()
    }
}

struct InsightsSectionView: View {
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
                        InsightRow(insight: insight) {
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

struct InsightRow: View {
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

struct HealthIntelligenceInsightDetailView: View {
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
                            Text(CommonKeys.Analytics.recommendedAction.localized)
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
            .navigationTitle("Insight Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
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
    HealthIntelligenceView()
        .environment(\.theme, DefaultLightTheme())
}
