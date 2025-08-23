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
    
    private var thisWeekStats: WeeklyStats {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        
        let thisWeekSessions = recentSessions.filter { session in
            let sessionDate = session.completedAt ?? session.startDate
            return sessionDate >= startOfWeek
        }
        
        let totalWorkouts = thisWeekSessions.count
        let totalTime = thisWeekSessions.reduce(0) { total, session in
            total + (session.duration ?? 0)
        }
        
        return WeeklyStats(
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
                
                // Last Workout Motivation Card
                if let lastWorkout = recentSessions.first {
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
                Text(LocalizationKeys.Training.Dashboard.title.localized)
                    .font(theme.typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textPrimary)
                
                if let user = currentUser {
                    Text("Welcome back, \(user.name)!")
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
                    Text(LocalizationKeys.Training.Dashboard.lastWorkout.localized)
                        .font(theme.typography.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(session.workoutName)
                        .font(theme.typography.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Celebration emoji
                Text("💪")
                    .font(.largeTitle)
            }
            
            // Stats
            HStack(spacing: theme.spacing.l) {
                if let duration = session.duration {
                    StatPill(
                        icon: "clock",
                        value: formatDuration(duration),
                        label: "Duration"
                    )
                }
                
                StatPill(
                    icon: "calendar",
                    value: formatRelativeDate(session.completedAt ?? session.startDate),
                    label: "When"
                )
                
                Spacer()
            }
            
            // Motivational message
            Text("Great job! Keep up the momentum! 🔥")
                .font(theme.typography.body)
                .foregroundColor(.white.opacity(0.9))
                .italic()
        }
        .padding(theme.spacing.l)
        .background(
            LinearGradient(
                colors: [theme.colors.success, theme.colors.success.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(theme.radius.l)
        .shadow(color: theme.colors.success.opacity(0.3), radius: 8, y: 4)
        .padding(.horizontal)
    }
    
    // MARK: - This Week Stats
    private var thisWeekStatsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            HStack {
                Text(LocalizationKeys.Training.Dashboard.thisWeek.localized)
                    .font(theme.typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                Spacer()
            }
            
            HStack(spacing: theme.spacing.m) {
                QuickStatCard(
                    title: "\(thisWeekStats.workouts)",
                    subtitle: "Workouts",
                    icon: "dumbbell.fill",
                    color: theme.colors.accent
                )
                
                QuickStatCard(
                    title: formatDuration(thisWeekStats.totalTime),
                    subtitle: "Total Time",
                    icon: "clock.fill",
                    color: theme.colors.accent
                )
                
                QuickStatCard(
                    title: "\(thisWeekStats.streak)",
                    subtitle: "Day Streak",
                    icon: "flame.fill",
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
                Text(LocalizationKeys.Training.Dashboard.quickActions.localized)
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
                    title: "Quick Lift",
                    subtitle: "Start strength training",
                    icon: "dumbbell.fill",
                    color: .strengthColor,
                    action: {
                        coordinator.selectWorkoutType(.lift)
                    }
                )
                
                QuickActionCard(
                    title: "Quick Cardio",
                    subtitle: "Start cardio session",
                    icon: "heart.fill",
                    color: .cardioColor,
                    action: {
                        coordinator.selectWorkoutType(.cardio)
                    }
                )
                
                QuickActionCard(
                    title: "Daily WOD",
                    subtitle: "Today's workout",
                    icon: "flame.fill",
                    color: .wodColor,
                    action: {
                        coordinator.selectWorkoutType(.wod)
                    }
                )
                
                QuickActionCard(
                    title: "Browse Programs",
                    subtitle: "Find a program",
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
                Text(LocalizationKeys.Training.Dashboard.recentActivity.localized)
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
                icon: "figure.strengthtraining.traditional",
                title: LocalizationKeys.Training.Dashboard.noRecentActivity.localized,
                description: "Start your first workout to see your progress here!",
                actionTitle: "Start Workout",
                action: {
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
}

// MARK: - Supporting Models & Views

struct WeeklyStats {
    let workouts: Int
    let totalTime: TimeInterval
    let streak: Int
}

protocol WorkoutSession {
    var workoutName: String { get }
    var startDate: Date { get }
    var completedAt: Date? { get }
    var duration: TimeInterval? { get }
    var isCompleted: Bool { get }
}

extension LiftSession: WorkoutSession {
    var workoutName: String {
        workout?.name ?? "Lift Session"
    }
    
    var duration: TimeInterval? {
        guard let completed = completedAt else { return nil }
        return completed.timeIntervalSince(startDate)
    }
}

extension CardioSession: WorkoutSession {
    var workoutName: String {
        exercises.first?.exerciseType.capitalized ?? "Cardio Session"
    }
    
    var completedAt: Date? {
        isCompleted ? Date() : nil // CardioSession might need this property
    }
    
    var duration: TimeInterval? {
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
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
            
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(theme.typography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, theme.spacing.s)
        .padding(.vertical, theme.spacing.xs)
        .background(.white.opacity(0.2))
        .cornerRadius(theme.radius.s)
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
            
            if let duration = session.duration {
                Text(formatDuration(duration))
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }
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