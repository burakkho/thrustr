import SwiftUI
import SwiftData

struct TrainingConsistencyRing: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    
    let user: User
    @State private var weeklyData: [WeeklyConsistency] = []
    @State private var isLoading = false
    @State private var selectedMetric: ConsistencyMetric = .frequency
    
    enum ConsistencyMetric: String, CaseIterable {
        case frequency = "frequency"
        case streak = "streak"
        case goals = "goals"
        
        var displayName: String {
            switch self {
            case .frequency: return TrainingKeys.ConsistencyAnalytics.frequency.localized
            case .streak: return TrainingKeys.ConsistencyAnalytics.streak.localized
            case .goals: return TrainingKeys.ConsistencyAnalytics.goals.localized
            }
        }
        
        var icon: String {
            switch self {
            case .frequency: return "calendar"
            case .streak: return "flame.fill"
            case .goals: return "target"
            }
        }
        
        var color: Color {
            switch self {
            case .frequency: return .blue
            case .streak: return .orange
            case .goals: return .green
            }
        }
    }
    
    struct WeeklyConsistency: Identifiable, Equatable {
        let id = UUID()
        let weekStart: Date
        let sessionsCompleted: Int
        let sessionTarget: Int // Target sessions for that week
        let streakDays: Int
        let goalCompletionRate: Double // 0.0 - 1.0
        
        var completionPercentage: Double {
            guard sessionTarget > 0 else { return 0.0 }
            return min(1.0, Double(sessionsCompleted) / Double(sessionTarget))
        }
        
        var isFullWeek: Bool {
            sessionsCompleted >= sessionTarget
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            headerSection
            metricSelector
            
            if isLoading {
                loadingState
            } else {
                consistencyRingView
                weeklyBreakdown
                consistencyInsights
            }
        }
        .padding(theme.spacing.m)
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.l)
        .shadow(color: theme.shadows.card, radius: 4, y: 2)
        .onAppear {
            loadConsistencyData()
        }
        .onChange(of: selectedMetric) { _, _ in
            loadConsistencyData()
        }
    }
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(TrainingKeys.ConsistencyAnalytics.title.localized)
                    .font(theme.typography.headline)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textPrimary)
                
                Text(TrainingKeys.ConsistencyAnalytics.subtitle.localized)
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }
            
            Spacer()
            
            Text("\(currentStreakDays) gün")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(consistencyColor)
                .cornerRadius(theme.radius.s)
        }
    }
    
    private var metricSelector: some View {
        HStack(spacing: 8) {
            ForEach(ConsistencyMetric.allCases, id: \.self) { metric in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedMetric = metric
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: metric.icon)
                            .font(.caption)
                        
                        Text(metric.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(selectedMetric == metric ? .white : theme.colors.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        selectedMetric == metric ? 
                        metric.color : 
                        theme.colors.backgroundSecondary
                    )
                    .cornerRadius(theme.radius.s)
                }
            }
            
            Spacer()
        }
    }
    
    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.2)
            
            Text(TrainingKeys.ConsistencyAnalytics.dataLoading.localized)
                .font(theme.typography.body)
                .foregroundColor(theme.colors.textSecondary)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }
    
    private var consistencyRingView: some View {
        VStack(spacing: theme.spacing.m) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(theme.colors.border.opacity(0.2), lineWidth: 12)
                    .frame(width: 160, height: 160)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: currentMetricProgress)
                    .stroke(
                        selectedMetric.color.gradient,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: currentMetricProgress)
                
                // Center content
                VStack(spacing: 4) {
                    Text(currentMetricValue)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Text(currentMetricLabel)
                        .font(.caption)
                        .foregroundColor(theme.colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Ring segments for weekly view
            weeklyRingSegments
        }
    }
    
    private var weeklyRingSegments: some View {
        HStack(spacing: 4) {
            ForEach(Array(weeklyData.enumerated()), id: \.offset) { index, week in
                RoundedRectangle(cornerRadius: 3)
                    .fill(weekConsistencyColor(week))
                    .frame(width: 8, height: 32)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(theme.colors.cardBackground, lineWidth: 1)
                    )
                    .scaleEffect(week.isFullWeek ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.3).delay(Double(index) * 0.1), value: weeklyData)
            }
        }
    }
    
    private var weeklyBreakdown: some View {
        VStack(spacing: theme.spacing.s) {
            HStack {
                Text(TrainingKeys.ConsistencyAnalytics.last12Weeks.localized)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                
                Spacer()
                
                Text("⚡ \(perfectWeeksCount) " + TrainingKeys.ConsistencyAnalytics.perfectWeeks.localized)
                    .font(.caption2)
                    .foregroundColor(theme.colors.success)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 6), spacing: 8) {
                ForEach(Array(weeklyData.suffix(12).enumerated()), id: \.offset) { index, week in
                    weeklyMiniCard(week: week, index: index)
                }
            }
        }
    }
    
    private func weeklyMiniCard(week: WeeklyConsistency, index: Int) -> some View {
        VStack(spacing: 2) {
            RoundedRectangle(cornerRadius: 4)
                .fill(weekConsistencyColor(week))
                .frame(height: 24)
                .overlay(
                    Text("\(week.sessionsCompleted)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
            
            Text("W\(index + 1)")
                .font(.caption2)
                .foregroundColor(theme.colors.textSecondary)
        }
        .animation(.easeInOut(duration: 0.3).delay(Double(index) * 0.05), value: weeklyData)
    }
    
    private var consistencyInsights: some View {
        VStack(spacing: theme.spacing.s) {
            Divider()
                .background(theme.colors.border.opacity(0.3))
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(TrainingKeys.ConsistencyAnalytics.thisWeek.localized)
                        .font(.caption)
                        .foregroundColor(theme.colors.textSecondary)
                    
                    Text("\(thisWeekSessions)/\(weeklyTarget)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.textPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .center, spacing: 4) {
                    Text(TrainingKeys.ConsistencyAnalytics.average.localized)
                        .font(.caption)
                        .foregroundColor(theme.colors.textSecondary)
                    
                    Text("\(String(format: "%.1f", averageWeeklySessions))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.accent)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(TrainingKeys.ConsistencyAnalytics.best.localized)
                        .font(.caption)
                        .foregroundColor(theme.colors.textSecondary)
                    
                    Text("\(bestWeekSessions)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.success)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var currentMetricProgress: Double {
        switch selectedMetric {
        case .frequency:
            return Double(thisWeekSessions) / Double(max(weeklyTarget, 1))
        case .streak:
            return min(1.0, Double(currentStreakDays) / 21.0) // 21 days = excellent streak
        case .goals:
            return weeklyGoalProgress
        }
    }
    
    private var currentMetricValue: String {
        switch selectedMetric {
        case .frequency:
            return "\(thisWeekSessions)"
        case .streak:
            return "\(currentStreakDays)"
        case .goals:
            return "\(Int(weeklyGoalProgress * 100))%"
        }
    }
    
    private var currentMetricLabel: String {
        switch selectedMetric {
        case .frequency:
            return TrainingKeys.ConsistencyAnalytics.thisWeekSessions.localized
        case .streak:
            return TrainingKeys.ConsistencyAnalytics.dailyStreak.localized
        case .goals:
            return TrainingKeys.ConsistencyAnalytics.weeklyGoal.localized
        }
    }
    
    private var thisWeekSessions: Int {
        weeklyData.last?.sessionsCompleted ?? 0
    }
    
    private var weeklyTarget: Int {
        weeklyData.last?.sessionTarget ?? 4 // Default 4 sessions per week
    }
    
    private var currentStreakDays: Int {
        user.currentWorkoutStreak
    }
    
    private var weeklyGoalProgress: Double {
        weeklyData.last?.completionPercentage ?? 0.0
    }
    
    private var perfectWeeksCount: Int {
        weeklyData.filter { $0.isFullWeek }.count
    }
    
    private var averageWeeklySessions: Double {
        guard !weeklyData.isEmpty else { return 0.0 }
        let total = weeklyData.map { $0.sessionsCompleted }.reduce(0, +)
        return Double(total) / Double(weeklyData.count)
    }
    
    private var bestWeekSessions: Int {
        weeklyData.map { $0.sessionsCompleted }.max() ?? 0
    }
    
    private var consistencyColor: Color {
        let streakDays = currentStreakDays
        if streakDays >= 21 { return theme.colors.success }
        else if streakDays >= 14 { return theme.colors.warning }
        else if streakDays >= 7 { return .orange }
        else { return theme.colors.error }
    }
    
    private func weekConsistencyColor(_ week: WeeklyConsistency) -> Color {
        let percentage = week.completionPercentage
        if percentage >= 1.0 { return theme.colors.success }
        else if percentage >= 0.75 { return theme.colors.warning }
        else if percentage >= 0.5 { return .orange }
        else if percentage > 0.0 { return theme.colors.error }
        else { return theme.colors.border.opacity(0.3) }
    }
    
    // MARK: - Data Loading
    
    private func loadConsistencyData() {
        isLoading = true
        
        let calendar = Calendar.current
        let today = Date()
        var weeks: [WeeklyConsistency] = []
        
        // Generate last 12 weeks of data
        for weekOffset in 0..<12 {
            let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: today) ?? today
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
            
            let sessionsInWeek = getSessionsInDateRange(start: weekStart, end: weekEnd)
            let target = calculateWeeklyTarget(for: weekStart)
            let streakForWeek = calculateStreakForWeek(weekStart: weekStart)
            
            weeks.append(WeeklyConsistency(
                weekStart: weekStart,
                sessionsCompleted: sessionsInWeek,
                sessionTarget: target,
                streakDays: streakForWeek,
                goalCompletionRate: min(1.0, Double(sessionsInWeek) / Double(target))
            ))
        }
        
        weeklyData = weeks.reversed() // Oldest to newest
        isLoading = false
    }
    
    private func getSessionsInDateRange(start: Date, end: Date) -> Int {
        // Count both lift and cardio sessions
        let liftCount = getLiftSessionCount(start: start, end: end)
        let cardioCount = getCardioSessionCount(start: start, end: end)
        return liftCount + cardioCount
    }
    
    private func getLiftSessionCount(start: Date, end: Date) -> Int {
        let descriptor = FetchDescriptor<LiftSession>(
            predicate: #Predicate { session in
                session.startDate >= start && session.startDate <= end && session.isCompleted
            }
        )
        
        return (try? modelContext.fetch(descriptor).count) ?? 0
    }
    
    private func getCardioSessionCount(start: Date, end: Date) -> Int {
        let descriptor = FetchDescriptor<CardioSession>(
            predicate: #Predicate { session in
                session.startDate >= start && session.startDate <= end && session.isCompleted
            }
        )
        
        return (try? modelContext.fetch(descriptor).count) ?? 0
    }
    
    private func calculateWeeklyTarget(for weekStart: Date) -> Int {
        // Base target from user preferences or default
        let baseTarget = user.weeklySessionGoal > 0 ? user.weeklySessionGoal : 4
        
        // Adjust based on user's experience level
        let experienceMultiplier: Double
        if user.totalWorkouts + user.totalCardioSessions > 100 {
            experienceMultiplier = 1.2 // Experienced athletes: higher targets
        } else if user.totalWorkouts + user.totalCardioSessions > 50 {
            experienceMultiplier = 1.1 // Intermediate
        } else {
            experienceMultiplier = 1.0 // Beginner: standard targets
        }
        
        return Int(Double(baseTarget) * experienceMultiplier)
    }
    
    private func calculateStreakForWeek(weekStart: Date) -> Int {
        // Mock streak calculation - in real implementation would check daily consistency
        let weekNumber = Calendar.current.component(.weekOfYear, from: weekStart)
        return max(0, currentStreakDays - (weekNumber % 7))
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: LiftSession.self, CardioSession.self, User.self, configurations: config)
    
    TrainingConsistencyRing(user: User(name: "Test Athlete"))
        .modelContainer(container)
        .padding()
}