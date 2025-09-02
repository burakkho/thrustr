import SwiftUI

/**
 * Standardized weight input field with validation and formatting.
 * 
 * Provides consistent weight input across the app with proper validation,
 * unit formatting, and accessibility support.
 */
struct WeightInputField: View {
    // MARK: - Properties
    @Binding var value: Double
    let exerciseType: StrengthExerciseType
    let placeholder: String
    let isEnabled: Bool
    
    @State private var textValue: String = ""
    @State private var isEditing: Bool = false
    
    @Environment(\.theme) private var theme
    
    // MARK: - Initialization
    init(
        value: Binding<Double>,
        exerciseType: StrengthExerciseType,
        placeholder: String? = nil,
        isEnabled: Bool = true
    ) {
        self._value = value
        self.exerciseType = exerciseType
        self.placeholder = placeholder ?? exerciseType.unit
        self.isEnabled = isEnabled
    }
    
    var body: some View {
        HStack(spacing: theme.spacing.s) {
            // Input field
            TextField(placeholder, text: $textValue)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .disabled(!isEnabled)
                .onAppear {
                    updateTextFromValue()
                }
                .onSubmit {
                    updateValueFromText()
                }
                .onChange(of: textValue) { _, newValue in
                    updateValueFromText()
                }
                .onChange(of: value) { _, newValue in
                    if !isEditing {
                        updateTextFromValue()
                    }
                }
            
            // Unit label
            Text(exerciseType.unit)
                .font(.system(.body, design: .rounded, weight: .medium))
                .foregroundColor(theme.colors.textSecondary)
                .frame(width: 35, alignment: .leading)
        }
        .opacity(isEnabled ? 1.0 : 0.6)
    }
    
    // MARK: - Helper Methods
    
    private func updateTextFromValue() {
        if value > 0 {
            // Always show integers only - no decimals
            textValue = String(Int(value))
        } else {
            textValue = ""
        }
    }
    
    private func updateValueFromText() {
        // Simple integer parsing - no decimals needed
        if let intValue = Int(textValue), intValue > 0 {
            value = Double(intValue)
        } else {
            value = 0
            textValue = ""
        }
    }
}

// MARK: - Weighted Pull-up Input Field

/**
 * Specialized input field for pull-ups with bodyweight/weighted toggle.
 */
struct PullUpInputField: View {
    // MARK: - Properties
    @Binding var reps: Double
    @Binding var isWeighted: Bool
    @Binding var additionalWeight: Double
    
    let userBodyWeight: Double
    let isEnabled: Bool
    
    @Environment(\.theme) private var theme
    
    init(
        reps: Binding<Double>,
        isWeighted: Binding<Bool>,
        additionalWeight: Binding<Double>,
        userBodyWeight: Double,
        isEnabled: Bool = true
    ) {
        self._reps = reps
        self._isWeighted = isWeighted
        self._additionalWeight = additionalWeight
        self.userBodyWeight = userBodyWeight
        self.isEnabled = isEnabled
    }
    
    var body: some View {
        VStack(spacing: theme.spacing.m) {
            // Bodyweight/Weighted toggle
            HStack {
                Text("strength.input.pullUpType".localized)
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .foregroundColor(theme.colors.textSecondary)
                
                Spacer()
                
                Picker("Pull-up Type", selection: $isWeighted) {
                    Text("strength.input.bodyweight".localized).tag(false)
                    Text("strength.input.weighted".localized).tag(true)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 200)
                .disabled(!isEnabled)
            }
            
            // Reps input
            HStack(spacing: theme.spacing.m) {
                Text("strength.input.reps".localized)
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .frame(width: 50, alignment: .leading)
                
                WeightInputField(
                    value: $reps,
                    exerciseType: .pullUp,
                    isEnabled: isEnabled
                )
            }
            
            // Additional weight input (for weighted pull-ups)
            if isWeighted {
                HStack(spacing: theme.spacing.m) {
                    Text("strength.input.additionalWeight".localized)
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .frame(width: 50, alignment: .leading)
                    
                    WeightInputField(
                        value: $additionalWeight,
                        exerciseType: .benchPress, // Use kg unit
                        placeholder: "0.0",
                        isEnabled: isEnabled
                    )
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Effective weight calculation display
            if reps > 0 {
                HStack {
                    Text("strength.input.effectiveWeight".localized)
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(theme.colors.textSecondary)
                    
                    Spacer()
                    
                    Text(formatEffectiveWeight())
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundColor(theme.colors.textPrimary)
                }
                .padding(.top, theme.spacing.xs)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isWeighted)
    }
    
    // MARK: - Helper Methods
    
    private func formatEffectiveWeight() -> String {
        if isWeighted && additionalWeight > 0 {
            let totalWeight = userBodyWeight + additionalWeight
            let effectiveWeight = (totalWeight / userBodyWeight) * reps
            return String(format: "%.1f equivalent reps", effectiveWeight)
        } else {
            return String(format: "%.0f bodyweight reps", reps)
        }
    }
}

// MARK: - Preview

#Preview("Weight Input Field") {
    VStack(spacing: 20) {
        WeightInputField(
            value: .constant(80.0),
            exerciseType: .benchPress,
            placeholder: "Enter weight"
        )
        
        WeightInputField(
            value: .constant(10.0),
            exerciseType: .pullUp
        )
        
        PullUpInputField(
            reps: .constant(8.0),
            isWeighted: .constant(true),
            additionalWeight: .constant(20.0),
            userBodyWeight: 80.0
        )
    }
    .padding()
}