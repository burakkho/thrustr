import SwiftUI
import SwiftData

struct LiftResultEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Query private var user: [User]
    
    let lift: Lift
    
    // Exercise tracking
    @State private var exerciseResults: [UUID: ExerciseResult] = [:]
    @State private var totalWeight: Double = 0
    @State private var bestSetWeight: Double = 0
    @State private var notes: String = ""
    @State private var showingSaveConfirmation = false
    
    private var currentUser: User? {
        user.first
    }
    
    struct ExerciseResult {
        var sets: [SetResult] = []
        
        struct SetResult {
            var weight: Double = 0
            var reps: Int = 0
            var isCompleted: Bool = false
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: theme.spacing.l) {
                    // Header
                    VStack(alignment: .leading, spacing: theme.spacing.s) {
                        Text(lift.localizedName)
                            .font(theme.typography.title2)
                            .fontWeight(.bold)
                            .foregroundColor(theme.colors.textPrimary)
                        
                        Text("Log your workout results")
                            .font(theme.typography.body)
                            .foregroundColor(theme.colors.textSecondary)
                        
                        // Show last PR if exists
                        if let pr = lift.personalRecord {
                            HStack {
                                Image(systemName: "trophy.fill")
                                    .foregroundColor(theme.colors.warning)
                                Text("Current PR: \(Int(pr.bestSet ?? 0))kg")
                                    .font(theme.typography.caption)
                                    .foregroundColor(theme.colors.textSecondary)
                            }
                            .padding(theme.spacing.s)
                            .background(theme.colors.warning.opacity(0.1))
                            .cornerRadius(theme.radius.s)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle()
                    
                    // Exercise Entry Cards
                    ForEach(lift.exercises.sorted(by: { $0.orderIndex < $1.orderIndex }), id: \.id) { exercise in
                        ExerciseEntryCard(
                            exercise: exercise,
                            lift: lift,
                            result: Binding(
                                get: { exerciseResults[exercise.id] ?? ExerciseResult() },
                                set: { exerciseResults[exercise.id] = $0 }
                            ),
                            onUpdate: updateTotals
                        )
                    }
                    
                    // Notes Section
                    VStack(alignment: .leading, spacing: theme.spacing.s) {
                        Text("Notes (Optional)")
                            .font(theme.typography.headline)
                            .foregroundColor(theme.colors.textPrimary)
                        
                        TextEditor(text: $notes)
                            .frame(minHeight: 80)
                            .padding(theme.spacing.s)
                            .background(theme.colors.backgroundSecondary)
                            .cornerRadius(theme.radius.m)
                    }
                    .padding(.horizontal)
                    
                    // Summary
                    VStack(spacing: theme.spacing.m) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Total Volume")
                                    .font(theme.typography.caption)
                                    .foregroundColor(theme.colors.textSecondary)
                                Text("\(Int(totalWeight))kg")
                                    .font(theme.typography.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(theme.colors.textPrimary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("Best Set")
                                    .font(theme.typography.caption)
                                    .foregroundColor(theme.colors.textSecondary)
                                Text("\(Int(bestSetWeight))kg")
                                    .font(theme.typography.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(theme.colors.textPrimary)
                            }
                        }
                        .padding()
                        .background(theme.colors.backgroundSecondary)
                        .cornerRadius(theme.radius.m)
                        
                        // Save Button
                        Button(action: saveResult) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Save Result")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(theme.colors.success)
                            .foregroundColor(.white)
                            .cornerRadius(theme.radius.m)
                        }
                        .disabled(totalWeight == 0)
                    }
                    .padding()
                }
            }
            .navigationTitle("Log Lift Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Result Saved!", isPresented: $showingSaveConfirmation) {
                Button("OK") { dismiss() }
            } message: {
                if bestSetWeight > (lift.personalRecord?.bestSet ?? 0) {
                    Text("Congratulations! You've set a new PR: \(Int(bestSetWeight))kg! 🎉")
                } else {
                    Text("Your workout has been recorded successfully.")
                }
            }
        }
        .onAppear {
            initializeExerciseResults()
        }
    }
    
    private func initializeExerciseResults() {
        for exercise in lift.exercises {
            var result = ExerciseResult()
            for _ in 0..<lift.sets {
                result.sets.append(ExerciseResult.SetResult(
                    weight: exercise.targetWeight ?? 0,
                    reps: lift.reps,
                    isCompleted: false
                ))
            }
            exerciseResults[exercise.id] = result
        }
        updateTotals()
    }
    
    private func updateTotals() {
        var total: Double = 0
        var bestSet: Double = 0
        
        for result in exerciseResults.values {
            for set in result.sets where set.isCompleted {
                let setVolume = set.weight * Double(set.reps)
                total += setVolume
                bestSet = max(bestSet, set.weight)
            }
        }
        
        totalWeight = total
        bestSetWeight = bestSet
    }
    
    private func saveResult() {
        let result = LiftResult(
            totalWeight: totalWeight,
            bestSet: bestSetWeight,
            totalReps: calculateTotalReps(),
            totalSets: calculateCompletedSets(),
            notes: notes.isEmpty ? nil : notes
        )
        
        result.lift = lift
        result.user = currentUser
        
        modelContext.insert(result)
        try? modelContext.save()
        
        showingSaveConfirmation = true
    }
    
    private func calculateTotalReps() -> Int {
        var total = 0
        for result in exerciseResults.values {
            for set in result.sets where set.isCompleted {
                total += set.reps
            }
        }
        return total
    }
    
    private func calculateCompletedSets() -> Int {
        var total = 0
        for result in exerciseResults.values {
            total += result.sets.filter { $0.isCompleted }.count
        }
        return total
    }
}

// MARK: - Exercise Entry Card
struct ExerciseEntryCard: View {
    @Environment(\.theme) private var theme
    let exercise: LiftExercise
    let lift: Lift
    @Binding var result: LiftResultEntryView.ExerciseResult
    let onUpdate: () -> Void
    
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            // Header
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(exercise.exerciseName)
                            .font(theme.typography.headline)
                            .foregroundColor(theme.colors.textPrimary)
                        Text("\(lift.sets) sets × \(lift.reps) reps")
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                // Set Entries
                ForEach(Array(result.sets.enumerated()), id: \.offset) { index, _ in
                    LiftSetEntryRow(
                        setNumber: index + 1,
                        set: Binding(
                            get: { result.sets[index] },
                            set: { 
                                result.sets[index] = $0
                                onUpdate()
                            }
                        )
                    )
                }
            }
        }
        .padding()
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.m)
        .padding(.horizontal)
    }
}

// MARK: - Set Entry Row
struct LiftSetEntryRow: View {
    @Environment(\.theme) private var theme
    let setNumber: Int
    @Binding var set: LiftResultEntryView.ExerciseResult.SetResult
    
    @State private var weightText: String = ""
    @State private var repsText: String = ""
    
    var body: some View {
        HStack(spacing: theme.spacing.m) {
            // Set Number
            Text("Set \(setNumber)")
                .font(theme.typography.body)
                .foregroundColor(theme.colors.textSecondary)
                .frame(width: 50, alignment: .leading)
            
            // Weight Input
            HStack(spacing: 4) {
                TextField("0", text: $weightText)
                    .textFieldStyle(.plain)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 60)
                    .padding(theme.spacing.s)
                    .background(theme.colors.backgroundSecondary)
                    .cornerRadius(theme.radius.s)
                    .onChange(of: weightText) { _, newValue in
                        set.weight = Double(newValue) ?? 0
                    }
                Text("kg")
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }
            
            Text("×")
                .foregroundColor(theme.colors.textSecondary)
            
            // Reps Input
            HStack(spacing: 4) {
                TextField("0", text: $repsText)
                    .textFieldStyle(.plain)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 50)
                    .padding(theme.spacing.s)
                    .background(theme.colors.backgroundSecondary)
                    .cornerRadius(theme.radius.s)
                    .onChange(of: repsText) { _, newValue in
                        set.reps = Int(newValue) ?? 0
                    }
                Text("reps")
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }
            
            Spacer()
            
            // Complete Toggle
            Button(action: {
                set.isCompleted.toggle()
            }) {
                Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(set.isCompleted ? theme.colors.success : theme.colors.textSecondary)
            }
        }
        .onAppear {
            weightText = set.weight > 0 ? String(format: "%.0f", set.weight) : ""
            repsText = set.reps > 0 ? "\(set.reps)" : ""
        }
    }
}

// MARK: - Preview
#Preview {
    LiftResultEntryView(lift: Lift(
        name: "StrongLifts 5x5 A",
        sets: 5,
        reps: 5
    ))
    .modelContainer(for: [Lift.self], inMemory: true)
}