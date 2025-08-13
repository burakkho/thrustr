import SwiftUI
import UIKit
import SwiftData

// MARK: - Workout Detail View
struct WorkoutDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.theme) private var theme

    @Bindable var workout: Workout
    @State private var showingAddPart = false
    @State private var showingGlobalExerciseSelection = false
    
    @State private var showingShare = false
    @State private var saveError: String? = nil
    @State private var isSaving: Bool = false
    @State private var showCompletion: Bool = false
    @AppStorage("preferences.haptic_feedback_enabled") private var hapticsEnabled: Bool = true
    @State private var didAddExerciseFromGlobalSelection: Bool = false
    // Global add → auto open SetTracking
    @State private var shouldOpenGlobalSetTracking: Bool = false
    @State private var showingGlobalSetTracking: Bool = false
    @State private var globalSelectedExercise: Exercise? = nil
    @State private var globalTargetPart: WorkoutPart? = nil
    // Manual WOD flow
    @State private var showingManualWOD: Bool = false
    @State private var manualTargetPart: WorkoutPart? = nil

    // removed; timer kept as @State

    var body: some View {
        NavigationStack {
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
                            ForEach(workout.parts.sorted(by: { $0.orderIndex < $1.orderIndex })) { part in
                                WorkoutPartCard(part: part)
                            }
                        }

                        if !workout.isCompleted {
            AddPartButton { showingAddPart = true }
                            AddExercisesButton { showingGlobalExerciseSelection = true }
                            WODCreateButton(title: LocalizationKeys.Training.WOD.create.localized) {
                                // Ensure a Metcon part exists (or create one) for WOD
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
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading:
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
            )
            // TEST: Header duration & sheet cleanup
            // 1) Active workout → time increases
            // 2) Finish workout → completed state shows end time
            // 3) Open ExerciseSelection then dismiss → no ghost overlay, no placeholders
        .sheet(isPresented: $showingAddPart, onDismiss: {
            removeOrphanPlaceholders()
        }) {
            AddPartQuickSheet(workout: workout)
                .presentationDetents([.medium])
        }
            .sheet(isPresented: $showingGlobalExerciseSelection, onDismiss: {
                // If a selection was made, open set tracking now
                if shouldOpenGlobalSetTracking {
                    showingGlobalSetTracking = true
                    shouldOpenGlobalSetTracking = false
                } else if !didAddExerciseFromGlobalSelection {
                    // Cleanup only if user dismissed without adding
                    removeOrphanPlaceholders()
                }
                didAddExerciseFromGlobalSelection = false
            }) {
                ExerciseSelectionView(workoutPart: nil) { exercise in
                    didAddExerciseFromGlobalSelection = true
                    // Infer target part type from exercise and add placeholder set under that part
                    let targetType = ExerciseCategory(rawValue: exercise.category)?.toWorkoutPartType() ?? .powerStrength
                    let part: WorkoutPart = {
                        if let existing = workout.parts.first(where: { WorkoutPartType.from(rawOrLegacy: $0.type) == targetType }) {
                            return existing
                        }
                        let created = workout.addPart(name: targetType.displayName, type: targetType)
                        return created
                    }()

                    // Insert placeholder without saving to disk synchronously; UI should update via @Bindable
                    let nextIndexForExercise = (part.exerciseSets
                        .filter { $0.exercise?.id == exercise.id }
                        .map { Int($0.setNumber) }
                        .max() ?? 0) + 1

                    let placeholder = ExerciseSet(setNumber: Int16(nextIndexForExercise), isCompleted: false)
                    placeholder.exercise = exercise
                    placeholder.workoutPart = part
                    modelContext.insert(placeholder)

                    // Defer save slightly to avoid UI hitch; allow SwiftData to publish first
                    DispatchQueue.main.async {
                        do { try modelContext.save() } catch { /* show later */ }
                    }

                    // Prepare to open SetTracking after sheet dismisses
                    globalSelectedExercise = exercise
                    globalTargetPart = part
                    shouldOpenGlobalSetTracking = true
                    showingGlobalExerciseSelection = false
                }
            }
            .sheet(isPresented: $showingGlobalSetTracking, onDismiss: {
                // Reset selection after closing SetTracking
                globalSelectedExercise = nil
                globalTargetPart = nil
            }) {
                if let ex = globalSelectedExercise, let part = globalTargetPart {
                    SetTrackingView(exercise: ex, workoutPart: part) { didSave in
                        // If user didn't save any sets, clear placeholder sets for this exercise
                        if !didSave {
                            let placeholders = part.exerciseSets.filter { $0.exercise?.id == ex.id && !$0.isCompleted }
                            placeholders.forEach { modelContext.delete($0) }
                            DispatchQueue.main.async {
                                do { try modelContext.save() } catch { /* ignore */ }
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingManualWOD, onDismiss: {
                manualTargetPart = nil
            }) {
                if let part = manualTargetPart {
                    WODManualBuilderView(part: part) { scoreText in
                        let clean = scoreText.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !clean.isEmpty {
                            part.wodResult = clean
                        }
                        DispatchQueue.main.async {
                            do { try modelContext.save() } catch { saveError = error.localizedDescription }
                        }
                    }
                }
            }
        }
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
        
        
        .alert(isPresented: Binding<Bool>(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )) {
            Alert(title: Text(LocalizationKeys.Common.error.localized), message: Text(saveError ?? ""), dismissButton: .default(Text(LocalizationKeys.Common.ok.localized)))
        }
        .sheet(isPresented: $showCompletion) {
            WorkoutCompletionSheet(workout: workout)
        }
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
                saveError = error.localizedDescription
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
        do { try modelContext.save(); if hapticsEnabled { HapticManager.shared.notification(.success) } } catch { saveError = error.localizedDescription }
    }

    // Remove any placeholder (isCompleted == false) sets that may have been created
    // if user opened exercise selection and then dismissed without selecting.
    private func removeOrphanPlaceholders() {
        let placeholders = workout.parts.flatMap { part in
            part.exerciseSets.filter { !$0.isCompleted }
        }
        guard !placeholders.isEmpty else { return }
        placeholders.forEach { modelContext.delete($0) }
        do { try modelContext.save() } catch { saveError = error.localizedDescription }
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

// MARK: - Recent Exercise Chips
private struct RecentExerciseChips: View {
    @Environment(\.theme) private var theme
    @Query private var exercises: [Exercise]
    let onSelect: (Exercise) -> Void

    private var recentIds: [UUID] {
        let ids = (UserDefaults.standard.array(forKey: "training.recent.exercises") as? [String]) ?? []
        return ids.compactMap { UUID(uuidString: $0) }
    }

    private var recentExercises: [Exercise] {
        let idSet = Set(recentIds)
        return exercises.filter { idSet.contains($0.id) && $0.isActive }
    }

    var body: some View {
        if !recentExercises.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: theme.spacing.s) {
                    ForEach(recentExercises.prefix(5)) { exercise in
                        Button(action: { onSelect(exercise) }) {
                            Text(exercise.nameTR)
                                .font(.caption)
                                .padding(.horizontal, theme.spacing.m)
                                .padding(.vertical, theme.spacing.s)
                                .background(theme.colors.accent.opacity(0.12))
                                .foregroundColor(theme.colors.accent)
                                .cornerRadius(16)
                        }
                        .buttonStyle(PressableStyle())
                    }
                }
                .padding(.vertical, theme.spacing.s)
            }
        }
    }
}

// NOTE: Removed local duplicates of WorkoutCompletionSheet and StatRow (shared component exists)

// MARK: - Header
struct WorkoutHeaderView: View {
    let workoutName: String
    let startTime: Date
    let endTime: Date?
    let isActive: Bool
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workoutName)
                        .font(.title2)
                        .fontWeight(.bold)
                    HStack(spacing: 4) {
                        Circle()
                            .fill(isActive ? theme.colors.success : theme.colors.textSecondary)
                            .frame(width: 8, height: 8)
                        Text(isActive ? LocalizationKeys.Training.Active.statusActive.localized : LocalizationKeys.Training.Active.statusCompleted.localized)
                            .font(.caption)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }
                Spacer()
            }
            .padding(.horizontal)
            Divider()
        }
        .background(theme.colors.backgroundPrimary)
    }

    private var timeRangeText: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let start = formatter.string(from: startTime)
        if let end = endTime { return "\(start) - \(formatter.string(from: end))" }
        return start
    }
}

// MARK: - Empty State
struct EmptyWorkoutState: View {
    let action: () -> Void
    @Environment(\.theme) private var theme
    var body: some View {
        VStack(spacing: theme.spacing.xl) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 60))
                .foregroundColor(theme.colors.accent)
                .symbolEffect(.pulse)

            VStack(spacing: theme.spacing.m) {
                Text(LocalizationKeys.Training.Detail.emptyTitle.localized)
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(LocalizationKeys.Training.Detail.emptySubtitle.localized)
                    .foregroundColor(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: action) {
                Label(LocalizationKeys.Training.Detail.addPart.localized, systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, theme.spacing.xl)
                    .padding(.vertical, theme.spacing.m)
                    .background(theme.colors.accent)
                    .cornerRadius(12)
            }
            .buttonStyle(PressableStyle())
        }
        .padding(.top, 60)
    }
}

// MARK: - Part Card
struct WorkoutPartCard: View {
    @Bindable var part: WorkoutPart
    @Environment(\.modelContext) private var modelContext
    @Environment(\.theme) private var theme
    @State private var showingSetTracking = false
    @State private var selectedExercise: Exercise?
    @State private var showingRename = false
    @State private var tempName: String = ""
    // removed selection timer (no timers in training revamp)
    @State private var saveError: String? = nil
    @State private var showingWODResult: Bool = false
    @State private var wodTemp: String = ""
    @State private var isCollapsed: Bool = false
    @State private var showingWODAdd: Bool = false

    var partType: WorkoutPartType {
        WorkoutPartType.from(rawOrLegacy: part.type)
    }

    var localizedPartName: String {
        switch partType {
        case .powerStrength:
            return LocalizationKeys.Training.Part.powerStrength.localized
        case .metcon:
            return LocalizationKeys.Training.Part.metcon.localized
        case .accessory:
            return LocalizationKeys.Training.Part.accessory.localized
        case .cardio:
            return LocalizationKeys.Training.Part.cardio.localized
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            headerSection
            // Removed inline recent chips to simplify UI per feedback
            if !isCollapsed {
                contentSection
                if part.totalSets > 0 { progressSection }
            }
        }
        .padding(theme.spacing.l)
        .cardStyle()
        .contextMenu {
            Button(LocalizationKeys.Training.Part.rename.localized) { tempName = part.name; showingRename = true }
            Button(LocalizationKeys.Training.Part.moveUp.localized) { movePart(direction: -1) }
            Button(LocalizationKeys.Training.Part.moveDown.localized) { movePart(direction: 1) }
            Divider()
            Button("Bölümü Kopyala") { duplicatePartToSameWorkout() }
            Button("Yeni Antrenmana Kopyala") { copyPartToNewWorkout() }
            Divider()
            Button(part.isCompleted ? LocalizationKeys.Training.Part.markInProgressAction.localized : LocalizationKeys.Training.Part.markCompletedAction.localized) {
                part.isCompleted.toggle(); do { try modelContext.save() } catch { saveError = error.localizedDescription }
            }
            Button(role: .destructive) { deletePart() } label: { Text(LocalizationKeys.Training.Part.deletePart.localized) }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) { deletePart() } label: {
                Label(LocalizationKeys.Common.delete.localized, systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading) {
            Button {
                part.isCompleted.toggle(); do { try modelContext.save() } catch { saveError = error.localizedDescription }
            } label: {
                Label(
                    part.isCompleted ? LocalizationKeys.Training.Part.markInProgressAction.localized : LocalizationKeys.Training.Part.markCompletedAction.localized,
                    systemImage: part.isCompleted ? "xmark.circle" : "checkmark.circle"
                )
            }
            .tint(part.isCompleted ? theme.colors.warning : theme.colors.success)
        }
        // Removed inline exercise selection per UX decision
        .sheet(isPresented: $showingSetTracking) {
            if let exercise = selectedExercise {
                SetTrackingView(exercise: exercise, workoutPart: part) { didSave in
                    // If user didn't save any sets, clear placeholder sets for this exercise
                    if !didSave {
                        let placeholders = part.exerciseSets.filter { $0.exercise?.id == exercise.id && !$0.isCompleted }
                        placeholders.forEach { modelContext.delete($0) }
                        do { try modelContext.save() } catch { /* ignore */ }
                    }
                }
            }
        }
        .sheet(isPresented: $showingWODResult) {
            NavigationView {
                VStack(spacing: 16) {
                    Text("WOD Sonucu")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    TextField("Örn: 12:34, 5 RFT 10+8+6…", text: $wodTemp, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                    Spacer()
                }
                .padding()
                .navigationTitle(LocalizedStringKey("WOD"))
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(
                    leading: Button(LocalizationKeys.Common.cancel.localized) { showingWODResult = false },
                    trailing: Button(LocalizationKeys.Common.save.localized) {
                        part.wodResult = wodTemp.trimmingCharacters(in: .whitespacesAndNewlines)
                        // Dismiss first so UI reflects instantly, then persist asynchronously
                        showingWODResult = false
                        DispatchQueue.main.async {
                            do { try modelContext.save() } catch { saveError = error.localizedDescription }
                        }
                    }.disabled(wodTemp.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                )
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showingWODAdd) {
            WODSelectorLocalView(part: part) { template, custom in
                if let template {
                    part.wodTemplateId = template.id
                }
                if let custom, !custom.isEmpty {
                    part.wodResult = custom
                }
                // Persist after UI updates propagate
                DispatchQueue.main.async {
                    do { try modelContext.save() } catch { saveError = error.localizedDescription }
                }
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showingRename) {
            RenamePartSheet(initialName: part.name) { newName in
                part.name = newName
                do { try modelContext.save() } catch { saveError = error.localizedDescription }
            }
        }
        .alert(isPresented: Binding<Bool>(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )) {
            Alert(
                title: Text(LocalizationKeys.Common.error.localized),
                message: Text(saveError ?? ""),
                dismissButton: .default(Text(LocalizationKeys.Common.ok.localized))
            )
        }
    }

    // MARK: - Sections
    @ViewBuilder private var headerSection: some View {
        HStack(alignment: .center) {
            HStack(spacing: 10) {
                Image(systemName: partType.icon)
                    .foregroundColor(partThemeColor)
                    .font(.system(size: 28, weight: .semibold))
                    .accessibilityLabel(localizedPartName)
                Text("\(part.name) \(part.exerciseSets.isEmpty ? "" : "(\(groupedExercises.count))")")
                    .font(.title3)
                    .fontWeight(.bold)
            }
            Spacer()
            HStack(spacing: 6) {
                Circle()
                    .fill(part.isCompleted ? theme.colors.success : theme.colors.warning)
                    .frame(width: 10, height: 10)
                Text(part.isCompleted ? LocalizationKeys.Training.Part.statusCompleted.localized : LocalizationKeys.Training.Part.statusInProgress.localized)
                    .font(.caption)
                    .foregroundColor(theme.colors.textSecondary)
                Button(action: { withAnimation(.spring()) { isCollapsed.toggle() } }) {
                    Image(systemName: isCollapsed ? "chevron.down" : "chevron.up")
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
        }
    }

    @ViewBuilder private var contentSection: some View {
        if part.exerciseSets.isEmpty && part.wodResult == nil {
            VStack(spacing: 10) {
                Text(LocalizationKeys.Training.Part.noExercise.localized)
                    .foregroundColor(theme.colors.textSecondary)
                    .font(.subheadline)
            }
            .padding(.top, 4)
        } else if let wodResult = part.wodResult {
            VStack(alignment: .leading, spacing: 8) {
                // Collapsed summary
                HStack {
                    let name = WODLookup.name(for: part.wodTemplateId) ?? "WOD"
                    Text("\(name) - \(wodResult)")
                        .fontWeight(.semibold)
                    Spacer()
                    Button {
                        wodTemp = wodResult
                        showingWODResult = true
                    } label: { Image(systemName: "pencil") }
                    Button(role: .destructive) {
                        part.wodResult = nil
                        do { try modelContext.save() } catch { saveError = error.localizedDescription }
                    } label: { Image(systemName: "trash") }
                }
                // Expanded movements
                if let tmpl = WODLookup.template(for: part.wodTemplateId) {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(tmpl.movements, id: \.self) { mv in
                            HStack(spacing: 8) {
                                Image(systemName: "circle.fill").font(.system(size: 6)).foregroundColor(.secondary)
                                Text(mv).font(.caption)
                            }
                        }
                    }
                    .padding(.leading, 4)
                }
            }
        } else {
            VStack(spacing: 10) {
                ForEach(groupedExercises, id: \.exercise.id) { group in
                    ExerciseGroupView(
                        exercise: group.exercise,
                        sets: group.sets,
                        onAddSet: {
                            selectedExercise = group.exercise
                            showingSetTracking = true
                        }
                    )
                }
                if partType == .metcon {
                    HStack(spacing: 12) {
                        Button(action: { showingWODAdd = true }) {
                            Label(LocalizationKeys.Training.WOD.add.localized, systemImage: "plus.circle.fill")
                        }
                        .buttonStyle(PressableStyle())

                        Button(action: {
                            wodTemp = part.wodResult ?? ""
                            showingWODResult = true
                        }) {
                            Label(part.wodResult == nil ? LocalizationKeys.Training.WOD.addResult.localized : LocalizationKeys.Training.WOD.editResult.localized, systemImage: "note.text")
                        }
                        .buttonStyle(PressableStyle())
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                // Inline add exercise removed; use top-level "Egzersiz Ekle"
            }
        }
    }

    @ViewBuilder private var progressSection: some View {
        VStack(spacing: 4) {
            ProgressView(value: Double(part.completedSets), total: Double(part.totalSets))
                .tint(partThemeColor)
            HStack {
                Text("\(part.completedSets)/\(part.totalSets) \(LocalizationKeys.Training.Stats.sets.localized)")
                    .font(.caption)
                    .foregroundColor(theme.colors.textSecondary)
                Spacer()
                Text("\(Int(part.totalVolume))kg")
                    .font(.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }
        }
    }

    private var groupedExercises: [(exercise: Exercise, sets: [ExerciseSet])] {
        let dict = Dictionary(grouping: part.exerciseSets) { $0.exercise }
        return dict.compactMap { (ex, sets) in
            guard let exercise = ex else { return nil }
            return (exercise, sets.sorted { $0.setNumber < $1.setNumber })
        }.sorted { $0.exercise.nameTR < $1.exercise.nameTR }
    }

    private var partThemeColor: Color {
        switch partType {
        case .powerStrength: return theme.colors.accent
        case .metcon: return theme.colors.warning
        case .accessory: return theme.colors.success
        case .cardio: return theme.colors.warning
        }
    }

    private func movePart(direction: Int) {
        guard let workout = part.workout else { return }
        var parts = workout.parts.sorted { $0.orderIndex < $1.orderIndex }
        guard let currentIndex = parts.firstIndex(where: { $0.id == part.id }) else { return }
        let newIndex = currentIndex + direction
        guard newIndex >= 0 && newIndex < parts.count else { return }
        parts.swapAt(currentIndex, newIndex)
        for (i, p) in parts.enumerated() { p.orderIndex = i }
        do { try modelContext.save() } catch { /* ignore */ }
    }

    private func deletePart() {
        modelContext.delete(part)
        do { try modelContext.save() } catch { /* ignore */ }
    }

    // cleanupPlaceholdersIfNeeded removed (inline selection removed)

    // MARK: - Part copy helpers
    private func duplicatePartToSameWorkout() {
        guard let workout = part.workout else { return }
        let type = WorkoutPartType.from(rawOrLegacy: part.type)
        let newPart = WorkoutPart(name: part.name + " (Kopya)", type: type, orderIndex: workout.parts.count)
        newPart.workout = workout

        // Copy sets: preserve setNumber and values, reset completion
        let ordered = part.exerciseSets.sorted { $0.setNumber < $1.setNumber }
        for s in ordered {
            let copy = ExerciseSet(
                setNumber: s.setNumber,
                weight: s.weight,
                reps: s.reps,
                duration: s.duration,
                distance: s.distance,
                rpe: nil,
                isCompleted: false
            )
            copy.exercise = s.exercise
            copy.workoutPart = newPart
            modelContext.insert(copy)
        }

        modelContext.insert(newPart)
        do { try modelContext.save(); HapticManager.shared.notification(.success) } catch { saveError = error.localizedDescription }
    }

    private func copyPartToNewWorkout() {
        let newWorkout = Workout(name: (part.workout?.name ?? LocalizationKeys.Training.Detail.defaultName.localized) + " - Kopya")
        let type = WorkoutPartType.from(rawOrLegacy: part.type)
        let newPart = WorkoutPart(name: part.name, type: type, orderIndex: 0)
        newPart.workout = newWorkout

        let ordered = part.exerciseSets.sorted { $0.setNumber < $1.setNumber }
        for s in ordered {
            let copy = ExerciseSet(
                setNumber: s.setNumber,
                weight: s.weight,
                reps: s.reps,
                duration: s.duration,
                distance: s.distance,
                rpe: nil,
                isCompleted: false
            )
            copy.exercise = s.exercise
            copy.workoutPart = newPart
            modelContext.insert(copy)
        }

        newWorkout.parts.append(newPart)
        modelContext.insert(newWorkout)
        do { try modelContext.save(); HapticManager.shared.notification(.success) } catch { saveError = error.localizedDescription }
    }
}

// MARK: - Exercise group view
struct ExerciseGroupView: View {
    let exercise: Exercise
    let sets: [ExerciseSet]
    let onAddSet: () -> Void
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext

    @State private var showAllSets: Bool = false
    @State private var editingSet: ExerciseSet? = nil
    @State private var showEditSheet: Bool = false
    @State private var confirmDeleteFor: ExerciseSet? = nil

    var completedSets: [ExerciseSet] {
        sets.filter { $0.isCompleted }
    }

    private var sortedAllSets: [ExerciseSet] {
        sets.sorted { $0.setNumber < $1.setNumber }
    }

    // MARK: - Best set (PR / En iyi)
    private var bestSet: ExerciseSet? {
        // Determine metric priority by exercise capability
        if exercise.supportsWeight {
            return completedSets.max(by: { ($0.weight ?? 0) < ($1.weight ?? 0) })
        } else if exercise.supportsDistance {
            return completedSets.max(by: { ($0.distance ?? 0) < ($1.distance ?? 0) })
        } else if exercise.supportsTime {
            return completedSets.max(by: { ($0.duration ?? 0) < ($1.duration ?? 0) })
        } else {
            return nil
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(exercise.nameTR).font(.subheadline).fontWeight(.medium)
                Spacer()
                Text(String(format: LocalizationKeys.Training.Exercise.setCount.localized, completedSets.count, sets.count))
                    .font(.caption)
                    .foregroundColor(theme.colors.textSecondary)
                Button("+ \(LocalizationKeys.Training.Stats.sets.localized)") { onAddSet() }
                    .font(.caption)
                    .foregroundColor(theme.colors.accent)
                    .buttonStyle(PressableStyle())
                    .accessibilityLabel(LocalizationKeys.Training.Exercise.addSet.localized)
            }

            ForEach(rowsToShow, id: \.id) { set in
                HStack(spacing: 8) {
                    Text(String(format: LocalizationKeys.Training.Exercise.setNumber.localized, set.setNumber))
                        .font(.caption)
                        .foregroundColor(theme.colors.textSecondary)
                        .frame(width: 50, alignment: .leading)
                    Text(set.displayText)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.9)
                        .accessibilityLabel("Set \(set.setNumber), \(set.displayText)")
                    Spacer()
                    if let best = bestSet, best.id == set.id {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill").foregroundColor(theme.colors.warning).font(.caption2)
                            Text("PR")
                                .font(.caption2)
                                .foregroundColor(theme.colors.warning)
                        }
                        .accessibilityLabel("En iyi set")
                    }
                    if set.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(theme.colors.success)
                            .accessibilityLabel(LocalizationKeys.Common.completed.localized)
                    }
                    Button { beginEdit(set) } label: {
                        Image(systemName: "pencil")
                            .font(.caption)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    .accessibilityLabel(LocalizationKeys.Common.edit.localized)
                    Button(role: .destructive) { confirmDeleteFor = set } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                    }
                    .accessibilityLabel(LocalizationKeys.Common.delete.localized)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        confirmDeleteFor = set
                    } label: {
                        Label(LocalizationKeys.Common.delete.localized, systemImage: "trash")
                    }
                    Button {
                        beginEdit(set)
                    } label: {
                        Label(LocalizationKeys.Common.edit.localized, systemImage: "pencil")
                    }
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button {
                        completeAllSets()
                    } label: {
                        Label(LocalizationKeys.Common.completed.localized, systemImage: "checkmark.circle")
                    }
                    .tint(.green)
                }
                .accessibilityElement(children: .combine)
            }

            if completedSets.count > 3 {
                Button(showAllSets ? LocalizationKeys.Common.close.localized : LocalizationKeys.Training.History.seeMore.localized) {
                    withAnimation { showAllSets.toggle() }
                }
                .font(.caption)
                .foregroundColor(theme.colors.accent)
            }
        }
        .padding(.vertical, theme.spacing.s)
        .padding(.horizontal, theme.spacing.s)
        .background(theme.colors.cardBackground)
        .cornerRadius(6)
        .confirmationDialog(LocalizationKeys.Common.confirmDelete.localized, isPresented: Binding(get: { confirmDeleteFor != nil }, set: { if !$0 { confirmDeleteFor = nil } }), titleVisibility: .visible) {
            Button(LocalizationKeys.Common.delete.localized, role: .destructive) { deleteSelected() }
            Button(LocalizationKeys.Common.cancel.localized, role: .cancel) {}
        }
        .sheet(isPresented: $showEditSheet, onDismiss: { editingSet = nil }) {
            if let set = editingSet {
                EditExerciseSetSheet(exercise: exercise, set: set) { updated in
                    // Persist changes
                    do { try modelContext.save() } catch { /* ignore for now; parent alerts handle */ }
                }
            }
        }
    }

    private var rowsToShow: [ExerciseSet] {
        let rows = showAllSets ? sortedAllSets : Array(completedSets.prefix(3))
        return rows
    }

    private func beginEdit(_ set: ExerciseSet) {
        editingSet = set
        showEditSheet = true
    }

    private func deleteSelected() {
        guard let target = confirmDeleteFor else { return }
        modelContext.delete(target)
        do { try modelContext.save() } catch { /* ignore */ }
        confirmDeleteFor = nil
    }

    private func completeAllSets() {
        for s in sets {
            s.isCompleted = true
        }
        do { try modelContext.save() } catch { /* ignore */ }
        HapticManager.shared.notification(.success)
    }
}

// MARK: - Action bar and helpers
struct AddPartButton: View {
    let action: () -> Void
    @Environment(\.theme) private var theme
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "plus.circle.fill").foregroundColor(theme.colors.accent)
                    .accessibilityLabel(LocalizationKeys.Training.Detail.addPart.localized)
                Text(LocalizationKeys.Training.Detail.addPart.localized).fontWeight(.medium)
                Spacer()
            }
            .padding()
            .background(theme.colors.accent.opacity(0.1))
            .cornerRadius(12)
        }
        .foregroundColor(theme.colors.accent)
        .buttonStyle(PressableStyle())
    }
}

// MARK: - Edit Exercise Set Sheet
private struct EditExerciseSetSheet: View {
    let exercise: Exercise
    @Bindable var set: ExerciseSet
    let onSave: (ExerciseSet) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme

    @State private var weightText: String = ""
    @State private var repsText: String = ""
    @State private var minutesText: String = ""
    @State private var secondsText: String = ""
    @State private var distanceText: String = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                if exercise.supportsWeight {
                    HStack {
                        Text(LocalizationKeys.Training.Set.Header.weight.localized).frame(width: 100, alignment: .leading)
                        TextField(LocalizationKeys.Training.Set.kg.localized, text: $weightText)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                if exercise.supportsReps {
                    HStack {
                        Text(LocalizationKeys.Training.Set.Header.reps.localized).frame(width: 100, alignment: .leading)
                        TextField(LocalizationKeys.Training.Set.reps.localized, text: $repsText)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                if exercise.supportsTime {
                    HStack {
                        Text(LocalizationKeys.Training.Set.Header.time.localized).frame(width: 100, alignment: .leading)
                        HStack(spacing: 6) {
                            TextField("MM", text: $minutesText).keyboardType(.numberPad).frame(width: 60)
                            Text(":")
                            TextField("SS", text: $secondsText).keyboardType(.numberPad).frame(width: 60)
                        }
                    }
                }
                if exercise.supportsDistance {
                    HStack {
                        Text(LocalizationKeys.Training.Set.Header.distance.localized).frame(width: 100, alignment: .leading)
                        TextField(LocalizationKeys.Training.Set.meters.localized, text: $distanceText)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                Spacer()
            }
            .padding()
            .navigationTitle(LocalizationKeys.Common.edit.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizationKeys.Common.cancel.localized) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizationKeys.Common.save.localized) { applyAndSave() }
                        .disabled(!isValid)
                }
            }
            .onAppear { loadFromSet() }
        }
    }

    private func loadFromSet() {
        if let w = set.weight { weightText = String(format: "%g", w) }
        if let r = set.reps { repsText = String(r) }
        if let d = set.duration { minutesText = String(d / 60); secondsText = String(d % 60) }
        if let dist = set.distance { distanceText = String(format: "%g", dist) }
    }

    private var isValid: Bool {
        // Any field can be empty; no strict validation beyond numeric formats
        if !weightText.isEmpty && Double(weightText) == nil { return false }
        if !repsText.isEmpty && Int(repsText) == nil { return false }
        if (!minutesText.isEmpty || !secondsText.isEmpty) && (Int(minutesText) == nil || Int(secondsText) == nil) { return false }
        if !distanceText.isEmpty && Double(distanceText) == nil { return false }
        return true
    }

    private func applyAndSave() {
        // Write back parsed values (nil if empty or zero)
        if let w = Double(weightText), w > 0 { set.weight = w } else { set.weight = nil }
        if let r = Int(repsText), r > 0 { set.reps = Int16(r) } else { set.reps = nil }
        let mins = Int(minutesText) ?? 0
        let secs = Int(secondsText) ?? 0
        let total = max(0, mins * 60 + min(max(0, secs), 59))
        set.duration = total > 0 ? Int32(total) : nil
        if let dist = Double(distanceText), dist > 0 { set.distance = dist } else { set.distance = nil }

        onSave(set)
        dismiss()
    }
}

struct AddExercisesButton: View {
    let action: () -> Void
    @Environment(\.theme) private var theme
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "plus")
                    .foregroundColor(theme.colors.success)
                    .accessibilityLabel(LocalizationKeys.Training.Part.addExercise.localized)
                Text(LocalizationKeys.Training.Part.addExercise.localized)
                    .fontWeight(.medium)
                Spacer()
            }
            .padding()
            .background(theme.colors.success.opacity(0.1))
            .cornerRadius(12)
        }
        .foregroundColor(theme.colors.success)
        .buttonStyle(PressableStyle())
    }
}

struct WorkoutActionBar: View {
    @Environment(\.theme) private var theme
    let workout: Workout
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            HStack {
                HStack(spacing: theme.spacing.l) {
                    StatBadge(title: LocalizationKeys.Training.Stats.parts.localized, value: "\(workout.parts.count)")
                    StatBadge(title: LocalizationKeys.Training.Stats.sets.localized, value: "\(workout.totalSets)")
                    StatBadge(title: LocalizationKeys.Training.Stats.volume.localized, value: "\(Int(workout.totalVolume))kg")
                }

                Spacer()

                Button(action: onFinish) {
                    Text(LocalizationKeys.Training.Detail.finishWorkout.localized)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, theme.spacing.l)
                        .padding(.vertical, theme.spacing.m)
                        .background(theme.colors.success)
                        .cornerRadius(8)
                }
                .buttonStyle(PressableStyle())
            }
            .padding(theme.spacing.m)
        }
        .background(.ultraThinMaterial)
    }
}

private struct ActionChip: View {
    @Environment(\.theme) private var theme
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: theme.spacing.s) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, theme.spacing.m)
            .padding(.vertical, theme.spacing.s)
            .background(color.opacity(0.12))
            .foregroundColor(color)
            .cornerRadius(16)
        }
        .buttonStyle(PressableStyle())
    }
}

struct StatBadge: View {
    let title: String
    let value: String
    @Environment(\.theme) private var theme
    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.headline).fontWeight(.semibold)
            Text(title).font(.caption).foregroundColor(theme.colors.textSecondary)
        }
    }
}

// MARK: - WOD Create Button
struct WODCreateButton: View {
    let title: String
    let action: () -> Void
    @Environment(\.theme) private var theme
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "figure.cross.training")
                    .foregroundColor(theme.colors.warning)
                Text(title)
                    .fontWeight(.medium)
                Spacer()
            }
            .padding()
            .background(theme.colors.warning.opacity(0.1))
            .cornerRadius(12)
        }
        .foregroundColor(theme.colors.warning)
        .buttonStyle(PressableStyle())
    }
}

// MARK: - Manual WOD Builder (For Time - simple)
struct WODManualBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    let part: WorkoutPart
    let onSaveScore: (String) -> Void

    @State private var wodName: String = ""
    @State private var selectedType: WODType = .forTime
    @State private var repScheme: String = "21-15-9"
    @State private var movementsText: String = ""
    @State private var showRunner: Bool = false
    @State private var builtMovements: [String] = []
    @State private var builtScheme: [Int] = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Picker("", selection: $selectedType) {
                    Text("For Time").tag(WODType.forTime)
                    Text("AMRAP").tag(WODType.amrap)
                    Text("EMOM").tag(WODType.emom)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text(titleForSelectedType)
                        .font(.headline)
                    TextField(LocalizationKeys.Training.WOD.Builder.namePlaceholder.localized, text: $wodName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    TextField(selectedType == .forTime ? LocalizationKeys.Training.WOD.Builder.schemePlaceholderForTime.localized : LocalizationKeys.Training.WOD.Builder.schemePlaceholderAmrap.localized, text: $repScheme)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(isSchemeValid ? Color.clear : Color.red.opacity(0.6), lineWidth: 1)
                        )
                    Text(selectedType == .forTime ? LocalizationKeys.Training.WOD.Builder.schemeHintForTime.localized : LocalizationKeys.Training.WOD.Builder.schemeHintAmrap.localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField(LocalizationKeys.Training.WOD.Builder.movementsPlaceholder.localized, text: $movementsText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(isMovementsValid ? Color.clear : Color.red.opacity(0.6), lineWidth: 1)
                        )
                    Text(LocalizationKeys.Training.WOD.Builder.movementsHint.localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)

                Spacer()

                Button(action: startRunner) {
                    Text(LocalizationKeys.Training.WOD.Builder.start.localized)
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(theme.spacing.m)
                        .background(isFormValid ? theme.colors.success : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(!isFormValid)
                .buttonStyle(PressableStyle())
                .padding(.horizontal)
            }
            .navigationTitle("WOD Oluştur")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizationKeys.Common.cancel.localized) { dismiss() }
                }
            }
            .sheet(isPresented: $showRunner) {
                WODRunnerSimpleView(
                    name: displayedName,
                    wodType: selectedType,
                    scheme: builtScheme,
                    movements: builtMovements
                ) { score in
                    // Persist minimal: name → template id yok; result → score text
                    if !wodName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        part.name = wodName
                    }
                    onSaveScore(score)
                    dismiss()
                }
            }
        }
        .onAppear {
            if let tmpl = WODLookup.template(for: part.wodTemplateId) {
                wodName = tmpl.name
                repScheme = inferScheme(from: tmpl.movements) ?? repScheme
                movementsText = inferMovements(from: tmpl.movements).joined(separator: ", ")
            }
        }
    }

    private var isFormValid: Bool {
        isMovementsValid && isSchemeValid
    }

    private var isMovementsValid: Bool { !parseMovements().isEmpty }
    private var isSchemeValid: Bool { !parseScheme().isEmpty }

    private var displayedName: String {
        if !wodName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return wodName }
        return WODLookup.name(for: part.wodTemplateId) ?? "WOD"
    }

    private var titleForSelectedType: String {
        switch selectedType {
        case .forTime: return "For Time"
        case .amrap: return "AMRAP"
        case .emom: return "EMOM"
        case .custom: return "WOD"
        }
    }

    private func startRunner() {
        builtMovements = parseMovements()
        builtScheme = parseScheme()
        #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
        if isFormValid {
            HapticManager.shared.impact(.light)
            DispatchQueue.main.async { showRunner = true }
        }
    }

    private func parseMovements() -> [String] {
        let separators = CharacterSet(charactersIn: ",\n")
        return movementsText
            .components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func parseScheme() -> [Int] {
        repScheme
            .split(separator: "-")
            .compactMap { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
            .filter { $0 > 0 }
    }

    // Heuristic: try find a pattern like "21-15-9" in movements description array
    private func inferScheme(from lines: [String]) -> String? {
        for l in lines {
            let cleaned = l.replacingOccurrences(of: " ", with: "")
            if cleaned.range(of: "^([0-9]+-)+[0-9]+$", options: .regularExpression) != nil {
                return cleaned
            }
        }
        return nil
    }

    private func inferMovements(from lines: [String]) -> [String] {
        // Return non-numeric movement lines
        return lines.filter { $0.range(of: "[a-zA-Z]", options: .regularExpression) != nil }
    }
}

// MARK: - Simple Runner (checklist + score input)
struct WODRunnerSimpleView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme

    let name: String
    let wodType: WODType
    let scheme: [Int]
    let movements: [String]
    let onFinish: (String) -> Void

    @State private var steps: [RunnerStep] = []
    @State private var showScoreSheet: Bool = false
    @State private var scoreText: String = ""
    @State private var amrapRounds: Int = 1
    @State private var minutesInput: String = ""
    @State private var secondsInput: String = ""
    @State private var showTip: Bool = false
    @State private var showExitConfirm: Bool = false
    @AppStorage("preferences.haptic_feedback_enabled") private var hapticsEnabled: Bool = true
    @FocusState private var minutesFocused: Bool
    @FocusState private var secondsFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    HStack(alignment: .center, spacing: 8) {
                        Text(name).font(.headline)
                        WODTypeChip(type: wodType)
                        Spacer()
                        if wodType == .forTime {
                            Text(String(format: LocalizationKeys.Training.WOD.Runner.stepsProgress.localized, doneCount, steps.count))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else if wodType == .amrap {
                            Text(String(format: LocalizationKeys.Training.WOD.Runner.roundsLabel.localized, amrapRounds))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        ProgressRing(progress: steps.isEmpty ? 0 : Double(doneCount) / Double(steps.count), size: 28, lineWidth: 4)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                if showTip {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "lightbulb")
                            .foregroundColor(theme.colors.warning)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(LocalizationKeys.Training.WOD.Runner.tipTitle.localized)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text(LocalizationKeys.Training.WOD.Runner.tipBody.localized)
                                .font(.caption)
                                .foregroundColor(theme.colors.textSecondary)
                        }
                        Spacer()
                        Button(LocalizationKeys.Common.done.localized) {
                            showTip = false
                            UserDefaults.standard.set(true, forKey: "training.wod.runner.tip_shown")
                            HapticManager.shared.impact(.light)
                        }
                        .buttonStyle(PressableStyle())
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(theme.colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(theme.colors.textSecondary.opacity(0.15), lineWidth: 1)
                    )
                    .cornerRadius(10)
                    .padding(.horizontal)
                }

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            if wodType == .amrap {
                                // Group by round
                                let roundNumbers: [Int] = Array(Set(steps.compactMap { $0.round })).sorted()
                                ForEach(roundNumbers, id: \.self) { round in
                                    // Round header (compact)
                                    HStack(spacing: 8) {
                                        Rectangle()
                                            .fill(theme.colors.textSecondary.opacity(0.4))
                                            .frame(width: 2, height: 16)
                                            .cornerRadius(1)
                                        Text("Round \(round)")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(theme.colors.textSecondary)
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                    .padding(.top, 4)
                                    // Steps in this round
                                    ForEach(steps.indices.filter { steps[$0].round == round }, id: \.self) { idx in
                                        HStack(alignment: .center) {
                                            Rectangle()
                                                .fill(steps[idx].isDone ? theme.colors.success : Color(.systemGray4))
                                                .frame(width: 3)
                                            Text(steps[idx].title)
                                                .font(.body)
                                                .foregroundColor(.primary)
                                            Spacer()
                                            Button(action: { toggle(idx, proxy) }) {
                                                Image(systemName: steps[idx].isDone ? "checkmark.circle.fill" : "circle")
                                                    .font(.title2)
                                                    .foregroundColor(steps[idx].isDone ? theme.colors.success : .secondary)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                        .padding(.horizontal)
                                        .padding(.vertical, 12)
                                        .background(steps[idx].isDone ? Color.green.opacity(0.08) : theme.colors.cardBackground)
                                        .cornerRadius(10)
                                        .id(steps[idx].id)
                                    }
                                }
                            } else {
                                ForEach(steps.indices, id: \.self) { idx in
                                    HStack(alignment: .center) {
                                        Rectangle()
                                            .fill(steps[idx].isDone ? theme.colors.success : Color(.systemGray4))
                                            .frame(width: 3)
                                        Text(steps[idx].title)
                                            .font(.body)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Button(action: { toggle(idx, proxy) }) {
                                            Image(systemName: steps[idx].isDone ? "checkmark.circle.fill" : "circle")
                                                .font(.title2)
                                                .foregroundColor(steps[idx].isDone ? theme.colors.success : .secondary)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 12)
                                    .background(steps[idx].isDone ? Color.green.opacity(0.08) : theme.colors.cardBackground)
                                    .cornerRadius(10)
                                    .id(steps[idx].id)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                }

                HStack(spacing: theme.spacing.m) {
                    Button(LocalizationKeys.Training.WOD.Runner.undo.localized) { undoLast() }
                        .disabled(lastDoneIndex == nil)
                        .buttonStyle(PressableStyle())
                    if wodType == .amrap {
                        Text(String(format: LocalizationKeys.Training.WOD.Runner.extraReps.localized, extraReps)).font(.caption).foregroundColor(.secondary)
                    }
                    if wodType == .amrap {
                        Button(LocalizationKeys.Training.WOD.Runner.addRound.localized) { addAmrapRound() }
                            .buttonStyle(PressableStyle())
                    }
                    Spacer()
                    if wodType == .forTime {
                        Button(LocalizationKeys.Training.WOD.Runner.scoreButton.localized) { showScoreSheet = true }
                            .disabled(!allDone)
                            .buttonStyle(PressableStyle())
                            .foregroundColor(.white)
                            .padding(.horizontal, theme.spacing.l)
                            .padding(.vertical, theme.spacing.s)
                            .background(allDone ? theme.colors.success : Color.gray)
                            .cornerRadius(10)
                                .onChange(of: allDone) { _, isDone in if isDone { HapticManager.shared.notification(.success) } }
                    } else if wodType == .amrap {
                        Button(LocalizationKeys.Training.WOD.Runner.finish.localized) { finishAmrap() }
                            .buttonStyle(PressableStyle())
                            .foregroundColor(.white)
                            .padding(.horizontal, theme.spacing.l)
                            .padding(.vertical, theme.spacing.s)
                            .background(theme.colors.success)
                            .cornerRadius(10)
                    } else if wodType == .emom {
                        Button(LocalizationKeys.Training.WOD.Runner.finish.localized) { onFinish(""); dismiss() }
                            .buttonStyle(PressableStyle())
                            .foregroundColor(.white)
                            .padding(.horizontal, theme.spacing.l)
                            .padding(.vertical, theme.spacing.s)
                            .background(theme.colors.success)
                            .cornerRadius(10)
                    }
                }
                .padding()
            }
            .navigationTitle("WOD")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button(LocalizationKeys.Common.close.localized) { handleClose() } } }
            .onAppear { buildInitialSteps() }
            .onAppear {
                #if canImport(UIKit)
                UIApplication.shared.isIdleTimerDisabled = true
                #endif
                let seen = UserDefaults.standard.bool(forKey: "training.wod.runner.tip_shown")
                if !seen { showTip = true }
            }
            .onDisappear {
                #if canImport(UIKit)
                UIApplication.shared.isIdleTimerDisabled = false
                #endif
            }
            .sheet(isPresented: $showScoreSheet) {
                NavigationView {
                    VStack(spacing: 12) {
                        Text(LocalizationKeys.Training.WOD.Runner.scoreTitle.localized)
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        HStack(spacing: 8) {
                            TextField("MM", text: $minutesInput)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 70)
                                .focused($minutesFocused)
                                .onChange(of: minutesInput) { _, newValue in
                                    if newValue.count >= 2 { secondsFocused = true }
                                }
                            Text(":")
                            TextField("SS", text: $secondsInput)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 70)
                                .focused($secondsFocused)
                                .onChange(of: secondsInput) { _, newValue in
                                    // Keep only digits and cap to 2 chars, then auto-dismiss
                                    let digits = newValue.filter { $0.isNumber }
                                    if digits != newValue { secondsInput = digits }
                                    if digits.count >= 2 {
                                        secondsInput = String(digits.prefix(2))
                                        secondsFocused = false
                                        #if canImport(UIKit)
                                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                        #endif
                                    }
                                }
                        }
                        Spacer()
                    }
                    .padding()
                    .navigationTitle("WOD Skoru")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) { Button(LocalizationKeys.Common.cancel.localized) { showScoreSheet = false } }
                        ToolbarItem(placement: .confirmationAction) {
                            Button(LocalizationKeys.Common.save.localized) {
                                let m = Int(minutesInput) ?? 0
                                let s = Int(secondsInput) ?? 0
                                let ss = String(format: "%02d", max(0, min(59, s)))
                                onFinish("\(max(0,m)):\(ss)")
                                dismiss()
                                if hapticsEnabled { HapticManager.shared.notification(.success) }
                            }.disabled(!isValidTimeInputs())
                        }
                    }
                }
                .presentationDetents([.medium])
                .onAppear { minutesFocused = true }
            }
            .alert(isPresented: $showExitConfirm) {
                Alert(
                    title: Text(LocalizationKeys.Common.confirmDiscard.localized),
                    message: Text(LocalizationKeys.Common.discardMessage.localized),
                    primaryButton: .destructive(Text(LocalizationKeys.Common.discard.localized)) { dismiss() },
                    secondaryButton: .cancel(Text(LocalizationKeys.Common.cancel.localized))
                )
            }
        }
    }

    private var allDone: Bool { steps.allSatisfy { $0.isDone } && !steps.isEmpty }
    private var lastDoneIndex: Int? { steps.lastIndex(where: { $0.isDone }) }
    private var doneCount: Int { steps.filter { $0.isDone }.count }
    private var extraReps: Int {
        let total = steps.reduce(0) { partial, step in partial + (step.isDone ? extractReps(from: step.title) : 0) }
        let perRound = amrapPerMovementReps().reduce(0, +)
        if perRound == 0 { return 0 }
        return total % perRound
    }

    private func buildInitialSteps() {
        switch wodType {
        case .forTime:
            steps = buildForTimeSteps()
        case .amrap:
            steps = buildAmrapRound(currentRound: 1)
        case .emom:
            // Optional: simple checklist from one interval
            steps = buildEmomSkeleton()
        case .custom:
            steps = buildForTimeSteps()
        }
    }

    private func toggle(_ idx: Int) {
        guard steps.indices.contains(idx) else { return }
        steps[idx].isDone.toggle()
        if hapticsEnabled { HapticManager.shared.impact(.light) }
    }

    private func toggle(_ idx: Int, _ proxy: ScrollViewProxy) {
        toggle(idx)
        // Auto scroll to next incomplete step
        if let nextIndex = steps.firstIndex(where: { !$0.isDone }) {
            let targetId = steps[nextIndex].id
            DispatchQueue.main.async {
                withAnimation { proxy.scrollTo(targetId, anchor: .center) }
            }
        }
    }

    private func undoLast() {
        if let idx = lastDoneIndex { steps[idx].isDone = false }
        if hapticsEnabled { HapticManager.shared.impact(.light) }
    }

    struct RunnerStep: Identifiable {
        let id = UUID()
        let title: String
        var isDone: Bool
        var round: Int? = nil
    }

    // MARK: - Builders
    private func buildForTimeSteps() -> [RunnerStep] {
        var result: [RunnerStep] = []
        for reps in scheme {
            for mv in movements {
                result.append(RunnerStep(title: "\(reps) \(mv)", isDone: false))
            }
        }
        return result
    }

    private func buildAmrapRound(currentRound: Int) -> [RunnerStep] {
        // Determine reps per movement for a single round
        let perMovementReps: [Int] = {
            if scheme.count == 1 { return Array(repeating: scheme[0], count: movements.count) }
            if scheme.count == movements.count { return scheme }
            return Array(repeating: scheme.first ?? 10, count: movements.count)
        }()
        var result: [RunnerStep] = []
        for (idx, mv) in movements.enumerated() {
            result.append(RunnerStep(title: "\(perMovementReps[idx]) \(mv)", isDone: false, round: currentRound))
        }
        return result
    }

    private func buildEmomSkeleton() -> [RunnerStep] {
        // Minimal: list movements once
        return movements.map { RunnerStep(title: $0, isDone: false) }
    }

    private func addAmrapRound() {
        amrapRounds += 1
        steps.append(contentsOf: buildAmrapRound(currentRound: amrapRounds))
    }

    private func finishAmrap() {
        // Sum all completed step reps
        let total = steps.reduce(0) { partial, step in
            partial + (step.isDone ? extractReps(from: step.title) : 0)
        }
        let repsPerRound = amrapPerMovementReps().reduce(0, +)
        let rounds = repsPerRound > 0 ? total / repsPerRound : 0
        let extra = repsPerRound > 0 ? total % repsPerRound : 0
        let text = extra > 0 ? "\(rounds) rounds + \(extra) reps" : "\(rounds) rounds"
        onFinish(text)
        dismiss()
        if hapticsEnabled { HapticManager.shared.notification(.success) }
    }

    private func extractReps(from title: String) -> Int {
        let components = title.split(separator: " ")
        if let first = components.first, let reps = Int(first) { return reps }
        return 0
    }

    private func amrapPerMovementReps() -> [Int] {
        if scheme.count == 1 { return Array(repeating: scheme[0], count: movements.count) }
        if scheme.count == movements.count { return scheme }
        return Array(repeating: scheme.first ?? 10, count: movements.count)
    }

    // MARK: - Time validation
    private func isValidTime(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.split(separator: ":")
        if parts.count != 2 { return false }
        guard let m = Int(parts[0]), let s = Int(parts[1]), m >= 0, (0...59).contains(s) else { return false }
        return true
    }

    private func normalizeTime(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.split(separator: ":")
        if parts.count == 2, let m = Int(parts[0]), let s = Int(parts[1]) {
            let mm = String(format: "%d", m)
            let ss = String(format: "%02d", s)
            return "\(mm):\(ss)"
        }
        return trimmed
    }

    private func isValidTimeInputs() -> Bool {
        guard let m = Int(minutesInput), let s = Int(secondsInput) else { return false }
        return m >= 0 && (0...59).contains(s)
    }
    
    private func handleClose() {
        let hasProgress = steps.contains { $0.isDone }
        if hasProgress && wodType == .forTime && minutesInput.isEmpty && secondsInput.isEmpty {
            showExitConfirm = true
        } else {
            dismiss()
        }
    }
}

// MARK: - Progress Ring
struct ProgressRing: View {
    let progress: Double // 0.0...1.0
    let size: CGFloat
    let lineWidth: CGFloat
    @Environment(\.theme) private var theme
    @State private var popScale: CGFloat = 1.0
    @State private var hasCelebrated: Bool = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: lineWidth)
            let ringColor = progress >= 1 ? theme.colors.success : theme.colors.accent
            Circle()
                .trim(from: 0, to: CGFloat(max(0, min(1, progress))))
                .stroke(ringColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
        .animation(.easeInOut(duration: 0.2), value: progress)
        .scaleEffect(popScale)
        .onChange(of: progress) { old, newValue in
            if newValue >= 1.0 && !hasCelebrated {
                hasCelebrated = true
                HapticManager.shared.notification(.success)
                withAnimation(.spring(response: 0.18, dampingFraction: 0.5)) { popScale = 1.08 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                    withAnimation(.spring(response: 0.22, dampingFraction: 0.7)) { popScale = 1.0 }
                }
            }
            if newValue < 1.0 {
                hasCelebrated = false
            }
        }
    }
}

// MARK: - WOD Type Chip
struct WODTypeChip: View {
    let type: WODType
    @Environment(\.theme) private var theme
    private var label: String {
        switch type {
        case .forTime: return LocalizationKeys.Training.WOD.forTime.localized
        case .amrap: return LocalizationKeys.Training.WOD.amrap.localized
        case .emom: return LocalizationKeys.Training.WOD.emom.localized
        case .custom: return LocalizationKeys.Training.WOD.title.localized
        }
    }
    private var icon: String {
        switch type {
        case .forTime: return "timer"
        case .amrap: return "arrow.triangle.2.circlepath"
        case .emom: return "metronome"
        case .custom: return "figure.cross.training"
        }
    }
    private var color: Color {
        switch type {
        case .forTime: return theme.colors.accent
        case .amrap: return theme.colors.warning
        case .emom: return theme.colors.success
        case .custom: return .secondary
        }
    }
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(label)
                .font(.caption2)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.12))
        .foregroundColor(color)
        .cornerRadius(6)
    }
}

// MARK: - Add Part Quick Sheet (4-card)
struct AddPartQuickSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.theme) private var theme
    let workout: Workout

    @State private var saveError: String? = nil

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                VStack(spacing: 6) {
                    Text(LocalizationKeys.Training.AddPart.title.localized)
                        .font(.title).fontWeight(.bold)
                    Text(LocalizationKeys.Training.AddPart.subtitle.localized)
                        .font(.subheadline).foregroundColor(.secondary)
                }
                .padding(.top)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    partCard(.powerStrength)
                    partCard(.metcon)
                    partCard(.accessory)
                    partCard(.cardio)
                }
                .padding(.horizontal)

                Spacer(minLength: 8)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizationKeys.Training.AddPart.cancel.localized) { dismiss() }
                }
            }
        }
        .alert(isPresented: Binding<Bool>(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )) {
            Alert(
                title: Text(LocalizationKeys.Common.error.localized),
                message: Text(saveError ?? ""),
                dismissButton: .default(Text(LocalizationKeys.Common.ok.localized))
            )
        }
    }

    @ViewBuilder
    private func partCard(_ type: WorkoutPartType) -> some View {
        Button {
            let name = {
                switch type {
                case .powerStrength: return LocalizationKeys.Training.Part.powerStrength.localized
                case .metcon: return LocalizationKeys.Training.Part.metcon.localized
                case .accessory: return LocalizationKeys.Training.Part.accessory.localized
                case .cardio: return LocalizationKeys.Training.Part.cardio.localized
                }
            }()
            _ = workout.addPart(name: name, type: type)
            do { try modelContext.save(); dismiss() } catch { saveError = error.localizedDescription }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: type.icon)
                    .font(.title2)
                    .foregroundColor(type.color)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 4) {
                    Text(type.displayName).font(.headline)
                    Text(type.description).font(.caption).foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding()
            .background(Color(.systemBackground))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(type.color.opacity(0.3), lineWidth: 2))
            .cornerRadius(12)
        }
        .buttonStyle(PressableStyle())
    }
}

struct PartTypeSelectionRow: View {
    let partType: WorkoutPartType
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.theme) private var theme

    var localizedDisplayName: String {
        switch partType {
        case .powerStrength:
            return LocalizationKeys.Training.Part.powerStrength.localized
        case .metcon:
            return LocalizationKeys.Training.Part.metcon.localized
        case .accessory:
            return LocalizationKeys.Training.Part.accessory.localized
        case .cardio:
            return LocalizationKeys.Training.Part.cardio.localized
        }
    }
    
    var localizedDescription: String {
        switch partType {
        case .powerStrength:
            return LocalizationKeys.Training.Part.powerStrengthDesc.localized
        case .metcon:
            return LocalizationKeys.Training.Part.metconDesc.localized
        case .accessory:
            return LocalizationKeys.Training.Part.accessoryDesc.localized
        case .cardio:
            return LocalizationKeys.Training.Part.cardioDesc.localized
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: partType.icon)
                    .font(.title2).foregroundColor(partColor).frame(width: 30)
                VStack(alignment: .leading, spacing: 2) {
                    Text(localizedDisplayName).font(.headline).foregroundColor(.primary)
                    Text(localizedDescription).font(.caption).foregroundColor(theme.colors.textSecondary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(partColor).font(.title2)
                }
            }
            .padding()
            .background(theme.colors.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? partColor : Color.clear, lineWidth: 2)
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var partColor: Color {
        switch partType {
        case .powerStrength: return theme.colors.accent
        case .metcon: return theme.colors.warning
        case .accessory: return theme.colors.success
        case .cardio: return theme.colors.warning
        }
    }
}

// MARK: - Rename Part Sheet
struct RenamePartSheet: View {
    @Environment(\.dismiss) private var dismiss
    let initialName: String
    let onSave: (String) -> Void
    @State private var name: String = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                TextField(LocalizationKeys.Training.AddPart.nameLabel.localized, text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                Spacer()
                Button(LocalizationKeys.Common.save.localized) {
                    onSave(name.isEmpty ? initialName : name)
                    dismiss()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background((name.isEmpty ? initialName : name).isEmpty ? Color.gray : Color.blue)
                .cornerRadius(12)
                .padding(.horizontal)
                .accessibilityLabel(LocalizationKeys.Common.save.localized)
            }
            .navigationTitle(LocalizationKeys.Training.Part.rename.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button(LocalizationKeys.Common.cancel.localized) { dismiss() }.accessibilityLabel(LocalizationKeys.Common.cancel.localized) } }
            .onAppear { name = initialName }
        }
    }
}

// MARK: - Preview
#Preview {
    let workout = Workout(name: "Test Antrenman")
    WorkoutDetailView(workout: workout)
        .modelContainer(for: [Workout.self, WorkoutPart.self, ExerciseSet.self, Exercise.self], inMemory: true)
}
