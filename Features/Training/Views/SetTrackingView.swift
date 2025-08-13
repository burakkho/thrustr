// MARK: - Reorderable list for sets
private struct ReorderSetsList: View {
    let exercise: Exercise
    @Binding var sets: [SetData]
    @Environment(\.theme) private var theme

    var body: some View {
        List {
            Section(header:
                        HStack {
                            Text(LocalizationKeys.Training.Set.Header.set.localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            if exercise.supportsWeight { Text(LocalizationKeys.Training.Set.Header.weight.localized).font(.caption).foregroundColor(.secondary) }
                            if exercise.supportsReps { Text(LocalizationKeys.Training.Set.Header.reps.localized).font(.caption).foregroundColor(.secondary) }
                            if exercise.supportsTime { Text(LocalizationKeys.Training.Set.Header.time.localized).font(.caption).foregroundColor(.secondary) }
                            if exercise.supportsDistance { Text(LocalizationKeys.Training.Set.Header.distance.localized).font(.caption).foregroundColor(.secondary) }
                        }
            ) {
                ForEach(Array(sets.enumerated()), id: \.element.id) { (index, _) in
                    HStack {
                        Text("\(index + 1)").font(.subheadline)
                        Spacer()
                        if exercise.supportsWeight { Text(sets[index].weight > 0 ? "\(Int(sets[index].weight))kg" : "-").font(.caption) }
                        if exercise.supportsReps { Text(sets[index].reps > 0 ? "\(sets[index].reps)" : "-").font(.caption) }
                        if exercise.supportsTime { Text(sets[index].durationSeconds > 0 ? timeText(sets[index].durationSeconds) : "-").font(.caption) }
                        if exercise.supportsDistance { Text(sets[index].distanceMeters > 0 ? distanceText(sets[index].distanceMeters) : "-").font(.caption) }
                    }
                }
                .onMove { indices, newOffset in
                    sets.move(fromOffsets: indices, toOffset: newOffset)
                }
            }
        }
        .listStyle(.insetGrouped)
        .toolbar { EditButton() }
    }

    private func timeText(_ secs: Int) -> String {
        let m = secs / 60, s = secs % 60
        return String(format: "%d:%02d", m, s)
    }

    private func distanceText(_ meters: Double) -> String {
        if meters >= 1000 { return String(format: "%.1fkm", meters / 1000) }
        return "\(Int(meters))m"
    }
}
import SwiftUI
import SwiftData

// MARK: - Set Tracking View
struct SetTrackingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let exercise: Exercise
    let workoutPart: WorkoutPart
    // Callback to inform parent whether any sets were saved
    var onDismiss: ((Bool) -> Void)? = nil
    
    @State private var sets: [SetData] = []
    @State private var notes = ""
    @State private var didSaveAnySet = false
    @State private var showSaveErrorAlert = false
    @State private var saveErrorMessage = ""
    @State private var showExitConfirm = false
    @State private var isReordering = false
    @State private var oneRMFormula: OneRMFormula = .epley
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Exercise header
                ExerciseHeader(exercise: exercise)
                
                if isReordering {
                    ReorderSetsList(exercise: exercise, sets: $sets)
                } else {
                    // Sets table
                    ScrollView {
                        VStack(spacing: 16) {
                            // Table header
                            SetTableHeader(exercise: exercise)
                            
                            // Sets list with stable IDs to avoid diff glitches
                            ForEach(Array(sets.enumerated()), id: \.element.id) { (index, _) in
                                SetRow(
                                    setData: $sets[index],
                                    setNumber: index + 1,
                                    exercise: exercise,
                                    onComplete: {
                                        completeSet(at: index)
                                    },
                                    oneRMFormula: oneRMFormula
                                )
                            }
                            
                            // Add set button
                            AddSetButton {
                                addNewSet()
                            }
                            
                            // Bulk add control (user selectable 1..5)
                            BulkAddControl(onAdd: { count in
                                addMultipleSets(count)
                            })
                            
                            // Notes section
                            NotesSection(notes: $notes)
                        }
                        .padding()
                    }
                }
                
                // Bottom action bar
                SetTrackingActionBar(
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
                        handleBack()
                    }
                    .accessibilityLabel(LocalizationKeys.Training.Set.back.localized)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isReordering ? LocalizationKeys.Common.done.localized : "Sırala") {
                        withAnimation { isReordering.toggle() }
                    }
                    .accessibilityLabel(isReordering ? LocalizationKeys.Common.done.localized : "Sırala")
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizationKeys.Training.Set.save.localized) {
                        finishExercise()
                    }
                    .fontWeight(.semibold)
                    .accessibilityLabel(LocalizationKeys.Training.Set.save.localized)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu("1RM: \(oneRMFormula.displayName)") {
                        ForEach(OneRMFormula.allCases, id: \.self) { formula in
                            Button(formula.displayName) { selectFormula(formula) }
                        }
                    }
                    .accessibilityLabel("1RM formülü")
                }
            }
            
        }
        // No auto-created sets on appear. User will add sets manually.
        .onDisappear {
            // Notify parent; if user dismissed without saving, inform false
            onDismiss?(didSaveAnySet)
        }
        .onAppear { loadFormulaPreference() }
        // Test Cases (Manual):
        // 1) Same exercise multiple completed sets -> set numbers should continue from max existing.
        // 2) Dismiss without completing any set -> no placeholder in part after parent onDismiss.
        // 3) Save with invalid data -> shows error alert.
        .alert(isPresented: $showExitConfirm) {
            Alert(
                title: Text(LocalizationKeys.Common.confirmDiscard.localized),
                message: Text(LocalizationKeys.Common.discardMessage.localized),
                primaryButton: .destructive(Text(LocalizationKeys.Common.discard.localized)) { dismiss() },
                secondaryButton: .cancel(Text(LocalizationKeys.Common.cancel.localized))
            )
        }
        .alert(isPresented: $showSaveErrorAlert) {
            Alert(
                title: Text(LocalizationKeys.Common.error.localized),
                message: Text(saveErrorMessage),
                dismissButton: .default(Text(LocalizationKeys.Common.ok.localized))
            )
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Button("Hızlı Doldur") { quickFillFromPrevious() }
                Spacer()
                Button(LocalizationKeys.Common.close.localized) { dismissKeyboard() }
            }
        }
    }
    
    private func addNewSet() {
        let newSet = SetData()
        
        // Copy previous set values as starting point
        if let lastSet = sets.last {
            newSet.weight = lastSet.weight
            newSet.reps = lastSet.reps
            newSet.durationSeconds = lastSet.durationSeconds
            newSet.distanceMeters = lastSet.distanceMeters
        }
        
        sets.append(newSet)
    }

    private func addMultipleSets(_ count: Int) {
        let safe = max(1, min(count, 5))
        for _ in 0..<safe { addNewSet() }
        HapticManager.shared.impact(.light)
    }
    
    private func completeSet(at index: Int) {
        var txn = Transaction()
        txn.disablesAnimations = true
        withTransaction(txn) {
            sets[index].isCompleted = true
        }
        HapticManager.shared.impact(.light)
        // If user completes the last row, auto-append a new set prefilled
        if index == sets.count - 1 {
            addNewSet()
        }
    }
    
    private func finishExercise() {
        // 1) Remove placeholder sets for this exercise
        let placeholders = workoutPart.exerciseSets.filter { $0.exercise?.id == exercise.id && $0.isCompleted == false }
        placeholders.forEach { modelContext.delete($0) }

        // 2) Determine next set number based on existing completed sets
        let currentMaxSetNumber = workoutPart.exerciseSets
            .filter { $0.exercise?.id == exercise.id }
            .map { Int($0.setNumber) }
            .max() ?? 0

        // 3) Prepare completed sets from UI
        let completedSets = sets.filter { $0.isCompleted && $0.hasValidData }

        // 4) Insert new sets continuing numbering
        for (offset, setData) in completedSets.enumerated() {
            let nextNumber = currentMaxSetNumber + offset + 1
            let exerciseSet = ExerciseSet(
                setNumber: Int16(nextNumber),
                weight: setData.weight,
                reps: setData.reps != 0 ? Int16(setData.reps) : nil,
                duration: setData.durationSeconds > 0 ? Int32(setData.durationSeconds) : nil,
                distance: setData.distanceMeters > 0 ? setData.distanceMeters : nil,
                rpe: nil,
                isCompleted: true
            )

            exerciseSet.exercise = exercise
            exerciseSet.workoutPart = workoutPart

            modelContext.insert(exerciseSet)
        }

        // 5) Save notes if any
        if !notes.isEmpty {
            if workoutPart.notes?.isEmpty ?? true {
                workoutPart.notes = notes
            } else {
                workoutPart.notes = (workoutPart.notes ?? "") + "\n\(exercise.nameTR): \(notes)"
            }
        }

        // 6) Persist and handle errors
        do {
            try modelContext.save()
            didSaveAnySet = !completedSets.isEmpty
            onDismiss?(didSaveAnySet)
            dismiss()
        } catch {
            saveErrorMessage = error.localizedDescription
            showSaveErrorAlert = true
        }
    }

    private func handleBack() {
        let hasCompleted = sets.contains { $0.isCompleted && $0.hasValidData }
        if hasCompleted || !notes.isEmpty {
            // There is data, ask confirmation if not yet saved
            if !didSaveAnySet {
                showExitConfirm = true
                return
            }
        }
        dismiss()
    }

    private func loadFormulaPreference() {
        let raw = UserDefaults.standard.string(forKey: "training.onerm.formula")
        if let raw, let f = OneRMFormula(rawValue: raw) { oneRMFormula = f }
    }

    private func selectFormula(_ f: OneRMFormula) {
        oneRMFormula = f
        UserDefaults.standard.set(f.rawValue, forKey: "training.onerm.formula")
    }

    private func quickFillFromPrevious() {
        guard sets.count >= 2 else { return }
        let src = sets[sets.count - 2]
        let dstIndex = sets.count - 1
        guard !sets[dstIndex].isCompleted else { return }
        sets[dstIndex].weight = src.weight
        sets[dstIndex].reps = src.reps
        sets[dstIndex].durationSeconds = src.durationSeconds
        sets[dstIndex].distanceMeters = src.distanceMeters
        HapticManager.shared.impact(.light)
    }

    private func dismissKeyboard() {
        #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }
}

// MARK: - Set Data Model
class SetData: ObservableObject, Identifiable {
    let id = UUID()
    @Published var weight: Double = 0
    @Published var reps: Int = 0
    @Published var durationSeconds: Int = 0
    @Published var distanceMeters: Double = 0
    @Published var isCompleted: Bool = false
    
    var hasValidData: Bool {
        weight > 0 || reps > 0 || durationSeconds > 0 || distanceMeters > 0
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(exercise.nameTR) başlık")
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
    let oneRMFormula: OneRMFormula
    
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
                    seconds: $setData.durationSeconds,
                    isEnabled: !setData.isCompleted
                )
                .frame(maxWidth: .infinity)
            }

            if exercise.supportsDistance {
                NumberInputField(
                    value: $setData.distanceMeters,
                    placeholder: LocalizationKeys.Training.Set.meters.localized,
                    isEnabled: !setData.isCompleted,
                    allowDecimals: true
                )
                .frame(maxWidth: .infinity)
            }

            if let estimate = estimatedOneRM() {
                Text("~\(Int(estimate)) 1RM")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(width: 70)
            }
            
			// Complete button
            Button(action: onComplete) {
                Image(systemName: setData.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(setData.isCompleted ? .green : .gray)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(setData.isCompleted ? LocalizationKeys.Training.Set.completed.localized : LocalizationKeys.Training.Set.finishExercise.localized)
            .accessibilityHint("Seti tamamla")
            .frame(width: 60)
            .disabled(setData.isCompleted || !setData.hasValidData)
            .contextMenu {
                Button(setData.isCompleted ? LocalizationKeys.Common.completed.localized : LocalizationKeys.Training.Set.finishExercise.localized) {
                    onComplete()
                }
                if setData.isCompleted {
                    Button(LocalizationKeys.Common.cancel.localized) {
                        setData.isCompleted = false
                    }
                }
            }
        }
		.accessibilityElement(children: .combine)
		.accessibilityLabel(accessibleSummary())
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(setData.isCompleted ? Color.green.opacity(0.1) : Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(setData.isCompleted ? Color.green : Color(.systemGray4), lineWidth: 1)
        )
    }

    private func estimatedOneRM() -> Double? {
        guard exercise.supportsWeight, exercise.supportsReps else { return nil }
        let w = setData.weight
        let r = setData.reps
        guard w > 0, r > 0 else { return nil }
        return oneRMFormula.estimate1RM(weight: w, reps: r)
    }

	private func accessibleSummary() -> String {
		var pieces: [String] = ["Set \(setNumber)"]
		if exercise.supportsWeight, setData.weight > 0 { pieces.append("\(Int(setData.weight)) kilogram") }
		if exercise.supportsReps, setData.reps > 0 { pieces.append("\(setData.reps) tekrar") }
		if exercise.supportsTime, setData.durationSeconds > 0 {
			let m = setData.durationSeconds / 60
			let s = setData.durationSeconds % 60
			pieces.append("\(m) dakika \(s) saniye")
		}
		if exercise.supportsDistance, setData.distanceMeters > 0 { pieces.append("\(Int(setData.distanceMeters)) metre") }
		pieces.append(setData.isCompleted ? "tamamlandı" : "tamamlanmadı")
		return pieces.joined(separator: ", ")
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
        let safeMinutes = max(0, minutes)
        let clampedSecs = min(max(0, secs), 59)
        minutes = safeMinutes
        secs = clampedSecs
        seconds = safeMinutes * 60 + clampedSecs
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
    @Environment(\.theme) private var theme
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(theme.colors.accent)
                Text(LocalizationKeys.Training.Set.addSet.localized)
                    .fontWeight(.medium)
                Spacer()
            }
            .padding(theme.spacing.m)
            .background(theme.colors.accent.opacity(0.1))
            .cornerRadius(8)
        }
        .foregroundColor(theme.colors.accent)
        .buttonStyle(PressableStyle())
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
    let onFinish: () -> Void
    let hasCompletedSets: Bool
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 12) {
                Spacer()
                // Finish button
                Button(LocalizationKeys.Training.Set.finishExercise.localized) {
                    onFinish()
                    HapticManager.shared.impact(.light)
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, theme.spacing.l)
                .padding(.vertical, theme.spacing.m)
                .background(hasCompletedSets ? theme.colors.success : Color.gray)
                .cornerRadius(8)
                .disabled(!hasCompletedSets)
                .buttonStyle(PressableStyle())
            }
            .padding(theme.spacing.m)
        }
        .background(theme.colors.backgroundPrimary)
    }
}

// MARK: - Bulk Add Control (1..5)
struct BulkAddControl: View {
    let onAdd: (Int) -> Void
    @Environment(\.theme) private var theme
    @State private var count: Int = 3

    var body: some View {
        HStack(spacing: theme.spacing.m) {
            HStack(spacing: theme.spacing.s) {
                Text("Toplu Ekle")
                    .font(.subheadline)
                    .foregroundColor(theme.colors.textSecondary)
                Stepper("x\(count)", value: $count, in: 1...5)
                    .labelsHidden()
            }
            Spacer()
            Button(LocalizationKeys.Common.add.localized) {
                onAdd(count)
            }
            .font(.subheadline)
            .foregroundColor(.white)
            .padding(.horizontal, theme.spacing.m)
            .padding(.vertical, theme.spacing.s)
            .background(theme.colors.accent)
            .cornerRadius(8)
            .buttonStyle(PressableStyle())
            .accessibilityLabel("Toplu set ekle")
        }
    }
}

#Preview {
    let exercise = Exercise(nameEN: "Bench Press", nameTR: "Göğüs Presi", category: "push", equipment: "barbell,bench")
    exercise.supportsWeight = true
    exercise.supportsReps = true
    let workoutPart = WorkoutPart(name: "Power & Strength", type: .powerStrength, orderIndex: 1)
    return SetTrackingView(exercise: exercise, workoutPart: workoutPart)
        .modelContainer(for: [Exercise.self, ExerciseSet.self, WorkoutPart.self], inMemory: true)
}

// MARK: - OneRM
enum OneRMFormula: String, CaseIterable {
    case epley
    case brzycki
    case lander

    var displayName: String {
        switch self {
        case .epley: return "Epley"
        case .brzycki: return "Brzycki"
        case .lander: return "Lander"
        }
    }

    func estimate1RM(weight: Double, reps: Int) -> Double {
        guard reps > 0 else { return weight }
        switch self {
        case .epley:
            // 1RM = w * (1 + r/30)
            return weight * (1.0 + Double(reps) / 30.0)
        case .brzycki:
            // 1RM = w * 36 / (37 - r)
            let denom = max(1.0, 37.0 - Double(reps))
            return weight * 36.0 / denom
        case .lander:
            // 1RM = w * 100 / (101.3 - 2.67123r)
            let denom = max(1.0, 101.3 - 2.67123 * Double(reps))
            return weight * 100.0 / denom
        }
    }
}
