import SwiftUI
import SwiftData

// MARK: - Set Tracking View
struct SetTrackingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let exercise: Exercise
    let workoutPart: WorkoutPart
    
    @State private var sets: [SetData] = []
    @State private var showingRestTimer = false
    @State private var restDuration = 60 // seconds
    @State private var notes = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Exercise header
                ExerciseHeader(exercise: exercise)
                
                // Sets table
                ScrollView {
                    VStack(spacing: 16) {
                        // Table header
                        SetTableHeader(exercise: exercise)
                        
                        // Sets list
                        ForEach(sets.indices, id: \.self) { index in
                            SetRow(
                                setData: $sets[index],
                                setNumber: index + 1,
                                exercise: exercise,
                                onComplete: {
                                    completeSet(at: index)
                                }
                            )
                        }
                        
                        // Add set button
                        AddSetButton {
                            addNewSet()
                        }
                        
                        // Notes section
                        NotesSection(notes: $notes)
                    }
                    .padding()
                }
                
                // Bottom action bar
                SetTrackingActionBar(
                    onRestTimer: {
                        showingRestTimer = true
                    },
                    onFinish: {
                        finishExercise()
                    },
                    hasCompletedSets: sets.contains { $0.isCompleted }
                )
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizationKeys.Training.Set.back.localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizationKeys.Training.Set.save.localized) {
                        finishExercise()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingRestTimer) {
                RestTimerView(duration: restDuration)
            }
        }
        .onAppear {
            setupInitialSets()
        }
    }
    
    private func setupInitialSets() {
        if sets.isEmpty {
            // Add 3 empty sets to start
            for _ in 0..<3 {
                sets.append(SetData())
            }
        }
    }
    
    private func addNewSet() {
        let newSet = SetData()
        
        // Copy previous set values as starting point
        if let lastSet = sets.last {
            newSet.weight = lastSet.weight
            newSet.reps = lastSet.reps
            newSet.duration = lastSet.duration
            newSet.distance = lastSet.distance
        }
        
        sets.append(newSet)
    }
    
    private func completeSet(at index: Int) {
        sets[index].isCompleted = true
        
        // Auto-add new set if this was the last one
        if index == sets.count - 1 {
            addNewSet()
        }
    }
    
    private func finishExercise() {
        // Save completed sets to Core Data
        let completedSets = sets.filter { $0.isCompleted && $0.hasValidData }
        
        for (index, setData) in completedSets.enumerated() {
            let exerciseSet = ExerciseSet(
                setNumber: Int16(index + 1),
                weight: setData.weight,
                reps: setData.reps != 0 ? Int16(setData.reps) : nil,
                duration: setData.duration != 0 ? Int32(setData.duration) : nil,
                distance: setData.distance != 0 ? setData.distance : nil,
                rpe: setData.rpe != 0 ? Int16(setData.rpe) : nil,
                isCompleted: true
            )
            
            exerciseSet.exercise = exercise
            exerciseSet.workoutPart = workoutPart
            
            modelContext.insert(exerciseSet)
        }
        
        // Save notes if any
        if !notes.isEmpty {
            if workoutPart.notes?.isEmpty ?? true {
                workoutPart.notes = notes
            } else {
                workoutPart.notes = (workoutPart.notes ?? "") + "\n\(exercise.nameTR): \(notes)"
            }
        }
        
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Set Data Model
class SetData: ObservableObject {
    @Published var weight: Double = 0
    @Published var reps: Int = 0
    @Published var duration: Int = 0 // seconds
    @Published var distance: Double = 0 // meters
    @Published var rpe: Int = 0 // 1-10 scale
    @Published var isCompleted: Bool = false
    
    var hasValidData: Bool {
        weight > 0 || reps > 0 || duration > 0 || distance > 0
    }
}

// MARK: - Exercise Header
struct ExerciseHeader: View {
    let exercise: Exercise
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.nameTR)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if !exercise.nameEN.isEmpty && exercise.nameEN != exercise.nameTR {
                        Text(exercise.nameEN)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Exercise category icon
                let category = ExerciseCategory(rawValue: exercise.category) ?? .other
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundColor(category.color)
            }
            .padding(.horizontal)
            
            if !exercise.equipment.isEmpty {
                HStack {
                    Text(LocalizationKeys.Training.Set.equipment.localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(exercise.equipment.replacingOccurrences(of: ",", with: ", "))
                        .font(.caption)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
            
            Divider()
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Set Table Header
struct SetTableHeader: View {
    let exercise: Exercise
    
    var body: some View {
        HStack(spacing: 0) {
            // Set number
            Text(LocalizationKeys.Training.Set.Header.set.localized)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .frame(width: 40)
            
            if exercise.supportsWeight {
                Text(LocalizationKeys.Training.Set.Header.weight.localized)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
            
            if exercise.supportsReps {
                Text(LocalizationKeys.Training.Set.Header.reps.localized)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
            
            if exercise.supportsTime {
                Text(LocalizationKeys.Training.Set.Header.time.localized)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
            
            if exercise.supportsDistance {
                Text(LocalizationKeys.Training.Set.Header.distance.localized)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
            
            // RPE
            Text(LocalizationKeys.Training.Set.Header.rpe.localized)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .frame(width: 50)
            
            // Complete button space
            Text("")
                .frame(width: 60)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Set Row
struct SetRow: View {
    @Binding var setData: SetData
    let setNumber: Int
    let exercise: Exercise
    let onComplete: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            // Set number
            Text("\(setNumber)")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(setData.isCompleted ? .green : .primary)
                .frame(width: 40)
            
            if exercise.supportsWeight {
                NumberInputField(
                    value: $setData.weight,
                    placeholder: LocalizationKeys.Training.Set.kg.localized,
                    isEnabled: !setData.isCompleted
                )
                .frame(maxWidth: .infinity)
            }
            
            if exercise.supportsReps {
                NumberInputField(
                    value: Binding(
                        get: { Double(setData.reps) },
                        set: { setData.reps = Int($0) }
                    ),
                    placeholder: LocalizationKeys.Training.Set.reps.localized,
                    isEnabled: !setData.isCompleted,
                    allowDecimals: false
                )
                .frame(maxWidth: .infinity)
            }
            
            if exercise.supportsTime {
                TimeInputField(
                    seconds: $setData.duration,
                    isEnabled: !setData.isCompleted
                )
                .frame(maxWidth: .infinity)
            }
            
            if exercise.supportsDistance {
                NumberInputField(
                    value: $setData.distance,
                    placeholder: LocalizationKeys.Training.Set.meters.localized,
                    isEnabled: !setData.isCompleted
                )
                .frame(maxWidth: .infinity)
            }
            
            // RPE picker
            RPEPicker(rpe: $setData.rpe, isEnabled: !setData.isCompleted)
                .frame(width: 50)
            
            // Complete button
            Button(action: onComplete) {
                Image(systemName: setData.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(setData.isCompleted ? .green : .gray)
            }
            .frame(width: 60)
            .disabled(setData.isCompleted || !setData.hasValidData)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(setData.isCompleted ? Color.green.opacity(0.1) : Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(setData.isCompleted ? Color.green : Color(.systemGray4), lineWidth: 1)
        )
    }
}

// MARK: - Number Input Field
struct NumberInputField: View {
    @Binding var value: Double
    let placeholder: String
    let isEnabled: Bool
    var allowDecimals: Bool = true
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        TextField(placeholder, value: $value, format: allowDecimals ? .number.precision(.fractionLength(0...1)) : .number.precision(.fractionLength(0)))
            .textFieldStyle(PlainTextFieldStyle())
            .multilineTextAlignment(.center)
            .font(.headline)
            .foregroundColor(isEnabled ? .primary : .secondary)
            .disabled(!isEnabled)
            .focused($isFocused)
            .keyboardType(allowDecimals ? .decimalPad : .numberPad)
            .onTapGesture {
                if isEnabled {
                    isFocused = true
                }
            }
    }
}

// MARK: - Time Input Field
struct TimeInputField: View {
    @Binding var seconds: Int
    let isEnabled: Bool
    
    @State private var minutes: Int = 0
    @State private var secs: Int = 0
    
    var body: some View {
        HStack(spacing: 2) {
            TextField("0", value: $minutes, format: .number)
                .textFieldStyle(PlainTextFieldStyle())
                .multilineTextAlignment(.center)
                .frame(width: 30)
                .disabled(!isEnabled)
                .keyboardType(.numberPad)
            
            Text(":")
                .font(.headline)
            
            TextField("00", value: $secs, format: .number.precision(.integerLength(2)))
                .textFieldStyle(PlainTextFieldStyle())
                .multilineTextAlignment(.center)
                .frame(width: 30)
                .disabled(!isEnabled)
                .keyboardType(.numberPad)
        }
        .font(.headline)
        .foregroundColor(isEnabled ? .primary : .secondary)
        .onAppear {
            updateFromSeconds()
        }
        .onChange(of: minutes) {
            updateSeconds()
        }
        .onChange(of: secs) {
            updateSeconds()
        }
        .onChange(of: seconds) {
            updateFromSeconds()
        }
    }
    
    private func updateSeconds() {
        seconds = minutes * 60 + secs
    }
    
    private func updateFromSeconds() {
        minutes = seconds / 60
        secs = seconds % 60
    }
}

// MARK: - RPE Picker
struct RPEPicker: View {
    @Binding var rpe: Int
    let isEnabled: Bool
    
    var body: some View {
        Menu {
            ForEach(0...10, id: \.self) { value in
                Button("\(value)") {
                    rpe = value
                }
            }
        } label: {
            Text(rpe == 0 ? "-" : "\(rpe)")
                .font(.headline)
                .foregroundColor(isEnabled ? .primary : .secondary)
                .frame(maxWidth: .infinity)
        }
        .disabled(!isEnabled)
    }
}

// MARK: - Add Set Button
struct AddSetButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.blue)
                Text(LocalizationKeys.Training.Set.addSet.localized)
                    .fontWeight(.medium)
                Spacer()
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
        .foregroundColor(.blue)
    }
}

// MARK: - Notes Section
struct NotesSection: View {
    @Binding var notes: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizationKeys.Training.Set.notes.localized)
                .font(.headline)
                .foregroundColor(.secondary)
            
            TextField(LocalizationKeys.Training.Set.notesPlaceholder.localized, text: $notes, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(3...6)
        }
    }
}

// MARK: - Set Tracking Action Bar
struct SetTrackingActionBar: View {
    let onRestTimer: () -> Void
    let onFinish: () -> Void
    let hasCompletedSets: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 12) {
                // Rest timer button
                Button(LocalizationKeys.Training.Set.rest.localized) {
                    onRestTimer()
                }
                .font(.subheadline)
                .foregroundColor(.orange)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
                
                Spacer()
                
                // Finish button
                Button(LocalizationKeys.Training.Set.finishExercise.localized) {
                    onFinish()
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(hasCompletedSets ? Color.green : Color.gray)
                .cornerRadius(8)
                .disabled(!hasCompletedSets)
            }
            .padding()
        }
        .background(Color(.systemBackground))
    }
}

#Preview {
    let exercise = Exercise(
        nameEN: "Bench Press",
        nameTR: "Göğüs Presi",
        category: "push",
        equipment: "barbell,bench"
    )
    exercise.supportsWeight = true
    exercise.supportsReps = true
    
    let workoutPart = WorkoutPart(name: "Strength", type: .strength, orderIndex: 1)
    
    return SetTrackingView(exercise: exercise, workoutPart: workoutPart)
        .modelContainer(for: [Exercise.self, ExerciseSet.self], inMemory: true)
}
