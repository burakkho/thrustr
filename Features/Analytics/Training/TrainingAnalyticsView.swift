import SwiftUI
import SwiftData

struct TrainingAnalyticsView: View {
    @Environment(\.theme) private var theme
    @Environment(UnitSettings.self) var unitSettings
    
    // Real SwiftData queries for lift exercise results
    @Query(
        sort: \LiftExerciseResult.performedAt,
        order: .reverse
    ) private var allLiftExerciseResults: [LiftExerciseResult]
    
    // Calculate 30 days ago for trend analysis
    private var thirtyDaysAgo: Date {
        Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    }
    
    // Filter recent lift exercise results
    private var recentLiftResults: [LiftExerciseResult] {
        allLiftExerciseResults.filter { result in
            result.performedAt >= thirtyDaysAgo
        }
    }
    
    var body: some View {
        LazyVStack(spacing: 32) {
            // 🎯 HERO TRAINING STORY - Your strength journey overview
            TrainingStoryHeroCard(liftResults: recentLiftResults)
            
            // 💪 STRENGTH PROGRESSION SHOWCASE - ActionableStatCard grid
            EnhancedStrengthProgressionSection(liftResults: recentLiftResults)
            
            // 🏆 PR CELEBRATION TIMELINE - Achievement showcase  
            EnhancedPRTimelineSection()
            
            // 📊 TRAINING INSIGHTS GRID - Frequency + patterns combined
            TrainingInsightsGridSection()
            
            // 🎯 GOALS & MOTIVATION - Next milestones
            TrainingGoalsMotivationSection(liftResults: recentLiftResults)
        }
    }
}

// MARK: - Strength Progression Section
struct StrengthProgressionSection: View {
    @Environment(\.theme) private var theme
    @Environment(UnitSettings.self) var unitSettings
    let liftResults: [LiftExerciseResult]
    
    // Calculate real exercise maxes from lift results
    private var exerciseMaxes: [(name: String, currentMax: Double, trend: TrendDirection, improvement: Double)] {
        let exerciseGroups = Dictionary(grouping: liftResults) { result in
            result.exercise?.exerciseName ?? "Unknown"
        }
        
        return exerciseGroups.compactMap { (exerciseName, results) in
            guard !results.isEmpty else { return nil }
            
            // Find current max (best set from all results)
            let currentMax = results.compactMap { $0.maxWeight }.max() ?? 0.0
            
            // Calculate trend (compare last 2 weeks vs previous 2 weeks)
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
        }.prefix(3).map { $0 } // Show top 3 exercises
    }
    
    var body: some View {
        VStack(spacing: theme.spacing.m) {
            HStack {
                Text("analytics.strength_progression".localized)
                    .font(theme.typography.headline)
                    .fontWeight(.semibold)
                Spacer()
                NavigationLink(destination: StrengthProgressionDetailView()) {
                    Text("common.view_all".localized)
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.accent)
                }
            }
            
            // Real 1RM Progression from SwiftData
            VStack(spacing: theme.spacing.s) {
                if exerciseMaxes.isEmpty {
                    // Empty state when no lift data available
                    VStack(spacing: theme.spacing.m) {
                        Image(systemName: "chart.bar.fill")
                            .font(.title)
                            .foregroundColor(theme.colors.textSecondary)
                        
                        Text(TrainingKeys.Analytics.noStrengthDataTitle.localized)
                            .font(theme.typography.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(theme.colors.textPrimary)
                        
                        Text(TrainingKeys.Analytics.noStrengthDataDesc.localized)
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, theme.spacing.l)
                } else {
                    ForEach(exerciseMaxes, id: \.name) { exerciseData in
                        StrengthMetricRow(
                            exercise: exerciseData.name,
                            currentMax: formatWeight(exerciseData.currentMax),
                            trend: exerciseData.trend,
                            trendValue: formatWeightDifference(exerciseData.improvement, trend: exerciseData.trend),
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
    
    // MARK: - Weight Formatting Functions
    
    private func formatWeight(_ weightInKg: Double) -> String {
        if unitSettings.unitSystem == .metric {
            return String(format: "%.1f kg", weightInKg)
        } else {
            let weightInLbs = weightInKg * 2.20462
            return String(format: "%.1f lb", weightInLbs)
        }
    }
    
    private func formatWeightDifference(_ diffInKg: Double, trend: TrendDirection) -> String {
        if diffInKg == 0 {
            return unitSettings.unitSystem == .metric ? "0kg" : "0lb"
        }
        
        let prefix = trend == .increasing ? "+" : (trend == .decreasing ? "-" : "")
        let absValue = abs(diffInKg)
        
        if unitSettings.unitSystem == .metric {
            return "\(prefix)\(String(format: "%.1f", absValue))kg"
        } else {
            let diffInLbs = absValue * 2.20462
            return "\(prefix)\(String(format: "%.1f", diffInLbs))lb"
        }
    }
}

// MARK: - Workout Frequency Section
struct WorkoutFrequencySection: View {
    @Environment(\.theme) private var theme
    
    // Real SwiftData queries for workout frequency
    @Query(
        sort: \LiftExerciseResult.performedAt,
        order: .reverse
    ) private var allLiftExerciseResults: [LiftExerciseResult]
    
    @Query(
        sort: \CardioResult.completedAt,
        order: .reverse
    ) private var allCardioResults: [CardioResult]
    
    @Query(
        sort: \LiftSession.startDate,
        order: .reverse
    ) private var allLiftSessions: [LiftSession]
    
    // Calculate date ranges
    private var oneWeekAgo: Date {
        Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    }
    
    private var oneMonthAgo: Date {
        Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    }
    
    // Calculate real metrics
    private var thisWeekWorkouts: Int {
        let liftWorkouts = allLiftExerciseResults.filter { $0.performedAt >= oneWeekAgo }.count
        let cardioWorkouts = allCardioResults.filter { $0.completedAt >= oneWeekAgo }.count
        return liftWorkouts + cardioWorkouts
    }
    
    private var thisMonthWorkouts: Int {
        let liftWorkouts = allLiftExerciseResults.filter { $0.performedAt >= oneMonthAgo }.count
        let cardioWorkouts = allCardioResults.filter { $0.completedAt >= oneMonthAgo }.count
        return liftWorkouts + cardioWorkouts
    }
    
    private var averageDuration: String {
        let recentSessions = allLiftSessions.filter { session in
            session.endDate != nil && session.startDate >= oneMonthAgo
        }
        guard !recentSessions.isEmpty else { return "0" }
        
        // Calculate average duration from actual session data
        let totalDuration = recentSessions.reduce(0.0) { total, session in
            total + session.duration
        }
        let avgSeconds = totalDuration / Double(recentSessions.count)
        let avgMinutes = Int(avgSeconds / 60)
        return "\(avgMinutes)"
    }
    
    var body: some View {
        VStack(spacing: theme.spacing.m) {
            HStack {
                Text("analytics.workout_frequency".localized)
                    .font(theme.typography.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            if thisWeekWorkouts == 0 && thisMonthWorkouts == 0 {
                // Empty state
                VStack(spacing: theme.spacing.s) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.title2)
                        .foregroundColor(theme.colors.textSecondary)
                    
                    Text(TrainingKeys.Analytics.noWorkoutsTitle.localized)
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.colors.textSecondary)
                    
                    Text("Start training to see your workout frequency")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, theme.spacing.m)
            } else {
                HStack(spacing: theme.spacing.l) {
                    FrequencyMetric(
                        title: "analytics.this_week".localized,
                        value: "\(thisWeekWorkouts)",
                        subtitle: "workouts".localized
                    )
                    
                    FrequencyMetric(
                        title: "analytics.this_month".localized,
                        value: "\(thisMonthWorkouts)",
                        subtitle: "workouts".localized
                    )
                    
                    FrequencyMetric(
                        title: "analytics.avg_duration".localized,
                        value: averageDuration,
                        subtitle: "minutes".localized
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

// MARK: - PR Timeline Section
struct PRTimelineSection: View {
    @Environment(\.theme) private var theme
    @Environment(UnitSettings.self) var unitSettings
    
    // Real SwiftData query for recent PRs
    @Query(
        sort: \LiftExerciseResult.performedAt,
        order: .reverse
    ) private var allLiftExerciseResults: [LiftExerciseResult]
    
    // Calculate real PRs from recent results
    private var recentPRs: [(exercise: String, weight: Double, date: Date, isNew: Bool)] {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let recentResults = allLiftExerciseResults.filter { $0.performedAt >= thirtyDaysAgo }
        
        // Group by exercise and find best weights
        let exerciseGroups = Dictionary(grouping: recentResults) { result in
            result.exercise?.exerciseName ?? "Unknown"
        }
        
        var prs: [(exercise: String, weight: Double, date: Date, isNew: Bool)] = []
        
        for (exerciseName, results) in exerciseGroups {
            // Filter results with valid maxWeight values
            let validResults: [(result: LiftExerciseResult, weight: Double)] = results.compactMap { result in
                guard let maxWeight = result.maxWeight, maxWeight > 0 else { return nil }
                return (result: result, weight: maxWeight)
            }
            
            guard let bestResult = validResults.max(by: { $0.weight < $1.weight }) else { continue }
            
            // Check if this is a new PR (within last 7 days)
            let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            let isNew = bestResult.result.performedAt >= oneWeekAgo
            
            prs.append((
                exercise: exerciseName,
                weight: bestResult.weight,
                date: bestResult.result.performedAt,
                isNew: isNew
            ))
        }
        
        return Array(prs.prefix(3)) // Show top 3 recent PRs
    }
    
    var body: some View {
        VStack(spacing: theme.spacing.m) {
            HStack {
                Text("analytics.recent_prs".localized)
                    .font(theme.typography.headline)
                    .fontWeight(.semibold)
                Spacer()
                NavigationLink(destination: PRHistoryDetailView()) {
                    Text("common.view_all".localized)
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.accent)
                }
            }
            
            VStack(spacing: theme.spacing.s) {
                if recentPRs.isEmpty {
                    // Empty state
                    VStack(spacing: theme.spacing.s) {
                        Image(systemName: "trophy")
                            .font(.title2)
                            .foregroundColor(theme.colors.textSecondary)
                        
                        Text(TrainingKeys.Analytics.noPRsTitle.localized)
                            .font(theme.typography.bodySmall)
                            .foregroundColor(theme.colors.textSecondary)
                        
                        Text("Complete workouts to set personal records")
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textTertiary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, theme.spacing.m)
                } else {
                    ForEach(recentPRs, id: \.exercise) { pr in
                        PRTimelineRow(
                            exercise: pr.exercise,
                            weight: formatWeight(pr.weight),
                            date: formatDate(pr.date),
                            isNew: pr.isNew
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
    
    // MARK: - Helper Functions
    
    private func formatWeight(_ weightInKg: Double) -> String {
        if unitSettings.unitSystem == .metric {
            return String(format: "%.1f kg", weightInKg)
        } else {
            let weightInLbs = weightInKg * 2.20462
            return String(format: "%.1f lb", weightInLbs)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let now = Date()
        let calendar = Calendar.current
        
        let daysDifference = calendar.dateComponents([.day], from: date, to: now).day ?? 0
        
        switch daysDifference {
        case 0:
            return "Today"
        case 1:
            return "1 day ago"
        case 2...6:
            return "\(daysDifference) days ago"
        case 7...13:
            return "1 week ago"
        case 14...20:
            return "2 weeks ago"
        case 21...27:
            return "3 weeks ago"
        default:
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
}

// MARK: - Training Patterns Section
struct TrainingPatternsSection: View {
    @Environment(\.theme) private var theme
    @Environment(UnitSettings.self) var unitSettings
    
    // Real SwiftData queries for training patterns
    @Query(
        sort: \LiftExerciseResult.performedAt,
        order: .reverse
    ) private var allLiftExerciseResults: [LiftExerciseResult]
    
    @Query(
        sort: \CardioResult.completedAt,
        order: .reverse
    ) private var allCardioResults: [CardioResult]
    
    // Calculate real training patterns
    private var mostActiveTimeRange: String {
        // Combine both lift and cardio results by converting to common date type
        let liftDates = allLiftExerciseResults.map { $0.performedAt }
        let cardioDates = allCardioResults.map { $0.completedAt }
        let allDates = liftDates + cardioDates
        
        guard !allDates.isEmpty else { return "No data" }
        
        let hourCounts = Dictionary(grouping: allDates) { date in
            Calendar.current.component(.hour, from: date)
        }.mapValues { $0.count }
        
        guard let mostActiveHour = hourCounts.max(by: { $0.value < $1.value })?.key else {
            return "No data"
        }
        
        let endHour = (mostActiveHour + 2) % 24
        return String(format: "%02d:00-%02d:00", mostActiveHour, endHour)
    }
    
    private var favoriteWorkoutDay: String {
        // Combine both lift and cardio results by converting to common date type
        let liftDates = allLiftExerciseResults.map { $0.performedAt }
        let cardioDates = allCardioResults.map { $0.completedAt }
        let allDates = liftDates + cardioDates
        
        guard !allDates.isEmpty else { return "No data" }
        
        let dayCounts = Dictionary(grouping: allDates) { date in
            Calendar.current.component(.weekday, from: date)
        }.mapValues { $0.count }
        
        guard let mostActiveDay = dayCounts.max(by: { $0.value < $1.value })?.key else {
            return "No data"
        }
        
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        let dayName = formatter.weekdaySymbols[mostActiveDay - 1]
        return dayName
    }
    
    private var weeklyVolume: Double {
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentResults = allLiftExerciseResults.filter { $0.performedAt >= oneWeekAgo }
        
        return recentResults.reduce(0.0) { total, result in
            total + result.totalVolume
        }
    }
    
    var body: some View {
        VStack(spacing: theme.spacing.m) {
            HStack {
                Text("analytics.training_patterns".localized)
                    .font(theme.typography.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: theme.spacing.s) {
                PatternInsight(
                    icon: "clock",
                    insight: "analytics.most_active_time".localized + ": " + mostActiveTimeRange
                )
                
                PatternInsight(
                    icon: "calendar",
                    insight: "analytics.favorite_workout_day".localized + ": " + favoriteWorkoutDay
                )
                
                PatternInsight(
                    icon: "chart.bar.fill",
                    insight: "analytics.avg_weekly_volume".localized + ": " + formatVolume(weeklyVolume)
                )
            }
        }
        .padding(theme.spacing.l)
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.l)
        .cardStyle()
    }
    
    private func formatVolume(_ weightInKg: Double) -> String {
        if weightInKg == 0 {
            return unitSettings.unitSystem == .metric ? "0 kg" : "0 lb"
        }
        
        if unitSettings.unitSystem == .metric {
            if weightInKg >= 1000 {
                let tons = weightInKg / 1000.0
                return String(format: "%.1f tons", tons)
            } else {
                return String(format: "%.0f kg", weightInKg)
            }
        } else {
            let weightInLbs = weightInKg * 2.20462
            if weightInLbs >= 2000 {
                let shortTons = weightInLbs / 2000.0
                return String(format: "%.1f tons", shortTons)
            } else {
                return String(format: "%.0f lb", weightInLbs)
            }
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

struct FrequencyMetric: View {
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
    let liftResults: [LiftExerciseResult]
    @Environment(\.theme) private var theme
    @Environment(UnitSettings.self) var unitSettings
    @State private var animateProgress = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Hero Header
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Strength Journey")
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
                    title: "PRs This Month",
                    value: "\(calculateMonthlyPRs())",
                    color: .orange,
                    celebrationType: calculateMonthlyPRs() > 0 ? .celebration : .none
                )
                
                TrainingStoryMetric(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Total Progress",
                    value: "+\(calculateTotalProgress())kg",
                    color: .green,
                    celebrationType: .progress
                )
                
                TrainingStoryMetric(
                    icon: "flame.fill",
                    title: "Streak",
                    value: "\(calculateStreak())d",
                    color: .red,
                    celebrationType: calculateStreak() >= 7 ? .fire : .none
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
        let prs = calculateMonthlyPRs()
        let progress = calculateTotalProgress()
        
        if prs >= 3 && progress >= 15 {
            return "🔥 You're crushing it! Outstanding strength gains this month."
        } else if prs >= 2 || progress >= 10 {
            return "💪 Solid progress! Your consistency is paying off."
        } else if liftResults.isEmpty {
            return "Ready to start your strength journey? Let's track those gains!"
        } else {
            return "🎯 Building momentum. Every rep counts towards your goals."
        }
    }
    
    private func calculateMonthlyPRs() -> Int {
        let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        let monthlyResults = liftResults.filter { $0.performedAt >= oneMonthAgo }
        
        // Group by exercise and find PRs
        let exerciseGroups = Dictionary(grouping: monthlyResults) { $0.exercise?.exerciseName ?? "Unknown" }
        
        return exerciseGroups.values.compactMap { results in
            results.compactMap { $0.maxWeight }.max()
        }.count
    }
    
    private func calculateTotalProgress() -> Int {
        let twoMonthsAgo = Calendar.current.date(byAdding: .month, value: -2, to: Date()) ?? Date()
        let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        
        let oldResults = liftResults.filter { $0.performedAt >= twoMonthsAgo && $0.performedAt < oneMonthAgo }
        let newResults = liftResults.filter { $0.performedAt >= oneMonthAgo }
        
        let oldMax = oldResults.compactMap { $0.maxWeight }.max() ?? 0
        let newMax = newResults.compactMap { $0.maxWeight }.max() ?? 0
        
        return max(0, Int(newMax - oldMax))
    }
    
    private func calculateStreak() -> Int {
        // Simple streak calculation - days with workouts
        let last30Days = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let recentResults = liftResults.filter { $0.performedAt >= last30Days }
        
        let workoutDays = Set(recentResults.map { 
            Calendar.current.startOfDay(for: $0.performedAt)
        })
        
        return min(workoutDays.count, 30)
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
                Text("Strength Progression")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                
                Spacer()
                
                NavigationLink(destination: StrengthProgressionDetailView()) {
                    Text("View All")
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
                        
                        Text("Complete your first workout to see strength progression analytics")
                            .font(.body)
                            .foregroundColor(theme.colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                    }
                    
                    NavigationLink(destination: Text("Lift Section")) {
                        Text("Start Training")
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
            result.exercise?.exerciseName ?? "Unknown"
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
                    Text("Personal Records")
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
                    Text("View All")
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
                        
                        Text("Set personal records and watch your strength progress unfold")
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
                                Text(formatWeight(pr.weight))
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
    
    private func formatWeight(_ weight: Double) -> String {
        if unitSettings.unitSystem == .metric {
            return String(format: "%.0f kg", weight)
        } else {
            let pounds = weight * 2.20462
            return String(format: "%.0f lb", pounds)
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

// 📊 TRAINING INSIGHTS GRID SECTION
struct TrainingInsightsGridSection: View {
    @Environment(\.theme) private var theme
    @Environment(UnitSettings.self) var unitSettings
    
    @Query(
        sort: \LiftExerciseResult.performedAt,
        order: .reverse
    ) private var allLiftExerciseResults: [LiftExerciseResult]
    
    @Query(
        sort: \CardioResult.completedAt,
        order: .reverse
    ) private var allCardioResults: [CardioResult]
    
    var body: some View {
        VStack(spacing: 20) {
            // Section Header
            HStack {
                Text("Training Insights")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                
                Spacer()
            }
            .padding(.horizontal, 4)
            
            // Insights Grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                TrainingInsightCard(
                    icon: "calendar.badge.clock",
                    title: "Workout Frequency",
                    value: "\(calculateWeeklyFrequency())/week",
                    trend: calculateFrequencyTrend(),
                    color: .blue
                )
                
                TrainingInsightCard(
                    icon: "clock.fill",
                    title: "Avg Duration",
                    value: "\(calculateAverageDuration())min",
                    trend: .stable,
                    color: .indigo
                )
                
                TrainingInsightCard(
                    icon: "flame.fill",
                    title: "Weekly Volume",
                    value: formatVolume(calculateWeeklyVolume()),
                    trend: calculateVolumeTrend(),
                    color: .orange
                )
                
                TrainingInsightCard(
                    icon: "star.fill",
                    title: "Best Day",
                    value: calculateBestWorkoutDay(),
                    trend: .stable,
                    color: .yellow
                )
            }
        }
    }
    
    // MARK: - Calculation Methods
    
    private func calculateWeeklyFrequency() -> Int {
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let liftWorkouts = allLiftExerciseResults.filter { $0.performedAt >= oneWeekAgo }.count
        let cardioWorkouts = allCardioResults.filter { $0.completedAt >= oneWeekAgo }.count
        return liftWorkouts + cardioWorkouts
    }
    
    private func calculateFrequencyTrend() -> TrendDirection {
        let thisWeek = calculateWeeklyFrequency()
        let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        let lastWeekLift = allLiftExerciseResults.filter { $0.performedAt >= twoWeeksAgo && $0.performedAt < oneWeekAgo }.count
        let lastWeekCardio = allCardioResults.filter { $0.completedAt >= twoWeeksAgo && $0.completedAt < oneWeekAgo }.count
        let lastWeek = lastWeekLift + lastWeekCardio
        
        if thisWeek > lastWeek { return .increasing }
        if thisWeek < lastWeek { return .decreasing }
        return .stable
    }
    
    private func calculateAverageDuration() -> Int {
        // Simplified calculation - would need LiftSession data for actual duration
        return 45 // Default average workout duration
    }
    
    private func calculateWeeklyVolume() -> Double {
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentResults = allLiftExerciseResults.filter { $0.performedAt >= oneWeekAgo }
        
        return recentResults.reduce(0.0) { total, result in
            total + result.totalVolume
        }
    }
    
    private func calculateVolumeTrend() -> TrendDirection {
        let thisWeekVolume = calculateWeeklyVolume()
        let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        let lastWeekResults = allLiftExerciseResults.filter { $0.performedAt >= twoWeeksAgo && $0.performedAt < oneWeekAgo }
        let lastWeekVolume = lastWeekResults.reduce(0.0) { total, result in
            total + result.totalVolume
        }
        
        if thisWeekVolume > lastWeekVolume * 1.1 { return .increasing }
        if thisWeekVolume < lastWeekVolume * 0.9 { return .decreasing }
        return .stable
    }
    
    private func calculateBestWorkoutDay() -> String {
        let liftDates = allLiftExerciseResults.map { $0.performedAt }
        let cardioDates = allCardioResults.map { $0.completedAt }
        let allDates = liftDates + cardioDates
        
        guard !allDates.isEmpty else { return "None" }
        
        let dayCounts = Dictionary(grouping: allDates) { date in
            Calendar.current.component(.weekday, from: date)
        }.mapValues { $0.count }
        
        guard let mostActiveDay = dayCounts.max(by: { $0.value < $1.value })?.key else {
            return "None"
        }
        
        let formatter = DateFormatter()
        let dayName = formatter.shortWeekdaySymbols[mostActiveDay - 1]
        return dayName
    }
    
    private func formatVolume(_ weightInKg: Double) -> String {
        if weightInKg == 0 {
            return "0"
        }
        
        if unitSettings.unitSystem == .metric {
            if weightInKg >= 1000 {
                let tons = weightInKg / 1000.0
                return String(format: "%.1ft", tons)
            } else {
                return String(format: "%.0fkg", weightInKg)
            }
        } else {
            let weightInLbs = weightInKg * 2.20462
            if weightInLbs >= 2000 {
                let shortTons = weightInLbs / 2000.0
                return String(format: "%.1ft", shortTons)
            } else {
                return String(format: "%.0flb", weightInLbs)
            }
        }
    }
}

// 🎯 TRAINING GOALS MOTIVATION SECTION
struct TrainingGoalsMotivationSection: View {
    let liftResults: [LiftExerciseResult]
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
                    Text("Set Goals")
                        .font(.caption)
                        .foregroundColor(theme.colors.accent)
                }
            }
            .padding(.horizontal, 4)
            
            // Motivation Cards
            VStack(spacing: 12) {
                MotivationCard(
                    title: "🎯 Next Milestone",
                    description: calculateNextMilestone(),
                    actionText: "Keep Pushing!",
                    progress: calculateMilestoneProgress()
                )
                
                MotivationCard(
                    title: "🔥 Weekly Challenge",
                    description: "Complete 4 workouts this week",
                    actionText: "\(calculateWeeklyWorkouts())/4 Done",
                    progress: Double(calculateWeeklyWorkouts()) / 4.0
                )
            }
        }
    }
    
    private func calculateNextMilestone() -> String {
        let maxWeight = liftResults.compactMap { $0.maxWeight }.max() ?? 0
        
        if maxWeight == 0 {
            return "Complete your first workout!"
        } else if maxWeight < 60 {
            return "Reach 60kg personal record"
        } else if maxWeight < 100 {
            return "Break the 100kg barrier"
        } else {
            let nextMilestone = ((Int(maxWeight) / 25) + 1) * 25
            return "Reach \(nextMilestone)kg milestone"
        }
    }
    
    private func calculateMilestoneProgress() -> Double {
        let maxWeight = liftResults.compactMap { $0.maxWeight }.max() ?? 0
        
        if maxWeight == 0 {
            return 0.0
        } else if maxWeight < 60 {
            return maxWeight / 60.0
        } else if maxWeight < 100 {
            return (maxWeight - 60) / 40.0
        } else {
            let currentMilestone = (Int(maxWeight) / 25) * 25
            let _ = currentMilestone + 25
            return (maxWeight - Double(currentMilestone)) / 25.0
        }
    }
    
    private func calculateWeeklyWorkouts() -> Int {
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return liftResults.filter { $0.performedAt >= oneWeekAgo }.count
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

enum CelebrationType {
    case none, celebration, progress, fire
}

struct TrainingStoryMetric: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    let celebrationType: CelebrationType
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                if celebrationType != .none {
                    Image(systemName: celebrationIcon)
                        .font(.caption)
                        .foregroundColor(celebrationColor)
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textPrimary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(theme.colors.backgroundSecondary.opacity(0.5))
        .cornerRadius(12)
    }
    
    private var celebrationIcon: String {
        switch celebrationType {
        case .celebration: return "party.popper.fill"
        case .progress: return "arrow.up.circle.fill"
        case .fire: return "flame.fill"
        case .none: return ""
        }
    }
    
    private var celebrationColor: Color {
        switch celebrationType {
        case .celebration: return .yellow
        case .progress: return .green
        case .fire: return .red
        case .none: return .clear
        }
    }
}

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
                Text(formatWeight(currentMax))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textPrimary)
                
                Text(exerciseName)
                    .font(.caption)
                    .foregroundColor(theme.colors.textSecondary)
                    .lineLimit(1)
                
                if improvement > 0 {
                    Text("+\(formatWeight(improvement))")
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
    
    private func formatWeight(_ weight: Double) -> String {
        if unitSettings.unitSystem == .metric {
            return String(format: "%.0f kg", weight)
        } else {
            let pounds = weight * 2.20462
            return String(format: "%.0f lb", pounds)
        }
    }
}

// MARK: - TrendDirection Support (uses HealthTrends.TrendDirection)
// Extensions are defined in Core/Models/HealthTrends.swift

#Preview {
    TrainingAnalyticsView()
        .environment(ThemeManager())
        .padding()
}