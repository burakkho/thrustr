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
    @State private var showingNewCardio = false
    @State private var showingQuickStart = false
    
    private var currentUser: User? {
        user.first
    }
    
    private let tabs = [
        TrainingTab(title: "Train", icon: "heart.fill"),
        TrainingTab(title: "Programs", icon: "rectangle.3.group"),
        TrainingTab(title: "Routines", icon: "square.stack"),
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
                        selectedTab: $selectedTab,
                        currentUser: currentUser
                    )
                case 1:
                    CardioProgramsSection(
                        currentUser: currentUser
                    )
                case 2:
                    CardioRoutinesSection(
                        currentUser: currentUser,
                        showingNewCardio: $showingNewCardio
                    )
                case 3:
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
        .sheet(isPresented: $showingNewCardio) {
            CreateCardioWorkoutView()
        }
        .sheet(isPresented: $showingQuickStart) {
            CardioQuickStartView()
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizationKeys.Training.Cardio.title.localized)
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
                
                Button(action: { showingNewCardio = true }) {
                    Label("New Routine", systemImage: "plus.circle")
                }
                
                Button(action: { selectedTab = 1 }) {
                    Label("Browse Programs", systemImage: "rectangle.3.group")
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
    @Query(filter: #Predicate<CardioProgramExecution> { !$0.isCompleted })
    private var activeProgramExecutions: [CardioProgramExecution]
    
    @Binding var selectedWorkout: CardioWorkout?
    @Binding var selectedWorkoutForSession: CardioWorkout?
    @Binding var showingQuickStart: Bool
    @Binding var selectedTab: Int
    let currentUser: User?
    
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
                // Active Program Card (if exists)
                if let activeExecution = activeProgramExecutions.first {
                    compactProgramCard(execution: activeExecution)
                } else {
                    // Quick Start Section
                    quickStartSection
                }
                
                // Recent Sessions
                if !recentSessions.isEmpty {
                    recentSessionsSection
                }
                
                // Browse Programs CTA
                if activeProgramExecutions.isEmpty {
                    browseProgramsCTA
                }
            }
            .padding(.vertical, theme.spacing.m)
        }
    }
    
    private func compactProgramCard(execution: CardioProgramExecution) -> some View {
        VStack(spacing: theme.spacing.m) {
            UnifiedWorkoutCard(
                title: execution.program.localizedName,
                subtitle: "Week \(execution.currentWeek) • \(execution.currentWorkout?.localizedName ?? "")",
                primaryStats: [
                    WorkoutStat(
                        label: "This Week",
                        value: "\(execution.completedSessionsThisWeek)/\(execution.program.daysPerWeek)",
                        icon: "checkmark.circle"
                    ),
                    WorkoutStat(
                        label: "Distance",
                        value: execution.formattedTotalDistance,
                        icon: "ruler"
                    ),
                    WorkoutStat(
                        label: "Streak",
                        value: "\(execution.currentStreak)",
                        icon: "flame.fill"
                    )
                ],
                cardStyle: .detailed,
                primaryAction: { /* View details */ },
                secondaryAction: { startCurrentWorkout(execution.currentWorkout) }
            )
            .padding(.horizontal)
            
            QuickActionButton(
                title: "Continue Training",
                icon: "play.circle.fill",
                style: .primary,
                size: .fullWidth,
                action: { startCurrentWorkout(execution.currentWorkout) }
            )
            .padding(.horizontal)
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
                    title: "Empty Cardio",
                    subtitle: "Start blank session",
                    color: theme.colors.accent,
                    action: { showingQuickStart = true }
                )
                
                quickActionCard(
                    icon: "list.bullet.rectangle",
                    title: "Pick Routine",
                    subtitle: "Choose custom workout",
                    color: theme.colors.success,
                    action: { selectedTab = 2 } // Navigate to Routines tab
                )
                
                quickActionCard(
                    icon: "heart.fill",
                    title: "Start Program",
                    subtitle: "Structured plan",
                    color: Color.cardioColor,
                    action: { selectedTab = 1 } // Navigate to Programs tab
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
                Button(LocalizationKeys.Training.Lift.seeAll.localized) {
                    selectedTab = 3 // Navigate to History tab
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
    
    // MARK: - Browse Programs CTA
    private var browseProgramsCTA: some View {
        QuickActionButton(
            title: "Browse Programs",
            icon: "rectangle.3.group",
            subtitle: "Structured cardio programs",
            style: .outlined,
            size: .fullWidth,
            action: { selectedTab = 1 } // Navigate to Programs tab
        )
        .padding(.horizontal)
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
                    title: LocalizationKeys.Training.Cardio.noHistory.localized,
                    message: LocalizationKeys.Training.Cardio.noHistoryMessage.localized,
                    primaryAction: .init(
                        title: LocalizationKeys.Training.Cardio.browseTemplates.localized,
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

// MARK: - Cardio Programs Section
struct CardioProgramsSection: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    
    @Query(filter: #Predicate<CardioProgram> { !$0.isCustom })
    private var availablePrograms: [CardioProgram]
    
    @Query(filter: #Predicate<CardioProgramExecution> { !$0.isCompleted })
    private var activeExecutions: [CardioProgramExecution]
    
    let currentUser: User?
    @State private var selectedProgram: CardioProgram?
    @State private var showingProgramDetail = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: theme.spacing.xl) {
                // Active Program (if any)
                if let activeExecution = activeExecutions.first {
                    activeProgramSection(activeExecution)
                }
                
                // Available Programs
                if !availablePrograms.isEmpty {
                    availableProgramsSection
                } else {
                    emptyStateSection
                }
            }
            .padding(.vertical, theme.spacing.m)
        }
        .sheet(item: $selectedProgram) { program in
            CardioProgramDetailView(program: program, currentUser: currentUser)
        }
    }
    
    private func activeProgramSection(_ execution: CardioProgramExecution) -> some View {
        VStack(spacing: theme.spacing.m) {
            HStack {
                Text("Active Program")
                    .font(theme.typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                Spacer()
            }
            .padding(.horizontal)
            
            UnifiedWorkoutCard(
                title: execution.program.localizedName,
                subtitle: execution.formattedProgress,
                description: "Continue your structured cardio training",
                primaryStats: [
                    WorkoutStat(
                        label: "This Week",
                        value: "\(execution.completedSessionsThisWeek)/\(execution.program.daysPerWeek)",
                        icon: "checkmark.circle"
                    ),
                    WorkoutStat(
                        label: "Progress",
                        value: "\(Int(execution.progressPercentage * 100))%",
                        icon: "chart.line.uptrend.xyaxis"
                    )
                ],
                secondaryInfo: [execution.formattedTotalDistance],
                cardStyle: .detailed,
                primaryAction: { /* Start next session */ }
            )
            .padding(.horizontal)
        }
    }
    
    private var availableProgramsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            HStack {
                Text("Available Programs")
                    .font(theme.typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                Spacer()
            }
            .padding(.horizontal)
            
            LazyVStack(spacing: theme.spacing.m) {
                ForEach(availablePrograms, id: \.id) { program in
                    programCard(program)
                        .padding(.horizontal)
                }
            }
        }
    }
    
    private func programCard(_ program: CardioProgram) -> some View {
        UnifiedWorkoutCard(
            title: program.localizedName,
            subtitle: "\(program.weeks) weeks • \(program.daysPerWeek) days/week",
            description: program.localizedDescription,
            primaryStats: [
                WorkoutStat(
                    label: "Level",
                    value: program.level.capitalized,
                    icon: program.difficultyIcon
                ),
                WorkoutStat(
                    label: "Duration",
                    value: program.estimatedDuration,
                    icon: "clock"
                ),
                WorkoutStat(
                    label: "Type",
                    value: program.category.capitalized,
                    icon: program.categoryIcon
                )
            ],
            secondaryInfo: program.totalDistance != nil ? [
                "Goal: \(String(format: "%.0fK", (program.totalDistance ?? 0) / 1000))"
            ] : [],
            cardStyle: .detailed,
            primaryAction: {
                selectedProgram = program
            }
        )
    }
    
    private var emptyStateSection: some View {
        EmptyStateCard(
            icon: "rectangle.3.group",
            title: "No Programs Available",
            message: "Cardio programs are being prepared. Check back soon for structured training programs.",
            primaryAction: .init(
                title: "Browse Workouts",
                action: { /* Navigate to workouts */ }
            )
        )
        .padding(.top, 50)
    }
}

// MARK: - Cardio Routines Section  
struct CardioRoutinesSection: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    let currentUser: User?
    @Binding var showingNewCardio: Bool
    
    @State private var builtInRoutines: [CardioRoutine] = []
    @Query private var customRoutines: [CardioRoutine]
    @State private var selectedRoutine: CardioRoutine?
    
    init(currentUser: User?, showingNewCardio: Binding<Bool>) {
        self.currentUser = currentUser
        self._showingNewCardio = showingNewCardio
        
        // Filter only custom routines in query
        self._customRoutines = Query(
            filter: #Predicate<CardioRoutine> { routine in
                routine.isCustom == true
            },
            sort: [SortDescriptor(\CardioRoutine.updatedAt, order: .reverse)]
        )
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: theme.spacing.l) {
                // Built-in Routines Section
                builtInRoutinesSection
                
                // Custom Routines Section  
                customRoutinesSection
            }
            .padding(.vertical, theme.spacing.m)
        }
        .onAppear {
            loadBuiltInRoutines()
        }
        .sheet(item: $selectedRoutine) { routine in
            if let user = currentUser {
                CardioRoutineSessionView(
                    routine: routine,
                    user: user
                )
            }
        }
    }
    
    // MARK: - Built-in Routines Section
    private var builtInRoutinesSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            // Section Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Built-in Routines")
                        .font(theme.typography.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Text("Popular cardio workouts")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                }
                
                Spacer()
            }
            .padding(.horizontal)
            
            // Routines Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: theme.spacing.m) {
                ForEach(builtInRoutines.prefix(8), id: \.id) { routine in
                    routineCard(routine)
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Custom Routines Section
    private var customRoutinesSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            // Section Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Custom Routines")
                        .font(theme.typography.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Text("Your personalized workouts")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                }
                
                Spacer()
                
                Button("Create") {
                    showingNewCardio = true
                }
                .font(theme.typography.body)
                .fontWeight(.medium)
                .foregroundColor(theme.colors.accent)
            }
            .padding(.horizontal)
            
            // Custom Routines or Empty State
            if customRoutines.isEmpty {
                EmptyStateCard(
                    icon: "square.stack",
                    title: "No Custom Routines",
                    message: "Create your first custom cardio routine to see it here.",
                    primaryAction: .init(
                        title: "Create Routine",
                        action: { showingNewCardio = true }
                    )
                )
                .padding(.horizontal)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: theme.spacing.m) {
                    ForEach(customRoutines, id: \.id) { routine in
                        routineCard(routine)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Routine Card
    private func routineCard(_ routine: CardioRoutine) -> some View {
        Button(action: { selectedRoutine = routine }) {
            VStack(alignment: .leading, spacing: theme.spacing.s) {
                // Icon and Difficulty
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.cardioColor.opacity(0.15))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: routine.icon)
                            .font(.system(size: 16))
                            .foregroundColor(Color.cardioColor)
                    }
                    
                    Spacer()
                    
                    // Difficulty Badge
                    Text(routine.difficulty.capitalized)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(routine.difficultyColor).opacity(0.2))
                        .foregroundColor(Color(routine.difficultyColor))
                        .cornerRadius(4)
                }
                
                // Title
                Text(routine.localizedName)
                    .font(theme.typography.body)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                    .lineLimit(1)
                
                // Primary Target (Distance or Duration)
                Text(routine.primaryTarget)
                    .font(theme.typography.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color.cardioColor)
                
                // Estimated Time
                if !routine.formattedEstimatedTime.isEmpty {
                    Text("~\(routine.formattedEstimatedTime)")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
            .padding(theme.spacing.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.colors.cardBackground)
            .cornerRadius(theme.radius.m)
            .shadow(color: theme.shadows.card.opacity(0.05), radius: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Helper Methods
    private func loadBuiltInRoutines() {
        builtInRoutines = CardioRoutineService.shared.loadBuiltInRoutines()
    }
}

// MARK: - Create Cardio Workout View (Placeholder)
struct CreateCardioWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Text("Create New Cardio Workout")
                .navigationTitle("New Cardio")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") { dismiss() }
                    }
                }
        }
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