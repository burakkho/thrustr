import SwiftUI
import SwiftData

struct ProgramDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]

    let program: LiftProgram
    @State private var showingOneRMSetup = false
    @State private var startingWorkout: LiftWorkout?

    private var currentUser: User? {
        users.first
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: theme.spacing.l) {
                    programHeaderSection
                    weekOverviewSection
                }
                .padding()
            }
            .navigationTitle(CommonKeys.Navigation.programDetails.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
        }
        .sheet(isPresented: $showingOneRMSetup) {
            oneRMSetupSheet
        }
        .fullScreenCover(item: $startingWorkout) { workout in
            LiftSessionView(workout: workout, programExecution: nil)
        }
    }
    
    private var programHeaderSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            Text(program.localizedName)
                .font(theme.typography.title2)
                .fontWeight(.bold)
            
            Text(program.localizedDescription)
                .font(theme.typography.body)
                .foregroundColor(theme.colors.textSecondary)
            
            programStatsRow
        }
        .padding()
        .background(theme.colors.backgroundSecondary)
        .cornerRadius(theme.radius.m)
    }
    
    private var programStatsRow: some View {
        HStack(spacing: theme.spacing.m) {
            Label("\(program.weeks) weeks", systemImage: "calendar")
            Label("\(program.daysPerWeek) days/week", systemImage: "clock")
            Label(program.level.capitalized, systemImage: "chart.bar")
        }
        .font(theme.typography.caption)
        .foregroundColor(theme.colors.textSecondary)
    }
    
    private var weekOverviewSection: some View {
        ForEach(1...program.weeks, id: \.self) { week in
            weekView(week: week)
        }
    }
    
    private func weekView(week: Int) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            Text("Week \(week)")
                .font(theme.typography.headline)
                .fontWeight(.semibold)
            
            ForEach(Array((program.workouts ?? []).prefix(program.daysPerWeek)), id: \.id) { workout in
                workoutRow(workout: workout)
            }
        }
    }
    
    private func workoutRow(workout: LiftWorkout) -> some View {
        HStack {
            Text(workout.localizedName)
                .font(theme.typography.body)
            Spacer()
            Text("\(workout.exercises?.count ?? 0) exercises")
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textSecondary)
        }
        .padding()
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.s)
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(CommonKeys.Onboarding.Common.close.localized) { 
                dismiss() 
            }
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(TrainingKeys.Common.startProgram.localized) {
                checkAndStartProgram()
            }
            .foregroundColor(theme.colors.accent)
        }
    }
    
    private var oneRMSetupSheet: some View {
        OneRMSetupView(program: program) { user in
            startProgramWithUser(user)
        }
    }
    
    private func checkAndStartProgram() {
        guard let user = currentUser else {
            Logger.error("No user found")
            return
        }
        
        // Check if user has 1RM data for StrongLifts exercises
        let hasRequiredOneRMs = user.squatOneRM != nil && 
                                user.benchPressOneRM != nil && 
                                user.deadliftOneRM != nil && 
                                user.overheadPressOneRM != nil
        
        if hasRequiredOneRMs {
            // User has 1RM data, start program directly
            startProgramWithUser(user)
        } else {
            // User needs 1RM setup first
            showingOneRMSetup = true
        }
    }
    
    private func startProgramWithUser(_ user: User) {
        let execution = ProgramExecution(program: program, user: user)
        modelContext.insert(execution)
        do {
            try modelContext.save()

            // Log program start activity
            Task { @MainActor in
                ActivityLoggerService.shared.setModelContext(modelContext)
                ActivityLoggerService.shared.logProgramStarted(
                    programName: program.localizedName,
                    weeks: program.weeks,
                    daysPerWeek: program.daysPerWeek,
                    user: user
                )
            }

            Logger.success("Program started successfully")

            // Start the first workout immediately
            if let firstWorkout = execution.currentWorkout {
                // Create LiftSession for the first workout
                let liftSession = LiftSession(
                    workout: firstWorkout,
                    user: user,
                    programExecution: execution
                )
                modelContext.insert(liftSession)
                try modelContext.save()

                // Navigate to the workout
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    startingWorkout = firstWorkout
                }
            } else {
                dismiss()
            }
        } catch {
            Logger.error("Failed to start program: \(error)")
        }
    }
}