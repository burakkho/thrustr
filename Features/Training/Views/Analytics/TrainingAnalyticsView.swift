import SwiftUI
import SwiftData
import Charts

struct TrainingAnalyticsView: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(TrainingCoordinator.self) private var coordinator
    @EnvironmentObject private var unitSettings: UnitSettings
    @Query private var users: [User]
    
    @StateObject private var analyticsService: AnalyticsService
    @State private var showingGoalSettings = false
    
    // Initialize AnalyticsService with modelContext
    init(modelContext: ModelContext) {
        self._analyticsService = StateObject(wrappedValue: AnalyticsService(modelContext: modelContext))
    }
    
    private var currentUser: User? {
        users.first
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: theme.spacing.xl) {
                // Header Section
                headerSection
                
                if let user = currentUser {
                    // Summary Cards Section
                    summaryCardsSection(for: user)
                    
                    // Weekly Activity Chart Section
                    weeklyChartSection
                    
                    // Monthly Goals Section
                    monthlyGoalsSection(for: user)
                    
                    // 1RM Progression Section
                    oneRMProgressionSection(for: user)
                    
                    // Recent PRs Section
                    recentPRsSection(for: user)
                } else {
                    // No user state
                    EmptyStateCard(
                        icon: "person.circle",
                        title: TrainingKeys.Analytics.noUserProfile.localized,
                        message: TrainingKeys.Analytics.setupProfileMessage.localized,
                        primaryAction: .init(
                            title: TrainingKeys.Analytics.setupProfile.localized,
                            action: { /* Navigate to profile */ }
                        )
                    )
                    .padding(.top, 50)
                }
            }
            .padding(.vertical, theme.spacing.m)
        }
        .sheet(isPresented: $showingGoalSettings) {
            if let user = currentUser {
                GoalSettingsView(user: user)
            }
        }
        .onAppear {
            if let user = currentUser {
                analyticsService.updateUserAnalytics(for: user)
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(TrainingKeys.Analytics.title.localized)
                    .font(theme.typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textPrimary)
                
                Text(TrainingKeys.Analytics.subtitle.localized)
                    .font(theme.typography.body)
                    .foregroundColor(theme.colors.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chart.bar.fill")
                .font(.largeTitle)
                .foregroundColor(theme.colors.accent.opacity(0.3))
        }
        .padding(.horizontal)
    }
    
    // MARK: - Summary Cards Section
    private func summaryCardsSection(for user: User) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            let weeklySummary = analyticsService.getWeeklySummary(for: user)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: theme.spacing.m) {
                QuickStatCard(
                    icon: "calendar",
                    title: TrainingKeys.Analytics.thisWeek.localized,
                    value: "\(weeklySummary.totalSessions)",
                    subtitle: TrainingKeys.Analytics.sessions.localized,
                    color: theme.colors.accent
                )
                
                QuickStatCard(
                    icon: "clock",
                    title: TrainingKeys.Analytics.totalTime.localized, 
                    value: formatDuration(weeklySummary.totalDuration),
                    subtitle: TrainingKeys.Analytics.thisWeekLower.localized,
                    color: theme.colors.success
                )
                
                QuickStatCard(
                    icon: "flame.fill",
                    title: TrainingKeys.Analytics.streak.localized,
                    value: "\(weeklySummary.currentStreak)",
                    subtitle: TrainingKeys.Analytics.days.localized,
                    color: theme.colors.warning
                )
                
                QuickStatCard(
                    icon: "trophy.fill",
                    title: TrainingKeys.Analytics.prs.localized,
                    value: "\(user.totalPRsThisMonth)",
                    subtitle: TrainingKeys.Analytics.thisMonth.localized,
                    color: theme.colors.error
                )
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Weekly Chart Section  
    private var weeklyChartSection: some View {
        VStack {
            let activityData = analyticsService.getDailyActivityData()
            
            if activityData.allSatisfy({ $0.totalSessions == 0 }) {
                EmptyActivityChart()
            } else {
                WeeklyActivityChart(activityData: activityData)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Monthly Goals Section
    private func monthlyGoalsSection(for user: User) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            HStack {
                Text(TrainingKeys.Analytics.monthlyGoals.localized)
                    .font(theme.typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                
                Spacer()
                
                Button(TrainingKeys.Analytics.editGoals.localized) {
                    showingGoalSettings = true
                }
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.accent)
            }
            .padding(.horizontal)
            
            let goalProgress = analyticsService.getMonthlyGoalProgress(for: user)
            
            HStack(spacing: theme.spacing.m) {
                GoalProgressCard(
                    title: TrainingKeys.Analytics.sessions.localized,
                    progress: goalProgress.sessionProgress,
                    current: "\(goalProgress.currentSessions)",
                    target: "\(goalProgress.targetSessions)",
                    color: theme.colors.accent,
                    onTap: { showingGoalSettings = true }
                )
                
                GoalProgressCard(
                    title: TrainingKeys.Analytics.distance.localized, 
                    progress: goalProgress.distanceProgress,
                    current: "\(Int(goalProgress.currentDistance / 1000))km",
                    target: "\(Int(goalProgress.targetDistance / 1000))km",
                    color: Color.cardioColor,
                    onTap: { showingGoalSettings = true }
                )
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Recent PRs Section
    private func recentPRsSection(for user: User) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            HStack {
                Text(TrainingKeys.Analytics.recentPRs.localized)
                    .font(theme.typography.headline) 
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                
                Spacer()
                
                Button(TrainingKeys.Analytics.viewAll.localized) {
                    // Navigate to detailed PR view
                }
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.accent)
            }
            .padding(.horizontal)
            
            let recentPRs = analyticsService.getRecentPRs(for: user, limit: 3)
            
            if recentPRs.isEmpty {
                EmptyStateCard(
                    icon: "trophy",
                    title: TrainingKeys.Analytics.noPRsYet.localized,
                    message: TrainingKeys.Analytics.noPRsMessage.localized,
                    primaryAction: .init(
                        title: TrainingKeys.Analytics.startTraining.localized,
                        action: { /* Navigate to training */ }
                    )
                )
                .padding(.horizontal)
            } else {
                LazyVStack(spacing: theme.spacing.s) {
                    ForEach(recentPRs, id: \.exerciseName) { pr in
                        prCard(pr: pr)
                            .padding(.horizontal)
                    }
                }
            }
        }
    }
    
    // MARK: - PR Card
    private func prCard(pr: AnalyticsService.PRRecord) -> some View {
        HStack(spacing: theme.spacing.m) {
            // Trophy icon with color based on recency
            ZStack {
                Circle()
                    .fill(pr.isRecent ? theme.colors.warning.opacity(0.15) : theme.colors.textSecondary.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "trophy.fill")
                    .font(.title3)
                    .foregroundColor(pr.isRecent ? theme.colors.warning : theme.colors.textSecondary)
            }
            
            // Exercise name and value
            VStack(alignment: .leading, spacing: 2) {
                Text(pr.exerciseName)
                    .font(theme.typography.body)
                    .fontWeight(.medium)
                    .foregroundColor(theme.colors.textPrimary)
                
                Text("\(String(format: "%.1f", pr.value)) \(pr.unit)")
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }
            
            Spacer()
            
            // Date
            Text(formatRelativeDate(pr.date))
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textSecondary)
        }
        .padding(theme.spacing.m)
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.m)
        .shadow(color: theme.shadows.card.opacity(0.05), radius: 1)
    }
    
    // MARK: - 1RM Progression Section
    private func oneRMProgressionSection(for user: User) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            HStack {
                Text("1RM Progression")
                    .font(theme.typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                
                Spacer()
                
                Button("Update 1RMs") {
                    // Navigate to strength test or 1RM input
                }
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.accent)
            }
            .padding(.horizontal)
            
            let oneRMs = analyticsService.getLatestOneRMs(for: user)
            
            if oneRMs.allSatisfy({ $0.value == nil }) {
                // Empty state for 1RM data
                EmptyStateCard(
                    icon: "scalemass.fill",
                    title: "No 1RM Data",
                    message: "Take a strength test to track your 1RM progression over time",
                    primaryAction: .init(
                        title: "Take Strength Test",
                        icon: "play.circle",
                        action: { /* Navigate to strength test */ }
                    )
                )
                .padding(.horizontal)
            } else {
                // 1RM Cards Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: theme.spacing.m) {
                    ForEach(oneRMs.filter { $0.value != nil }, id: \.name) { oneRM in
                        oneRMCard(
                            exercise: oneRM.name,
                            value: oneRM.value ?? 0,
                            date: oneRM.date
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func oneRMCard(exercise: String, value: Double, date: Date?) -> some View {
        VStack(spacing: theme.spacing.s) {
            // Exercise icon
            Image(systemName: exerciseIcon(for: exercise))
                .font(.title2)
                .foregroundColor(theme.colors.accent)
            
            // Exercise name
            Text(exercise)
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            // 1RM value
            Text(UnitsFormatter.formatWeight(kg: value, system: unitSettings.unitSystem))
                .font(theme.typography.headline)
                .fontWeight(.bold)
                .foregroundColor(theme.colors.textPrimary)
            
            // Last updated
            if let date = date {
                Text(formatRelativeDate(date))
                    .font(.caption2)
                    .foregroundColor(theme.colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.m)
        .shadow(color: theme.shadows.card.opacity(0.05), radius: 1)
    }
    
    private func exerciseIcon(for exercise: String) -> String {
        switch exercise.lowercased() {
        case let name where name.contains("squat"):
            return "figure.squat"
        case let name where name.contains("bench"):
            return "figure.strengthtraining.traditional"
        case let name where name.contains("deadlift"):
            return "figure.strengthtraining.functional"
        case let name where name.contains("overhead") || name.contains("press"):
            return "figure.arms.open"
        default:
            return "dumbbell.fill"
        }
    }
    
    // MARK: - Helper Methods
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: User.self, CardioSession.self, LiftSession.self, configurations: config)
    
    // Create test user
    let user = User(name: "Test User")
    user.currentWorkoutStreak = 5
    user.totalPRsThisMonth = 2
    user.squatOneRM = 100
    user.benchPressOneRM = 80
    container.mainContext.insert(user)
    
    return TrainingAnalyticsView(modelContext: container.mainContext)
        .environment(TrainingCoordinator())
        .modelContainer(container)
}