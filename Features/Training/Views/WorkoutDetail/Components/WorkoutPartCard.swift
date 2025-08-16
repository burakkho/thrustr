import SwiftUI
import SwiftData

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
    @State private var toastMessage: String? = nil
    // Callback to notify parent when exercise is added
    var onExerciseAdded: (() -> Void)? = nil

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
            Button(LocalizationKeys.Training.Part.copyPart.localized) { duplicatePartToSameWorkout() }
            Button(LocalizationKeys.Training.Part.copyToNewWorkout.localized) { copyPartToNewWorkout() }
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
                        do { try modelContext.save() } catch { toastMessage = error.localizedDescription }
                    }
                    // Notify parent that exercise was added/modified
                    onExerciseAdded?()
                }
            }
        }
            .sheet(isPresented: $showingWODResult) {
            NavigationView {
                VStack(spacing: 16) {
                    Text(LocalizationKeys.Training.WOD.scoreTitleCompact.localized)
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    TextField("\(LocalizationKeys.Training.WOD.round.localized) 1, 12:34…", text: $wodTemp, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                    Spacer()
                }
                .padding()
                .navigationTitle(LocalizationKeys.Training.WOD.title.localized)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(
                    leading: Button(LocalizationKeys.Common.cancel.localized) { showingWODResult = false },
                    trailing: Button(LocalizationKeys.Common.save.localized) {
                        part.wodResult = wodTemp.trimmingCharacters(in: .whitespacesAndNewlines)
                        // Dismiss first so UI reflects instantly, then persist asynchronously
                        showingWODResult = false
                        DispatchQueue.main.async {
                            do { try modelContext.save() } catch { saveError = error.localizedDescription }
                            // Notify parent that WOD result was updated
                            onExerciseAdded?()
                        }
                    }.disabled(wodTemp.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                )
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showingWODAdd) {
            // WOD selection temporarily disabled - use WOD tab instead
            Text("Please use the WOD tab to create and manage WODs")
                .padding()
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
        .modifier(ToastModifier(message: $toastMessage))
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
            VStack(alignment: .leading, spacing: 12) {
                // WOD Header with actions
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        let name = LocalizationKeys.Training.WOD.title.localized
                        Text(name)
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        // Show WOD type and result
                        HStack(spacing: 8) {
                            if part.wodTemplateId != nil {
                                Text("WOD")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.orange.opacity(0.2))
                                    .cornerRadius(4)
                            } else if let t = part.wodTypeEnum {
                                Text(t == .forTime ? "For Time" : t == .amrap ? "AMRAP" : t == .emom ? "EMOM" : "Custom")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.orange.opacity(0.2))
                                    .cornerRadius(4)
                            }
                            
                            if !wodResult.isEmpty {
                                Text(wodResult)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .background(Color.green.opacity(0.2))
                                    .cornerRadius(6)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Button {
                            wodTemp = wodResult
                            showingWODResult = true
                        } label: { 
                            Image(systemName: "pencil")
                                .foregroundColor(.blue)
                        }
                        Button(role: .destructive) {
                            part.wodResult = nil
                            do { try modelContext.save() } catch { toastMessage = error.localizedDescription }
                        } label: { 
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                // WOD Movements - Always visible
                if part.wodTemplateId != nil {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Hareketler:")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        ForEach(part.wodMovements, id: \.self) { mv in
                            HStack(spacing: 8) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                                    .foregroundColor(theme.colors.accent)
                                Text(mv)
                                    .font(part.wodMovements.count <= 3 ? .headline : .subheadline)
                                    .foregroundColor(.primary)
                                    .fontWeight(part.wodMovements.count <= 3 ? .medium : .regular)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                } else if part.wodTemplateId == nil, part.wodTypeEnum != nil, !part.wodMovements.isEmpty {
                    // Custom WOD movements
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Hareketler:")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        ForEach(part.wodMovements, id: \.self) { mv in
                            HStack(spacing: 8) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                                    .foregroundColor(theme.colors.accent)
                                Text(mv)
                                    .font(part.wodMovements.count <= 3 ? .headline : .subheadline)
                                    .foregroundColor(.primary)
                                    .fontWeight(part.wodMovements.count <= 3 ? .medium : .regular)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        } else {
            VStack(spacing: 10) {
                // Accordion exercise cards
                ForEach(groupedExercises, id: \.exercise.id) { group in
                    AccordionExerciseCard(
                        exercise: group.exercise,
                        sets: .constant(group.sets),
                        onNavigateToAdvancedEdit: { exercise, sets in
                            selectedExercise = exercise
                            showingSetTracking = true
                        }
                    )
                    .draggable(group.exercise.id.uuidString)
                    .dropDestination(for: String.self) { items, _ in
                        guard let sourceId = items.first, let srcUUID = UUID(uuidString: sourceId) else { return false }
                        reorderExercise(from: srcUUID, to: group.exercise.id)
                        return true
                    }
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

    private func deleteAllSets(of exercise: Exercise) {
        let affected = part.exerciseSets.filter { $0.exercise?.id == exercise.id }
        if affected.isEmpty { return }
        // Prepare undo payload
        undoPayload = (exercise, affected.map { UndoSetData(setNumber: $0.setNumber, weight: $0.weight, reps: $0.reps, duration: $0.duration, distance: $0.distance, isCompleted: $0.isCompleted) })
        withAnimation { showUndoBar = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { withAnimation { showUndoBar = false }; undoPayload = nil }
        // Delete
        affected.forEach { modelContext.delete($0) }
        do { try modelContext.save() } catch { /* ignore */ }
    }

    private func reorderExercise(from sourceId: UUID, to targetId: UUID) {
        // Stable sort by current set order, then rewrite contiguous blocks by exercise
        var items = part.exerciseSets.sorted { $0.setNumber < $1.setNumber }
        guard let _ = items.firstIndex(where: { $0.exercise?.id == sourceId }),
              let _ = items.firstIndex(where: { $0.exercise?.id == targetId }) else { return }
        // Identify contiguous blocks per exercise
        func blockRange(for exId: UUID) -> Range<Int>? {
            let idxs = items.indices.filter { items[$0].exercise?.id == exId }
            guard let first = idxs.first, let last = idxs.last else { return nil }
            return first..<(last+1)
        }
        guard let sRange = blockRange(for: sourceId), let tRange = blockRange(for: targetId) else { return }
        let block = Array(items[sRange])
        items.removeSubrange(sRange)
        let insertAt = (sRange.lowerBound < tRange.lowerBound) ? (blockRange(for: targetId)?.upperBound ?? items.endIndex) : (blockRange(for: targetId)?.lowerBound ?? items.endIndex)
        items.insert(contentsOf: block, at: min(max(0, insertAt), items.count))
        // Re-number sets sequentially to keep UI stable
        for (i, s) in items.enumerated() { s.setNumber = Int16(i + 1) }
        do { try modelContext.save() } catch { /* ignore */ }
    }

    // Undo reconstruction
    private struct UndoSetData { let setNumber: Int16; let weight: Double?; let reps: Int16?; let duration: Int32?; let distance: Double?; let isCompleted: Bool }
    @State private var undoPayload: (exercise: Exercise, data: [UndoSetData])? = nil
    @State private var showUndoBar: Bool = false
    private func undoDelete(_ payload: (exercise: Exercise, data: [UndoSetData])) {
        for d in payload.data.sorted(by: { $0.setNumber < $1.setNumber }) {
            let restored = ExerciseSet(setNumber: d.setNumber, weight: d.weight, reps: d.reps, duration: d.duration, distance: d.distance, rpe: nil, isCompleted: d.isCompleted)
            restored.exercise = payload.exercise
            restored.workoutPart = part
            modelContext.insert(restored)
        }
        do { try modelContext.save() } catch { /* ignore */ }
        withAnimation { showUndoBar = false }
        undoPayload = nil
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
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
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
                            Text(LocalizationKeys.Training.Exercise.pr.localized)
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
        // Swipe actions on the whole exercise block
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if let onDelete { Button(role: .destructive) { onDelete() } label: { Label(LocalizationKeys.Common.delete.localized, systemImage: "trash") } }
        }
        .swipeActions(edge: .leading) {
            if let onEdit { Button { onEdit() } label: { Label(LocalizationKeys.Common.edit.localized, systemImage: "pencil") } }
        }
        .padding(.vertical, theme.spacing.s)
        .padding(.horizontal, theme.spacing.s)
        .background(theme.colors.cardBackground)
        .cornerRadius(6)
        // Long press quick actions
        .contextMenu {
            if let onEdit { Button(LocalizationKeys.Common.edit.localized) { onEdit() } }
            Button(LocalizationKeys.Training.Exercise.addSet.localized) { onAddSet() }
            if let onDelete { Button(role: .destructive) { onDelete() } label: { Text(LocalizationKeys.Common.delete.localized) } }
        }
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
