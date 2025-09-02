import SwiftUI

/**
 * Minimalist input row for strength test exercises.
 * 
 * Replaces the card-based TestExerciseCard with a clean,
 * horizontal input layout matching the new design.
 */
struct StrengthTestInputRow: View {
    // MARK: - Properties
    let exerciseType: StrengthExerciseType
    @Binding var weight: Double
    @Binding var reps: Double
    
    let previousBest: Double?
    let isCompleted: Bool
    let isEnabled: Bool
    let onInstructionsTap: () -> Void
    
    @Environment(\.theme) private var theme
    
    // MARK: - Initialization
    init(
        exerciseType: StrengthExerciseType,
        weight: Binding<Double>,
        reps: Binding<Double>,
        previousBest: Double? = nil,
        isCompleted: Bool = false,
        isEnabled: Bool = true,
        onInstructionsTap: @escaping () -> Void
    ) {
        self.exerciseType = exerciseType
        self._weight = weight
        self._reps = reps
        self.previousBest = previousBest
        self.isCompleted = isCompleted
        self.isEnabled = isEnabled
        self.onInstructionsTap = onInstructionsTap
    }
    
    var body: some View {
        VStack(spacing: theme.spacing.xs) {
        HStack(spacing: theme.spacing.l) {
            // Exercise name with status
            HStack(spacing: theme.spacing.s) {
                // Status indicator
                Group {
                    if isCompleted {
                        Text("✅")
                            .font(.body)
                    } else {
                        Text("○")
                            .font(.body)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }
                .animation(.spring(duration: 0.3), value: isCompleted)
                
                Text(exerciseType.name)
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .foregroundColor(theme.colors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(width: 130, alignment: .leading)
            
            // Input section based on exercise type
            if exerciseType == .pullUp {
                pullUpInputSection
            } else {
                standardInputSection
            }
        }
        .padding(.vertical, theme.spacing.m)
        .opacity(isEnabled ? 1.0 : 0.6)
        
        // Previous best indicator (if available)
        if let previousBest = previousBest, previousBest > 0 {
            HStack {
                Spacer()
                Text("⚡ Previous: \(formatPreviousBest(previousBest))")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundColor(theme.colors.textSecondary)
                    .padding(.horizontal, theme.spacing.m)
            }
        }
        }
    }
    
    // MARK: - Standard Exercise Input
    
    @ViewBuilder
    private var standardInputSection: some View {
        HStack(spacing: theme.spacing.xl) {
            // Weight input
            VStack(spacing: theme.spacing.xs) {
                Text("Weight")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(theme.colors.textSecondary)
                
                UnderlinedNumericField(
                    placeholder: "0",
                    value: $weight,
                    suffix: "kg",
                    isEnabled: isEnabled,
                    minValue: 0,
                    maxValue: 500
                )
                .frame(width: 120)
            }
            
            // Reps input
            VStack(spacing: theme.spacing.xs) {
                Text("Reps")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(theme.colors.textSecondary)
                
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(theme.colors.textSecondary)
                
                UnderlinedNumericField(
                    placeholder: "1",
                    value: $reps,
                    isEnabled: isEnabled,
                    minValue: 0,
                    maxValue: 20,
                    keyboardType: .numberPad
                )
                .frame(width: 100)
            }
        }
    }
    
    // MARK: - Pull-up Specific Input
    
    @ViewBuilder
    private var pullUpInputSection: some View {
        HStack(spacing: theme.spacing.xl) {
            // Empty space for alignment (like weight column)
            Spacer()
                .frame(width: 80)
            
            // Reps input
            VStack(spacing: theme.spacing.xs) {
                Text("Reps")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(theme.colors.textSecondary)
                
                UnderlinedNumericField(
                    placeholder: "1",
                    value: $reps,
                    isEnabled: isEnabled,
                    minValue: 0,
                    maxValue: 100,
                    keyboardType: .numberPad
                )
                .frame(width: 100)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatPreviousBest(_ value: Double) -> String {
        if exerciseType == .pullUp {
            return String(format: "%.0f reps", value)
        } else {
            return String(format: "%.0f kg", value)
        }
    }
}


// MARK: - Preview

#Preview("Strength Test Input Rows") {
    VStack(spacing: 24) {
        StrengthTestInputRow(
            exerciseType: .backSquat,
            weight: .constant(150),
            reps: .constant(1),
            onInstructionsTap: { }
        )
        
        StrengthTestInputRow(
            exerciseType: .deadlift,
            weight: .constant(220),
            reps: .constant(1),
            isCompleted: true,
            onInstructionsTap: { }
        )
        
        StrengthTestInputRow(
            exerciseType: .benchPress,
            weight: .constant(125),
            reps: .constant(1),
            onInstructionsTap: { }
        )
        
        StrengthTestInputRow(
            exerciseType: .overheadPress,
            weight: .constant(75),
            reps: .constant(1),
            onInstructionsTap: { }
        )
        
        StrengthTestInputRow(
            exerciseType: .pullUp,
            weight: .constant(0),
            reps: .constant(10),
            onInstructionsTap: { }
        )
    }
    .padding(20)
}