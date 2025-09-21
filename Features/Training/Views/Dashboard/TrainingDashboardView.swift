import SwiftUI
import SwiftData

struct TrainingDashboardView: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(TrainingCoordinator.self) private var coordinator
    
    @Query private var liftSessions: [LiftSession]
    @Query private var cardioSessions: [CardioSession]
    @Query private var wodResults: [WODResult]
    @Query private var user: [User]
    
    @State private var sessionsCache = RecentSessionsCache()
    
    // Quick action sheet states
    @State private var showingQuickCardio = false
    @State private var showingQuickWOD = false
    @State private var showingPrograms = false
    @State private var selectedQuickWorkout: LiftWorkout?
    
    private var currentUser: User? {
        user.first
    }
    
    private var recentSessions: [any WorkoutSession] {
        // Try to get cached sessions first
        if let cached = sessionsCache.getCachedSessions() {
            return cached
        }

        // Use service for fresh sessions computation
        let freshSessions = TrainingDashboardService.computeRecentSessions(
            liftSessions: liftSessions,
            cardioSessions: cardioSessions,
            wodResults: wodResults
        )

        // Cache the result
        sessionsCache.updateCache(freshSessions)
        return freshSessions
    }
    
    private var thisWeekStats: TrainingWeeklyStats {
        return TrainingDashboardService.calculateWeeklyStats(from: recentSessions)
    }
    
    var body: some View {
        // Show only overview content - no pills navigation needed
        overviewContent
        .onAppear {
            updateCacheIfNeeded()
        }
        .onChange(of: liftSessions.count) { _, _ in
            Task { @MainActor in
                invalidateCacheAndUpdate()
            }
        }
        .onChange(of: cardioSessions.count) { _, _ in
            Task { @MainActor in
                invalidateCacheAndUpdate()
            }
        }
        .sheet(isPresented: $showingQuickCardio) {
            CardioQuickStartView()
        }
        .sheet(isPresented: $showingQuickWOD) {
            WODBuilderView()
        }
        .sheet(isPresented: $showingPrograms) {
            LiftProgramsSection()
                .environment(coordinator)
        }
        .sheet(item: $selectedQuickWorkout) { workout in
            LiftSessionView(workout: workout, programExecution: nil)
        }
    }
    
    
    // MARK: - Overview Content
    private var overviewContent: some View {
        ScrollView {
            VStack(spacing: theme.spacing.xl) {
                // Last Workout Card
                if let lastWorkout = recentSessions.first {
                    // Last Workout Motivation Card (fallback)
                    lastWorkoutCard(lastWorkout)
                }
                
                // This Week Stats
                thisWeekStatsSection
                
                // Quick Actions
                quickActionsSection
                
                // Recent Activity
                if !recentSessions.isEmpty {
                    recentActivitySection
                } else {
                    emptyStateSection
                }
            }
            .padding(.vertical, theme.spacing.m)
        }
    }
    
    
    // MARK: - Last Workout Card
    private func lastWorkoutCard(_ session: any WorkoutSession) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(TrainingKeys.Dashboard.lastWorkout.localized)
                        .font(theme.typography.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(session.workoutName)
                        .font(theme.typography.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Workout type icon
                Image(systemName: workoutTypeIcon(for: session))
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.9))
            }
            
            // Stats
            HStack(spacing: theme.spacing.s) {
                StatPill(
                    icon: "clock",
                    value: formatDuration(session.sessionDuration),
                    label: TrainingKeys.Dashboard.duration.localized
                )
                
                StatPill(
                    icon: "calendar",
                    value: formatRelativeDate(session.completedAt ?? session.startDate),
                    label: TrainingKeys.Dashboard.when.localized
                )
                
                Spacer()
            }
            
            // Motivational message
            Text(TrainingKeys.Dashboard.motivationalMessage.localized)
                .font(theme.typography.body)
                .foregroundColor(.white.opacity(0.9))
                .italic()
        }
        .padding(theme.spacing.m)
        .background(
            LinearGradient(
                colors: [theme.colors.success.opacity(0.8), theme.colors.success.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(theme.radius.m)
        .shadow(color: theme.colors.success.opacity(0.15), radius: 4, y: 2)
        .padding(.horizontal)
    }
    
    
    // MARK: - This Week Stats
    private var thisWeekStatsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            HStack {
                Text(TrainingKeys.Dashboard.thisWeek.localized)
                    .font(theme.typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                Spacer()
            }
            
            HStack(spacing: theme.spacing.m) {
                QuickStatCard(
                    icon: "dumbbell.fill",
                    title: TrainingKeys.Dashboard.workouts.localized,
                    value: "\(thisWeekStats.workouts)",
                    subtitle: TrainingKeys.Dashboard.thisWeek.localized,
                    color: theme.colors.accent
                )
                
                QuickStatCard(
                    icon: "clock.fill",
                    title: TrainingKeys.Dashboard.totalTime.localized,
                    value: formatDuration(thisWeekStats.totalTime),
                    subtitle: TrainingKeys.Dashboard.thisWeek.localized,
                    color: theme.colors.accent
                )
                
                QuickStatCard(
                    icon: "flame.fill",
                    title: TrainingKeys.Dashboard.streak.localized,
                    value: "\(thisWeekStats.streak)",
                    subtitle: TrainingKeys.Analytics.days.localized,
                    color: theme.colors.warning
                )
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            HStack {
                Text(TrainingKeys.Dashboard.quickActions.localized)
                    .font(theme.typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: theme.spacing.m) {
                QuickActionCard(
                    title: TrainingKeys.Welcome.quickLift.localized,
                    subtitle: TrainingKeys.Welcome.startStrengthTraining.localized,
                    icon: "dumbbell.fill",
                    color: .strengthColor,
                    action: {
                        createQuickLiftWorkout()
                    }
                )
                
                QuickActionCard(
                    title: TrainingKeys.Welcome.quickCardio.localized,
                    subtitle: TrainingKeys.Welcome.startCardioSession.localized,
                    icon: "heart.fill",
                    color: .cardioColor,
                    action: {
                        showingQuickCardio = true
                    }
                )
                
                QuickActionCard(
                    title: TrainingKeys.Welcome.createWOD.localized,
                    subtitle: TrainingKeys.Welcome.createWODSubtitle.localized,
                    icon: "flame.fill",
                    color: .wodColor,
                    action: {
                        showingQuickWOD = true
                    }
                )
                
                QuickActionCard(
                    title: TrainingKeys.ProgramCompletion.browsePrograms.localized,
                    subtitle: TrainingKeys.Welcome.findProgram.localized,
                    icon: "rectangle.3.group",
                    color: theme.colors.accent,
                    action: {
                        showingPrograms = true
                    }
                )
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Recent Activity Section
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            HStack {
                Text(TrainingKeys.Dashboard.recentActivity.localized)
                    .font(theme.typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                Spacer()
                
                Button("See All") {
                    coordinator.navigateToHistory()
                }
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.accent)
            }
            
            VStack(spacing: theme.spacing.s) {
                ForEach(Array(recentSessions.prefix(3).enumerated()), id: \.offset) { index, session in
                    RecentActivityRow(session: session)
                }
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Empty State
    private var emptyStateSection: some View {
        VStack(spacing: theme.spacing.l) {
            EmptyStateView(
                systemImage: "figure.strengthtraining.traditional",
                title: TrainingKeys.Dashboard.noRecentActivity.localized,
                message: TrainingKeys.EmptyStatesNew.firstWorkoutMessage.localized,
                primaryTitle: TrainingKeys.EmptyStatesNew.startWorkout.localized,
                primaryAction: {
                    coordinator.selectWorkoutType(.lift)
                }
            )
        }
        .padding(.horizontal)
        .padding(.top, theme.spacing.xl)
    }
    
    // MARK: - Cache Management
    @MainActor
    private func updateCacheIfNeeded() {
        if !sessionsCache.isValid {
            let freshSessions = TrainingDashboardService.computeRecentSessions(
                liftSessions: liftSessions,
                cardioSessions: cardioSessions,
                wodResults: wodResults
            )
            sessionsCache.updateCache(freshSessions)
        }
    }

    @MainActor
    private func invalidateCacheAndUpdate() {
        sessionsCache.invalidateCache()
        let freshSessions = TrainingDashboardService.computeRecentSessions(
            liftSessions: liftSessions,
            cardioSessions: cardioSessions,
            wodResults: wodResults
        )
        sessionsCache.updateCache(freshSessions)
    }
    
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
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func workoutTypeIcon(for session: any WorkoutSession) -> String {
        if session is LiftSession { return "dumbbell.fill" }
        if session is CardioSession { return "heart.fill" }
        return "flame.fill"
    }
    
    // MARK: - Quick Action Functions
    
    private func createQuickLiftWorkout() {
        let quickWorkout = LiftWorkout(
            name: "Quick Lift",
            isTemplate: false,
            isCustom: true
        )
        modelContext.insert(quickWorkout)
        
        do {
            try modelContext.save()
            selectedQuickWorkout = quickWorkout
        } catch {
            print("Failed to create quick lift workout: \(error)")
        }
    }
}

// MARK: - Supporting Models & Views






#Preview {
    TrainingDashboardView()
        .environment(TrainingCoordinator())
        .modelContainer(for: [
            User.self,
            LiftSession.self,
            CardioSession.self,
            WODResult.self
        ], inMemory: true)
}