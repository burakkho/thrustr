import SwiftUI
import SwiftData

struct CardioMainView: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(TrainingCoordinator.self) private var coordinator
    @EnvironmentObject private var unitSettings: UnitSettings
    
    @Query private var cardioWorkouts: [CardioWorkout]
    @Query private var cardioSessions: [CardioSession]
    @Query private var user: [User]
    
    @State private var selectedTab = 0
    @State private var selectedWorkout: CardioWorkout?
    @State private var showingQuickStart = false
    
    private var currentUser: User? {
        user.first
    }
    
    private let tabs = [
        TrainingTab(title: TrainingKeys.Cardio.train.localized, icon: "heart.fill"),
        TrainingTab(title: TrainingKeys.Cardio.history.localized, icon: "clock.arrow.circlepath")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Tab Selector
            TrainingTabSelector(
                selection: $selectedTab,
                tabs: tabs
            )
            
            // Content
            Group {
                switch selectedTab {
                case 0:
                    CardioTrainSection(
                        selectedWorkout: $selectedWorkout,
                        showingQuickStart: $showingQuickStart,
                        currentUser: currentUser,
                        onNavigateToHistory: { selectedTab = 1 }
                    )
                case 1:
                    CardioHistorySection(
                        sessions: cardioSessions,
                        currentUser: currentUser
                    )
                default:
                    EmptyView()
                }
            }
        }
        .sheet(item: $selectedWorkout) { workout in
            CardioWorkoutDetail(workout: workout)
        }
        .sheet(isPresented: $showingQuickStart) {
            CardioQuickStartView()
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(TrainingKeys.Cardio.title.localized)
                    .font(theme.typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textPrimary)
                
                if coordinator.hasActiveSession && coordinator.activeSessionType == .cardio {
                    Label(TrainingKeys.Cardio.sessionInProgress.localized, systemImage: "circle.fill")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.success)
                }
            }
            
            Spacer()
            
            // Quick Actions Menu
            Menu {
                Button(action: { showingQuickStart = true }) {
                    Label(TrainingKeys.Cardio.quickStart.localized, systemImage: "play.circle")
                }
                
                Button(action: { selectedTab = 1 }) {
                    Label(TrainingKeys.Cardio.viewHistory.localized, systemImage: "clock.arrow.circlepath")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title2)
                    .foregroundColor(theme.colors.accent)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, theme.spacing.m)
    }
}

// MARK: - Cardio Train Section
struct CardioTrainSection: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var unitSettings: UnitSettings
    
    @Query private var cardioSessions: [CardioSession]
    
    @Binding var selectedWorkout: CardioWorkout?
    @Binding var showingQuickStart: Bool
    let currentUser: User?
    let onNavigateToHistory: () -> Void
    
    private var recentSessions: [CardioSession] {
        cardioSessions
            .filter { $0.isCompleted }
            .sorted { $0.startDate > $1.startDate }
            .prefix(3)
            .map { $0 }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: theme.spacing.xl) {
                // Weekly Analytics
                CardioAnalyticsCard(sessions: cardioSessions, currentUser: currentUser)
                
                // Quick Start Section
                quickStartSection
                
                // Recent Sessions
                if !recentSessions.isEmpty {
                    recentSessionsSection
                }
            }
            .padding(.vertical, theme.spacing.m)
        }
    }
    
    
    
    // MARK: - Quick Start Section
    private var quickStartSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            Text(TrainingKeys.Cardio.quickStart.localized)
                .font(theme.typography.headline)
                .foregroundColor(theme.colors.textPrimary)
                .padding(.horizontal)
            
            HStack(spacing: theme.spacing.m) {
                quickActionCard(
                    icon: "plus.circle.fill",
                    title: TrainingKeys.Cardio.quickStart.localized,
                    subtitle: TrainingKeys.Cardio.quickStartDesc.localized,
                    color: theme.colors.accent,
                    action: { showingQuickStart = true }
                )
                
                quickActionCard(
                    icon: "clock.arrow.circlepath",
                    title: TrainingKeys.Cardio.viewHistory.localized,
                    subtitle: TrainingKeys.Cardio.viewHistoryDesc.localized,
                    color: theme.colors.success,
                    action: { onNavigateToHistory() }
                )
            }
            .padding(.horizontal)
        }
    }
    
    private func quickActionCard(
        icon: String,
        title: String,
        subtitle: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: theme.spacing.s) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(theme.typography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, theme.spacing.m)
            .background(theme.colors.cardBackground)
            .cornerRadius(theme.radius.m)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Recent Sessions Section
    private var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            HStack {
                Text(TrainingKeys.Cardio.recentSessions.localized)
                    .font(theme.typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                Spacer()
                Button(TrainingKeys.Lift.seeAll.localized) {
                    onNavigateToHistory()
                }
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.accent)
            }
            .padding(.horizontal)
            
            LazyVStack(spacing: theme.spacing.s) {
                ForEach(recentSessions, id: \.id) { session in
                    recentSessionCard(session: session)
                        .padding(.horizontal)
                }
            }
        }
    }
    
    private func recentSessionCard(session: CardioSession) -> some View {
        UnifiedWorkoutCard(
            title: session.workoutName,
            subtitle: formatDuration(TimeInterval(session.duration)),
            description: formatRelativeDate(session.startDate),
            primaryStats: buildSessionStats(for: session),
            secondaryInfo: [],
            cardStyle: .compact,
            primaryAction: { /* View session detail */ }
        )
    }
    
    private func buildSessionStats(for session: CardioSession) -> [WorkoutStat] {
        var stats: [WorkoutStat] = []
        
        if session.totalDistance > 0 {
            stats.append(WorkoutStat(
                label: TrainingKeys.Cardio.distance.localized,
                value: UnitsFormatter.formatDistance(meters: session.totalDistance, system: unitSettings.unitSystem),
                icon: "ruler"
            ))
        }
        
        if let averageSpeed = session.averageSpeed, averageSpeed > 0 {
            stats.append(WorkoutStat(
                label: TrainingKeys.Cardio.avgSpeed.localized,
                value: UnitsFormatter.formatSpeed(kmh: averageSpeed, system: unitSettings.unitSystem),
                icon: "speedometer"
            ))
        }
        
        return stats
    }
    
    
    // MARK: - Helper Methods
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
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

// MARK: - Cardio History Section
struct CardioHistorySection: View {
    @Environment(\.theme) private var theme
    @EnvironmentObject private var unitSettings: UnitSettings
    let sessions: [CardioSession]
    let currentUser: User?
    
    @State private var selectedSession: CardioSession?
    
    private var completedSessions: [CardioSession] {
        sessions
            .filter { $0.isCompleted }
            .sorted { $0.completedAt ?? $0.startDate > $1.completedAt ?? $1.startDate }
    }
    
    var body: some View {
        ScrollView {
            if completedSessions.isEmpty {
                EmptyStateCard(
                    icon: "clock.arrow.circlepath",
                    title: TrainingKeys.Cardio.noHistory.localized,
                    message: TrainingKeys.Cardio.noHistoryMessage.localized,
                    primaryAction: .init(
                        title: TrainingKeys.Cardio.browseTemplates.localized,
                        action: { /* Navigate to templates */ }
                    )
                )
                .padding(.top, 100)
            } else {
                LazyVStack(spacing: theme.spacing.m) {
                    ForEach(completedSessions, id: \.id) { session in
                        let sessionMetrics = buildSessionMetrics(for: session, theme: theme)
                        let sessionAchievements = buildAchievements(for: session, unitSystem: unitSettings.unitSystem)
                        
                        SessionHistoryCard(
                            workoutName: session.workoutName,
                            date: session.completedAt ?? session.startDate,
                            duration: TimeInterval(session.totalDuration),
                            primaryMetric: SessionMetric(
                                label: TrainingKeys.Cardio.distance.localized,
                                value: session.formattedDistance
                            ),
                            secondaryMetrics: sessionMetrics,
                            achievements: sessionAchievements,
                            feeling: session.feeling != nil ? 
                                WorkoutFeeling(
                                    emoji: session.feelingEmoji,
                                    description: session.feeling!.capitalized,
                                    note: nil
                                ) : nil,
                            onTap: { selectedSession = session }
                        )
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, theme.spacing.m)
            }
        }
        .sheet(item: $selectedSession) { session in
            CardioSessionDetailView(session: session)
        }
    }
    
    private func buildSessionMetrics(for session: CardioSession, theme: Theme) -> [SessionMetric] {
        var metrics: [SessionMetric] = []
        
        if let pace = session.formattedAveragePace {
            metrics.append(SessionMetric(label: TrainingKeys.Cardio.pace.localized, value: pace))
        }
        
        if let calories = session.totalCaloriesBurned, calories > 0 {
            metrics.append(SessionMetric(label: TrainingKeys.Cardio.calories.localized, value: "\(calories)"))
        }
        
        return metrics
    }
    
    private func buildAchievements(for session: CardioSession, unitSystem: UnitSystem) -> [String] {
        var achievements: [String] = []
        
        if !session.personalRecordsHit.isEmpty {
            achievements.append(TrainingKeys.Cardio.personalRecord.localized)
        }
        
        if session.duration > 3600 {
            achievements.append("1h+")
        }
        
        let achievementDistance = unitSystem == .metric ? 10000.0 : 16093.4 // 10K or 10 miles
        if session.totalDistance > achievementDistance {
            let label = unitSystem == .metric ? "10K+" : "10mi+"
            achievements.append(label)
        }
        
        return achievements
    }
    
}




#Preview {
    CardioMainView()
        .environment(TrainingCoordinator())
        .environmentObject(UnitSettings.shared)
        .modelContainer(for: [
            CardioWorkout.self,
            CardioSession.self,
            User.self
        ], inMemory: true)
}
