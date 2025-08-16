import SwiftUI
import UIKit
import SwiftData

// MARK: - Navigation Routes for Workout Detail
private enum WorkoutDetailRoute: Hashable {
    case exerciseSelection
    case setTracking
}

// MARK: - Workout Detail View
struct WorkoutDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.theme) private var theme

    @Bindable var workout: Workout
    @State private var showingAddPart = false
    
    @State private var showingShare = false
    @State private var saveError: String? = nil
    @State private var isSaving: Bool = false
    @State private var showCompletion: Bool = false
    @AppStorage("preferences.haptic_feedback_enabled") private var hapticsEnabled: Bool = true
    @State private var toastMessage: String? = nil
    // Global add flow via push navigation
    @State private var path: [WorkoutDetailRoute] = []
    @State private var globalSelectedExercise: Exercise? = nil
    @State private var globalTargetPart: WorkoutPart? = nil
    @State private var showingExerciseSelection: Bool = false
    // Unified set tracking target for smooth sheet presentation
    private struct SetTarget: Identifiable { let id = UUID(); let exercise: Exercise; let part: WorkoutPart }
    @State private var setTarget: SetTarget? = nil
    // Manual WOD flow
    @State private var showingManualWOD: Bool = false
    @State private var manualTargetPart: WorkoutPart? = nil
    // Set tracking as dedicated sheet to avoid push/sheet race conditions
    @State private var showSetTrackingSheet: Bool = false
    // SwiftData automatic observation for workout parts
    @State private var lastPartCount: Int = 0
    @State private var lastSetCount: Int = 0

    // removed; timer kept as @State

    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 0) {
            WorkoutHeaderView(
                workoutName: workout.name ?? LocalizationKeys.Training.Detail.defaultName.localized,
                startTime: workout.startTime,
                endTime: workout.endTime,
                isActive: !workout.isCompleted
            )

            ScrollView {
                LazyVStack(spacing: 16) {
                    if workout.parts.isEmpty {
                        EmptyWorkoutState { showingAddPart = true }
                    } else {
                        ForEach(workout.parts.sorted(by: { $0.orderIndex < $1.orderIndex }), id: \.id) { part in
                            WorkoutPartCard(part: part, onExerciseAdded: {
                                HapticManager.shared.impact(.light)
                            })
                            .id(part.id)
                        }
                    }

                    if !workout.isCompleted {
                        AddMenuButton(
                            onAddPart: { showingAddPart = true },
                            onAddExercise: {
                                DispatchQueue.main.async { showingExerciseSelection = true }
                            },
                            onAddWOD: {
                                handleAddWOD()
                            }
                        )
                    }
                }
                .padding(.horizontal, theme.spacing.l)
                .padding(.vertical, theme.spacing.m)
            }

            if !workout.isCompleted {
                WorkoutActionBar(
                    workout: workout,
                    onFinish: { finishWorkout() }
                )
            }
        }
    }
    
    @ViewBuilder
    private var navigationBar: some View {
        HStack(spacing: 8) {
            Button(LocalizationKeys.Training.Detail.back.localized) { dismiss() }
            if !workout.isCompleted {
                Button(action: toggleTemplate) {
                    Text(workout.isTemplate ? LocalizationKeys.Training.Templates.removeFromTemplates.localized : LocalizationKeys.Training.Templates.saveAsTemplate.localized)
                        .font(.caption)
                }
            }
        }
        .accessibilityLabel(LocalizationKeys.Training.Detail.back.localized)
    }
    
    var body: some View {
        NavigationStack(path: $path) {
            mainContent
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: navigationBar)
            // TEST: Header duration & sheet cleanup
            // 1) Active workout → time increases
            // 2) Finish workout → completed state shows end time
            // 3) Open ExerciseSelection then dismiss → no ghost overlay, no placeholders
            .sheet(isPresented: $showingAddPart, onDismiss: {
                // SwiftData will automatically refresh the view
                if hapticsEnabled { HapticManager.shared.impact(.light) }
            }) {
            AddPartQuickSheet(workout: workout)
                .presentationDetents([.medium])
        }
            .sheet(isPresented: $showingManualWOD, onDismiss: {
                manualTargetPart = nil
                // SwiftData will automatically refresh the view
                if hapticsEnabled { HapticManager.shared.impact(.light) }
            }) {
            if let part = manualTargetPart {
                WODManualBuilderView(part: part) { scoreText in
                    let clean = scoreText.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !clean.isEmpty {
                        part.wodResult = clean
                    }
                    Task { @MainActor in
                        do { 
                            try modelContext.save() 
                            if hapticsEnabled { HapticManager.shared.notification(.success) }
                        } catch { 
                            toastMessage = error.localizedDescription
                            if hapticsEnabled { HapticManager.shared.notification(.error) }
                        }
                    }
                }
            }
        }
        }
        .navigationDestination(for: WorkoutDetailRoute.self) { route in
            switch route {
            case .exerciseSelection:
                ExerciseSelectionView(workoutPart: nil) { exercise in
                    // Infer target part type and ensure part exists; no placeholder pre-insert
                    let targetType = ExerciseCategory(rawValue: exercise.category)?.toWorkoutPartType() ?? .powerStrength
                    let part: WorkoutPart = {
                        if let existing = workout.parts.first(where: { WorkoutPartType.from(rawOrLegacy: $0.type) == targetType }) {
                            return existing
                        }
                        let created = workout.addPart(name: targetType.displayName, type: targetType)
                        return created
                    }()

                    // Prepare for SetTracking push
                    globalSelectedExercise = exercise
                    globalTargetPart = part
                    path.append(.setTracking)
                }
            case .setTracking:
                if let ex = globalSelectedExercise, let part = globalTargetPart {
                    SetTrackingView(exercise: ex, workoutPart: part) { didSave in
                        // No placeholders are created anymore; only clean-up would be needed for legacy cases
                        // Pop set tracking and provide haptic feedback
                        if !path.isEmpty { path.removeLast() }
                        if didSave && hapticsEnabled { HapticManager.shared.notification(.success) }
                    }
                } else {
                    EmptyView()
                }
            }
        }
        .modifier(ToastModifier(message: $toastMessage))
        .overlay {
            if isSaving {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                }
            }
        }
        .sheet(isPresented: $showCompletion) {
            WorkoutCompletionSheet(workout: workout)
        }
        // Egzersiz seçimi sheet → set sheet (item:) ile tek sunum zinciri
        .sheet(isPresented: $showingExerciseSelection) {
            ExerciseSelectionView(workoutPart: nil) { exercise in
                let targetType = ExerciseCategory(rawValue: exercise.category)?.toWorkoutPartType() ?? .powerStrength
                let part: WorkoutPart = {
                    if let existing = workout.parts.first(where: { WorkoutPartType.from(rawOrLegacy: $0.type) == targetType }) {
                        return existing
                    }
                    let created = workout.addPart(name: targetType.displayName, type: targetType)
                    return created
                }()
                showingExerciseSelection = false
                DispatchQueue.main.async {
                    setTarget = SetTarget(exercise: exercise, part: part)
                    if hapticsEnabled { HapticManager.shared.impact(.light) }
                }
            }
        }
        .sheet(item: $setTarget) { target in
            SetTrackingView(exercise: target.exercise, workoutPart: target.part) { didSave in
                if didSave && hapticsEnabled { HapticManager.shared.notification(.success) }
            }
        }
        
    }

    

    private func handleAddWOD() {
        let targetPart: WorkoutPart = {
            if let existing = workout.parts.first(where: { WorkoutPartType.from(rawOrLegacy: $0.type) == .metcon }) {
                return existing
            }
            let created = workout.addPart(name: WorkoutPartType.metcon.displayName, type: .metcon)
            do { try modelContext.save() } catch { /* ignore */ }
            return created
        }()
        manualTargetPart = targetPart
        showingManualWOD = true
        if hapticsEnabled { HapticManager.shared.impact(.light) }
    }
    
    private func finishWorkout() {
        isSaving = true
        Task {
            workout.finishWorkout()
        do {
                try modelContext.save()
                if hapticsEnabled { HapticManager.shared.notification(.success) }
                showCompletion = true
            } catch {
            if hapticsEnabled { HapticManager.shared.notification(.error) }
            toastMessage = error.localizedDescription
            }
            isSaving = false
        }
    }

    private func inferPartType(from exercise: Exercise) -> WorkoutPartType {
        let category = ExerciseCategory(rawValue: exercise.category) ?? .other
        switch category {
        case .cardio: return .cardio
        case .functional: return .metcon
        case .core, .isolation: return .accessory
        case .warmup, .flexibility: return .accessory
        case .plyometric: return .accessory
        case .olympic: return .powerStrength
        default: return .powerStrength
        }
    }


    private func toggleTemplate() {
        workout.isTemplate.toggle()
        do { try modelContext.save(); if hapticsEnabled { HapticManager.shared.notification(.success) } } catch { toastMessage = error.localizedDescription }
    }

    // Remove any placeholder (isCompleted == false) sets that may have been created
    // if user opened exercise selection and then dismissed without selecting.
    private func removeOrphanPlaceholders() {
        let placeholders = workout.parts.flatMap { part in
            part.exerciseSets.filter { !$0.isCompleted }
        }
        guard !placeholders.isEmpty else { return }
        placeholders.forEach { modelContext.delete($0) }
        do { try modelContext.save() } catch { toastMessage = error.localizedDescription }
    }

    private var shareMessage: String {
        let exerciseCount: Int = {
            let exerciseIds = workout.parts.flatMap { part in
                part.exerciseSets.compactMap { $0.exercise?.id }
            }
            return Set(exerciseIds).count
        }()
        let totalVolume = Int(workout.totalVolume)

        return """
        💪 Antrenmanımı tamamladım!

        🏋️ Egzersizler: \(exerciseCount)
        📊 Toplam: \(totalVolume) kg

        Sen de katıl: Spor Hocam 🚀
        """
    }
}

// File-scope helper so it can be used by multiple views in this file
private func inferWODType(from raw: String?) -> WODType? {
    guard let txt = raw?.lowercased() else { return nil }
    if txt.contains("amrap") { return .amrap }
    if txt.contains("emom") { return .emom }
    if txt.contains("time") { return .forTime }
    return .custom
}

// MARK: - Recent Exercise Chips

// NOTE: Removed local duplicates of WorkoutCompletionSheet and StatRow (shared component exists)

// MARK: - Part Card
// WorkoutPartCard moved to WorkoutPartCard.swift

// MARK: - Action bar and helpers

// MARK: - Edit Exercise Set Sheet

// MARK: - Unified Add Menu Button

// WorkoutActionBar moved to WorkoutActions.swift

// StatBadge moved to WorkoutActions.swift

// MARK: - WOD Create Button

// MARK: - Manual WOD Builder (For Time - simple)
// WODManualBuilderView moved to WODComponents.swift

// MARK: - Simple Runner (checklist + score input)
// WODRunnerSimpleView moved to WODComponents.swift
// WODRunnerSimpleView implementation moved to WODComponents.swift

// MARK: - Add Part Quick Sheet (4-card)

// MARK: - Preview
#Preview {
    let workout = Workout(name: "Test Antrenman")
    WorkoutDetailView(workout: workout)
        .modelContainer(for: [Workout.self, WorkoutPart.self, ExerciseSet.self, Exercise.self], inMemory: true)
}
