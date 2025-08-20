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
        TrainingTab(title: LocalizationKeys.Training.Cardio.templates.localized, icon: "heart.text.square"),
        TrainingTab(title: LocalizationKeys.Training.Cardio.history.localized, icon: "clock.arrow.circlepath")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Quick Start Button
            quickStartButton
            
            // Tab Selector
            TrainingTabSelector(
                selection: $selectedTab,
                tabs: tabs
            )
            
            // Content
            Group {
                switch selectedTab {
                case 0:
                    CardioTemplatesSection(
                        workouts: cardioWorkouts,
                        selectedWorkout: $selectedWorkout,
                        selectedWorkoutForSession: $selectedWorkoutForSession,
                        currentUser: currentUser
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
                
                if let lastSession = cardioSessions.filter({ $0.isCompleted }).sorted(by: { $0.startDate > $1.startDate }).first {
                    Text("\(LocalizationKeys.Training.Cardio.lastSession.localized): \(lastSession.startDate, formatter: RelativeDateTimeFormatter())")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
            
            Spacer()
            
            Button(action: { showingNewCardio = true }) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(theme.colors.accent)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, theme.spacing.m)
    }
    
    private var quickStartButton: some View {
        Button(action: { showingQuickStart = true }) {
            HStack(spacing: theme.spacing.m) {
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Hızlı Başlat")
                        .font(theme.typography.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("GPS ile koşu, yürüyüş veya bisiklet")
                        .font(theme.typography.caption)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(theme.spacing.l)
            .background(
                LinearGradient(
                    colors: [theme.colors.accent, theme.colors.accent.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(theme.radius.m)
            .shadow(color: theme.colors.accent.opacity(0.3), radius: 8, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
        .padding(.vertical, theme.spacing.s)
    }
}

// MARK: - Cardio Templates Section
struct CardioTemplatesSection: View {
    @Environment(\.theme) private var theme
    let workouts: [CardioWorkout]
    @Binding var selectedWorkout: CardioWorkout?
    @Binding var selectedWorkoutForSession: CardioWorkout?
    let currentUser: User?
    
    @State private var searchText = ""
    @State private var selectedCategory: CardioCategory = .exercise
    
    private var filteredWorkouts: [CardioWorkout] {
        let categoryWorkouts = selectedCategory == .exercise ? 
            workouts.filter { !$0.isCustom } : 
            workouts.filter { $0.isCustom }
        
        if searchText.isEmpty {
            return categoryWorkouts.sorted { $0.name < $1.name }
        }
        
        return categoryWorkouts.filter { workout in
            workout.localizedName.localizedCaseInsensitiveContains(searchText) ||
            workout.localizedDescription.localizedCaseInsensitiveContains(searchText)
        }.sorted { $0.name < $1.name }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: theme.spacing.l) {
                // Search Bar
                searchBar
                
                // Category Filter
                categoryFilter
                
                // Workouts List
                if !filteredWorkouts.isEmpty {
                    workoutsList
                } else {
                    EmptyStateCard(
                        icon: "heart.circle",
                        title: selectedCategory == .custom ? 
                            LocalizationKeys.Training.Cardio.customSessions.localized : 
                            LocalizationKeys.Training.Cardio.noExerciseTypes.localized,
                        message: searchText.isEmpty ? 
                            LocalizationKeys.Training.Cardio.noHistoryMessage.localized : 
                            LocalizationKeys.Training.Cardio.adjustSearch.localized,
                        primaryAction: .init(
                            title: searchText.isEmpty ? 
                                LocalizationKeys.Training.Cardio.startSession.localized : 
                                LocalizationKeys.Training.Cardio.clearSearch.localized,
                            action: { searchText = "" }
                        )
                    )
                    .padding(.top, 50)
                }
            }
            .padding(.vertical, theme.spacing.m)
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(theme.colors.textSecondary)
            TextField(LocalizationKeys.Training.Exercise.searchPlaceholder.localized, text: $searchText)
                .textFieldStyle(.plain)
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
        }
        .padding(theme.spacing.m)
        .background(theme.colors.backgroundSecondary)
        .cornerRadius(theme.radius.m)
        .padding(.horizontal)
    }
    
    private var categoryFilter: some View {
        HStack(spacing: theme.spacing.m) {
            ForEach(CardioCategory.allCases, id: \.self) { category in
                Button(action: { selectedCategory = category }) {
                    Text(category.displayName)
                        .font(theme.typography.caption)
                        .fontWeight(selectedCategory == category ? .semibold : .regular)
                        .foregroundColor(selectedCategory == category ? .white : theme.colors.textSecondary)
                        .padding(.horizontal, theme.spacing.m)
                        .padding(.vertical, theme.spacing.s)
                        .background(
                            RoundedRectangle(cornerRadius: theme.radius.m)
                                .fill(selectedCategory == category ? theme.colors.accent : theme.colors.backgroundSecondary)
                        )
                }
            }
            Spacer()
        }
        .padding(.horizontal)
    }
    
    private var workoutsList: some View {
        LazyVStack(spacing: theme.spacing.m) {
            ForEach(filteredWorkouts) { workout in
                UnifiedWorkoutCard(
                    title: workout.localizedName,
                    subtitle: workout.displayEquipment,
                    description: workout.localizedDescription,
                    primaryStats: buildWorkoutStats(for: workout),
                    secondaryInfo: buildSecondaryInfo(for: workout),
                    isFavorite: workout.isFavorite,
                    cardStyle: .detailed,
                    primaryAction: { selectedWorkout = workout },
                    secondaryAction: { startWorkout(workout) }
                )
                .padding(.horizontal)
            }
        }
    }
    
    private func buildWorkoutStats(for workout: CardioWorkout) -> [WorkoutStat] {
        var stats: [WorkoutStat] = []
        
        if let exercise = workout.exercises.first {
            stats.append(WorkoutStat(
                label: "Type",
                value: exercise.exerciseType.capitalized,
                icon: exercise.exerciseIcon
            ))
        }
        
        if let pr = workout.personalRecord {
            if let time = pr.formattedTime {
                stats.append(WorkoutStat(
                    label: "PR",
                    value: time,
                    icon: "trophy.fill"
                ))
            } else if let distance = pr.formattedDistance {
                stats.append(WorkoutStat(
                    label: "PR",
                    value: distance,
                    icon: "trophy.fill"
                ))
            }
        }
        
        return stats
    }
    
    private func buildSecondaryInfo(for workout: CardioWorkout) -> [String] {
        var info: [String] = []
        
        if let lastDate = workout.lastPerformed {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .short
            info.append(formatter.localizedString(for: lastDate, relativeTo: Date()))
        } else {
            info.append(LocalizationKeys.Training.Cardio.neverAttempted.localized)
        }
        
        return info
    }
    
    private func startWorkout(_ workout: CardioWorkout) {
        selectedWorkoutForSession = workout
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