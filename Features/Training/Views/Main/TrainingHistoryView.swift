import SwiftUI
import SwiftData

// MARK: - Workout History View
struct WorkoutHistoryView: View {
    let workouts: [Workout]
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @State private var showAll: Bool = false
    
    private var displayedWorkouts: [Workout] {
        showAll ? completedWorkouts : Array(completedWorkouts.prefix(7))
    }
    
    var completedWorkouts: [Workout] {
        workouts.filter { $0.isCompleted }.sorted { $0.date > $1.date }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: theme.spacing.m) {
                if completedWorkouts.isEmpty {
                    // Empty state
                    VStack(spacing: theme.spacing.m) {
                        Image(systemName: "dumbbell")
                            .font(.system(size: 50))
                            .foregroundColor(theme.colors.textSecondary)
                        
                        Text(LocalizationKeys.Training.History.emptyTitle.localized)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(LocalizationKeys.Training.History.emptySubtitle.localized)
                            .foregroundColor(theme.colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 100)
                } else {
                    ForEach(displayedWorkouts) { workout in
                        WorkoutHistoryCard(workout: workout)
                            .contextMenu {
                                Button(LocalizationKeys.Training.History.repeat.localized) {
                                    repeatWorkout(workout)
                                }
                            }
                    }
                    if !showAll && completedWorkouts.count > 7 {
                        Button(LocalizationKeys.Training.History.seeMore.localized) { showAll = true }
                            .font(.subheadline)
                            .foregroundColor(theme.colors.accent)
                    }
                }
            }
            .padding(theme.spacing.m)
        }
    }

    private func repeatWorkout(_ template: Workout) {
        let newWorkout = Workout(name: template.name)
        // Copy parts and exercises
        for (idx, part) in template.parts.sorted(by: { $0.orderIndex < $1.orderIndex }).enumerated() {
            let newPart = WorkoutPart(name: part.name, type: WorkoutPartType.from(rawOrLegacy: part.type), orderIndex: idx)
            newPart.workout = newWorkout
            // copy only completed sets structure (exercise and last values), not results
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
    }
}

// MARK: - Workout History Card
struct WorkoutHistoryCard: View {
    let workout: Workout
    @Environment(\.theme) private var theme
    @EnvironmentObject var unitSettings: UnitSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.name ?? LocalizationKeys.Training.History.defaultName.localized)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(workout.date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(workout.totalSets) \(LocalizationKeys.Training.Stats.sets.localized.lowercased())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Parts summary
            HStack(spacing: 8) {
                ForEach(workout.parts.sorted(by: { $0.orderIndex < $1.orderIndex }), id: \.id) { part in
                    PartTypeChip(partType: WorkoutPartType.from(rawOrLegacy: part.type))
                }
                
                if workout.parts.isEmpty {
                    Text(LocalizationKeys.Training.History.noParts.localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Prominent stats: Volume + Duration
            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Image(systemName: "scalemass").foregroundColor(.blue)
                    Text(UnitsFormatter.formatVolume(kg: workout.totalVolume, system: unitSettings.unitSystem))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                HStack(spacing: 6) {
                    Image(systemName: "clock").foregroundColor(.orange)
                    Text(durationText).font(.subheadline).fontWeight(.semibold)
                }
                Spacer()
            }
        }
        .padding(theme.spacing.m)
        .background(theme.colors.cardBackground)
        .cornerRadius(12)
    }

    private func formattedTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }

    private var durationText: String {
        guard let end = workout.endTime else { return "-" }
        let interval = end.timeIntervalSince(workout.startTime)
        let minutes = max(0, Int(interval) / 60)
        let hours = minutes / 60
        let mins = minutes % 60
        return hours > 0 ? "\(hours)sa \(mins)dk" : "\(mins)dk"
    }
}

// MARK: - Part Type Chip
struct PartTypeChip: View {
    let partType: WorkoutPartType
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
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: partType.icon)
                .font(.caption)
            Text(localizedDisplayName)
                .font(.caption)
        }
        .padding(.horizontal, theme.spacing.s)
        .padding(.vertical, theme.spacing.xs)
        .background(partColor.opacity(0.2))
        .foregroundColor(partColor)
        .cornerRadius(8)
    }
    
    private var partColor: Color {
        switch partType {
        case .powerStrength: return .blue
        case .metcon: return .red
        case .accessory: return .green
        case .cardio: return .orange
        }
    }
}
