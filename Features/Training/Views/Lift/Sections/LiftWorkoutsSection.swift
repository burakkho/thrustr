import SwiftUI
import SwiftData

struct LiftWorkoutsSection: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(TrainingCoordinator.self) private var coordinator
    
    @Query(
        filter: #Predicate<LiftSession> { $0.isCompleted == true },
        sort: [SortDescriptor(\LiftSession.startDate, order: .reverse)]
    ) private var completedSessions: [LiftSession]
    
    @Query(filter: #Predicate<ProgramExecution> { $0.isCompleted == false })
    private var activeProgramExecutions: [ProgramExecution]
    
    @Query private var users: [User]
    
    @State private var selectedWorkout: LiftWorkout?
    @State private var showingScratchBuilder = false
    
    private var recentSessions: [LiftSession] {
        Array(completedSessions.prefix(3))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: theme.spacing.xl) {
                // Weekly Analytics
                LiftAnalyticsCard(sessions: completedSessions, currentUser: users.first)
                
                // Active Program Card (if exists)
                if let activeExecution = activeProgramExecutions.first {
                    compactProgramCard(execution: activeExecution)
                } else {
                    // Quick Start Section
                    quickStartSection
                }
                
                // Recent Workouts
                if !recentSessions.isEmpty {
                    recentWorkoutsSection
                } else if activeProgramExecutions.isEmpty {
                    // Empty state for first-time users
                    EmptyStateView(
                        systemImage: "dumbbell.fill",
                        title: TrainingKeys.Lift.noWorkouts.localized,
                        message: TrainingKeys.Lift.noWorkoutsDesc.localized,
                        primaryTitle: TrainingKeys.Lift.startFirstWorkout.localized,
                        primaryAction: { showingScratchBuilder = true },
                        secondaryTitle: TrainingKeys.Lift.browsePrograms.localized,
                        secondaryAction: { coordinator.navigateToProgramSelection() }
                    )
                    .padding(.top, theme.spacing.xl)
                }
                
                // Browse Programs CTA
                if activeProgramExecutions.isEmpty && !recentSessions.isEmpty {
                    browseProgramsCTA
                }
            }
            .padding(.vertical, theme.spacing.m)
        }
        .sheet(item: $selectedWorkout) { workout in
            LiftSessionView(
                workout: workout,
                programExecution: findProgramExecutionForWorkout(workout)
            )
        }
        .sheet(isPresented: $showingScratchBuilder) {
            ScratchRoutineBuilderView()
        }
    }
    
    private func compactProgramCard(execution: ProgramExecution) -> some View {
        VStack(spacing: theme.spacing.m) {
            UnifiedWorkoutCard(
                title: execution.program?.localizedName ?? "Unknown Program",
                subtitle: "Week \(execution.currentWeek) • \(execution.currentWorkout?.localizedName ?? "")",
                primaryStats: [
                    WorkoutStat(
                        label: "This Week",
                        value: "\(execution.completedWorkoutsThisWeek)/\(execution.program?.daysPerWeek ?? 3)",
                        icon: "checkmark.circle"
                    ),
                    WorkoutStat(
                        label: "Streak",
                        value: "\(execution.currentStreak)",
                        icon: "flame.fill"
                    )
                ],
                cardStyle: .detailed,
                primaryAction: { },
                secondaryAction: { startWorkout(execution.currentWorkout) }
            )
            .padding(.horizontal)
            
            QuickActionButton(
                title: "training.lift.startWorkout".localized,
                icon: "play.circle.fill",
                style: .primary,
                size: .fullWidth,
                action: { startWorkout(execution.currentWorkout) }
            )
            .padding(.horizontal)
        }
    }
    
    private var quickStartSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            Text("training.lift.quickStart".localized)
                .font(theme.typography.headline)
                .foregroundColor(theme.colors.textPrimary)
                .padding(.horizontal)
            
            HStack(spacing: theme.spacing.m) {
                quickActionCard(
                    icon: "plus.circle.fill",
                    title: "training.lift.emptyWorkout".localized,
                    subtitle: "training.lift.emptyWorkout.subtitle".localized,
                    color: theme.colors.accent,
                    action: createEmptyWorkout
                )
                
                quickActionCard(
                    icon: "list.bullet.rectangle",
                    title: "training.lift.pickRoutine".localized,
                    subtitle: "training.lift.pickRoutine.subtitle".localized,
                    color: theme.colors.success,
                    action: { }
                )
                
                quickActionCard(
                    icon: "dumbbell.fill",
                    title: "training.lift.startProgram".localized,
                    subtitle: "training.lift.startProgram.subtitle".localized,
                    color: theme.colors.warning,
                    action: { coordinator.navigateToProgramSelection() }
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
    
    private var recentWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            Text("training.lift.recentWorkouts".localized)
                .font(theme.typography.headline)
                .foregroundColor(theme.colors.textPrimary)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: theme.spacing.m) {
                    ForEach(recentSessions, id: \.id) { session in
                        recentSessionCard(session: session)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func recentSessionCard(session: LiftSession) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.s) {
            Text(session.workout?.localizedName ?? "Unknown Workout")
                .font(theme.typography.body)
                .fontWeight(.medium)
                .foregroundColor(theme.colors.textPrimary)
                .lineLimit(1)
            
            Text(session.startDate.formatted(.relative(presentation: .named)))
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textSecondary)
            
            HStack {
                Text("\(Int(session.totalVolume)) kg")
                    .font(theme.typography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.accent)
                
                Spacer()
                
                Text("\(session.totalSets) sets")
                    .font(.caption2)
                    .foregroundColor(theme.colors.textSecondary)
            }
            
            if !session.prsHit.isEmpty {
                Label("\(session.prsHit.count) PR", systemImage: "trophy.fill")
                    .font(.caption2)
                    .foregroundColor(theme.colors.warning)
            }
        }
        .padding(theme.spacing.m)
        .frame(width: 160)
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.m)
        .shadow(color: theme.shadows.card.opacity(0.05), radius: 2)
    }
    
    private var browseProgramsCTA: some View {
        QuickActionButton(
            title: "training.lift.browsePrograms".localized,
            icon: "rectangle.3.group",
            subtitle: "training.lift.browsePrograms.subtitle".localized,
            style: .outlined,
            size: .fullWidth,
            action: { coordinator.navigateToProgramSelection() }
        )
        .padding(.horizontal)
    }
    
    private func createEmptyWorkout() {
        let emptyWorkout = LiftWorkout(
            name: "Quick Workout",
            isTemplate: false,
            isCustom: true
        )
        modelContext.insert(emptyWorkout)
        
        do {
            try modelContext.save()
            selectedWorkout = emptyWorkout
        } catch {
            Logger.error("Failed to create empty workout: \(error)")
        }
    }
    
    private func startWorkout(_ workout: LiftWorkout?) {
        guard let workout = workout else { return }
        selectedWorkout = workout
    }
    
    private func findProgramExecutionForWorkout(_ workout: LiftWorkout) -> ProgramExecution? {
        activeProgramExecutions.first { execution in
            (execution.program?.workouts ?? []).contains { $0.id == workout.id }
        }
    }
}