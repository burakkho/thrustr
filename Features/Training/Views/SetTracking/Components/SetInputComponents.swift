import SwiftUI
import SwiftData

// MARK: - Number Input Field
struct NumberInputField: View {
    @Binding var value: Double
    let placeholder: String
    let isEnabled: Bool
    var allowDecimals: Bool = true
    var isWeight: Bool = false
    var isReps: Bool = false
    var onNextField: (() -> Void)?
    var onPreviousField: (() -> Void)?
    var onCompleteSet: (() -> Void)?
    
    @FocusState private var isFocused: Bool
    @AppStorage("preferredUnitSystem") private var preferredUnitSystem: String = "metric"
    
    var body: some View {
        HStack(spacing: 4) {
            if isWeight && isEnabled {
                incrementButton(increment: -weightIncrement, systemImage: "minus.circle.fill")
            } else if isReps && isEnabled {
                incrementButton(increment: -1, systemImage: "minus.circle.fill")
            }
            
            TextField(placeholder, value: $value, format: allowDecimals ? .number.precision(.fractionLength(0...1)) : .number.precision(.fractionLength(0)))
                .textFieldStyle(PlainTextFieldStyle())
                .multilineTextAlignment(.center)
                .font(.headline)
                .foregroundColor(isEnabled ? .primary : .secondary)
                .disabled(!isEnabled)
                .focused($isFocused)
                .keyboardType(allowDecimals ? .decimalPad : .numberPad)
                .onTapGesture {
                    if isEnabled {
                        isFocused = true
                    }
                }
            
            if isWeight && isEnabled {
                incrementButton(increment: weightIncrement, systemImage: "plus.circle.fill")
            } else if isReps && isEnabled {
                incrementButton(increment: 1, systemImage: "plus.circle.fill")
            }
        }
    }
    
    private var weightIncrement: Double {
        preferredUnitSystem == "imperial" ? 5 : 2.5 // 5 lbs or 2.5 kg
    }
    
    private func incrementButton(increment: Double, systemImage: String) -> some View {
        Button {
            let newValue = max(0, value + increment)
            value = newValue
            HapticManager.shared.impact(.light)
        } label: {
            Image(systemName: systemImage)
                .font(.caption)
                .foregroundColor(.blue)
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: 20, height: 20)
    }
}

// MARK: - Time Input Field
struct TimeInputField: View {
    @Binding var seconds: Int
    let isEnabled: Bool
    
    @State private var minutes: Int = 0
    @State private var secs: Int = 0
    
    var body: some View {
        HStack(spacing: 2) {
            TextField("0", value: $minutes, format: .number)
                .textFieldStyle(PlainTextFieldStyle())
                .multilineTextAlignment(.center)
                .frame(width: 30)
                .disabled(!isEnabled)
                .keyboardType(.numberPad)
            
            Text(":")
                .font(.headline)
            
            TextField("00", value: $secs, format: .number.precision(.integerLength(2)))
                .textFieldStyle(PlainTextFieldStyle())
                .multilineTextAlignment(.center)
                .frame(width: 30)
                .disabled(!isEnabled)
                .keyboardType(.numberPad)
        }
        .font(.headline)
        .foregroundColor(isEnabled ? .primary : .secondary)
        .onAppear {
            updateFromSeconds()
        }
        .onChange(of: minutes) {
            updateSeconds()
        }
        .onChange(of: secs) {
            updateSeconds()
        }
        .onChange(of: seconds) {
            updateFromSeconds()
        }
    }
    
    private func updateSeconds() {
        let safeMinutes = max(0, minutes)
        let clampedSecs = min(max(0, secs), 59)
        minutes = safeMinutes
        secs = clampedSecs
        seconds = safeMinutes * 60 + clampedSecs
    }
    
    private func updateFromSeconds() {
        minutes = seconds / 60
        secs = seconds % 60
    }
}

// MARK: - RPE Picker
struct RPEPicker: View {
    @Binding var rpe: Int
    let isEnabled: Bool
    
    var body: some View {
        Menu {
            ForEach(0...10, id: \.self) { value in
                Button("\(value)") {
                    rpe = value
                }
            }
        } label: {
            Text(rpe == 0 ? "-" : "\(rpe)")
                .font(.headline)
                .foregroundColor(isEnabled ? .primary : .secondary)
                .frame(maxWidth: .infinity)
        }
        .disabled(!isEnabled)
    }
}
