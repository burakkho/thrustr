import SwiftUI
import SwiftData

// MARK: - Program Dashboard View
struct ProgramDashboardView: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(TrainingCoordinator.self) private var coordinator
    @Environment(UnitSettings.self) var unitSettings
    @State private var viewModel: ProgramDashboardViewModel?

    let execution: ProgramExecution?
    let onStartWorkout: () -> Void
    let onPauseProgram: () -> Void
    let onViewDetails: () -> Void

    // MARK: - Computed Properties for Safe ViewModel Access
    private var totalVolume: Double {
        guard let execution = execution, let viewModel = viewModel else { return 0.0 }
        return viewModel.totalVolume(execution: execution)
    }

    private var prsThisWeek: Int {
        guard let execution = execution, let viewModel = viewModel else { return 0 }
        return viewModel.prsThisWeek(execution: execution)
    }

    private var averageSessionDuration: TimeInterval {
        guard let execution = execution, let viewModel = viewModel else { return 0 }
        return viewModel.averageSessionDuration(execution: execution)
    }

    private var totalSetsCompleted: Int {
        guard let execution = execution, let viewModel = viewModel else { return 0 }
        return viewModel.totalSetsCompleted(execution: execution)
    }

    private var totalRepsCompleted: Int {
        guard let execution = execution, let viewModel = viewModel else { return 0 }
        return viewModel.totalRepsCompleted(execution: execution)
    }

    private var weeklyCompletionPercentage: Double {
        guard let execution = execution, let viewModel = viewModel else { return 0.0 }
        return viewModel.weeklyCompletionPercentage(execution: execution)
    }

    private var programIntensityScore: Double {
        guard let execution = execution, let viewModel = viewModel else { return 0.0 }
        return viewModel.programIntensityScore(execution: execution)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if let execution = execution {
                activeProgramDashboard(execution: execution)
            } else {
                noProgramPrompt
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = ProgramDashboardViewModel()
                viewModel?.setModelContext(modelContext)
            }
        }
    }

    // MARK: - Active Program Dashboard
    private func activeProgramDashboard(execution: ProgramExecution) -> some View {
        VStack(spacing: theme.spacing.l) {
            // Header Section
            programHeader(execution: execution)
            
            // Progress Section
            progressSection(execution: execution)
            
            // Stats Section
            statsSection(execution: execution)
            
            // Next Workout Section
            nextWorkoutSection(execution: execution)
            
            // Action Buttons
            actionButtons(execution: execution)
        }
        .padding(theme.spacing.l)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    theme.colors.accent.opacity(0.05),
                    theme.colors.success.opacity(0.03)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: theme.radius.l)
                .stroke(theme.colors.accent.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(theme.radius.l)
        .padding(.horizontal)
    }
    
    // MARK: - Program Header
    private func programHeader(execution: ProgramExecution) -> some View {
        VStack(spacing: theme.spacing.s) {
            HStack {
                Image(systemName: "dumbbell.fill")
                    .font(.title2)
                    .foregroundColor(theme.colors.accent)
                
                Text("training.program_dashboard.active_program".localized)
                    .font(theme.typography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.colors.textSecondary)
                    .tracking(1.2)
                
                Spacer()
                
                if execution.isPaused {
                    Image(systemName: "pause.circle.fill")
                        .font(.title2)
                        .foregroundColor(theme.colors.warning)
                }
            }
            
            Text(execution.program?.localizedName ?? "Unknown Program")
                .font(theme.typography.title2)
                .fontWeight(.bold)
                .foregroundColor(theme.colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }
    
    // MARK: - Progress Section
    private func progressSection(execution: ProgramExecution) -> some View {
        VStack(spacing: theme.spacing.m) {
            // Progress Bar
            VStack(spacing: theme.spacing.s) {
                HStack {
                    Text("\(TrainingKeys.ProgramCompletion.weekOf.localized) \(execution.currentWeek) \(TrainingKeys.Charts.of.localized) \(execution.program?.weeks ?? 0)")
                        .font(theme.typography.body)
                        .fontWeight(.medium)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Spacer()
                    
                    Text("\(Int(execution.progressPercentage * 100))%")
                        .font(theme.typography.body)
                        .fontWeight(.medium)
                        .foregroundColor(theme.colors.accent)
                }
                
                ProgressView(value: execution.progressPercentage)
                    .progressViewStyle(LinearProgressViewStyle(tint: theme.colors.accent))
                    .scaleEffect(x: 1, y: 3, anchor: .center)
                    .animation(.easeInOut(duration: 0.5), value: execution.progressPercentage)
            }
        }
    }
    
    // MARK: - Stats Section
    private func statsSection(execution: ProgramExecution) -> some View {
        HStack(spacing: theme.spacing.l) {
            statItem(
                icon: "checkmark.circle.fill",
                title: "Completed",
                value: "\(execution.completedWorkouts?.count ?? 0)/\(execution.program?.totalWorkouts ?? 0)"
            )
            
            Divider()
                .frame(height: 40)
            
            statItem(
                icon: "chart.line.uptrend.xyaxis",
                title: "Total Volume",
                value: UnitsFormatter.formatVolume(kg: totalVolume, system: unitSettings.unitSystem)
            )
            
            Divider()
                .frame(height: 40)
            
            statItem(
                icon: "trophy.fill",
                title: "PRs This Week",
                value: "\(prsThisWeek)"
            )
        }
        .padding(.vertical, theme.spacing.m)
    }
    
    private func statItem(icon: String, title: String, value: String) -> some View {
        VStack(spacing: theme.spacing.xs) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(theme.colors.accent)
            
            Text(value)
                .font(theme.typography.headline)
                .fontWeight(.bold)
                .foregroundColor(theme.colors.textPrimary)
            
            Text(title)
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Next Workout Section
    private func nextWorkoutSection(execution: ProgramExecution) -> some View {
        VStack(spacing: theme.spacing.m) {
            HStack {
                Image(systemName: "target")
                    .font(.title3)
                    .foregroundColor(theme.colors.success)
                
                Text("training.program_dashboard.next_workout".localized)
                    .font(theme.typography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.colors.textSecondary)
                    .tracking(1.0)
                
                Spacer()
            }
            
            if let currentWorkout = execution.currentWorkout {
                nextWorkoutCard(workout: currentWorkout)
            } else {
                completedProgramView
            }
        }
    }
    
    private func nextWorkoutCard(workout: LiftWorkout) -> some View {
        HStack(spacing: theme.spacing.m) {
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text(workout.localizedName)
                    .font(theme.typography.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                
                HStack(spacing: theme.spacing.m) {
                    Label("\(workout.exercises?.count ?? 0) exercises", systemImage: "list.bullet")
                    Label("\(workout.estimatedDuration ?? 45) min", systemImage: "clock")
                }
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right.circle.fill")
                .font(.title)
                .foregroundColor(theme.colors.accent)
        }
        .padding()
        .background(theme.colors.backgroundSecondary)
        .cornerRadius(theme.radius.m)
    }
    
    private var completedProgramView: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .font(.title)
                .foregroundColor(theme.colors.success)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(TrainingKeys.ProgramCompletion.programCompleted.localized)
                    .font(theme.typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                
                Text(TrainingKeys.ProgramCompletion.congratulations.localized)
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }
            
            Spacer()
        }
        .padding()
        .background(theme.colors.success.opacity(0.1))
        .cornerRadius(theme.radius.m)
    }
    
    // MARK: - Action Buttons
    private func actionButtons(execution: ProgramExecution) -> some View {
        VStack(spacing: theme.spacing.m) {
            // Primary Action Button
            if execution.isCompleted {
                completedProgramButton
            } else if execution.isPaused {
                resumeProgramButton
            } else {
                startWorkoutButton
            }
            
            // Secondary Actions
            secondaryActions(execution: execution)
        }
    }
    
    private var startWorkoutButton: some View {
        Button(action: onStartWorkout) {
            HStack(spacing: theme.spacing.m) {
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                
                Text("training.program_dashboard.start_workout".localized)
                    .font(theme.typography.headline)
                    .fontWeight(.bold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, theme.spacing.m)
            .background(theme.colors.accent)
            .cornerRadius(theme.radius.m)
        }
        .buttonStyle(PressableStyle())
    }
    
    private var resumeProgramButton: some View {
        Button(action: onStartWorkout) {
            HStack(spacing: theme.spacing.m) {
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                
                Text("training.program_dashboard.resume_program".localized)
                    .font(theme.typography.headline)
                    .fontWeight(.bold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, theme.spacing.m)
            .background(theme.colors.success)
            .cornerRadius(theme.radius.m)
        }
        .buttonStyle(PressableStyle())
    }
    
    private var completedProgramButton: some View {
        Button(action: { coordinator.navigateToProgramSelection() }) {
            HStack(spacing: theme.spacing.m) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                
                Text("training.program_dashboard.start_new_program".localized)
                    .font(theme.typography.headline)
                    .fontWeight(.bold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, theme.spacing.m)
            .background(theme.colors.accent)
            .cornerRadius(theme.radius.m)
        }
        .buttonStyle(PressableStyle())
    }
    
    private func secondaryActions(execution: ProgramExecution) -> some View {
        HStack(spacing: theme.spacing.m) {
            if !execution.isCompleted {
                Button(action: onPauseProgram) {
                    HStack(spacing: theme.spacing.s) {
                        Image(systemName: execution.isPaused ? "play.circle" : "pause.circle")
                            .font(.body)
                        Text(execution.isPaused ? "Resume" : "Pause")
                            .font(theme.typography.body)
                    }
                    .foregroundColor(theme.colors.textSecondary)
                    .padding(.vertical, theme.spacing.s)
                    .padding(.horizontal, theme.spacing.m)
                    .background(theme.colors.backgroundSecondary)
                    .cornerRadius(theme.radius.s)
                }
            }
            
            Button(action: onViewDetails) {
                HStack(spacing: theme.spacing.s) {
                    Image(systemName: "chart.bar.fill")
                        .font(.body)
                    Text("training.program_dashboard.details".localized)
                        .font(theme.typography.body)
                }
                .foregroundColor(theme.colors.textSecondary)
                .padding(.vertical, theme.spacing.s)
                .padding(.horizontal, theme.spacing.m)
                .background(theme.colors.backgroundSecondary)
                .cornerRadius(theme.radius.s)
            }
            
            Spacer()
        }
    }
    
    // MARK: - No Program Prompt
    private var noProgramPrompt: some View {
        VStack(spacing: theme.spacing.l) {
            Image(systemName: "dumbbell")
                .font(.system(size: 48))
                .foregroundColor(theme.colors.accent.opacity(0.6))
            
            VStack(spacing: theme.spacing.s) {
                Text(TrainingKeys.ProgramCompletion.readyToStart.localized)
                    .font(theme.typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textPrimary)
                
                Text(TrainingKeys.ProgramCompletion.chooseFromPrograms.localized)
                    .font(theme.typography.body)
                    .foregroundColor(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: { coordinator.navigateToProgramSelection() }) {
                HStack(spacing: theme.spacing.s) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                    Text(TrainingKeys.ProgramCompletion.browsePrograms.localized)
                        .font(theme.typography.headline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.vertical, theme.spacing.m)
                .padding(.horizontal, theme.spacing.xl)
                .background(theme.colors.accent)
                .cornerRadius(theme.radius.m)
            }
            .buttonStyle(PressableStyle())
        }
        .padding(theme.spacing.xl)
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.l)
        .padding(.horizontal)
    }
}

// MARK: - Preview
#Preview {
    ProgramDashboardView(
        execution: nil,
        onStartWorkout: {},
        onPauseProgram: {},
        onViewDetails: {}
    )
}