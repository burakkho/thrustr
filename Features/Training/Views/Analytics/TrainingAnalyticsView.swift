import SwiftUI
import SwiftData
import Charts

struct TrainingAnalyticsView: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(TrainingCoordinator.self) private var coordinator
    @Environment(UnitSettings.self) private var unitSettings
    @Query private var users: [User]
    
    @State private var analyticsService: AnalyticsService
    @State private var showingGoalSettings = false
    
    // Initialize AnalyticsService with default empty service, will be updated in onAppear
    init() {
        // Temporary initialization - will be updated when view appears
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let tempContainer = try! ModelContainer(for: User.self, configurations: config)
        self._analyticsService = StateObject(wrappedValue: AnalyticsService(modelContext: tempContainer.mainContext))
    }
    
    private var currentUser: User? {
        users.first
    }
    
    var body: some View {
        VStack(spacing: theme.spacing.l) {
            if let user = currentUser {
                // Summary Cards Section (Most Important)
                summaryCardsSection(for: user)
                
                // Compact Progress Section
                VStack(spacing: theme.spacing.m) {
                    // Training Consistency Ring - Compact
                    TrainingConsistencyRing(user: user)
                        .padding(.horizontal)
                        .frame(maxHeight: 200) // Limit height
                    
                    // Weekly Activity Chart Section - Compact
                    weeklyChartSection
                        .frame(maxHeight: 150) // Limit chart height
                }
                
                // Additional Analytics - Collapsed by default
                VStack(spacing: theme.spacing.m) {
                    // PR Timeline Card - Compact
                    PRTimelineCard(user: user)
                        .padding(.horizontal)
                        .frame(maxHeight: 120) // Compact PR display
                    
                    // Monthly Goals Section
                    monthlyGoalsSection(for: user)
                }
                
            } else {
                // No user state
                EmptyStateCard(
                    icon: "person.circle",
                    title: TrainingKeys.Analytics.noUserProfile.localized,
                    message: TrainingKeys.Analytics.setupProfileMessage.localized,
                    primaryAction: .init(
                        title: TrainingKeys.Analytics.setupProfile.localized,
                        action: { coordinator.navigateToOneRMSetup() }
                    )
                )
                .padding(.top, 50)
            }
            
            Spacer(minLength: 0) // Allow flexible spacing
        }
        .padding(.vertical, theme.spacing.m)
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
                    current: UnitsFormatter.formatDistance(meters: goalProgress.currentDistance, system: unitSettings.unitSystem),
                    target: UnitsFormatter.formatDistance(meters: goalProgress.targetDistance, system: unitSettings.unitSystem),
                    color: Color.cardioColor,
                    onTap: { showingGoalSettings = true }
                )
            }
            .padding(.horizontal)
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
    
    return TrainingAnalyticsView()
        .environment(TrainingCoordinator())
        .modelContainer(container)
}