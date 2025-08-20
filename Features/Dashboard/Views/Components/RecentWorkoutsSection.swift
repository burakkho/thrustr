import SwiftUI
import SwiftData

struct RecentWorkoutsSection: View {
    @Environment(\.theme) private var theme
    @EnvironmentObject private var tabRouter: TabRouter
    @Query(
        filter: #Predicate<LiftSession> { $0.isCompleted },
        sort: \LiftSession.startDate,
        order: .reverse
    ) private var recentSessions: [LiftSession]
    
    // Show last 5 sessions
    private var workouts: [LiftSession] {
        Array(recentSessions.prefix(5))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            DashboardSectionHeader(
                title: LocalizationKeys.Dashboard.recentWorkouts.localized,
                showSeeAllButton: !workouts.isEmpty,
                onSeeAllTap: navigateToWorkoutHistory
            )
            
            if workouts.isEmpty {
                EmptyWorkoutsState(onStartWorkout: navigateToTraining)
            } else {
                WorkoutsList(workouts: workouts)
            }
        }
    }
    
    // MARK: - Navigation Handlers
    private func navigateToWorkoutHistory() {
        // Navigate to workout history - could be implemented later
        print("Navigate to workout history")
    }
    
    private func navigateToTraining() {
        tabRouter.selected = 1
    }
}

// MARK: - Dashboard Section Header Component
private struct DashboardSectionHeader: View {
    let title: String
    let showSeeAllButton: Bool
    let onSeeAllTap: () -> Void
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            
            Spacer()
            
            if showSeeAllButton {
                Button(LocalizationKeys.Dashboard.seeAll.localized) {
                    onSeeAllTap()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Empty State Component
private struct EmptyWorkoutsState: View {
    @Environment(\.theme) private var theme
    let onStartWorkout: () -> Void
    
    var body: some View {
        VStack(spacing: theme.spacing.s) {
            EmptyStateIcon()
            EmptyStateText()
            StartWorkoutButton(onTap: onStartWorkout)
        }
        .padding()
        .dashboardSurfaceStyle()
    }
}

private struct EmptyStateIcon: View {
    @Environment(\.theme) private var theme
    
    var body: some View {
        Image(systemName: "dumbbell")
            .font(.largeTitle)
            .foregroundColor(theme.colors.textSecondary)
    }
}

private struct EmptyStateText: View {
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 8) {
            Text(LocalizationKeys.Dashboard.NoWorkouts.title.localized)
                .font(.headline)
                .foregroundColor(theme.colors.textSecondary)
            
            Text(LocalizationKeys.Dashboard.NoWorkouts.subtitle.localized)
                .font(.subheadline)
                .foregroundColor(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
}

private struct StartWorkoutButton: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onTap()
        }) {
            Text(LocalizationKeys.Dashboard.Actions.startWorkout.localized)
                .font(.headline)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
    }
}

// MARK: - Workouts List Component
private struct WorkoutsList: View {
    let workouts: [LiftSession]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(workouts, id: \.id) { session in
                    LiftSessionCard(session: session)
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Lift Session Card
private struct LiftSessionCard: View {
    @Environment(\.theme) private var theme
    let session: LiftSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.s) {
            Text(session.workout.name)
                .font(theme.typography.headline)
                .foregroundColor(theme.colors.textPrimary)
            
            Text(session.startDate.formatted(date: .abbreviated, time: .omitted))
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textSecondary)
            
            HStack {
                Text("\(Int(session.totalVolume))kg")
                    .font(theme.typography.body)
                    .foregroundColor(theme.colors.accent)
                
                Spacer()
                
                Text("\(session.totalSets) sets")
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }
        }
        .padding()
        .frame(width: 160)
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.m)
    }
}

#Preview {
    RecentWorkoutsSection()
        .environmentObject(TabRouter())
        .modelContainer(for: [LiftSession.self], inMemory: true)
        .padding()
}