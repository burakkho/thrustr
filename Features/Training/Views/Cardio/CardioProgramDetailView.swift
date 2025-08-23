import SwiftUI
import SwiftData

struct CardioProgramDetailView: View {
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let program: CardioProgram
    let currentUser: User?
    
    @State private var showingStartConfirmation = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: theme.spacing.xl) {
                    // Header Info
                    headerSection
                    
                    // Program Overview
                    overviewSection
                    
                    // Weekly Breakdown
                    if !program.workouts.isEmpty {
                        weeklyBreakdownSection
                    }
                    
                    // Start Program Button
                    startProgramSection
                }
                .padding(.vertical, theme.spacing.m)
            }
            .navigationTitle(program.localizedName)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundColor(theme.colors.accent)
                }
            }
        }
        .confirmationDialog(
            "Start Program", 
            isPresented: $showingStartConfirmation,
            titleVisibility: .visible
        ) {
            Button("Start \(program.localizedName)") {
                startProgram()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you ready to begin your \(program.weeks)-week journey? This will create a new program execution to track your progress.")
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: theme.spacing.m) {
            // Program Icon
            ZStack {
                Circle()
                    .fill(Color.cardioColor.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Image(systemName: program.categoryIcon)
                    .font(.largeTitle)
                    .foregroundColor(.cardioColor)
            }
            
            VStack(spacing: theme.spacing.s) {
                Text(program.localizedName)
                    .font(theme.typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(program.localizedDescription)
                    .font(theme.typography.body)
                    .foregroundColor(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
        }
        .padding(.horizontal)
    }
    
    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            Text("Program Overview")
                .font(theme.typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(theme.colors.textPrimary)
                .padding(.horizontal)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: theme.spacing.m) {
                overviewCard(
                    icon: "calendar",
                    title: "Duration",
                    value: "\(program.weeks) Weeks",
                    color: theme.colors.accent
                )
                
                overviewCard(
                    icon: "clock",
                    title: "Frequency",
                    value: "\(program.daysPerWeek) days/week",
                    color: theme.colors.success
                )
                
                overviewCard(
                    icon: program.difficultyIcon,
                    title: "Level",
                    value: program.level.capitalized,
                    color: theme.colors.warning
                )
                
                overviewCard(
                    icon: program.categoryIcon,
                    title: "Type",
                    value: program.category.capitalized,
                    color: .cardioColor
                )
            }
            .padding(.horizontal)
        }
    }
    
    private func overviewCard(icon: String, title: String, value: String, color: Color) -> some View {
        VStack(spacing: theme.spacing.s) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            VStack(spacing: 2) {
                Text(value)
                    .font(theme.typography.body)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                
                Text(title)
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(theme.spacing.m)
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.m)
    }
    
    private var weeklyBreakdownSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            Text("Weekly Breakdown")
                .font(theme.typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(theme.colors.textPrimary)
                .padding(.horizontal)
            
            LazyVStack(spacing: theme.spacing.s) {
                ForEach(Array(program.workouts.enumerated()), id: \.offset) { index, workout in
                    weekCard(week: index + 1, workout: workout)
                        .padding(.horizontal)
                }
            }
        }
    }
    
    private func weekCard(week: Int, workout: CardioWorkout) -> some View {
        HStack(spacing: theme.spacing.m) {
            // Week number
            ZStack {
                Circle()
                    .fill(Color.cardioColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Text("\(week)")
                    .font(theme.typography.body)
                    .fontWeight(.bold)
                    .foregroundColor(.cardioColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.localizedName)
                    .font(theme.typography.body)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                
                Text(workout.localizedDescription)
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textSecondary)
                    .lineLimit(2)
                
                if let duration = workout.formattedTargetTime {
                    Label(duration, systemImage: "clock")
                        .font(.caption2)
                        .foregroundColor(.cardioColor)
                }
            }
            
            Spacer()
        }
        .padding(theme.spacing.m)
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.m)
    }
    
    private var startProgramSection: some View {
        VStack(spacing: theme.spacing.m) {
            if program.totalDistance != nil {
                Text("Goal: Run \(String(format: "%.0fK", (program.totalDistance ?? 0) / 1000)) continuously")
                    .font(theme.typography.body)
                    .foregroundColor(.cardioColor)
                    .fontWeight(.medium)
            }
            
            Button(action: { showingStartConfirmation = true }) {
                HStack {
                    Image(systemName: "play.circle.fill")
                        .font(.title3)
                    Text("Start Program")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.cardioColor)
                .foregroundColor(.white)
                .cornerRadius(theme.radius.m)
            }
        }
        .padding(.horizontal)
    }
    
    private func startProgram() {
        guard let user = currentUser else { return }
        
        let execution = CardioProgramExecution(program: program, user: user)
        modelContext.insert(execution)
        
        do {
            try modelContext.save()
            dismiss()
            Logger.info("Started cardio program: \(program.localizedName)")
        } catch {
            Logger.error("Failed to start cardio program: \(error)")
        }
    }
}

#Preview {
    let program = CardioProgram(
        name: "Couch to 5K",
        nameEN: "Couch to 5K",
        nameTR: "Kanepeden 5K'ya",
        description: "Progressive running program for beginners",
        descriptionEN: "Progressive running program for beginners",
        descriptionTR: "Yeni başlayanlar için ilerleyici koşu programı",
        weeks: 9,
        daysPerWeek: 3,
        level: "beginner",
        category: "running"
    )
    
    CardioProgramDetailView(program: program, currentUser: nil)
        .modelContainer(for: [
            CardioProgram.self,
            CardioProgramExecution.self,
            CardioWorkout.self,
            User.self
        ], inMemory: true)
}