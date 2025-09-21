import SwiftUI
import SwiftData

struct LiftProgramsSection: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(TrainingCoordinator.self) private var coordinator
    @Query private var programs: [LiftProgram]
    @Query(filter: #Predicate<ProgramExecution> { !$0.isCompleted })
    private var activeProgramExecutions: [ProgramExecution]
    @Query private var users: [User]

    @State private var selectedProgram: LiftProgram?
    @State private var selectedWorkout: LiftWorkout?
    @State private var searchText = ""

    private var currentUser: User? {
        users.first
    }
    
    private var filteredPrograms: [LiftProgram] {
        let featured = programs
        if searchText.isEmpty {
            return featured
        }
        return featured.filter { program in
            program.localizedName.localizedCaseInsensitiveContains(searchText) ||
            program.localizedDescription.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    
    var body: some View {
        ScrollView {
            VStack(spacing: theme.spacing.xl) {
                // Search Bar
                if !programs.isEmpty {
                    searchBar
                }
                
                // Active Program
                if let activeExecution = activeProgramExecutions.first {
                    activeProgramCard(activeExecution)
                }
                
                // Programs
                if !filteredPrograms.isEmpty {
                    programsSection
                }
                
                
                // Empty State
                if programs.isEmpty {
                    EmptyStateCard(
                        icon: "rectangle.3.group",
                        title: "training.lift.noPrograms".localized,
                        message: "training.lift.noProgramsMessage".localized,
                        primaryAction: nil
                    )
                    .padding(.top, 50)
                }
            }
            .padding(.vertical, theme.spacing.m)
        }
        .sheet(item: $selectedProgram) { program in
            ProgramDetailView(program: program)
        }
        .fullScreenCover(item: $selectedWorkout) { workout in
            LiftSessionView(workout: workout, programExecution: nil)
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(theme.colors.textSecondary)
            TextField("Search", text: $searchText)
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
    
    private func activeProgramCard(_ execution: ProgramExecution) -> some View {
        VStack(spacing: theme.spacing.m) {
            HStack {
                Text("training.lift.activeProgram".localized)
                    .font(theme.typography.headline)
                    .foregroundColor(theme.colors.textPrimary)
                Spacer()
            }
            .padding(.horizontal)
            
            UnifiedWorkoutCard(
                title: execution.program?.localizedName ?? "Unknown Program",
                subtitle: "Week \(execution.currentWeek) • Day \(execution.currentDay)",
                description: execution.currentWorkout?.localizedName,
                primaryStats: [
                    WorkoutStat(
                        label: "training.lift.stats.progress".localized,
                        value: "\(Int(execution.progressPercentage * 100))%",
                        icon: "chart.bar.fill"
                    ),
                    WorkoutStat(
                        label: "training.lift.stats.streak".localized,
                        value: "\(execution.currentStreak)",
                        icon: "flame.fill"
                    ),
                    WorkoutStat(
                        label: "training.lift.stats.remaining".localized,
                        value: "\(execution.remainingWeeks) weeks",
                        icon: "calendar"
                    )
                ],
                isFavorite: execution.program?.isFavorite ?? false,
                cardStyle: .hero,
                primaryAction: { selectedProgram = execution.program },
                secondaryAction: { startCurrentWorkout(execution: execution) }
            )
            .padding(.horizontal)
        }
    }
    
    private var programsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            Text("training.lift.programs".localized)
                .font(theme.typography.headline)
                .foregroundColor(theme.colors.textPrimary)
                .padding(.horizontal)
            
            ForEach(filteredPrograms) { program in
                UnifiedWorkoutCard(
                    title: program.localizedName,
                    subtitle: "\(program.weeks) weeks • \(program.daysPerWeek) days/week",
                    description: program.localizedDescription,
                    secondaryInfo: [program.level.capitalized, program.category.capitalized],
                    isFavorite: program.isFavorite,
                    cardStyle: .detailed,
                    primaryAction: { selectedProgram = program }
                )
                .padding(.horizontal)
            }
        }
    }
    

    private func startCurrentWorkout(execution: ProgramExecution) {
        guard let user = currentUser,
              let currentWorkout = execution.currentWorkout else {
            Logger.error("Missing user or current workout for program execution")
            return
        }

        // Create a new LiftSession for the current workout
        let liftSession = LiftSession(
            workout: currentWorkout,
            user: user,
            programExecution: execution
        )

        do {
            modelContext.insert(liftSession)
            try modelContext.save()

            // Start the lift session
            selectedWorkout = currentWorkout

            Logger.success("Started workout: \(currentWorkout.localizedName)")
        } catch {
            Logger.error("Failed to start workout: \(error)")
        }
    }
}