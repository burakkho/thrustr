import SwiftUI
import SwiftData

struct ExerciseSuggestions: View {
    @Environment(\.theme) private var theme
    let workoutPart: WorkoutPart
    let onSelect: (Exercise) -> Void

    @Query private var exercises: [Exercise]

    var suggestedExercises: [Exercise] {
        // Basit öneri: aynı partType ile eşleşen kategorilerden aktif egzersizleri sırala
        let allowed = Set(workoutPart.workoutPartType.suggestedExerciseCategories.map { $0.rawValue })
        return exercises
            .filter { $0.isActive && allowed.contains($0.category) }
            .sorted { $0.isFavorite && !$1.isFavorite }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            Text("Önerilen Egzersizler")
                .font(.headline)
                .foregroundColor(theme.colors.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: theme.spacing.m) {
                    ForEach(suggestedExercises.prefix(8)) { exercise in
                        SuggestionChip(exercise: exercise) {
                            onSelect(exercise)
                        }
                    }
                }
                .padding(.vertical, theme.spacing.s)
            }
        }
        .padding(.horizontal)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Önerilen egzersizler listesi")
    }
}

// Inline-lightweight sürüm (explicit exercises ile)
struct InlineExerciseSuggestions: View {
    @Environment(\.theme) private var theme
    let workoutPart: WorkoutPart
    let exercises: [Exercise]
    let onSelect: (Exercise) -> Void

    var suggestedExercises: [Exercise] {
        let allowed = Set(workoutPart.workoutPartType.suggestedExerciseCategories.map { $0.rawValue })
        return exercises
            .filter { $0.isActive && allowed.contains($0.category) }
            .sorted { $0.isFavorite && !$1.isFavorite }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            Text("Önerilen Egzersizler")
                .font(.headline)
                .foregroundColor(theme.colors.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: theme.spacing.m) {
                    ForEach(suggestedExercises.prefix(8)) { exercise in
                        SuggestionChip(exercise: exercise) {
                            onSelect(exercise)
                        }
                    }
                }
                .padding(.vertical, theme.spacing.s)
            }
        }
        .padding(.horizontal)
    }
}

struct SuggestionChip: View {
    @Environment(\.theme) private var theme
    let exercise: Exercise
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: (ExerciseCategory(rawValue: exercise.category) ?? .other).icon)
                    .font(.caption)
                    .foregroundColor(theme.colors.accent)
                Text(exercise.nameTR)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            .padding(.horizontal, theme.spacing.m)
            .padding(.vertical, theme.spacing.s)
            .background(theme.colors.accent.opacity(0.12))
            .cornerRadius(16)
        }
        .buttonStyle(PressableStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(exercise.nameTR)
        .accessibilityHint("Seçmek için çift dokun")
    }
}


