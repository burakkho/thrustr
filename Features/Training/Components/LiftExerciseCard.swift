import SwiftUI
import Foundation

struct LiftExerciseCard: View {
    @Environment(\.theme) private var theme
    @Binding var exerciseData: ExerciseResultData
    let isExpanded: Bool
    let isEditMode: Bool
    let onToggle: () -> Void
    let onAddSet: () -> Void
    let onCompleteSet: (Int) -> Void

    var body: some View {
        VStack(spacing: theme.spacing.s) {
            // Exercise Header
            Button(action: onToggle) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(exerciseData.exerciseName)
                            .font(theme.typography.body)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.colors.textPrimary)

                        if !exerciseData.sets.isEmpty {
                            Text("\(exerciseData.completedSets)/\(exerciseData.sets.count) sets")
                                .font(theme.typography.caption)
                                .foregroundColor(theme.colors.textSecondary)
                        }
                    }

                    Spacer()

                    // Progress indicator
                    if !exerciseData.sets.isEmpty {
                        progressIndicator
                    }

                    // Expand/collapse icon
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(theme.colors.textSecondary)
                }
                .padding(theme.spacing.m)
            }
            .buttonStyle(PlainButtonStyle())

            // Expanded content
            if isExpanded {
                VStack(spacing: theme.spacing.s) {
                    // Sets list
                    ForEach(Array(exerciseData.sets.enumerated()), id: \.offset) { index, setData in
                        SetRow(
                            setData: setData,
                            setNumber: index + 1,
                            onComplete: { onCompleteSet(index) }
                        )
                    }

                    // Add set button
                    Button(action: onAddSet) {
                        HStack {
                            Image(systemName: "plus.circle")
                            Text("Add Set")
                        }
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, theme.spacing.s)
                        .background(theme.colors.accent.opacity(0.1))
                        .cornerRadius(theme.radius.s)
                    }
                }
                .padding(.horizontal, theme.spacing.m)
                .padding(.bottom, theme.spacing.m)
            }
        }
        .background(theme.colors.backgroundSecondary)
        .cornerRadius(theme.radius.m)
        .overlay(
            RoundedRectangle(cornerRadius: theme.radius.m)
                .stroke(isExpanded ? theme.colors.accent : Color.clear, lineWidth: 1)
        )
    }

    private var progressIndicator: some View {
        ZStack {
            Circle()
                .stroke(theme.colors.backgroundTertiary, lineWidth: 2)
                .frame(width: 24, height: 24)

            Circle()
                .trim(from: 0, to: exerciseData.progressPercentage)
                .stroke(theme.colors.success, lineWidth: 2)
                .frame(width: 24, height: 24)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: exerciseData.progressPercentage)
        }
    }
}

// MARK: - Set Row Component
struct SetRow: View {
    @Environment(\.theme) private var theme
    let setData: SetData
    let setNumber: Int
    let onComplete: () -> Void

    var body: some View {
        HStack(spacing: theme.spacing.m) {
            // Set number
            Text("\(setNumber)")
                .font(theme.typography.caption)
                .fontWeight(.medium)
                .foregroundColor(theme.colors.textSecondary)
                .frame(width: 20)

            // Weight
            VStack(spacing: 2) {
                Text("Weight")
                    .font(.caption2)
                    .foregroundColor(theme.colors.textSecondary)
                Text(setData.weight != nil ? "\(setData.weight!, specifier: "%.1f") kg" : "-")
                    .font(theme.typography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(setData.isCompleted ? theme.colors.success : theme.colors.textPrimary)
            }
            .frame(minWidth: 60)

            // Reps
            VStack(spacing: 2) {
                Text("Reps")
                    .font(.caption2)
                    .foregroundColor(theme.colors.textSecondary)
                Text("\(setData.reps)")
                    .font(theme.typography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(setData.isCompleted ? theme.colors.success : theme.colors.textPrimary)
            }
            .frame(minWidth: 40)

            Spacer()

            // Complete button
            Button(action: onComplete) {
                Image(systemName: setData.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(setData.isCompleted ? theme.colors.success : theme.colors.textSecondary)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, theme.spacing.xs)
        .padding(.horizontal, theme.spacing.s)
        .background(setData.isCompleted ? theme.colors.success.opacity(0.1) : Color.clear)
        .cornerRadius(theme.radius.s)
    }
}

#Preview {
    // Create simple mock data for preview
    @Previewable @State var mockData = ExerciseResultData(
        id: UUID(),
        exerciseId: UUID().uuidString,
        exerciseName: "Bench Press",
        targetSets: 3,
        targetReps: 10,
        targetWeight: 60.0,
        sets: [
            SetData(setNumber: 1, weight: 60.0, reps: 10, isWarmup: false, isCompleted: true),
            SetData(setNumber: 2, weight: 70.0, reps: 8, isWarmup: false, isCompleted: false)
        ],
        notes: nil,
        isPersonalRecord: false,
        isCompleted: false
    )

    return LiftExerciseCard(
        exerciseData: $mockData,
        isExpanded: true,
        isEditMode: false,
        onToggle: {},
        onAddSet: {},
        onCompleteSet: { _ in }
    )
    .environment(\.theme, DefaultLightTheme())
    .padding()
}