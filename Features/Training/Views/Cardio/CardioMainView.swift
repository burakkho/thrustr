import SwiftUI
import SwiftData

struct CardioMainView: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(TrainingCoordinator.self) private var coordinator
    
    @Query private var cardioWorkouts: [CardioWorkout]
    @Query private var cardioSessions: [CardioSession]
    @Query private var user: [User]
    
    @State private var selectedTab = 0
    @State private var selectedWorkout: CardioWorkout?
    @State private var selectedWorkoutForSession: CardioWorkout?
    @State private var showingQuickStart = false
    
    private var currentUser: User? {
        user.first
    }
    
    private let tabs = [
        TrainingTab(title: "Train", icon: "heart.fill"),
        TrainingTab(title: "History", icon: "clock.arrow.circlepath")
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
                        selectedWorkoutForSession: $selectedWorkoutForSession,
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
        .sheet(item: $selectedWorkoutForSession) { workout in
            if let user = currentUser {
                CardioSessionInputView(exerciseType: workout, user: user)
            }
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
                    Label("Session in progress", systemImage: "circle.fill")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.success)
                }
            }
            
            Spacer()
            
            // Quick Actions Menu
            Menu {
                Button(action: { showingQuickStart = true }) {
                    Label("Quick Start", systemImage: "play.circle")
                }
                
                Button(action: { selectedTab = 1 }) {
                    Label("View History", systemImage: "clock.arrow.circlepath")
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
    
    @Query private var cardioSessions: [CardioSession]
    
    @Binding var selectedWorkout: CardioWorkout?
    @Binding var selectedWorkoutForSession: CardioWorkout?
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
    
    
    private func startCurrentWorkout(_ workout: CardioWorkout?) {
        guard let workout = workout else { return }
        selectedWorkoutForSession = workout
    }
    
    // MARK: - Quick Start Section
    private var quickStartSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            Text("Quick Start")
                .font(theme.typography.headline)
                .foregroundColor(theme.colors.textPrimary)
                .padding(.horizontal)
            
            HStack(spacing: theme.spacing.m) {
                quickActionCard(
                    icon: "plus.circle.fill",
                    title: "Quick Start",
                    subtitle: "Start cardio session",
                    color: theme.colors.accent,
                    action: { showingQuickStart = true }
                )
                
                quickActionCard(
                    icon: "clock.arrow.circlepath",
                    title: "View History",
                    subtitle: "Past sessions",
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
                Text("Recent Sessions")
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
                label: "Distance",
                value: String(format: "%.1f km", session.totalDistance / 1000),
                icon: "ruler"
            ))
        }
        
        if let averageSpeed = session.averageSpeed, averageSpeed > 0 {
            stats.append(WorkoutStat(
                label: "Avg Speed",
                value: String(format: "%.1f km/h", averageSpeed * 3.6),
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
    let sessions: [CardioSession]
    let currentUser: User?
    
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
                        SessionHistoryCard(
                            workoutName: session.workoutName,
                            date: session.completedAt ?? session.startDate,
                            duration: TimeInterval(session.duration),
                            primaryMetric: SessionMetric(
                                label: "Distance",
                                value: session.formattedDistance
                            ),
                            secondaryMetrics: buildSessionMetrics(for: session),
                            achievements: buildAchievements(for: session),
                            feeling: session.feeling != nil ? 
                                WorkoutFeeling(
                                    emoji: session.feelingEmoji,
                                    description: session.feeling!.capitalized,
                                    note: nil
                                ) : nil,
                            onTap: { viewSessionDetail(session) }
                        )
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, theme.spacing.m)
            }
        }
    }
    
    private func buildSessionMetrics(for session: CardioSession) -> [SessionMetric] {
        var metrics: [SessionMetric] = []
        
        if let pace = session.formattedAveragePace {
            metrics.append(SessionMetric(label: "Pace", value: pace))
        }
        
        if let calories = session.totalCaloriesBurned, calories > 0 {
            metrics.append(SessionMetric(label: "Calories", value: "\(calories)"))
        }
        
        return metrics
    }
    
    private func buildAchievements(for session: CardioSession) -> [String] {
        var achievements: [String] = []
        
        if !session.personalRecordsHit.isEmpty {
            achievements.append("PR")
        }
        
        if session.duration > 3600 {
            achievements.append("1h+")
        }
        
        if session.totalDistance > 10000 {
            achievements.append("10K+")
        }
        
        return achievements
    }
    
    private func viewSessionDetail(_ session: CardioSession) {
        // Navigate to session detail
        Logger.info("View cardio session detail: \(session.id)")
    }
}




#Preview {
    CardioMainView()
        .environment(TrainingCoordinator())
        .modelContainer(for: [
            CardioWorkout.self,
            CardioSession.self,
            User.self
        ], inMemory: true)
}