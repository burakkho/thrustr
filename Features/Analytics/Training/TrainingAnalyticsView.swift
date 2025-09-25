import SwiftUI
import SwiftData

struct TrainingAnalyticsView: View {
    @State private var viewModel = TrainingAnalyticsViewModel()
    @Environment(\.theme) private var theme
    @Environment(UnitSettings.self) var unitSettings
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        LazyVStack(spacing: 32) {
            // 🎯 HERO TRAINING STORY - Your strength journey overview
            TrainingStoryHeroCard(viewModel: viewModel)

            // 💪 STRENGTH PROGRESSION SHOWCASE - ActionableStatCard grid
            AnalyticsStrengthProgressionSection(liftResults: viewModel.recentLiftResults)

            // 🏆 PR CELEBRATION TIMELINE - Achievement showcase
            EnhancedPRTimelineSection()

            // 📊 TRAINING INSIGHTS GRID - Frequency + patterns combined
            TrainingInsightsGridSection(
                liftResults: viewModel.recentLiftResults,
                cardioResults: viewModel.recentCardioResults,
                liftSessions: viewModel.recentLiftSessions
            )

            // 🎯 GOALS & MOTIVATION - Next milestones
            TrainingGoalsMotivationSection(viewModel: viewModel)
        }
        .onAppear {
            // Set ModelContext and load data when view appears
            viewModel.setModelContext(modelContext)
        }
    }
}





// MARK: - Supporting Components

struct StrengthMetricRow: View {
    let exercise: String
    let currentMax: String
    let trend: TrendDirection
    let trendValue: String
    let unitSettings: UnitSettings
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack {
            Text(exercise)
                .font(theme.typography.body)
                .foregroundColor(theme.colors.textPrimary)
            
            Spacer()
            
            HStack(spacing: theme.spacing.xs) {
                Text(currentMax)
                    .font(theme.typography.bodySmall)
                    .fontWeight(.medium)
                    .foregroundColor(theme.colors.textPrimary)
                
                HStack(spacing: 2) {
                    Image(systemName: trend.icon)
                        .font(.caption2)
                        .foregroundColor(trend.swiftUIColor)
                    
                    Text(trendValue)
                        .font(theme.typography.caption)
                        .foregroundColor(trend.swiftUIColor)
                }
            }
        }
        .padding(.vertical, theme.spacing.xs)
    }
}

struct TrainingFrequencyMetric: View {
    let title: String
    let value: String
    let subtitle: String
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: theme.spacing.xs) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(theme.colors.accent)
            
            Text(subtitle)
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textSecondary)
            
            Text(title)
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct PRTimelineRow: View {
    let exercise: String
    let weight: String
    let date: String
    let isNew: Bool
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack {
            HStack(spacing: theme.spacing.s) {
                Image(systemName: "trophy.fill")
                    .foregroundColor(isNew ? .orange : theme.colors.textSecondary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise)
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Text(date)
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textTertiary)
                }
            }
            
            Spacer()
            
            Text(weight)
                .font(theme.typography.bodySmall)
                .fontWeight(.medium)
                .foregroundColor(theme.colors.textPrimary)
        }
        .padding(.vertical, theme.spacing.xs)
    }
}

struct PatternInsight: View {
    let icon: String
    let insight: String
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack(spacing: theme.spacing.s) {
            Image(systemName: icon)
                .foregroundColor(theme.colors.accent)
                .frame(width: 20)
            
            Text(insight)
                .font(theme.typography.bodySmall)
                .foregroundColor(theme.colors.textSecondary)
            
            Spacer()
        }
    }
}

// MARK: - Enhanced Training Components (%100 UX)

// 🎯 HERO TRAINING STORY CARD
struct TrainingStoryHeroCard: View {
    let viewModel: TrainingAnalyticsViewModel
    @Environment(\.theme) private var theme
    @Environment(UnitSettings.self) var unitSettings
    @State private var animateProgress = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Hero Header
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(CommonKeys.Analytics.strengthJourney.localized)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Text(heroStoryMessage)
                        .font(.body)
                        .foregroundColor(theme.colors.textSecondary)
                        .lineSpacing(2)
                }
                
                Spacer()
                
                // Animated strength icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.2), Color.blue.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)
                        .scaleEffect(animateProgress ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: animateProgress)
                    
                    Image(systemName: "dumbbell.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                        .scaleEffect(animateProgress ? 1.05 : 0.98)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: animateProgress)
                }
            }
            
            // Key Metrics Grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 16) {
                TrainingStoryMetric(
                    icon: "trophy.fill",
                    title: CommonKeys.Analytics.prsThisMonth.localized,
                    value: "\(viewModel.calculateMonthlyPRs())",
                    color: .orange,
                    celebrationType: viewModel.calculateMonthlyPRs() > 0 ? .celebration : .none
                )

                TrainingStoryMetric(
                    icon: "chart.line.uptrend.xyaxis",
                    title: CommonKeys.Analytics.totalProgress.localized,
                    value: "+\(viewModel.calculateTotalProgress())kg",
                    color: .green,
                    celebrationType: .progress
                )

                TrainingStoryMetric(
                    icon: "flame.fill",
                    title: CommonKeys.Analytics.streak.localized,
                    value: "\(viewModel.calculateStreak())d",
                    color: .red,
                    celebrationType: viewModel.calculateStreak() >= 7 ? .fire : .none
                )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(theme.colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.blue.opacity(0.1), lineWidth: 1)
                )
        )
        .shadow(color: Color.blue.opacity(0.1), radius: 12, x: 0, y: 6)
        .onAppear {
            animateProgress = true
        }
    }
    
    // MARK: - Computed Properties
    
    private var heroStoryMessage: String {
        let prs = viewModel.calculateMonthlyPRs()
        let progress = viewModel.calculateTotalProgress()

        if prs >= 3 && progress >= 15 {
            return "🔥 You're crushing it! Outstanding strength gains this month."
        } else if prs >= 2 || progress >= 10 {
            return "💪 Solid progress! Your consistency is paying off."
        } else if viewModel.recentLiftResults.isEmpty {
            return "Ready to start your strength journey? Let's track those gains!"
        } else {
            return "🎯 Building momentum. Every rep counts towards your goals."
        }
    }
    
}

// 💪 ENHANCED STRENGTH PROGRESSION SECTION
struct EnhancedStrengthProgressionSection: View {
    let liftResults: [LiftExerciseResult]
    @Environment(\.theme) private var theme
    @Environment(UnitSettings.self) var unitSettings
    
    // Calculate exercise maxes (reuse existing logic)
    private var exerciseMaxes: [(name: String, currentMax: Double, trend: TrendDirection, improvement: Double)] {
        let exerciseGroups = Dictionary(grouping: liftResults) { result in
            result.exercise?.exerciseName ?? "Unknown"
        }
        
        return exerciseGroups.compactMap { (exerciseName, results) in
            guard !results.isEmpty else { return nil }
            
            let currentMax = results.compactMap { $0.maxWeight }.max() ?? 0.0
            let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
            let fourWeeksAgo = Calendar.current.date(byAdding: .day, value: -28, to: Date()) ?? Date()
            
            let recentResults = results.filter { $0.performedAt >= twoWeeksAgo }
            let previousResults = results.filter { $0.performedAt >= fourWeeksAgo && $0.performedAt < twoWeeksAgo }
            
            let recentMax = recentResults.compactMap { $0.maxWeight }.max() ?? 0.0
            let previousMax = previousResults.compactMap { $0.maxWeight }.max() ?? 0.0
            
            let improvement = recentMax - previousMax
            let trend: TrendDirection = {
                if improvement > 2.5 { return .increasing }
                if improvement < -2.5 { return .decreasing }
                return .stable
            }()
            
            return (exerciseName, currentMax, trend, abs(improvement))
        }.prefix(4).map { $0 } // Show top 4 for 2x2 grid
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Section Header
            HStack {
                Text(CommonKeys.Analytics.strengthProgression.localized)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                
                Spacer()
                
                NavigationLink(destination: StrengthProgressionDetailView()) {
                    Text(CommonKeys.Analytics.viewAll.localized)
                        .font(.caption)
                        .foregroundColor(theme.colors.accent)
                }
            }
            .padding(.horizontal, 4)
            
            if exerciseMaxes.isEmpty {
                // Enhanced empty state
                VStack(spacing: 16) {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 40))
                        .foregroundColor(theme.colors.textSecondary)
                    
                    VStack(spacing: 8) {
                        Text("💪 Start Your Strength Journey")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.colors.textPrimary)
                        
                        Text(CommonKeys.Analytics.completeFirstWorkout.localized)
                            .font(.body)
                            .foregroundColor(theme.colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                    }
                    
                    NavigationLink(destination: Text("Lift Section")) {
                        Text(CommonKeys.Analytics.startTraining.localized)
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                }
                .padding(.vertical, 40)
                .frame(maxWidth: .infinity)
            } else {
                // ActionableStatCard Grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 16) {
                    ForEach(exerciseMaxes, id: \.name) { exercise in
                        ActionableStrengthCard(
                            exerciseName: exercise.name,
                            currentMax: exercise.currentMax,
                            trend: exercise.trend,
                            improvement: exercise.improvement,
                            unitSettings: unitSettings
                        )
                    }
                }
            }
        }
    }
}

// 🏆 ENHANCED PR TIMELINE SECTION  
struct EnhancedPRTimelineSection: View {
    @Environment(\.theme) private var theme
    @Environment(UnitSettings.self) var unitSettings
    
    @Query(
        sort: \LiftExerciseResult.performedAt,
        order: .reverse
    ) private var allLiftExerciseResults: [LiftExerciseResult]
    
    // Calculate recent PRs (reuse existing logic)
    private var recentPRs: [(exercise: String, weight: Double, date: Date, isNew: Bool)] {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let recentResults = allLiftExerciseResults.filter { $0.performedAt >= thirtyDaysAgo }
        
        let exerciseGroups = Dictionary(grouping: recentResults) { result in
            result.exercise?.exerciseName ?? CommonKeys.Analytics.unknownExercise.localized
        }
        
        var prs: [(exercise: String, weight: Double, date: Date, isNew: Bool)] = []
        
        for (exerciseName, results) in exerciseGroups {
            let validResults: [(result: LiftExerciseResult, weight: Double)] = results.compactMap { result in
                guard let maxWeight = result.maxWeight, maxWeight > 0 else { return nil }
                return (result: result, weight: maxWeight)
            }
            
            guard let bestResult = validResults.max(by: { $0.weight < $1.weight }) else { continue }
            
            let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            let isNew = bestResult.result.performedAt >= oneWeekAgo
            
            prs.append((
                exercise: exerciseName,
                weight: bestResult.weight,
                date: bestResult.result.performedAt,
                isNew: isNew
            ))
        }
        
        return Array(prs.prefix(3))
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Section Header with celebration
            HStack {
                HStack(spacing: 8) {
                    Text(CommonKeys.Analytics.personalRecords.localized)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    if recentPRs.contains(where: { $0.isNew }) {
                        Text("🔥")
                            .font(.title3)
                            .scaleEffect(1.2)
                    }
                }
                
                Spacer()
                
                NavigationLink(destination: PRHistoryDetailView()) {
                    Text(CommonKeys.Analytics.viewAll.localized)
                        .font(.caption)
                        .foregroundColor(theme.colors.accent)
                }
            }
            .padding(.horizontal, 4)
            
            if recentPRs.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.orange.opacity(0.6))
                    
                    VStack(spacing: 8) {
                        Text("🏆 Your First PR Awaits")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.colors.textPrimary)
                        
                        Text(CommonKeys.Analytics.setPRMessage.localized)
                            .font(.body)
                            .foregroundColor(theme.colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                    }
                }
                .padding(.vertical, 32)
                .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 12) {
                    ForEach(recentPRs, id: \.exercise) { pr in
                        HStack {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(pr.isNew ? Color.orange.opacity(0.2) : theme.colors.backgroundSecondary)
                                        .frame(width: 40, height: 40)
                                    
                                    Image(systemName: "trophy.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(pr.isNew ? .orange : theme.colors.textSecondary)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(pr.exercise)
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(theme.colors.textPrimary)
                                    
                                    Text(formatRelativeDate(pr.date))
                                        .font(.caption)
                                        .foregroundColor(theme.colors.textSecondary)
                                }
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(TrainingAnalyticsService.formatWeight(pr.weight, unitSystem: unitSettings.unitSystem))
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(theme.colors.textPrimary)
                                
                                if pr.isNew {
                                    Text("NEW PR! 🔥")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(theme.colors.cardBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(pr.isNew ? Color.orange.opacity(0.3) : Color.clear, lineWidth: 1)
                                )
                        )
                        .shadow(color: pr.isNew ? Color.orange.opacity(0.1) : Color.clear, radius: 4, x: 0, y: 2)
                    }
                }
            }
        }
    }
    
    
    private func formatRelativeDate(_ date: Date) -> String {
        let now = Date()
        let calendar = Calendar.current
        let daysDifference = calendar.dateComponents([.day], from: date, to: now).day ?? 0
        
        switch daysDifference {
        case 0: return "Today"
        case 1: return "Yesterday"
        case 2...6: return "\(daysDifference) days ago"
        case 7...13: return "1 week ago"
        case 14...20: return "2 weeks ago"
        case 21...27: return "3 weeks ago"
        default:
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
}


// 🎯 TRAINING GOALS MOTIVATION SECTION
struct TrainingGoalsMotivationSection: View {
    let viewModel: TrainingAnalyticsViewModel
    @Environment(\.theme) private var theme
    @Environment(UnitSettings.self) var unitSettings
    
    var body: some View {
        VStack(spacing: 20) {
            // Section Header
            HStack {
                Text("Goals & Motivation")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                
                Spacer()
                
                NavigationLink(destination: Text("Goals Detail")) {
                    Text(CommonKeys.Analytics.setGoals.localized)
                        .font(.caption)
                        .foregroundColor(theme.colors.accent)
                }
            }
            .padding(.horizontal, 4)
            
            // Motivation Cards
            VStack(spacing: 12) {
                MotivationCard(
                    title: "🎯 Next Milestone",
                    description: viewModel.calculateNextMilestone(),
                    actionText: "Keep Pushing!",
                    progress: viewModel.calculateMilestoneProgress()
                )

                MotivationCard(
                    title: "🔥 Weekly Challenge",
                    description: "Complete 4 workouts this week",
                    actionText: "\(viewModel.calculateWeeklyWorkouts())/4 Done",
                    progress: Double(viewModel.calculateWeeklyWorkouts()) / 4.0
                )
            }
        }
    }
}

// MARK: - Supporting Components

struct TrainingInsightCard: View {
    let icon: String
    let title: String
    let value: String
    let trend: TrendDirection
    let color: Color
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
                
                Image(systemName: trend.icon)
                    .font(.caption)
                    .foregroundColor(trend.swiftUIColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textPrimary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct MotivationCard: View {
    let title: String
    let description: String
    let actionText: String
    let progress: Double
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Text(description)
                        .font(.body)
                        .foregroundColor(theme.colors.textSecondary)
                }
                
                Spacer()
                
                Text(actionText)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.colors.accent)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(theme.colors.backgroundSecondary)
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(theme.colors.accent)
                        .frame(width: geometry.size.width * min(progress, 1.0), height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(theme.colors.accent.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Supporting Components


struct ActionableStrengthCard: View {
    let exerciseName: String
    let currentMax: Double
    let trend: TrendDirection
    let improvement: Double
    let unitSettings: UnitSettings
    @Environment(\.theme) private var theme
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Exercise icon and trend
            HStack {
                Image(systemName: exerciseIcon)
                    .font(.title2)
                    .foregroundColor(trendColor)
                
                Spacer()
                
                Image(systemName: trend.icon)
                    .font(.caption)
                    .foregroundColor(trendColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(TrainingAnalyticsService.formatWeight(currentMax, unitSystem: unitSettings.unitSystem))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textPrimary)
                
                Text(exerciseName)
                    .font(.caption)
                    .foregroundColor(theme.colors.textSecondary)
                    .lineLimit(1)
                
                if improvement > 0 {
                    Text("+\(TrainingAnalyticsService.formatWeight(improvement, unitSystem: unitSettings.unitSystem))")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(trendColor)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(trendColor.opacity(0.2), lineWidth: 1)
                )
        )
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, perform: {}, onPressingChanged: { pressing in
            isPressed = pressing
        })
    }
    
    private var exerciseIcon: String {
        let name = exerciseName.lowercased()
        if name.contains("bench") { return "rectangle.fill" }
        if name.contains("squat") { return "figure.squat" }
        if name.contains("deadlift") { return "figure.strengthtraining.traditional" }
        if name.contains("press") { return "arrow.up.circle.fill" }
        return "dumbbell.fill"
    }
    
    private var trendColor: Color {
        switch trend {
        case .increasing: return .green
        case .decreasing: return .red
        case .stable: return .blue
        }
    }
    
}

// MARK: - Supporting Components

struct TrainingStoryMetric: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    let celebrationType: CelebrationType
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Spacer()
                if celebrationType != .none {
                    Image(systemName: celebrationType.icon)
                        .foregroundColor(celebrationType.color)
                        .font(.caption)
                }
            }

            Text(value)
                .font(theme.typography.title2)
                .fontWeight(.bold)
                .foregroundColor(theme.colors.textPrimary)

            Text(title)
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textSecondary)
                .multilineTextAlignment(.leading)
        }
        .padding(16)
        .background(theme.colors.cardBackground)
        .cornerRadius(12)
        .cardStyle()
    }

}


// MARK: - TrendDirection Support (uses HealthTrends.TrendDirection)
// Extensions are defined in Core/Models/HealthTrends.swift

#Preview {
    TrainingAnalyticsView()
        .environment(ThemeManager())
        .padding()
}