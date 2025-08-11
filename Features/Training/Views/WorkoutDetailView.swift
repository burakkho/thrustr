import SwiftUI
import UIKit
import SwiftData

// MARK: - Workout Detail View
struct WorkoutDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.theme) private var theme

    let workout: Workout
    @State private var showingAddPart = false
    @State private var showingGlobalExerciseSelection = false
    @State private var currentTime = Date()
    @State private var timer = Timer.publish(every: 1.0, on: .main, in: .common)
        .autoconnect()
    @State private var showingShare = false
    @State private var saveError: String? = nil
    @State private var isSaving: Bool = false
    @State private var showCompletion: Bool = false
    @AppStorage("preferences.haptic_feedback_enabled") private var hapticsEnabled: Bool = true

    // removed; timer kept as @State

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                WorkoutHeaderView(
                    workoutName: workout.name ?? LocalizationKeys.Training.Detail.defaultName.localized,
                    duration: workout.isCompleted
                        ? formatDuration(workout.totalDuration)
                        : formatDuration(Int(currentTime.timeIntervalSince(workout.startTime))),
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
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizationKeys.Training.Detail.back.localized) { dismiss() }
                        .accessibilityLabel(LocalizationKeys.Training.Detail.back.localized)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        if !workout.isCompleted {
                            Button(LocalizationKeys.Training.Detail.finish.localized) { finishWorkout() }
                                .foregroundColor(theme.colors.error)
                                .accessibilityHint(LocalizationKeys.Training.Detail.finishWorkout.localized)
                                .accessibilityLabel(LocalizationKeys.Training.Detail.finish.localized)
                        }
                    }
                }
            }
            // TEST: Header duration & sheet cleanup
            // 1) Active workout → time increases
            // 2) Finish workout → time constant (totalDuration)
            // 3) Open ExerciseSelection then dismiss → no ghost overlay, no placeholders
        .sheet(isPresented: $showingAddPart, onDismiss: {
            removeOrphanPlaceholders()
        }) {
            AddPartSheet(workout: workout)
        }
            .sheet(isPresented: $showingGlobalExerciseSelection, onDismiss: {
                // Cleanup orphan placeholders if user closed without adding
                removeOrphanPlaceholders()
            }) {
                ExerciseSelectionView(workoutPart: nil) { exercise in
                    // Infer target part type from exercise and add placeholder set under that part
                    let targetType = inferPartType(from: exercise)
                    let part: WorkoutPart = {
                        if let existing = workout.parts.first(where: { WorkoutPartType(rawValue: $0.type) == targetType }) {
                            return existing
                        }
                        let created = workout.addPart(name: targetType.displayName, type: targetType)
                        do { try modelContext.save() } catch { /* show later */ }
                        return created
                    }()

                    let nextIndexForExercise = (part.exerciseSets
                        .filter { $0.exercise?.id == exercise.id }
                        .map { Int($0.setNumber) }
                        .max() ?? 0) + 1

                    let placeholder = ExerciseSet(setNumber: Int16(nextIndexForExercise), isCompleted: false)
                    placeholder.exercise = exercise
                    placeholder.workoutPart = part
                    modelContext.insert(placeholder)
                    do { try modelContext.save() } catch { /* show later */ }

                    // Explicitly dismiss the sheet to avoid ghost overlay on first add
                    showingGlobalExerciseSelection = false
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
        .onReceive(timer) { _ in currentTime = Date() }
        .onDisappear {
            // Cancel timer to prevent leaks
            timer.upstream.connect().cancel()
        }
        .alert(isPresented: Binding<Bool>(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )) {
            Alert(title: Text(LocalizationKeys.Common.error.localized), message: Text(saveError ?? ""), dismissButton: .default(Text(LocalizationKeys.Common.ok.localized)))
        }
        .sheet(isPresented: $showCompletion) {
            WorkoutCompletionView(workout: workout)
        }
    }

    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }

    private func finishWorkout() {
        isSaving = true
        Task {
            workout.finishWorkout()
            do {
                try modelContext.save()
                if hapticsEnabled { UINotificationFeedbackGenerator().notificationOccurred(.success) }
                showCompletion = true
            } catch {
                if hapticsEnabled { UINotificationFeedbackGenerator().notificationOccurred(.error) }
                saveError = error.localizedDescription
            }
            isSaving = false
        }
    }

    private func inferPartType(from exercise: Exercise) -> WorkoutPartType {
        let category = ExerciseCategory(rawValue: exercise.category) ?? .other
        switch category {
        case .cardio: return .conditioning
        case .functional: return .functional
        case .core, .isolation: return .accessory
        case .warmup, .flexibility, .plyometric: return .warmup
        default: return .strength
        }
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
        let durationString = formatDuration(workout.totalDuration)
        let exerciseCount: Int = {
            let exerciseIds = workout.parts.flatMap { part in
                part.exerciseSets.compactMap { $0.exercise?.id }
            }
            return Set(exerciseIds).count
        }()
        let totalVolume = Int(workout.totalVolume)

        return """
        💪 Antrenmanımı tamamladım!

        ⏱ Süre: \(durationString)
        🏋️ Egzersizler: \(exerciseCount)
        📊 Toplam: \(totalVolume) kg

        Sen de katıl: Spor Hocam 🚀
        """
    }
}

// Local fallback for completion sheet to avoid target-membership issues
private struct WorkoutCompletionView: View {
    @Environment(\.theme) private var theme
    let workout: Workout
    @State private var animate = false

    var body: some View {
        VStack(spacing: theme.spacing.xl) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(theme.colors.success)
                .symbolEffect(.bounce, value: animate)

            Text("Tebrikler! 🎉")
                .font(.largeTitle)
                .fontWeight(.bold)

            VStack(spacing: theme.spacing.m) {
                StatRow(label: "Süre", value: formatDuration(workout.totalDuration))
                StatRow(label: "Toplam Set", value: "\(workout.totalSets)")
                StatRow(label: "Volume", value: "\(Int(workout.totalVolume)) kg")
            }
            .padding()
            .background(theme.colors.cardBackground)
            .cornerRadius(12)

            ShareLink(item: shareMessage) {
                Label("Paylaş", systemImage: "square.and.arrow.up")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(theme.colors.accent)
                    .cornerRadius(12)
            }
            .buttonStyle(PressableStyle())
        }
        .padding()
        .onAppear {
            animate = true
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Antrenman tamamlandı, süre \(formatDuration(workout.totalDuration)), set \(workout.totalSets), volume \(Int(workout.totalVolume)) kilogram")
    }

    private var shareMessage: String {
        "\n💪 Antrenmanımı tamamladım!\n\n⏱ Süre: \(formatDuration(workout.totalDuration))\n🏋️ Egzersizler: \(Set(workout.parts.flatMap { $0.exerciseSets.compactMap { $0.exercise?.id } }).count)\n📊 Toplam: \(Int(workout.totalVolume)) kg\n\nSpor Hocam 🚀"
    }

    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        return hours > 0 ? String(format: "%d:%02d:%02d", hours, minutes, secs) : String(format: "%d:%02d", minutes, secs)
    }
}

private struct StatRow: View {
    @Environment(\.theme) private var theme
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(theme.colors.textSecondary)
            Spacer()
            Text(value)
                .font(.headline)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

// MARK: - Header
struct WorkoutHeaderView: View {
    let workoutName: String
    let duration: String
    let isActive: Bool
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workoutName).font(.title2).fontWeight(.bold)
            HStack(spacing: 4) {
                Circle().fill(isActive ? theme.colors.success : theme.colors.textSecondary).frame(width: 8, height: 8)
                        Text(isActive ? LocalizationKeys.Training.Active.statusActive.localized : LocalizationKeys.Training.Active.statusCompleted.localized)
                            .font(.caption)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(duration)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(isActive ? theme.colors.accent : theme.colors.textSecondary)
                    Text(LocalizationKeys.Training.Active.duration.localized)
                        .font(.caption)
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
            .padding(.horizontal)
            Divider()
        }
        .background(theme.colors.backgroundPrimary)
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
    let part: WorkoutPart
    @Environment(\.modelContext) private var modelContext
    @Environment(\.theme) private var theme
    @State private var showingExerciseSelection = false
    @State private var showingSetTracking = false
    @State private var selectedExercise: Exercise?
    @State private var showingRename = false
    @State private var tempName: String = ""
    @State private var selectionTimer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    @State private var shouldOpenSetTracking = false

    var partType: WorkoutPartType {
        WorkoutPartType(rawValue: part.type) ?? .strength
    }

    var localizedPartName: String {
        switch partType {
        case .strength:
            return LocalizationKeys.Training.Part.strength.localized
        case .conditioning:
            return LocalizationKeys.Training.Part.conditioning.localized
        case .accessory:
            return LocalizationKeys.Training.Part.accessory.localized
        case .warmup:
            return LocalizationKeys.Training.Part.warmup.localized
        case .functional:
            return LocalizationKeys.Training.Part.functional.localized
        case .olympic:
            return "Olimpik"
        case .plyometric:
            return "Plyometrik"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            headerSection
            contentSection
            if part.totalSets > 0 { progressSection }
        }
        .padding(theme.spacing.l)
        .cardStyle()
        .contextMenu {
            Button(LocalizationKeys.Training.Part.rename.localized) { tempName = part.name; showingRename = true }
            Button(LocalizationKeys.Training.Part.moveUp.localized) { movePart(direction: -1) }
            Button(LocalizationKeys.Training.Part.moveDown.localized) { movePart(direction: 1) }
            Divider()
            Button(part.isCompleted ? LocalizationKeys.Training.Part.markInProgressAction.localized : LocalizationKeys.Training.Part.markCompletedAction.localized) {
                part.isCompleted.toggle(); do { try modelContext.save() } catch { /* ignore */ }
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
                part.isCompleted.toggle(); try? modelContext.save()
            } label: {
                Label(
                    part.isCompleted ? LocalizationKeys.Training.Part.markInProgressAction.localized : LocalizationKeys.Training.Part.markCompletedAction.localized,
                    systemImage: part.isCompleted ? "xmark.circle" : "checkmark.circle"
                )
            }
            .tint(part.isCompleted ? theme.colors.warning : theme.colors.success)
        }
        .sheet(isPresented: $showingExerciseSelection, onDismiss: {
            // If an exercise was picked, open set tracking after sheet fully dismisses
            if shouldOpenSetTracking {
                showingSetTracking = true
                shouldOpenSetTracking = false
            } else {
                // If dismissed without selecting, cleanup possible placeholders
                cleanupPlaceholdersIfNeeded()
            }
        }) {
            ExerciseSelectionView(
                workoutPart: part,
                onExerciseSelected: { exercise in
                    selectedExercise = exercise

                    // Create a placeholder set so the exercise appears immediately under this part
                    let nextIndexForExercise = (part.exerciseSets
                        .filter { $0.exercise?.id == exercise.id }
                        .map { Int($0.setNumber) }
                        .max() ?? 0) + 1

                    let placeholder = ExerciseSet(setNumber: Int16(nextIndexForExercise), isCompleted: false)
                    placeholder.exercise = exercise
                    placeholder.workoutPart = part
                    modelContext.insert(placeholder)
                    do { try modelContext.save() } catch { /* ignore here */ }

                    // Dismiss selection sheet, then present set tracking in onDismiss callback
                    shouldOpenSetTracking = true
                    showingExerciseSelection = false
                }
            )
        }
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
        .sheet(isPresented: $showingRename) {
            RenamePartSheet(initialName: part.name) { newName in
                part.name = newName
                do { try modelContext.save() } catch { /* ignore */ }
            }
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
                Text(part.name)
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
            HStack {
                Text(LocalizationKeys.Training.Part.result.localized)
                    .foregroundColor(theme.colors.textSecondary)
                Text(wodResult)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.success)
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
        case .strength: return theme.colors.accent
        case .conditioning: return theme.colors.warning
        case .accessory: return theme.colors.success
        case .warmup: return theme.colors.warning
        case .functional: return theme.colors.accent
        case .olympic: return theme.colors.accent
        case .plyometric: return theme.colors.accent
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

    // Cleans up placeholder sets for the last selected exercise if user dismissed without proceeding
    private func cleanupPlaceholdersIfNeeded() {
        guard !shouldOpenSetTracking, let exercise = selectedExercise else { return }
        let placeholders = part.exerciseSets.filter { $0.exercise?.id == exercise.id && !$0.isCompleted }
        guard !placeholders.isEmpty else { return }
        placeholders.forEach { modelContext.delete($0) }
        do { try modelContext.save() } catch { /* ignore */ }
        selectedExercise = nil
    }
}

// MARK: - Exercise group view
struct ExerciseGroupView: View {
    let exercise: Exercise
    let sets: [ExerciseSet]
    let onAddSet: () -> Void
    @Environment(\.theme) private var theme

    var completedSets: [ExerciseSet] {
        sets.filter { $0.isCompleted }
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

            ForEach(completedSets.prefix(3), id: \.id) { set in
                HStack {
                    Text(String(format: LocalizationKeys.Training.Exercise.setNumber.localized, set.setNumber))
                        .font(.caption)
                        .foregroundColor(theme.colors.textSecondary)
                        .frame(width: 50, alignment: .leading)
                    Text(set.displayText).font(.caption).fontWeight(.medium)
                    Spacer()
                    if set.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption).foregroundColor(theme.colors.success)
                    }
                }
            }

            if completedSets.count > 3 {
                Text(String(format: LocalizationKeys.Training.Exercise.moreSets.localized, completedSets.count - 3))
                    .font(.caption2)
                    .foregroundColor(theme.colors.textSecondary)
            }
        }
        .padding(.vertical, theme.spacing.s)
        .padding(.horizontal, theme.spacing.s)
        .background(theme.colors.cardBackground)
        .cornerRadius(6)
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
    @State private var showingQuickActions = false

    var body: some View {
        VStack(spacing: 0) {
            if showingQuickActions {
                HStack(spacing: theme.spacing.m) {
                    ActionChip(icon: "timer", title: "Rest", color: theme.colors.warning) {
                        // handled in parent if needed
                    }
                    ActionChip(icon: "camera", title: "Foto", color: theme.colors.accent) {
                        // Open progress photo
                    }
                    ActionChip(icon: "note.text", title: "Not", color: theme.colors.accent) {
                        // Add note
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, theme.spacing.s)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            Divider()

            HStack {
                Button(action: {
                    withAnimation(.spring(response: 0.3)) { showingQuickActions.toggle() }
                }) {
                    Image(systemName: showingQuickActions ? "chevron.down" : "chevron.up")
                        .foregroundColor(theme.colors.textSecondary)
                }

                Spacer()

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

// MARK: - Add Part Sheet + Row
struct AddPartSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.theme) private var theme
    let workout: Workout

    @State private var selectedPartType: WorkoutPartType = .strength
    @State private var partName = ""
    @State private var saveError: String? = nil

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text(LocalizationKeys.Training.AddPart.title.localized).font(.largeTitle).fontWeight(.bold)
                    Text(LocalizationKeys.Training.AddPart.subtitle.localized)
                        .font(.subheadline).foregroundColor(.secondary)
                }
                .padding(.top)

                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizationKeys.Training.AddPart.nameLabel.localized).font(.headline)
                    TextField(LocalizationKeys.Training.AddPart.namePlaceholder.localized, text: $partName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 12) {
                    Text(LocalizationKeys.Training.AddPart.typeLabel.localized).font(.headline).padding(.horizontal)
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(WorkoutPartType.allCases, id: \.self) { partType in
                                PartTypeSelectionRow(
                                    partType: partType,
                                    isSelected: selectedPartType == partType
                                ) {
                                    selectedPartType = partType
                                    if partName.isEmpty {
                                        partName = getLocalizedPartName(for: partType)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                Spacer()

                Button(LocalizationKeys.Training.AddPart.add.localized) { addPart() }
                    .font(.headline).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding()
                    .background(partName.isEmpty ? Color.gray : theme.colors.accent)
                    .cornerRadius(12)
                    .disabled(partName.isEmpty)
                    .padding(.horizontal)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizationKeys.Training.AddPart.cancel.localized) { dismiss() }
                        .accessibilityLabel(LocalizationKeys.Training.AddPart.cancel.localized)
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

    private func addPart() {
        _ = workout.addPart(name: partName, type: selectedPartType)
        do {
            try modelContext.save()
            dismiss()
        } catch {
            saveError = error.localizedDescription
        }
    }
    
    private func getLocalizedPartName(for partType: WorkoutPartType) -> String {
        switch partType {
        case .strength:
            return LocalizationKeys.Training.Part.strength.localized
        case .conditioning:
            return LocalizationKeys.Training.Part.conditioning.localized
        case .accessory:
            return LocalizationKeys.Training.Part.accessory.localized
        case .warmup:
            return LocalizationKeys.Training.Part.warmup.localized
        case .functional:
            return LocalizationKeys.Training.Part.functional.localized
        case .olympic:
            return "Olimpik"
        case .plyometric:
            return "Plyometrik"
        }
    }
}

struct PartTypeSelectionRow: View {
    let partType: WorkoutPartType
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.theme) private var theme

    var localizedDisplayName: String {
        switch partType {
        case .strength:
            return LocalizationKeys.Training.Part.strength.localized
        case .conditioning:
            return LocalizationKeys.Training.Part.conditioning.localized
        case .accessory:
            return LocalizationKeys.Training.Part.accessory.localized
        case .warmup:
            return LocalizationKeys.Training.Part.warmup.localized
        case .functional:
            return LocalizationKeys.Training.Part.functional.localized
        case .olympic:
            return "Olimpik"
        case .plyometric:
            return "Plyometrik"
        }
    }
    
    var localizedDescription: String {
        switch partType {
        case .strength:
            return LocalizationKeys.Training.Part.strengthDesc.localized
        case .conditioning:
            return LocalizationKeys.Training.Part.conditioningDesc.localized
        case .accessory:
            return LocalizationKeys.Training.Part.accessoryDesc.localized
        case .warmup:
            return LocalizationKeys.Training.Part.warmupDesc.localized
        case .functional:
            return LocalizationKeys.Training.Part.functionalDesc.localized
        case .olympic:
            return "Olimpik halter kaldırışları"
        case .plyometric:
            return "Plyometrik/Patlayıcı güç çalışmaları"
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
        case .strength: return theme.colors.accent
        case .conditioning: return theme.colors.warning
        case .accessory: return theme.colors.success
        case .warmup: return theme.colors.warning
        case .functional: return theme.colors.accent
        case .olympic: return theme.colors.accent
        case .plyometric: return theme.colors.accent
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
