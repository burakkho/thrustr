import SwiftUI

/**
 * Enhanced input row with real-time validation and feedback.
 */
struct EnhancedStrengthTestInputRow: View {
    // MARK: - Properties
    let exerciseType: StrengthExerciseType
    @Binding var weight: Double
    @Binding var reps: Double
    
    let previousBest: Double?
    let isCompleted: Bool
    let errorMessage: String?
    let estimatedOneRM: Double?
    let isFocused: Bool
    let isEnabled: Bool
    let onInstructionsTap: () -> Void
    let onFocusChange: (Bool) -> Void
    
    @Environment(\.theme) private var theme
    @FocusState private var isWeightFocused: Bool
    @FocusState private var isRepsFocused: Bool
    
    // MARK: - Initialization
    init(
        exerciseType: StrengthExerciseType,
        weight: Binding<Double>,
        reps: Binding<Double>,
        previousBest: Double? = nil,
        isCompleted: Bool = false,
        errorMessage: String? = nil,
        estimatedOneRM: Double? = nil,
        isFocused: Bool = false,
        isEnabled: Bool = true,
        onInstructionsTap: @escaping () -> Void,
        onFocusChange: @escaping (Bool) -> Void = { _ in }
    ) {
        self.exerciseType = exerciseType
        self._weight = weight
        self._reps = reps
        self.previousBest = previousBest
        self.isCompleted = isCompleted
        self.errorMessage = errorMessage
        self.estimatedOneRM = estimatedOneRM
        self.isFocused = isFocused
        self.isEnabled = isEnabled
        self.onInstructionsTap = onInstructionsTap
        self.onFocusChange = onFocusChange
    }
    
    var body: some View {
        VStack(spacing: theme.spacing.s) {
            // Main input row
            HStack(spacing: theme.spacing.l) {
                // Exercise name with status and info
                exerciseInfoSection
                
                Spacer()
                
                // Input section based on exercise type
                if exerciseType == .pullUp {
                    pullUpInputSection
                } else {
                    standardInputSection
                }
            }
            .padding(.vertical, theme.spacing.m)
            .opacity(isEnabled ? 1.0 : 0.6)
            
            // Feedback section (error, previous best, estimate)
            feedbackSection
        }
        .onChange(of: isWeightFocused || isRepsFocused) { _, isFocusedNow in
            onFocusChange(isFocusedNow)
        }
    }
    
    // MARK: - Exercise Info Section
    
    private var exerciseInfoSection: some View {
        HStack(spacing: theme.spacing.m) {
            // Status indicator with animation
            Group {
                if isCompleted {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.2))
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: "checkmark")
                            .font(.system(.caption, weight: .bold))
                            .foregroundColor(.green)
                    }
                } else if hasError {
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.2))
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: "exclamationmark")
                            .font(.system(.caption, weight: .bold))
                            .foregroundColor(.red)
                    }
                } else {
                    ZStack {
                        Circle()
                            .stroke(theme.colors.textSecondary.opacity(0.3), lineWidth: 2)
                            .frame(width: 28, height: 28)
                        
                        if isFocused {
                            Circle()
                                .fill(theme.colors.accent.opacity(0.1))
                                .frame(width: 28, height: 28)
                        }
                    }
                }
            }
            .animation(.spring(duration: 0.3), value: isCompleted)
            .animation(.spring(duration: 0.3), value: hasError)
            .animation(.spring(duration: 0.3), value: isFocused)
            
            // Exercise name and info button
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                HStack(spacing: theme.spacing.s) {
                    Text(exerciseType.name)
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Button(action: onInstructionsTap) {
                        Image(systemName: "questionmark.circle")
                            .font(.system(.caption))
                            .foregroundColor(theme.colors.accent)
                    }
                    .scaleEffect(0.9)
                }
                
                // Clean muscle group indicator
                HStack(spacing: theme.spacing.xs) {
                    Circle()
                        .fill(muscleGroupColor)
                        .frame(width: 6, height: 6)
                    
                    Text(exerciseType.muscleGroup.name)
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
            .frame(width: 140, alignment: .leading)
        }
    }
    
    // MARK: - Standard Exercise Input
    
    private var standardInputSection: some View {
        HStack(spacing: theme.spacing.l) {
            // Weight input
            VStack(spacing: theme.spacing.xs) {
                Text("Ağırlık")
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundColor(inputLabelColor)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(inputBorderColor, lineWidth: inputBorderWidth)
                        .frame(width: 80, height: 36)
                    
                    TextField("0", value: $weight, format: .number)
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundColor(theme.colors.textPrimary)
                        .multilineTextAlignment(.center)
                        .focused($isWeightFocused)
                        .keyboardType(.decimalPad)
                        .frame(width: 76, height: 32)
                }
            }
            
            // Multiplication symbol
            Image(systemName: "xmark")
                .font(.system(.caption, weight: .medium))
                .foregroundColor(theme.colors.textSecondary)
            
            // Reps input
            VStack(spacing: theme.spacing.xs) {
                Text("Tekrar")
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundColor(inputLabelColor)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(inputBorderColor, lineWidth: inputBorderWidth)
                        .frame(width: 60, height: 36)
                    
                    TextField("1", value: $reps, format: .number)
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundColor(theme.colors.textPrimary)
                        .multilineTextAlignment(.center)
                        .focused($isRepsFocused)
                        .keyboardType(.numberPad)
                        .frame(width: 56, height: 32)
                }
            }
        }
    }
    
    // MARK: - Pull-up Specific Input
    
    private var pullUpInputSection: some View {
        HStack(spacing: theme.spacing.l) {
            Spacer()
                .frame(width: 80) // Align with weight column
            
            // Reps input for pull-ups
            VStack(spacing: theme.spacing.xs) {
                Text("Tekrar")
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundColor(inputLabelColor)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(inputBorderColor, lineWidth: inputBorderWidth)
                        .frame(width: 80, height: 36)
                    
                    TextField("0", value: $reps, format: .number)
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundColor(theme.colors.textPrimary)
                        .multilineTextAlignment(.center)
                        .focused($isRepsFocused)
                        .keyboardType(.numberPad)
                        .frame(width: 76, height: 32)
                }
            }
        }
    }
    
    // MARK: - Feedback Section
    
    @ViewBuilder
    private var feedbackSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            // Error message
            if let errorMessage = errorMessage {
                HStack(spacing: theme.spacing.s) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(.caption2))
                        .foregroundColor(.red)
                    
                    Text(errorMessage)
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.red)
                    
                    Spacer()
                }
                .padding(.horizontal, theme.spacing.m)
                .padding(.vertical, theme.spacing.s)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.red.opacity(0.1))
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Positive feedback (estimate or previous best)
            if !hasError {
                HStack {
                    // Estimated 1RM
                    if let estimate = estimatedOneRM, estimate > 0 {
                        HStack(spacing: theme.spacing.xs) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(.caption2))
                                .foregroundColor(.green)
                            
                            Text(formatEstimate(estimate))
                                .font(.system(.caption, design: .rounded, weight: .medium))
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, theme.spacing.s)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.green.opacity(0.1))
                        )
                    }
                    
                    Spacer()
                    
                    // Clean previous best indicator
                    if let previousBest = previousBest, previousBest > 0 {
                        HStack(spacing: theme.spacing.xs) {
                            Circle()
                                .fill(theme.colors.accent.opacity(0.6))
                                .frame(width: 4, height: 4)
                            
                            Text("Önceki: \(formatPreviousBest(previousBest))")
                                .font(.system(.caption2, design: .rounded))
                                .foregroundColor(theme.colors.textSecondary)
                        }
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: errorMessage)
        .animation(.easeInOut(duration: 0.2), value: estimatedOneRM)
    }
    
    // MARK: - Helper Properties
    
    private var hasError: Bool {
        errorMessage != nil
    }
    
    private var inputBorderColor: Color {
        if hasError {
            return .red
        } else if isFocused {
            return theme.colors.accent
        } else if isCompleted {
            return .green.opacity(0.6)
        } else {
            return theme.colors.textSecondary.opacity(0.3)
        }
    }
    
    private var inputBorderWidth: CGFloat {
        if hasError || isFocused {
            return 2
        } else {
            return 1
        }
    }
    
    private var inputLabelColor: Color {
        if hasError {
            return .red
        } else if isFocused {
            return theme.colors.accent
        } else {
            return theme.colors.textSecondary
        }
    }
    
    private var muscleGroupColor: Color {
        switch exerciseType.muscleGroup {
        case .chest: return .blue
        case .shoulders: return .orange
        case .back: return .green
        case .legs: return .purple
        case .hips: return .red
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatEstimate(_ estimate: Double) -> String {
        if exerciseType == .pullUp {
            return String(format: "~%.0f tekrar (1RM)", estimate)
        } else {
            return String(format: "~%.0f kg (1RM)", estimate)
        }
    }
    
    private func formatPreviousBest(_ value: Double) -> String {
        if exerciseType == .pullUp {
            return String(format: "%.0f tekrar", value)
        } else {
            return String(format: "%.0f kg", value)
        }
    }
}

// MARK: - Preview

#Preview("Enhanced Strength Test Input Rows") {
    ScrollView {
        VStack(spacing: 24) {
            // Normal state
            EnhancedStrengthTestInputRow(
                exerciseType: .benchPress,
                weight: .constant(0),
                reps: .constant(0),
                onInstructionsTap: { }
            )
            
            // With values and estimate
            EnhancedStrengthTestInputRow(
                exerciseType: .deadlift,
                weight: .constant(150),
                reps: .constant(5),
                estimatedOneRM: 169.5,
                onInstructionsTap: { }
            )
            
            // Completed state
            EnhancedStrengthTestInputRow(
                exerciseType: .backSquat,
                weight: .constant(120),
                reps: .constant(3),
                previousBest: 115,
                isCompleted: true,
                estimatedOneRM: 127.9,
                onInstructionsTap: { }
            )
            
            // Error state
            EnhancedStrengthTestInputRow(
                exerciseType: .overheadPress,
                weight: .constant(0),
                reps: .constant(0),
                errorMessage: "Ağırlık ve tekrar sayısı girin",
                onInstructionsTap: { }
            )
            
            // Pull-up with reps only
            EnhancedStrengthTestInputRow(
                exerciseType: .pullUp,
                weight: .constant(0),
                reps: .constant(8),
                estimatedOneRM: 8,
                onInstructionsTap: { }
            )
        }
        .padding(20)
    }
}