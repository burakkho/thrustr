import SwiftUI
import SwiftData

// MARK: - Main Training View
struct TrainingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var workouts: [Workout]
    @Query private var exercises: [Exercise]
    
    @State private var showingNewWorkout = false
    @State private var selectedTab = 0
    @State private var workoutToShow: Workout?
    @State private var showWorkoutDetail = false
    @State private var showActiveConflictDialog = false
    
    private enum PendingStartAction {
        case newDefault
        case programTemplate(Workout)
    }
    @State private var pendingStart: PendingStartAction? = nil
    
    private var hasActiveWorkout: Bool {
        workouts.contains { $0.isActive }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segment Control
                Picker(LocalizationKeys.Training.title.localized, selection: $selectedTab) {
                    Text(LocalizationKeys.Training.history.localized).tag(0)
                    Text(LocalizationKeys.Training.active.localized).tag(1)
                    Text(LocalizationKeys.Training.templates.localized).tag(2)
                    Text("WOD").tag(3)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content based on selected tab
                switch selectedTab {
                case 0:
                    WorkoutHistoryView(workouts: workouts)
                case 1:
                    ActiveWorkoutView(onWorkoutTap: { workout in
                        workoutToShow = workout
                        showWorkoutDetail = true
                    })
                case 2:
                    WorkoutTemplatesView()
                case 3:
                    WODMainView()
                default:
                    EmptyView()
                }
            }
            .navigationTitle(LocalizationKeys.Training.title.localized)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        if hasActiveWorkout {
                            pendingStart = .newDefault
                            showActiveConflictDialog = true
                        } else {
                            startNewDefaultWorkout()
                        }
                    }) {
                        Image(systemName: "plus")
                            .font(.headline)
                            .accessibilityLabel(LocalizationKeys.Common.add.localized)
                    }
                }
            }
            .fullScreenCover(item: $workoutToShow) { workout in
                WorkoutDetailView(workout: workout)
            }
            .onAppear {
                if hasActiveWorkout { selectedTab = 1 }
            }
            .confirmationDialog(LocalizationKeys.Training.ActiveConflict.title.localized, isPresented: $showActiveConflictDialog, titleVisibility: .visible) {
                Button(LocalizationKeys.Training.ActiveConflict.continue.localized) {
                    if let existing = workouts.first(where: { $0.isActive }) {
                        workoutToShow = existing
                        selectedTab = 1
                    }
                    pendingStart = nil
                }
                Button(LocalizationKeys.Training.ActiveConflict.finishAndStart.localized) {
                    if let existing = workouts.first(where: { $0.isActive }) {
                        existing.finishWorkout()
                        do { try modelContext.save() } catch { /* ignore */ }
                    }
                    performPendingStart()
                }
                Button(LocalizationKeys.Common.cancel.localized, role: .cancel) { pendingStart = nil }
            } message: {
                Text(LocalizationKeys.Training.ActiveConflict.message.localized)
            }
        }
    }
}

#Preview {
    TrainingView()
        .modelContainer(for: [Workout.self, Exercise.self], inMemory: true)
}

// MARK: - Helpers (Single Active Policy + Start Actions)
private extension TrainingView {
    func startNewDefaultWorkout() {
        let newWorkout = Workout(name: LocalizationKeys.Training.History.defaultName.localized)
        modelContext.insert(newWorkout)
        workoutToShow = newWorkout
        selectedTab = 1
    }


    func startProgramTemplate(_ template: Workout) {
        let newWorkout = Workout(name: template.name ?? LocalizationKeys.Training.History.defaultName.localized)
        for (idx, part) in template.parts.sorted(by: { $0.orderIndex < $1.orderIndex }).enumerated() {
            let newPart = WorkoutPart(name: part.name, type: WorkoutPartType.from(rawOrLegacy: part.type), orderIndex: idx)
            newPart.workout = newWorkout
            let grouped: [UUID?: [ExerciseSet]] = Dictionary(grouping: part.exerciseSets, by: { $0.exercise?.id })
            for (_, sets) in grouped {
                guard let exercise = sets.first?.exercise else { continue }
                let completed = sets.compactMap { $0.isCompleted ? $0 : nil }
                if let last = completed.last {
                    let copy = ExerciseSet(setNumber: 1, weight: last.weight, reps: last.reps, isCompleted: false)
                    copy.exercise = exercise
                    copy.workoutPart = newPart
                }
            }
            newWorkout.parts.append(newPart)
        }
        modelContext.insert(newWorkout)
        do { try modelContext.save() } catch { /* ignore */ }
        workoutToShow = newWorkout
        selectedTab = 1
    }

    func performPendingStart() {
        guard let pending = pendingStart else { return }
        switch pending {
        case .newDefault:
            startNewDefaultWorkout()
        case .programTemplate(let tmpl):
            startProgramTemplate(tmpl)
        }
        pendingStart = nil
    }
}
