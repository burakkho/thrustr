import SwiftUI
import SwiftData

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

// MARK: - Unified Add Menu Button
struct AddMenuButton: View {
    let onAddPart: () -> Void
    let onAddExercise: () -> Void
    let onAddWOD: () -> Void
    @Environment(\.theme) private var theme
    var body: some View {
        Menu {
            Button { onAddPart() } label: {
                Label(LocalizationKeys.Training.Detail.addPart.localized, systemImage: "rectangle.stack.badge.plus")
            }
            Button { onAddExercise() } label: {
                Label(LocalizationKeys.Training.Part.addExercise.localized, systemImage: "plus")
            }
            Button { onAddWOD() } label: {
                Label(LocalizationKeys.Training.WOD.create.localized, systemImage: "figure.cross.training")
            }
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(theme.colors.accent)
                Text(LocalizationKeys.Common.add.localized)
                    .fontWeight(.medium)
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

struct WorkoutActionBar: View {
    @Environment(\.theme) private var theme
    @EnvironmentObject var unitSettings: UnitSettings
    let workout: Workout
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            HStack {
                HStack(spacing: theme.spacing.l) {
                    StatBadge(title: LocalizationKeys.Training.Stats.parts.localized, value: "\(workout.parts.count)")
                    StatBadge(title: LocalizationKeys.Training.Stats.sets.localized, value: "\(workout.totalSets)")
                    StatBadge(title: LocalizationKeys.Training.Stats.volume.localized, value: UnitsFormatter.formatVolume(kg: workout.totalVolume, system: unitSettings.unitSystem))
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

// MARK: - Recent Exercise Chips
struct RecentExerciseChips: View {
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

// MARK: - Edit Exercise Set Sheet
struct EditExerciseSetSheet: View {
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

// MARK: - Action Chip
struct ActionChip: View {
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

// MARK: - Stat Badge
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
