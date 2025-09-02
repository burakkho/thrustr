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
    
    private var currentUser: User? {
        user.first
    }
    
    private var recentSessions: [any WorkoutSession] {
        var allSessions: [any WorkoutSession] = []
        
        // Add lift sessions
        allSessions.append(contentsOf: liftSessions.filter { $0.isCompleted })
        
        // Add cardio sessions  
        allSessions.append(contentsOf: cardioSessions.filter { $0.isCompleted })
        
        // Sort by date and take recent 5
        return allSessions
            .sorted { session1, session2 in
                let date1 = session1.completedAt ?? session1.startDate
                let date2 = session2.completedAt ?? session2.startDate
                return date1 > date2
            }
            .prefix(5)
            .map { $0 }
    }
    
    private var thisWeekStats: TrainingWeeklyStats {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        
        let thisWeekSessions = recentSessions.filter { session in
            let sessionDate = session.completedAt ?? session.startDate
            return sessionDate >= startOfWeek
        }
        
        let totalWorkouts = thisWeekSessions.count
        let totalTime = thisWeekSessions.reduce(0) { total, session in
            total + session.sessionDuration
        }
        
        return TrainingWeeklyStats(
            workouts: totalWorkouts,
            totalTime: totalTime,
            streak: calculateStreak()
        )
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: theme.spacing.xl) {
                // Header Section
                headerSection
                
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
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(TrainingKeys.Dashboard.title.localized)
                    .font(theme.typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textPrimary)
                
                if let user = currentUser {
                    Text(String(format: TrainingKeys.Welcome.welcomeBack.localized, user.name))
                        .font(theme.typography.body)
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal)
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
                        coordinator.selectWorkoutType(.lift)
                    }
                )
                
                QuickActionCard(
                    title: TrainingKeys.Welcome.quickCardio.localized,
                    subtitle: TrainingKeys.Welcome.startCardioSession.localized,
                    icon: "heart.fill",
                    color: .cardioColor,
                    action: {
                        coordinator.selectWorkoutType(.cardio)
                    }
                )
                
                QuickActionCard(
                    title: TrainingKeys.Welcome.dailyWOD.localized,
                    subtitle: TrainingKeys.Welcome.todaysWorkout.localized,
                    icon: "flame.fill",
                    color: .wodColor,
                    action: {
                        coordinator.selectWorkoutType(.wod)
                    }
                )
                
                QuickActionCard(
                    title: TrainingKeys.ProgramCompletion.browsePrograms.localized,
                    subtitle: TrainingKeys.Welcome.findProgram.localized,
                    icon: "rectangle.3.group",
                    color: theme.colors.accent,
                    action: {
                        coordinator.selectWorkoutType(.lift)
                        // Navigate to programs tab
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
                    // Navigate to history
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
                message: "Start your first workout to see your progress here!",
                primaryTitle: "Start Workout",
                primaryAction: {
                    coordinator.selectWorkoutType(.lift)
                }
            )
        }
        .padding(.horizontal)
        .padding(.top, theme.spacing.xl)
    }
    
    // MARK: - Helper Methods
    private func calculateStreak() -> Int {
        // Simple streak calculation - consecutive days with workouts
        let calendar = Calendar.current
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        while streak < 30 { // Max 30 days check
            let hasWorkout = recentSessions.contains { session in
                let sessionDate = calendar.startOfDay(for: session.completedAt ?? session.startDate)
                return sessionDate == currentDate
            }
            
            if hasWorkout {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }
        
        return streak
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
}

// MARK: - Supporting Models & Views

struct TrainingWeeklyStats {
    let workouts: Int
    let totalTime: TimeInterval
    let streak: Int
}

protocol WorkoutSession {
    var workoutName: String { get }
    var startDate: Date { get }
    var completedAt: Date? { get }
    var sessionDuration: TimeInterval { get } // Renamed to avoid conflicts
    var isCompleted: Bool { get }
}

extension LiftSession: WorkoutSession {
    var workoutName: String {
        workout.name
    }
    
    var completedAt: Date? {
        endDate // LiftSession uses endDate instead of completedAt
    }
    
    var sessionDuration: TimeInterval {
        self.duration // LiftSession's duration is already TimeInterval
    }
    
    // startDate and isCompleted already exist in LiftSession model
}

extension CardioSession: WorkoutSession {
    // CardioSession already has all required properties:
    // - workoutName: String
    // - startDate: Date  
    // - completedAt: Date?
    // - duration: Int (but we need TimeInterval)
    // - isCompleted: Bool
    
    var sessionDuration: TimeInterval {
        TimeInterval(self.duration)
    }
}

// MARK: - Quick Action Card
struct QuickActionCard: View {
    @Environment(\.theme) private var theme
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: theme.spacing.s) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                    Spacer()
                }
                
                Text(title)
                    .font(theme.typography.body)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                
                Text(subtitle)
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }
            .padding(theme.spacing.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.colors.cardBackground)
            .cornerRadius(theme.radius.m)
            .shadow(color: theme.shadows.card.opacity(0.05), radius: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Stat Pill
struct StatPill: View {
    @Environment(\.theme) private var theme
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        HStack(spacing: theme.spacing.xs) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.8))
            
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, theme.spacing.xs)
        .padding(.vertical, theme.spacing.xxs)
        .background(.white.opacity(0.15))
        .cornerRadius(theme.radius.xs)
    }
}

// MARK: - Recent Activity Row
struct RecentActivityRow: View {
    @Environment(\.theme) private var theme
    let session: any WorkoutSession
    
    var body: some View {
        HStack(spacing: theme.spacing.m) {
            // Workout type icon
            Image(systemName: workoutTypeIcon)
                .font(.body)
                .foregroundColor(workoutTypeColor)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(session.workoutName)
                    .font(theme.typography.body)
                    .fontWeight(.medium)
                    .foregroundColor(theme.colors.textPrimary)
                
                Text(formatRelativeDate(session.completedAt ?? session.startDate))
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }
            
            Spacer()
            
            Text(formatDuration(session.sessionDuration))
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textSecondary)
        }
        .padding(.vertical, theme.spacing.s)
    }
    
    private var workoutTypeIcon: String {
        if session is LiftSession { return "dumbbell.fill" }
        if session is CardioSession { return "heart.fill" }
        return "figure.strengthtraining.traditional"
    }
    
    private var workoutTypeColor: Color {
        if session is LiftSession { return .strengthColor }
        if session is CardioSession { return .cardioColor }
        return .gray
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        return "\(minutes)m"
    }
    
    private func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

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