// MARK: - Reorderable list for sets
import SwiftUI
import SwiftData

// MARK: - Set Tracking View
struct SetTrackingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("preferredUnitSystem") private var preferredUnitSystem: String = "metric"
    
    let exercise: Exercise
    let workoutPart: WorkoutPart
    // Callback to inform parent whether any sets were saved
    var onDismiss: ((Bool) -> Void)? = nil
    
    @State private var sets: [SetData] = []
    @State private var notes = ""
    @State private var didSaveAnySet = false
    @State private var toastMessage: String? = nil
    @State private var showExitConfirm = false
    @State private var isReordering = false
    @State private var oneRMFormula: OneRMFormula = .epley
    @State private var didInsertInitialSet = false
    @State private var isSaving = false
    @AppStorage("preferences.haptic_feedback_enabled") private var hapticsEnabled: Bool = true
    
    // Individual set saving states
    @State private var savingSetId: UUID? = nil
    @State private var savedSetIds: Set<UUID> = []
    @State private var setSaveErrors: [UUID: Error] = [:]
    
    // MARK: - Computed Views
    @ViewBuilder
    private var mainContentView: some View {
        if isReordering {
            ReorderSetsList(exercise: exercise, sets: $sets)
        } else {
            setsTrackingView
        }
    }
    
    @ViewBuilder
    private var setsTrackingView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Exercise info header
                VStack(alignment: .leading, spacing: 8) {
                    Text(exercise.nameTR)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(LocalizationKeys.Training.Set.advancedEditDescription.localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
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
                        oneRMFormula: oneRMFormula,
                        shouldAutofocus: index == sets.count - 1 && !sets[index].isCompleted,
                        onCompleteSet: {
                            completeSet(at: index)
                        },
                        onDelete: {
                            deleteSet(at: index)
                        },
                        onRepeat: {
                            repeatSet(at: index)
                        },
                        isLoading: savingSetId == sets[index].id,
                        isSaved: savedSetIds.contains(sets[index].id),
                        hasError: setSaveErrors[sets[index].id] != nil
                    )
                }
                
                // Add set button
                AddSetButton {
                    addNewSet()
                }
                
                // Quick reps selector (only for exercises that support reps)
                if exercise.supportsReps && !sets.isEmpty {
                    QuickRepsSelector(
                        reps: Binding(
                            get: { sets.last?.reps ?? 0 },
                            set: { newValue in
                                if let lastIndex = sets.indices.last, !sets[lastIndex].isCompleted {
                                    sets[lastIndex].reps = newValue
                                }
                            }
                        ),
                        isEnabled: !(sets.last?.isCompleted ?? true)
                    )
                }
                
                // Notes section
                NotesSection(notes: $notes)
            }
            .padding()
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Exercise header
            ExerciseHeader(exercise: exercise)
            
            // Main content area
            mainContentView
            
            // Bottom action bar
            SetTrackingActionBar(
                onFinish: finishExercise,
                hasCompletedSets: sets.contains { $0.isCompleted }
            )
        }
            .navigationTitle(LocalizationKeys.Training.Set.advancedEdit.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizationKeys.Training.Set.back.localized) {
                        handleBack()
                    }
                    .accessibilityLabel(LocalizationKeys.Training.Set.back.localized)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isReordering ? LocalizationKeys.Common.done.localized : LocalizationKeys.Training.Set.reorder.localized) {
                        withAnimation { isReordering.toggle() }
                    }
                    .accessibilityLabel(isReordering ? LocalizationKeys.Common.done.localized : LocalizationKeys.Training.Set.reorder.localized)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu("1RM: \(oneRMFormula.displayName)") {
                        ForEach(OneRMFormula.allCases, id: \.self) { formula in
                            Button(formula.displayName) { selectFormula(formula) }
                        }
                    }
                    .accessibilityLabel("1RM formülü")
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                    // Complete Set button
                    Button("Seti Tamamla") {
                        if let lastIndex = sets.indices.last, !sets[lastIndex].isCompleted {
                            completeSet(at: lastIndex)
                        }
                    }
                    .disabled(sets.isEmpty || sets.last?.isCompleted == true || !(sets.last?.hasValidData == true))
                    
                    Spacer()
                    
                    // Quick Fill button
                    Button(LocalizationKeys.Training.Set.quickFill.localized) { 
                        quickFillFromPrevious() 
                    }
                    .disabled(sets.count < 2)
                    
                    Spacer()
                    
                    // Close keyboard
                    Button(LocalizationKeys.Common.close.localized) { 
                        dismissKeyboard() 
                    }
                }
            }
        .onDisappear {
            // Notify parent; if user dismissed without saving, inform false
            onDismiss?(didSaveAnySet)
        }
        .onAppear {
            loadFormulaPreference()
            // Automatically add first set for new exercises
            if !didInsertInitialSet && sets.isEmpty {
                addNewSet()
                didInsertInitialSet = true
            }
        }
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
        .modifier(ToastModifier(message: $toastMessage))
        .overlay {
            if isSaving {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.5)
                        
                        Text("Kaydediliyor...")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(12)
                }
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
    
    private func deleteSet(at index: Int) {
        // Prevent deleting if it's the last set and it's the only set
        guard sets.count > 1 || !sets[index].isCompleted else {
            toastMessage = "Son seti silemezsiniz"
            return
        }
        
        sets.remove(at: index)
        HapticManager.shared.impact(.medium)
    }
    
    private func repeatSet(at index: Int) {
        let sourceSet = sets[index]
        let newSet = SetData()
        
        // Copy all values from the source set
        newSet.weight = sourceSet.weight
        newSet.reps = sourceSet.reps
        newSet.durationSeconds = sourceSet.durationSeconds
        newSet.distanceMeters = sourceSet.distanceMeters
        newSet.rpe = sourceSet.rpe
        // Don't copy completed status - new set should be ready for input
        
        sets.append(newSet)
        
        HapticManager.shared.impact(.light)
    }

    
    private func completeSet(at index: Int) {
        sets[index].isCompleted = true
        
        HapticManager.shared.impact(.medium)
        
        // Save set immediately to database
        saveIndividualSet(sets[index])
        
        // If user completes the last row, auto-append a new set prefilled
        if index == sets.count - 1 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                addNewSet()
            }
        }
    }
    
    private func saveIndividualSet(_ setData: SetData) {
        guard setData.hasValidData else { return }
        
        savingSetId = setData.id
        
        Task { @MainActor in
            do {
                // Determine next set number based on existing completed sets
                let currentMaxSetNumber = workoutPart.exerciseSets
                    .filter { $0.exercise?.id == exercise.id }
                    .map { Int($0.setNumber) }
                    .max() ?? 0
                
                let nextNumber = currentMaxSetNumber + 1
                
                // Convert weight to kg if using imperial units
                let weightForSave: Double? = {
                    let w = setData.weight
                    guard w > 0 else { return nil }
                    return preferredUnitSystem == "imperial" ? UnitsConverter.lbsToKg(w) : w
                }()
                
                let exerciseSet = ExerciseSet(
                    setNumber: Int16(nextNumber),
                    weight: weightForSave,
                    reps: setData.reps != 0 ? Int16(setData.reps) : nil,
                    duration: setData.durationSeconds > 0 ? Int32(setData.durationSeconds) : nil,
                    distance: setData.distanceMeters > 0 ? setData.distanceMeters : nil,
                    rpe: setData.rpe > 0 ? Int16(setData.rpe) : nil,
                    isCompleted: true
                )
                
                exerciseSet.exercise = exercise
                exerciseSet.workoutPart = workoutPart
                modelContext.insert(exerciseSet)
                
                // Save to database
                try modelContext.save()
                
                // Mark as successfully saved
                savedSetIds.insert(setData.id)
                setSaveErrors.removeValue(forKey: setData.id)
                savingSetId = nil
                
                if hapticsEnabled { HapticManager.shared.notification(.success) }
                
            } catch {
                // Handle error
                setSaveErrors[setData.id] = error
                savingSetId = nil
                
                toastMessage = getErrorMessage(for: error)
                if hapticsEnabled { HapticManager.shared.notification(.error) }
            }
        }
    }
    
    private func finishExercise() {
        // Check if we have any completed sets or notes
        let completedSets = sets.filter { $0.isCompleted && $0.hasValidData }
        
        guard !completedSets.isEmpty || !notes.isEmpty else {
            toastMessage = LocalizationKeys.Training.Set.noDataToSave.localized
            if hapticsEnabled { HapticManager.shared.notification(.warning) }
            return
        }
        
        isSaving = true
        
        Task { @MainActor in
            do {
                // 1) Save any remaining unsaved sets first
                let unsavedSets = completedSets.filter { !savedSetIds.contains($0.id) }
                for setData in unsavedSets {
                    // Wait a bit for any ongoing individual saves to complete
                    while savingSetId != nil {
                        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
                    }
                    if !savedSetIds.contains(setData.id) {
                        saveIndividualSet(setData)
                        // Wait for this save to complete
                        while savingSetId == setData.id {
                            try await Task.sleep(nanoseconds: 100_000_000)
                        }
                    }
                }
                
                // 2) Remove placeholder sets for this exercise (if any exist)
                let placeholders = workoutPart.exerciseSets.filter { 
                    $0.exercise?.id == exercise.id && $0.isCompleted == false 
                }
                placeholders.forEach { modelContext.delete($0) }

                // 3) Save notes if any
                if !notes.isEmpty {
                    if workoutPart.notes?.isEmpty ?? true {
                        workoutPart.notes = notes
                    } else {
                        workoutPart.notes = (workoutPart.notes ?? "") + "\n\(exercise.nameTR): \(notes)"
                    }
                }

                // 4) Final save for notes and cleanup
                try modelContext.save()
                
                // Success! Clean exit
                didSaveAnySet = !completedSets.isEmpty
                if hapticsEnabled { HapticManager.shared.notification(.success) }
                
                isSaving = false
                onDismiss?(didSaveAnySet)
                dismiss()
                
            } catch {
                isSaving = false
                toastMessage = getErrorMessage(for: error)
                if hapticsEnabled { HapticManager.shared.notification(.error) }
            }
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
    
    // MARK: - Error Handling Methods
    
    private func getErrorMessage(for error: Error) -> String {
        let errorDescription = error.localizedDescription.lowercased()
        
        if errorDescription.contains("unique") || errorDescription.contains("constraint") {
            return "Bu set zaten kaydedilmiş. Lütfen tekrar deneyin."
        } else if errorDescription.contains("disk") || errorDescription.contains("space") {
            return "Cihaz hafızası dolu. Lütfen yer açın."
        } else if errorDescription.contains("permission") || errorDescription.contains("access") {
            return "Veritabanı erişim hatası. Uygulamayı yeniden başlatın."
        } else if errorDescription.contains("timeout") {
            return "İşlem zaman aşımına uğradı. Tekrar deneyin."
        } else {
            return "Kaydetme sırasında hata oluştu: \(error.localizedDescription)"
        }
    }
    
}


// MARK: - Set Data Model
class SetData: ObservableObject, Identifiable {
    let id = UUID()
    @Published var weight: Double = 0
    @Published var reps: Int = 0
    @Published var durationSeconds: Int = 0
    @Published var distanceMeters: Double = 0
    @Published var rpe: Int = 0
    @Published var isCompleted: Bool = false
    
    var hasValidData: Bool {
        weight > 0 || reps > 0 || durationSeconds > 0 || distanceMeters > 0
    }
}


// MARK: - Exercise Header

// MARK: - Set Table Header

// MARK: - Set Row

// MARK: - Number Input Field

// MARK: - Add Set Button

#Preview {
    let exercise = Exercise(nameEN: "Bench Press", nameTR: "Göğüs Presi", category: "push", equipment: "barbell,bench")
    exercise.supportsWeight = true
    exercise.supportsReps = true
    let workoutPart = WorkoutPart(name: "Power & Strength", type: .powerStrength, orderIndex: 1)
    return SetTrackingView(exercise: exercise, workoutPart: workoutPart)
        .modelContainer(for: [Exercise.self, ExerciseSet.self, WorkoutPart.self], inMemory: true)
}
