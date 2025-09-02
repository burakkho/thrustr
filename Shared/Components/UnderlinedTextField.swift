import SwiftUI

/**
 * Underlined text field component for clean, minimalist input design.
 * 
 * Provides a text field with bottom border styling that matches
 * the strength test input design requirements.
 */
public struct UnderlinedTextField: View {
    let placeholder: String
    @Binding var text: String
    let keyboardType: UIKeyboardType
    let isEnabled: Bool
    let suffix: String?
    
    @Environment(\.theme) private var theme
    @FocusState private var isFocused: Bool
    
    public init(
        placeholder: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType = .default,
        isEnabled: Bool = true,
        suffix: String? = nil
    ) {
        self.placeholder = placeholder
        self._text = text
        self.keyboardType = keyboardType
        self.isEnabled = isEnabled
        self.suffix = suffix
    }
    
    public var body: some View {
        HStack(spacing: theme.spacing.s) {
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .disabled(!isEnabled)
                .focused($isFocused)
                .font(.system(.body, design: .rounded, weight: .medium))
                .foregroundColor(isEnabled ? theme.colors.textPrimary : theme.colors.textSecondary)
                .multilineTextAlignment(.center)
            
            if let suffix = suffix {
                Text(suffix)
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(theme.colors.textSecondary)
            }
        }
        .padding(.vertical, theme.spacing.s)
        .background(
            Rectangle()
                .frame(height: 2)
                .foregroundColor(isFocused ? theme.colors.accent : theme.colors.accent.opacity(0.3))
                .animation(.easeInOut(duration: 0.2), value: isFocused),
            alignment: .bottom
        )
        .opacity(isEnabled ? 1.0 : 0.6)
    }
}

/**
 * Specialized numeric input field with underlined styling.
 */
public struct UnderlinedNumericField: View {
    let placeholder: String
    @Binding var value: Double
    let suffix: String?
    let isEnabled: Bool
    let minValue: Double
    let maxValue: Double
    let keyboardType: UIKeyboardType
    
    @State private var textValue: String = ""
    @Environment(\.theme) private var theme
    
    public init(
        placeholder: String,
        value: Binding<Double>,
        suffix: String? = nil,
        isEnabled: Bool = true,
        minValue: Double = 0,
        maxValue: Double = 9999,
        keyboardType: UIKeyboardType = .decimalPad
    ) {
        self.placeholder = placeholder
        self._value = value
        self.suffix = suffix
        self.isEnabled = isEnabled
        self.minValue = minValue
        self.maxValue = maxValue
        self.keyboardType = keyboardType
    }
    
    public var body: some View {
        UnderlinedTextField(
            placeholder: placeholder,
            text: $textValue,
            keyboardType: keyboardType,
            isEnabled: isEnabled,
            suffix: suffix
        )
        .onAppear {
            if value > 0 {
                textValue = String(format: value == floor(value) ? "%.0f" : "%.1f", value)
            }
        }
        .onChange(of: textValue) { _, newValue in
            // Only update value when text changes from user input
            if let numericValue = Double(newValue) {
                // Only enforce maximum value, let minimum be handled by validation elsewhere
                let clampedValue = min(maxValue, numericValue)
                if clampedValue != value {
                    value = clampedValue
                }
            } else if newValue.isEmpty {
                value = 0
            }
        }
        .onChange(of: value) { _, newValue in
            // Only update text when value changes externally (not from text input)
            let expectedText = newValue == 0 ? "" : String(format: newValue == floor(newValue) ? "%.0f" : "%.1f", newValue)
            if textValue != expectedText {
                textValue = expectedText
            }
        }
    }
}

// MARK: - Preview

#Preview("Underlined Text Field") {
    VStack(spacing: 32) {
        UnderlinedTextField(
            placeholder: "Enter weight",
            text: .constant("150"),
            keyboardType: .decimalPad,
            suffix: "kg"
        )
        
        UnderlinedNumericField(
            placeholder: "0",
            value: .constant(150.0),
            suffix: "kg"
        )
        
        UnderlinedNumericField(
            placeholder: "0",
            value: .constant(10.0),
            suffix: "reps"
        )
    }
    .padding(40)
}