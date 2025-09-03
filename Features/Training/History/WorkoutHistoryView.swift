import SwiftUI
import SwiftData


struct WorkoutHistoryView: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \LiftSession.startDate, order: .reverse) private var liftSessions: [LiftSession]
    @Query(sort: \CardioSession.startDate, order: .reverse) private var cardioSessions: [CardioSession]
    @Query(sort: \WODResult.completedAt, order: .reverse) private var wodResults: [WODResult]
    
    @StateObject private var healthKitService = HealthKitService.shared
    @State private var selectedFilter: WorkoutFilter = .all
    @State private var searchText = ""
    @State private var showHealthKitWorkouts = true
    @State private var workoutStats: WorkoutStats = .empty
    
    private var filteredWODs: [WODResult] {
        wodResults.filter { wod in
            searchText.isEmpty || (wod.wod?.name.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    private var filteredSessions: [any WorkoutSession] {
        var allSessions: [any WorkoutSession] = []
        
        switch selectedFilter {
        case .all:
            allSessions.append(contentsOf: liftSessions.filter { $0.isCompleted })
            allSessions.append(contentsOf: cardioSessions.filter { $0.isCompleted })
        case .strength:
            allSessions.append(contentsOf: liftSessions.filter { $0.isCompleted })
        case .cardio:
            allSessions.append(contentsOf: cardioSessions.filter { $0.isCompleted })
        case .wod:
            // WODs are handled separately, don't add to WorkoutSession array
            break
        case .healthkit:
            // HealthKit workouts would be handled here when implemented
            break
        }
        
        return allSessions
            .sorted { session1, session2 in
                let date1 = session1.completedAt ?? session1.startDate
                let date2 = session2.completedAt ?? session2.startDate
                return date1 > date2
            }
            .filter { session in
                searchText.isEmpty || session.workoutName.localizedCaseInsensitiveContains(searchText)
            }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter Bar
                filterBar
                
                // Search Bar
                searchBar
                
                // Content
                if filteredSessions.isEmpty && (selectedFilter != .wod || filteredWODs.isEmpty) {
                    emptyStateView
                } else {
                    sessionsList
                }
            }
            .navigationTitle(TrainingKeys.Dashboard.recentActivity.localized)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(CommonKeys.Onboarding.Common.done.localized) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                Task {
                    await loadHealthKitData()
                }
            }
            .refreshable {
                await loadHealthKitData()
            }
        }
    }
    
    private func loadHealthKitData() async {
        // Load HealthKit workout history and stats
        let workouts = await healthKitService.readWorkoutHistory(limit: 50, daysBack: 30)
        let stats = await healthKitService.getTotalWorkoutStats(daysBack: 30)
        
        await MainActor.run {
            healthKitService.workoutHistory = workouts
            workoutStats = stats
        }
    }
    
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: theme.spacing.s) {
                ForEach(WorkoutFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.title,
                        isSelected: selectedFilter == filter,
                        action: { selectedFilter = filter }
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, theme.spacing.s)
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(theme.colors.textSecondary)
            
            TextField(CommonKeys.Onboarding.Common.search.localized, text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding(theme.spacing.s)
        .background(theme.colors.backgroundSecondary)
        .cornerRadius(theme.radius.s)
        .padding(.horizontal)
        .padding(.bottom, theme.spacing.s)
    }
    
    private var sessionsList: some View {
        ScrollView {
            LazyVStack(spacing: theme.spacing.s) {
                // HealthKit Workout Stats (when showing HealthKit or all)
                if selectedFilter == .all || selectedFilter == .healthkit {
                    HealthKitWorkoutStatsCard(stats: workoutStats)
                        .padding(.horizontal)
                }
                
                // HealthKit Workouts (when filter is .all or .healthkit)
                if selectedFilter == .all || selectedFilter == .healthkit {
                    ForEach(healthKitService.workoutHistory) { workout in
                        HealthKitWorkoutRow(workout: workout)
                            .padding(.horizontal)
                    }
                }
                
                // Regular workout sessions (Lift & Cardio)
                if selectedFilter != .healthkit {
                    ForEach(filteredSessions.indices, id: \.self) { index in
                        WorkoutHistoryRow(session: filteredSessions[index])
                            .padding(.horizontal)
                    }
                    
                    // WOD Results (when filter is .all or .wod)
                    if selectedFilter == .all || selectedFilter == .wod {
                        ForEach(filteredWODs.indices, id: \.self) { index in
                            WODHistoryRow(result: filteredWODs[index])
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.vertical, theme.spacing.s)
        }
    }
    
    private var emptyStateView: some View {
        EmptyStateView(
            systemImage: "clock.arrow.circlepath",
            title: "No Workout History",
            message: "Complete your first workout to see your training history here.",
            primaryTitle: "Start Training",
            primaryAction: { dismiss() }
        )
        .padding(.top, theme.spacing.xxl)
    }
}

// MARK: - Supporting Types & Views

enum WorkoutFilter: CaseIterable {
    case all, strength, cardio, wod, healthkit
    
    var title: String {
        switch self {
        case .all: return CommonKeys.Onboarding.Common.all.localized
        case .strength: return TrainingKeys.Lift.title.localized
        case .cardio: return TrainingKeys.Cardio.title.localized
        case .wod: return TrainingKeys.WOD.title.localized
        case .healthkit: return "HealthKit"
        }
    }
}



struct WorkoutHistoryRow: View {
    @Environment(\.theme) private var theme
    let session: any WorkoutSession
    
    var body: some View {
        HStack(spacing: theme.spacing.m) {
            // Workout type icon
            Image(systemName: workoutTypeIcon)
                .font(.title3)
                .foregroundColor(workoutTypeColor)
                .frame(width: 32, height: 32)
                .background(workoutTypeColor.opacity(0.1))
                .cornerRadius(theme.radius.s)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(session.workoutName)
                    .font(theme.typography.body)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                
                Text(formatDate(session.completedAt ?? session.startDate))
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatDuration(session.sessionDuration))
                    .font(theme.typography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.colors.textPrimary)
                
                Text(workoutTypeLabel)
                    .font(theme.typography.caption2)
                    .foregroundColor(theme.colors.textSecondary)
            }
        }
        .padding(theme.spacing.m)
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.m)
        .shadow(color: theme.shadows.card.opacity(0.05), radius: 2)
    }
    
    private var workoutTypeIcon: String {
        if session is LiftSession { return "dumbbell.fill" }
        if session is CardioSession { return "heart.fill" }
        return "flame.fill"
    }
    
    private var workoutTypeColor: Color {
        if session is LiftSession { return .strengthColor }
        if session is CardioSession { return .cardioColor }
        return .wodColor
    }
    
    private var workoutTypeLabel: String {
        if session is LiftSession { return TrainingKeys.Lift.title.localized }
        if session is CardioSession { return TrainingKeys.Cardio.title.localized }
        return TrainingKeys.WOD.title.localized
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - HealthKit Components

struct HealthKitWorkoutStatsCard: View {
    let stats: WorkoutStats
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(CommonKeys.HealthKit.statisticsTitle.localized)
                .font(theme.typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(theme.colors.textPrimary)
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(stats.totalWorkouts)")
                        .font(theme.typography.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text("Antrenman")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(stats.totalDurationFormatted)
                        .font(theme.typography.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text(CommonKeys.HealthKit.totalDuration.localized)
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(stats.totalCaloriesFormatted)
                        .font(theme.typography.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    
                    Text("Kalori")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                }
                
                Spacer()
            }
        }
        .padding(theme.spacing.m)
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.m)
        .shadow(color: theme.shadows.card.opacity(0.05), radius: 2)
    }
}

struct HealthKitWorkoutRow: View {
    let workout: WorkoutHistoryItem
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack(spacing: theme.spacing.m) {
            // Activity Icon
            Image(systemName: workout.activityIcon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 32, height: 32)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(theme.radius.s)
            
            // Workout Details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(workout.activityDisplayName)
                        .font(theme.typography.body)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Spacer()
                    
                    // Source badge
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.caption2)
                            .foregroundColor(.red)
                        
                        Text(workout.source)
                            .font(.caption2)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(theme.colors.backgroundSecondary)
                    .cornerRadius(6)
                }
                
                HStack(spacing: 8) {
                    Text(formatDate(workout.startDate))
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                    
                    Text("•")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                    
                    Text(workout.durationFormatted)
                        .font(theme.typography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    if let calories = workout.caloriesFormatted {
                        Text("•")
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textSecondary)
                        
                        Text(calories)
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    
                    if let distance = workout.distanceFormatted {
                        Text("•")
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textSecondary)
                        
                        Text(distance)
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(theme.spacing.m)
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.m)
        .shadow(color: theme.shadows.card.opacity(0.05), radius: 2)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    NavigationStack {
        WorkoutHistoryView()
    }
    .modelContainer(for: [
        LiftSession.self,
        CardioSession.self,
        WODResult.self
    ], inMemory: true)
}