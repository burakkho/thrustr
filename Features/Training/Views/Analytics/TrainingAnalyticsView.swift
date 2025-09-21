import SwiftUI
import SwiftData
import Charts

struct TrainingAnalyticsView: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(TrainingCoordinator.self) private var coordinator
    @Environment(UnitSettings.self) private var unitSettings
    @Query private var users: [User]
    
    @State private var analyticsService: AnalyticsService?
    @State private var showingGoalSettings = false
    @State private var exerciseProgressions: [(name: String, currentMax: Double, trend: TrendDirection, improvement: Double)] = []
    @State private var workoutFrequency: (thisWeek: Int, lastWeek: Int, trend: TrendDirection) = (0, 0, .stable)
    @State private var progressInsights: [String] = []
    
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
                
                // Additional Analytics - Enhanced with TrainingAnalyticsService
                VStack(spacing: theme.spacing.m) {
                    // Exercise Progressions from TrainingAnalyticsService
                    exerciseProgressionsSection

                    // Workout Frequency Analysis
                    workoutFrequencySection

                    // Progress Insights
                    progressInsightsSection

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
            if analyticsService == nil {
                analyticsService = AnalyticsService(modelContext: modelContext)
            }
            if let user = currentUser, let service = analyticsService {
                service.updateUserAnalytics(for: user)
                loadTrainingAnalytics(for: user)
            }
        }
    }
    
    // MARK: - Summary Cards Section
    private func summaryCardsSection(for user: User) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            if let service = analyticsService {
                let weeklySummary = service.getWeeklySummary(for: user)
            
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
            } else {
                ProgressView()
                    .frame(height: 200)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Weekly Chart Section  
    private var weeklyChartSection: some View {
        VStack {
            if let service = analyticsService {
                let activityData = service.getDailyActivityData()
            
                if activityData.allSatisfy({ $0.totalSessions == 0 }) {
                    EmptyActivityChart()
                } else {
                    WeeklyActivityChart(activityData: activityData)
                }
            } else {
                ProgressView()
                    .frame(height: 150)
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

            if let service = analyticsService {
                let goalProgress = service.getMonthlyGoalProgress(for: user)
            
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
            } else {
                ProgressView()
                    .frame(height: 100)
                    .padding(.horizontal)
            }
        }
    }

    // MARK: - TrainingAnalyticsService Sections

    private var exerciseProgressionsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            HStack {
                Text("Exercise Progressions")
                    .font(theme.typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)

                Spacer()

                Text("Top 3")
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }
            .padding(.horizontal)

            if exerciseProgressions.isEmpty {
                Text("Start logging workouts to see progressions")
                    .font(theme.typography.body)
                    .foregroundColor(theme.colors.textSecondary)
                    .padding(.horizontal)
            } else {
                VStack(spacing: theme.spacing.s) {
                    ForEach(exerciseProgressions, id: \.name) { progression in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(progression.name)
                                    .font(theme.typography.subheadline)
                                    .fontWeight(.medium)

                                Text(TrainingAnalyticsService.formatWeight(progression.currentMax, unitSystem: unitSettings.unitSystem))
                                    .font(theme.typography.caption)
                                    .foregroundColor(theme.colors.textSecondary)
                            }

                            Spacer()

                            HStack(spacing: 4) {
                                Image(systemName: progression.trend.icon)
                                    .foregroundColor(progression.trend.color)

                                Text(TrainingAnalyticsService.formatWeightDifference(progression.improvement, trend: progression.trend, unitSystem: unitSettings.unitSystem))
                                    .font(theme.typography.caption)
                                    .foregroundColor(progression.trend.color)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, theme.spacing.xs)
                        .background(theme.colors.surfaceSecondary)
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var workoutFrequencySection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            HStack {
                Text("Workout Frequency")
                    .font(theme.typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: workoutFrequency.trend.icon)
                        .foregroundColor(workoutFrequency.trend.color)

                    Text(workoutFrequency.trend.displayName)
                        .font(theme.typography.caption)
                        .foregroundColor(workoutFrequency.trend.color)
                }
            }
            .padding(.horizontal)

            HStack {
                VStack {
                    Text("\(workoutFrequency.thisWeek)")
                        .font(theme.typography.title)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.textPrimary)

                    Text("This Week")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                }
                .frame(maxWidth: .infinity)

                VStack {
                    Text("\(workoutFrequency.lastWeek)")
                        .font(theme.typography.title)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.textSecondary)

                    Text("Last Week")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
            .background(theme.colors.surfaceSecondary)
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }

    private var progressInsightsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            HStack {
                Text("Progress Insights")
                    .font(theme.typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)

                Spacer()

                Image(systemName: "lightbulb.fill")
                    .foregroundColor(theme.colors.warning)
            }
            .padding(.horizontal)

            if progressInsights.isEmpty {
                Text("Complete more workouts to generate insights")
                    .font(theme.typography.body)
                    .foregroundColor(theme.colors.textSecondary)
                    .padding(.horizontal)
            } else {
                VStack(alignment: .leading, spacing: theme.spacing.s) {
                    ForEach(progressInsights, id: \.self) { insight in
                        HStack(alignment: .top, spacing: theme.spacing.s) {
                            Image(systemName: "star.fill")
                                .foregroundColor(theme.colors.accent)
                                .font(.caption)
                                .padding(.top, 2)

                            Text(insight)
                                .font(theme.typography.body)
                                .foregroundColor(theme.colors.textPrimary)

                            Spacer()
                        }
                        .padding()
                        .background(theme.colors.surfaceSecondary)
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - TrainingAnalyticsService Integration

    private func loadTrainingAnalytics(for user: User) {
        Task {
            // Get lift results for TrainingAnalyticsService
            let liftResults = user.completedLiftSessions?.flatMap { session in
                session.exerciseResults?.compactMap { exerciseResult in
                    // Convert to the format expected by TrainingAnalyticsService
                    LiftExerciseResult.fromModel(exerciseResult)
                } ?? []
            } ?? []

            // Get cardio results
            let cardioResults = user.completedCardioSessions?.compactMap { session in
                CardioResult.fromModel(session)
            } ?? []

            await MainActor.run {
                // Calculate exercise progressions using TrainingAnalyticsService
                exerciseProgressions = TrainingAnalyticsService.calculateExerciseMaxes(from: liftResults)

                // Calculate workout frequency
                workoutFrequency = TrainingAnalyticsService.calculateWorkoutFrequency(
                    liftResults: liftResults,
                    cardioResults: cardioResults
                )

                // Generate progress insights
                progressInsights = TrainingAnalyticsService.generateProgressInsights(liftResults: liftResults)
            }
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