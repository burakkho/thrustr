import SwiftUI
import SwiftData

// MARK: - Workout Detail View
struct WorkoutDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let workout: Workout
    @State private var showingAddPart = false
    @State private var showingGlobalExerciseSelection = false
    @State private var currentTime = Date()
    @State private var showingShare = false

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                WorkoutHeaderView(
                    workoutName: workout.name ?? LocalizationKeys.Training.Detail.defaultName.localized,
                    duration: formatDuration(Int(currentTime.timeIntervalSince(workout.startTime))),
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

                        AddPartButton { showingAddPart = true }
                        AddExercisesButton { showingGlobalExerciseSelection = true }
                    }
                    .padding()
                }

                WorkoutActionBar(
                    workout: workout,
                    onFinish: { finishWorkout() }
                )
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizationKeys.Training.Detail.back.localized) { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        if workout.isCompleted {
                            ShareLink(item: shareMessage) {
                                Image(systemName: "square.and.arrow.up")
                            }
                            .accessibilityLabel("Share workout summary")
                        }
                        Button(LocalizationKeys.Training.Detail.finish.localized) { finishWorkout() }
                            .foregroundColor(.red)
                    }
                }
            }
            .sheet(isPresented: $showingAddPart) {
                AddPartSheet(workout: workout)
            }
            .sheet(isPresented: $showingGlobalExerciseSelection) {
                ExerciseSelectionView(workoutPart: nil) { exercise in
                    // Infer target part type from exercise and add placeholder set under that part
                    let targetType = inferPartType(from: exercise)
                    let part: WorkoutPart = {
                        if let existing = workout.parts.first(where: { WorkoutPartType(rawValue: $0.type) == targetType }) {
                            return existing
                        }
                        let created = workout.addPart(name: targetType.displayName, type: targetType)
                        try? modelContext.save()
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
                    try? modelContext.save()
                }
            }
        }
        .onReceive(timer) { _ in currentTime = Date() }
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
        workout.finishWorkout()
        try? modelContext.save()
        // Keep the view so user can share; do not dismiss immediately
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

// MARK: - Header
struct WorkoutHeaderView: View {
    let workoutName: String
    let duration: String
    let isActive: Bool

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workoutName).font(.title2).fontWeight(.bold)
                    HStack(spacing: 4) {
                        Circle().fill(isActive ? Color.green : Color.gray).frame(width: 8, height: 8)
                        Text(isActive ? LocalizationKeys.Training.Active.statusActive.localized : LocalizationKeys.Training.Active.statusCompleted.localized).font(.caption).foregroundColor(.secondary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(duration).font(.title).fontWeight(.bold)
                        .foregroundColor(isActive ? .blue : .secondary)
                    Text(LocalizationKeys.Training.Active.duration.localized).font(.caption).foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            Divider()
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Empty State
struct EmptyWorkoutState: View {
    let action: () -> Void
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "plus.circle.dashed").font(.system(size: 60)).foregroundColor(.gray)
            Text(LocalizationKeys.Training.Detail.emptyTitle.localized).font(.title2).fontWeight(.semibold)
            Text(LocalizationKeys.Training.Detail.emptySubtitle.localized)
                .foregroundColor(.secondary).multilineTextAlignment(.center)
        }
        .padding(.top, 60)
    }
}

// MARK: - Part Card
struct WorkoutPartCard: View {
    let part: WorkoutPart
    @Environment(\.modelContext) private var modelContext
    @State private var showingExerciseSelection = false
    @State private var showingSetTracking = false
    @State private var selectedExercise: Exercise?

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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: partType.icon).foregroundColor(partColor)
                    Text(part.name).font(.headline).fontWeight(.semibold)
                }
                Spacer()
                HStack(spacing: 4) {
                    Circle()
                        .fill(part.isCompleted ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                    Text(part.isCompleted ? LocalizationKeys.Training.Part.statusCompleted.localized : LocalizationKeys.Training.Part.statusInProgress.localized)
                        .font(.caption).foregroundColor(.secondary)
                }
            }

            if part.exerciseSets.isEmpty && part.wodResult == nil {
                VStack(spacing: 8) {
                    Text(LocalizationKeys.Training.Part.noExercise.localized)
                        .foregroundColor(.secondary).font(.subheadline)
                    Button(LocalizationKeys.Training.Part.addExercise.localized) { showingExerciseSelection = true }
                        .font(.subheadline).foregroundColor(.blue)
                }
            } else if let wodResult = part.wodResult {
                HStack {
                    Text(LocalizationKeys.Training.Part.result.localized).foregroundColor(.secondary)
                    Text(wodResult).fontWeight(.semibold).foregroundColor(.green)
                }
                Button(LocalizationKeys.Training.Part.addExercise.localized) { showingExerciseSelection = true }
                    .font(.caption).foregroundColor(.blue)
            } else {
                VStack(spacing: 8) {
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
                    Button("+ \(LocalizationKeys.Training.Part.addExercise.localized)") { showingExerciseSelection = true }
                        .font(.caption).foregroundColor(.blue).padding(.top, 4)
                }
            }

            HStack(spacing: 16) {
                StatBadge(title: LocalizationKeys.Training.Stats.sets.localized, value: "\(part.completedSets)/\(part.totalSets)")
                StatBadge(title: LocalizationKeys.Training.Stats.volume.localized, value: "\(Int(part.totalVolume))kg")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .sheet(isPresented: $showingExerciseSelection) {
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
                    try? modelContext.save()

                    showingSetTracking = true
                }
            )
        }
        .sheet(isPresented: $showingSetTracking) {
            if let exercise = selectedExercise {
                SetTrackingView(exercise: exercise, workoutPart: part)
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

    private var partColor: Color {
        switch partType {
        case .strength: return .blue
        case .conditioning: return .red
        case .accessory: return .green
        case .warmup: return .orange
        case .functional: return .purple
        case .olympic: return .yellow
        case .plyometric: return .pink
        }
    }
}

// MARK: - Exercise group view
struct ExerciseGroupView: View {
    let exercise: Exercise
    let sets: [ExerciseSet]
    let onAddSet: () -> Void

    var completedSets: [ExerciseSet] {
        sets.filter { $0.isCompleted }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(exercise.nameTR).font(.subheadline).fontWeight(.medium)
                Spacer()
                Text(String(format: LocalizationKeys.Training.Exercise.setCount.localized, completedSets.count, sets.count))
                    .font(.caption).foregroundColor(.secondary)
                Button("+ \(LocalizationKeys.Training.Stats.sets.localized)") { onAddSet() }
                    .font(.caption).foregroundColor(.blue)
            }

            ForEach(completedSets.prefix(3), id: \.id) { set in
                HStack {
                    Text(String(format: LocalizationKeys.Training.Exercise.setNumber.localized, set.setNumber))
                        .font(.caption).foregroundColor(.secondary)
                        .frame(width: 50, alignment: .leading)
                    Text(set.displayText).font(.caption).fontWeight(.medium)
                    Spacer()
                    if set.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption).foregroundColor(.green)
                    }
                }
            }

            if completedSets.count > 3 {
                Text(String(format: LocalizationKeys.Training.Exercise.moreSets.localized, completedSets.count - 3))
                    .font(.caption2).foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color(.systemBackground))
        .cornerRadius(6)
    }
}

// MARK: - Action bar and helpers
struct AddPartButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "plus.circle.fill").foregroundColor(.blue)
                Text(LocalizationKeys.Training.Detail.addPart.localized).fontWeight(.medium)
                Spacer()
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
        }
        .foregroundColor(.blue)
    }
}

struct AddExercisesButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "plus")
                    .foregroundColor(.green)
                Text(LocalizationKeys.Training.Part.addExercise.localized)
                    .fontWeight(.medium)
                Spacer()
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)
        }
        .foregroundColor(.green)
    }
}

struct WorkoutActionBar: View {
    let workout: Workout
    let onFinish: () -> Void
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 12) {
                HStack(spacing: 16) {
                    StatBadge(title: LocalizationKeys.Training.Stats.parts.localized, value: "\(workout.parts.count)")
                    StatBadge(title: LocalizationKeys.Training.Stats.sets.localized, value: "\(workout.totalSets)")
                    StatBadge(title: LocalizationKeys.Training.Stats.volume.localized, value: "\(Int(workout.totalVolume))kg")
                }
                Spacer()
                Button(LocalizationKeys.Training.Detail.finishWorkout.localized, action: onFinish)
                    .font(.headline).foregroundColor(.white)
                    .padding(.horizontal, 20).padding(.vertical, 12)
                    .background(Color.green).cornerRadius(8)
            }
            .padding()
        }
        .background(Color(.systemBackground))
    }
}

struct StatBadge: View {
    let title: String
    let value: String
    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.subheadline).fontWeight(.semibold)
            Text(title).font(.caption2).foregroundColor(.secondary)
        }
    }
}

// MARK: - Add Part Sheet + Row
struct AddPartSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let workout: Workout

    @State private var selectedPartType: WorkoutPartType = .strength
    @State private var partName = ""

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
                    .background(partName.isEmpty ? Color.gray : Color.blue)
                    .cornerRadius(12)
                    .disabled(partName.isEmpty)
                    .padding(.horizontal)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizationKeys.Training.AddPart.cancel.localized) { dismiss() }
                }
            }
        }
    }

    private func addPart() {
        _ = workout.addPart(name: partName, type: selectedPartType)
        try? modelContext.save()
        dismiss()
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
                    Text(localizedDescription).font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(partColor).font(.title2)
                }
            }
            .padding()
            .background(isSelected ? partColor.opacity(0.1) : Color(.systemGray6))
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
        case .strength: return .blue
        case .conditioning: return .red
        case .accessory: return .green
        case .warmup: return .orange
        case .functional: return .purple
        case .olympic: return .yellow
        case .plyometric: return .pink
        }
    }
}

// MARK: - Preview
#Preview {
    let workout = Workout(name: "Test Antrenman")
    WorkoutDetailView(workout: workout)
        .modelContainer(for: [Workout.self, WorkoutPart.self, ExerciseSet.self, Exercise.self], inMemory: true)
}
