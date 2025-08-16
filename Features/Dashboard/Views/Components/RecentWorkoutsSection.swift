import SwiftUI

struct RecentWorkoutsSection: View {
    @Environment(\.theme) private var theme
    @EnvironmentObject private var tabRouter: TabRouter
    let workouts: [Workout]
    
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
    let workouts: [Workout]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(workouts, id: \.id) { workout in
                    WorkoutCard(workout: workout)
                }
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    let emptyWorkouts: [Workout] = []
    let sampleWorkouts = [
        Workout(name: "Push Day"),
        Workout(name: "Pull Day"),
        Workout(name: "Leg Day")
    ]
    
    return VStack(spacing: 20) {
        RecentWorkoutsSection(workouts: emptyWorkouts)
        RecentWorkoutsSection(workouts: sampleWorkouts)
    }
    .environmentObject(TabRouter())
    .padding()
}