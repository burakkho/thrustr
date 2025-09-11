import SwiftUI
import SwiftData

struct LiftProgramsSection: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Query private var programs: [LiftProgram]
    @Query(filter: #Predicate<ProgramExecution> { !$0.isCompleted })
    private var activeProgramExecutions: [ProgramExecution]
    
    @State private var selectedProgram: LiftProgram?
    @State private var searchText = ""
    
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
        // Implementation for starting workout
        Logger.info("Starting workout for program: \(execution.program?.localizedName ?? "Unknown")")
    }
}