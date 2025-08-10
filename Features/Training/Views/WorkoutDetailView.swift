import SwiftUI
import SwiftData

// MARK: - Workout Detail View
struct WorkoutDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let workout: Workout
    @State private var showingAddPart = false
    @State private var currentTime = Date()

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                WorkoutHeaderView(
                    workoutName: workout.name ?? "Antrenman",
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
                    Button("Geri") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Bitir") { finishWorkout() }
                        .foregroundColor(.red)
                }
            }
            .sheet(isPresented: $showingAddPart) {
                AddPartSheet(workout: workout)
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
        dismiss()
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
                        Text(isActive ? "Aktif" : "Tamamlandı").font(.caption).foregroundColor(.secondary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(duration).font(.title).fontWeight(.bold)
                        .foregroundColor(isActive ? .blue : .secondary)
                    Text("Süre").font(.caption).foregroundColor(.secondary)
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
            Text("Antrenmanına Başla").font(.title2).fontWeight(.semibold)
            Text("İlk bölümünü ekleyerek antrenmanına başla")
                .foregroundColor(.secondary).multilineTextAlignment(.center)
            Button("Bölüm Ekle", action: action)
                .font(.headline).foregroundColor(.white)
                .padding().background(Color.blue).cornerRadius(12)
        }
        .padding(.top, 60)
    }
}

// MARK: - Part Card
struct WorkoutPartCard: View {
    let part: WorkoutPart
    @State private var showingExerciseSelection = false
    @State private var showingSetTracking = false
    @State private var selectedExercise: Exercise?

    var partType: WorkoutPartType {
        WorkoutPartType(rawValue: part.type) ?? .strength
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
                    Text(part.isCompleted ? "Tamamlandı" : "Devam ediyor")
                        .font(.caption).foregroundColor(.secondary)
                }
            }

            if part.exerciseSets.isEmpty && part.wodResult == nil {
                VStack(spacing: 8) {
                    Text("Henüz egzersiz eklenmedi")
                        .foregroundColor(.secondary).font(.subheadline)
                    Button("Egzersiz Ekle") { showingExerciseSelection = true }
                        .font(.subheadline).foregroundColor(.blue)
                }
            } else if let wodResult = part.wodResult {
                HStack {
                    Text("Sonuç:").foregroundColor(.secondary)
                    Text(wodResult).fontWeight(.semibold).foregroundColor(.green)
                }
                Button("Egzersiz Ekle") { showingExerciseSelection = true }
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
                    Button("+ Egzersiz Ekle") { showingExerciseSelection = true }
                        .font(.caption).foregroundColor(.blue).padding(.top, 4)
                }
            }

            HStack(spacing: 16) {
                StatBadge(title: "Set", value: "\(part.completedSets)/\(part.totalSets)")
                StatBadge(title: "Volume", value: "\(Int(part.totalVolume))kg")
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
                Text("\(completedSets.count)/\(sets.count)")
                    .font(.caption).foregroundColor(.secondary)
                Button("+ Set") { onAddSet() }
                    .font(.caption).foregroundColor(.blue)
            }

            ForEach(completedSets.prefix(3), id: \.id) { set in
                HStack {
                    Text("Set \(set.setNumber):")
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
                Text("... ve \(completedSets.count - 3) set daha")
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
                Text("Bölüm Ekle").fontWeight(.medium)
                Spacer()
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
        }
        .foregroundColor(.blue)
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
                    StatBadge(title: "Bölüm", value: "\(workout.parts.count)")
                    StatBadge(title: "Set", value: "\(workout.totalSets)")
                    StatBadge(title: "Volume", value: "\(Int(workout.totalVolume))kg")
                }
                Spacer()
                Button("Antrenmanı Bitir", action: onFinish)
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
    let workout: Workout

    @State private var selectedPartType: WorkoutPartType = .strength
    @State private var partName = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Bölüm Ekle").font(.largeTitle).fontWeight(.bold)
                    Text("Hangi tür bölüm eklemek istiyorsun?")
                        .font(.subheadline).foregroundColor(.secondary)
                }
                .padding(.top)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Bölüm Adı").font(.headline)
                    TextField("Örn: Warm-up, Strength", text: $partName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Bölüm Türü").font(.headline).padding(.horizontal)
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(WorkoutPartType.allCases, id: \.self) { partType in
                                PartTypeSelectionRow(
                                    partType: partType,
                                    isSelected: selectedPartType == partType
                                ) {
                                    selectedPartType = partType
                                    if partName.isEmpty { partName = partType.displayName }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                Spacer()

                Button("Bölüm Ekle") { addPart() }
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
                    Button("İptal") { dismiss() }
                }
            }
        }
    }

    private func addPart() {
        _ = workout.addPart(name: partName, type: selectedPartType)
        dismiss()
    }
}

struct PartTypeSelectionRow: View {
    let partType: WorkoutPartType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: partType.icon)
                    .font(.title2).foregroundColor(partColor).frame(width: 30)
                VStack(alignment: .leading, spacing: 2) {
                    Text(partType.displayName).font(.headline).foregroundColor(.primary)
                    Text(partTypeDescription).font(.caption).foregroundColor(.secondary)
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
        }
    }

    private var partTypeDescription: String {
        switch partType {
        case .strength: return "Ağırlık antrenmanı, set/rep tracking"
        case .conditioning: return "WOD, kardiyo, kondisyon antrenmanı"
        case .accessory: return "Yardımcı hareketler, izolasyon"
        case .warmup: return "Isınma hareketleri"
        case .functional: return "Fonksiyonel hareketler, crossfit"
        }
    }
}

// MARK: - Preview
#Preview {
    let workout = Workout(name: "Test Antrenman")
    WorkoutDetailView(workout: workout)
        .modelContainer(for: [Workout.self, WorkoutPart.self, ExerciseSet.self, Exercise.self], inMemory: true)
}

