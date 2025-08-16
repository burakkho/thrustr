import SwiftUI
import SwiftData

// MARK: - Set Tracking Action Bar
struct SetTrackingActionBar: View {
    let onFinish: () -> Void
    let hasCompletedSets: Bool
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 12) {
                Spacer()
                // Finish button
                Button(LocalizationKeys.Training.Set.finishExercise.localized) {
                    onFinish()
                    HapticManager.shared.impact(.light)
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, theme.spacing.l)
                .padding(.vertical, theme.spacing.m)
                .background(hasCompletedSets ? theme.colors.success : Color.gray)
                .cornerRadius(8)
                .disabled(!hasCompletedSets)
                .buttonStyle(PressableStyle())
            }
            .padding(theme.spacing.m)
        }
        .background(theme.colors.backgroundPrimary)
    }
}

// MARK: - Reorderable list for sets
struct ReorderSetsList: View {
    let exercise: Exercise
    @Binding var sets: [SetData]
    @Environment(\.theme) private var theme

    var body: some View {
        List {
            Section(header:
                        HStack {
                            Text(LocalizationKeys.Training.Set.Header.set.localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            if exercise.supportsWeight { Text(LocalizationKeys.Training.Set.Header.weight.localized).font(.caption).foregroundColor(.secondary) }
                            if exercise.supportsReps { Text(LocalizationKeys.Training.Set.Header.reps.localized).font(.caption).foregroundColor(.secondary) }
                            if exercise.supportsTime { Text(LocalizationKeys.Training.Set.Header.time.localized).font(.caption).foregroundColor(.secondary) }
                            if exercise.supportsDistance { Text(LocalizationKeys.Training.Set.Header.distance.localized).font(.caption).foregroundColor(.secondary) }
                        }
            ) {
                ForEach(Array(sets.enumerated()), id: \.element.id) { (index, _) in
                    HStack {
                        Text("\(index + 1)").font(.subheadline)
                        Spacer()
                        if exercise.supportsWeight { Text(sets[index].weight > 0 ? "\(Int(sets[index].weight))kg" : "-").font(.caption) }
                        if exercise.supportsReps { Text(sets[index].reps > 0 ? "\(sets[index].reps)" : "-").font(.caption) }
                        if exercise.supportsTime { Text(sets[index].durationSeconds > 0 ? timeText(sets[index].durationSeconds) : "-").font(.caption) }
                        if exercise.supportsDistance { Text(sets[index].distanceMeters > 0 ? distanceText(sets[index].distanceMeters) : "-").font(.caption) }
                    }
                }
                .onMove { indices, newOffset in
                    sets.move(fromOffsets: indices, toOffset: newOffset)
                }
            }
        }
        .listStyle(.insetGrouped)
        .toolbar { EditButton() }
    }

    private func timeText(_ secs: Int) -> String {
        let m = secs / 60, s = secs % 60
        return String(format: "%d:%02d", m, s)
    }

    private func distanceText(_ meters: Double) -> String {
        if meters >= 1000 { return String(format: "%.1fkm", meters / 1000) }
        return "\(Int(meters))m"
    }
}

// MARK: - OneRM
enum OneRMFormula: String, CaseIterable {
    case epley
    case brzycki
    case lander

    var displayName: String {
        switch self {
        case .epley: return "Epley"
        case .brzycki: return "Brzycki"
        case .lander: return "Lander"
        }
    }

    func estimate1RM(weight: Double, reps: Int) -> Double {
        guard reps > 0 else { return weight }
        switch self {
        case .epley:
            // 1RM = w * (1 + r/30)
            return weight * (1.0 + Double(reps) / 30.0)
        case .brzycki:
            // 1RM = w * 36 / (37 - r)
            let denom = max(1.0, 37.0 - Double(reps))
            return weight * 36.0 / denom
        case .lander:
            // 1RM = w * 100 / (101.3 - 2.67123r)
            let denom = max(1.0, 101.3 - 2.67123 * Double(reps))
            return weight * 100.0 / denom
        }
    }
}
