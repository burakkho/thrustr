import SwiftUI
import SwiftData

struct ProgramDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    
    let program: LiftProgram
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: theme.spacing.l) {
                    // Program Header
                    VStack(alignment: .leading, spacing: theme.spacing.m) {
                        Text(program.localizedName)
                            .font(theme.typography.title2)
                            .fontWeight(.bold)
                        
                        Text(program.localizedDescription)
                            .font(theme.typography.body)
                            .foregroundColor(theme.colors.textSecondary)
                        
                        HStack(spacing: theme.spacing.m) {
                            Label("\(program.weeks) weeks", systemImage: "calendar")
                            Label("\(program.daysPerWeek) days/week", systemImage: "clock")
                            Label(program.level.capitalized, systemImage: "chart.bar")
                        }
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                    }
                    .padding()
                    .background(theme.colors.backgroundSecondary)
                    .cornerRadius(theme.radius.m)
                    
                    // Week Overview
                    ForEach(1...program.weeks, id: \.self) { week in
                        VStack(alignment: .leading, spacing: theme.spacing.m) {
                            Text("Week \(week)")
                                .font(theme.typography.headline)
                                .fontWeight(.semibold)
                            
                            ForEach(program.workouts.prefix(program.daysPerWeek), id: \.id) { workout in
                                HStack {
                                    Text(workout.localizedName)
                                        .font(theme.typography.body)
                                    Spacer()
                                    Text("\(workout.exercises.count) exercises")
                                        .font(theme.typography.caption)
                                        .foregroundColor(theme.colors.textSecondary)
                                }
                                .padding()
                                .background(theme.colors.cardBackground)
                                .cornerRadius(theme.radius.s)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Program Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Start Program") {
                        startProgram()
                    }
                    .foregroundColor(theme.colors.accent)
                }
            }
        }
    }
    
    private func startProgram() {
        let execution = ProgramExecution(program: program)
        modelContext.insert(execution)
        do {
            try modelContext.save()
            dismiss()
        } catch {
            Logger.error("Failed to start program: \(error)")
        }
    }
}