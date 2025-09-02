import SwiftUI

/**
 * Individual exercise card within strength test interface.
 * 
 * Displays exercise information, input field, current level, and instructions
 * in a clean card format.
 */
struct TestExerciseCard: View {
    // MARK: - Properties
    let exerciseType: StrengthExerciseType
    @Binding var value: Double
    @Binding var isWeighted: Bool
    @Binding var additionalWeight: Double
    
    let userWeight: Double
    let previousBest: Double?
    let isCompleted: Bool
    let isEnabled: Bool
    let onInstructionsTap: () -> Void
    
    @State private var showingStrengthLevel: Bool = false
    @Environment(\.theme) private var theme
    
    // MARK: - Initialization
    init(
        exerciseType: StrengthExerciseType,
        value: Binding<Double>,
        isWeighted: Binding<Bool> = .constant(false),
        additionalWeight: Binding<Double> = .constant(0),
        userWeight: Double,
        previousBest: Double? = nil,
        isCompleted: Bool = false,
        isEnabled: Bool = true,
        onInstructionsTap: @escaping () -> Void
    ) {
        self.exerciseType = exerciseType
        self._value = value
        self._isWeighted = isWeighted
        self._additionalWeight = additionalWeight
        self.userWeight = userWeight
        self.previousBest = previousBest
        self.isCompleted = isCompleted
        self.isEnabled = isEnabled
        self.onInstructionsTap = onInstructionsTap
    }
    
    var body: some View {
        VStack(spacing: theme.spacing.m) {
            // Header with exercise info
            HStack {
                // Exercise icon and name
                HStack(spacing: theme.spacing.s) {
                    Image(systemName: exerciseType.icon)
                        .font(.title2)
                        .foregroundColor(theme.colors.accent)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(exerciseType.name)
                            .font(.system(.headline, design: .rounded, weight: .semibold))
                            .foregroundColor(theme.colors.textPrimary)
                        
                        Text("\(exerciseType.muscleGroup.emoji) \(exerciseType.muscleGroup.name)")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }
                
                Spacer()
                
                // Instructions button
                Button(action: onInstructionsTap) {
                    Image(systemName: "questionmark.circle")
                        .font(.title3)
                        .foregroundColor(theme.colors.textSecondary)
                }
                .buttonStyle(.plain)
            }
            
            // Input section
            inputSection
            
            // Current level and previous best
            if value > 0 || previousBest != nil {
                Divider()
                
                HStack {
                    // Previous best
                    if let previousBest = previousBest {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("strength.card.previousBest".localized)
                                .font(.system(.caption2, design: .rounded))
                                .foregroundColor(theme.colors.textSecondary)
                            
                            Text(formatValue(previousBest))
                                .font(.system(.caption, design: .rounded, weight: .medium))
                                .foregroundColor(theme.colors.textPrimary)
                        }
                    }
                    
                    Spacer()
                    
                    // Current level indicator
                    if value > 0 {
                        HStack(spacing: theme.spacing.xs) {
                            CompactLevelRing(
                                level: currentLevel.level,
                                percentileInLevel: currentLevel.percentile
                            )
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(currentLevel.level.name)
                                    .font(.system(.caption, design: .rounded, weight: .medium))
                                    .foregroundColor(theme.colors.textPrimary)
                                
                                Text("\(Int(currentLevel.percentile * 100))%")
                                    .font(.system(.caption2, design: .rounded))
                                    .foregroundColor(theme.colors.textSecondary)
                            }
                        }
                    }
                }
            }
            
            // Completion status
            if isCompleted {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    
                    Text("strength.card.completed".localized)
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundColor(.green)
                    
                    Spacer()
                    
                    if isPersonalRecord {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.orange)
                            
                            Text("strength.card.personalRecord".localized)
                                .font(.system(.caption, design: .rounded, weight: .medium))
                                .foregroundColor(.orange)
                        }
                    }
                }
                .padding(.top, theme.spacing.xs)
            }
        }
        .padding(theme.spacing.m)
        .background(theme.colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.l))
        .shadow(color: theme.shadows.card.opacity(0.05), radius: 2)
        .opacity(isEnabled ? 1.0 : 0.7)
        .animation(.easeInOut(duration: 0.2), value: isCompleted)
    }
    
    // MARK: - Input Section
    
    @ViewBuilder
    private var inputSection: some View {
        if exerciseType == .pullUp {
            PullUpInputField(
                reps: $value,
                isWeighted: $isWeighted,
                additionalWeight: $additionalWeight,
                userBodyWeight: userWeight,
                isEnabled: isEnabled
            )
        } else {
            HStack(spacing: theme.spacing.m) {
                Text("strength.card.weight".localized)
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .foregroundColor(theme.colors.textPrimary)
                    .frame(width: 60, alignment: .leading)
                
                WeightInputField(
                    value: $value,
                    exerciseType: exerciseType,
                    isEnabled: isEnabled
                )
            }
        }
    }
    
    // MARK: - Helper Properties
    
    private var currentLevel: (level: StrengthLevel, percentile: Double) {
        guard value > 0 else { return (.beginner, 0.0) }
        
        let result = StrengthStandardsConfig.strengthLevel(
            for: value,
            exerciseType: exerciseType,
            userGender: Gender.male, // This would come from user data
            userAge: 25, // This would come from user data
            userWeight: userWeight
        )
        return (level: result.level, percentile: result.percentileInLevel)
    }
    
    private var isPersonalRecord: Bool {
        guard let previousBest = previousBest else { return value > 0 }
        return value > previousBest
    }
    
    private func formatValue(_ value: Double) -> String {
        if exerciseType.isRepetitionBased {
            return String(format: "%.0f %@", value, exerciseType.unit)
        } else {
            return String(format: "%.1f %@", value, exerciseType.unit)
        }
    }
}

// MARK: - Exercise Instructions Sheet

// TestInstructionsSheet moved to separate file

// MARK: - Preview

#Preview("Test Exercise Card") {
    VStack(spacing: 20) {
        TestExerciseCard(
            exerciseType: .benchPress,
            value: .constant(80.0),
            userWeight: 75.0,
            previousBest: 75.0,
            isCompleted: true,
            onInstructionsTap: { }
        )
        
        TestExerciseCard(
            exerciseType: .pullUp,
            value: .constant(10.0),
            isWeighted: .constant(true),
            additionalWeight: .constant(20.0),
            userWeight: 80.0,
            onInstructionsTap: { }
        )
    }
    .padding()
}