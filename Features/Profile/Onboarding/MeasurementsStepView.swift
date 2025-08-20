//
//  MeasurementsStepView.swift
//  SporHocam
//
//  Body Measurements Step - Localized
//

import SwiftUI
import SwiftData
// MARK: - Measurements Step
struct MeasurementsStepView: View {
    @Binding var data: OnboardingData
    let onNext: () -> Void
    @State private var validationMessage: String? = nil
    @EnvironmentObject private var unitSettings: UnitSettings
    @FocusState private var neckFocused: Bool
    @FocusState private var waistFocused: Bool
    @FocusState private var hipFocused: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text(LocalizationKeys.Onboarding.measurementsTitle.localized)
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                Text(LocalizationKeys.Onboarding.measurementsSubtitle.localized)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top)
            
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "ruler")
                                .foregroundColor(.blue)
                                .font(.title2)
                            Text(LocalizationKeys.Onboarding.navyMethodTitle.localized)
                                .font(.headline)
                        }
                        Text(LocalizationKeys.Onboarding.navyMethodDesc.localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    
                    VStack(spacing: 16) {
                        MeasurementInput(
                            title: LocalizationKeys.Onboarding.neckLabel.localized,
                            value: $data.neckCircumference,
                            range: data.unitSystem == "imperial" ? 10...20 : 25...50,
                            unit: data.unitSystem == "imperial" ? "in" : "cm",
                            placeholder: LocalizationKeys.Onboarding.optional.localized,
                            unitSystem: data.unitSystem,
                            focus: $neckFocused
                        )
                        
                        MeasurementInput(
                            title: data.gender == "male" ?
                                LocalizationKeys.Onboarding.waistMaleLabel.localized :
                                LocalizationKeys.Onboarding.waistFemaleLabel.localized,
                            value: $data.waistCircumference,
                            range: data.unitSystem == "imperial" ? 20...60 : 50...150,
                            unit: data.unitSystem == "imperial" ? "in" : "cm",
                            placeholder: LocalizationKeys.Onboarding.optional.localized,
                            unitSystem: data.unitSystem,
                            focus: $waistFocused
                        )
                        
                        if data.gender == "female" {
                            MeasurementInput(
                                title: LocalizationKeys.Onboarding.hipLabel.localized,
                                value: $data.hipCircumference,
                                range: data.unitSystem == "imperial" ? 25...60 : 70...150,
                                unit: data.unitSystem == "imperial" ? "in" : "cm",
                                placeholder: LocalizationKeys.Onboarding.optional.localized,
                                unitSystem: data.unitSystem,
                                focus: $hipFocused
                            )
                        }
                    }
                    
                    if canCalculateNavyMethod() {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "chart.pie.fill")
                                    .foregroundColor(.green)
                                    .font(.title2)
                                Text(LocalizationKeys.Onboarding.bodyFatTitle.localized)
                                    .font(.headline)
                            }
                            let bodyFat = calculateNavyMethod()
                            HStack {
                                Text(LocalizationKeys.Onboarding.bodyFatNavy.localized)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("%\(String(format: "%.1f", bodyFat))")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.gray)
                            Text(LocalizationKeys.Onboarding.optionalInfo.localized)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                        }
                        Text(LocalizationKeys.Onboarding.optionalDesc.localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            
            VStack(spacing: 12) {
                if let message = validationMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                PrimaryButton(title: LocalizationKeys.Onboarding.continueButton.localized, icon: "arrow.right") {
                    validationMessage = validateInputs()
                    if validationMessage == nil {
                        onNext()
                    }
                }
                
                Button(LocalizationKeys.Onboarding.skipStep.localized) {
                    data.neckCircumference = nil
                    data.waistCircumference = nil
                    data.hipCircumference = nil
                    onNext()
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
    
    private func canCalculateNavyMethod() -> Bool {
        if data.gender == "male" {
            return data.neckCircumference != nil && data.waistCircumference != nil
        } else {
            return data.neckCircumference != nil && data.waistCircumference != nil && data.hipCircumference != nil
        }
    }
    
    private func calculateNavyMethod() -> Double {
        guard let neck = data.neckCircumference, let waist = data.waistCircumference else { return 0 }
        let height = data.height
        if data.gender == "male" {
            let denom = 1.0324 - 0.19077 * log10(waist - neck) + 0.15456 * log10(height)
            return max(0, min(50, 495 / denom - 450))
        } else {
            guard let hip = data.hipCircumference else { return 0 }
            let denom = 1.29579 - 0.35004 * log10(waist + hip - neck) + 0.22100 * log10(height)
            return max(0, min(50, 495 / denom - 450))
        }
    }
}

// MARK: - Measurement Input Component
struct MeasurementInput: View {
    let title: String
    @Binding var value: Double?
    let range: ClosedRange<Double>
    let unit: String
    let placeholder: String
    let unitSystem: String
    let focus: FocusState<Bool>.Binding
    
    @State private var textValue: String = ""
    @State private var errorText: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            HStack {
                TextField(placeholder, text: $textValue)
                    .keyboardType(.decimalPad)
                    .focused(focus)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: textValue) { _, newValue in
                        parseAndValidate(newValue)
                    }
                    .onAppear {
                        if let v = value {
                            if unitSystem == "imperial" {
                                // convert cm -> inches for display
                                let inches = v / 2.54
                                textValue = String(format: "%.0f", inches)
                            } else {
                                textValue = String(format: "%.0f", v)
                            }
                        } else {
                            textValue = ""
                        }
                    }
                Text(unit)
                    .foregroundColor(.secondary)
                    .padding(.trailing, 8)
            }
            if let errorText = errorText {
                Text(errorText)
                    .font(.caption)
                    .foregroundColor(.red)
            } else {
                Text("\(Int(range.lowerBound))-\(Int(range.upperBound)) \(unit)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Validation Helper
private extension MeasurementsStepView {
    func validateInputs() -> String? {
        // All optional, but if provided must be within range (already enforced). No blocking needed.
        return nil
    }
}

// MARK: - Localized number parsing for MeasurementInput
private extension MeasurementInput {
    func parseAndValidate(_ raw: String) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            value = nil
            errorText = nil
            return
        }
        // Accept both comma and dot as decimal separator
        let normalized = trimmed.replacingOccurrences(of: ",", with: ".")
        if let v = Double(normalized) {
            if range.contains(v) {
                // Convert to metric if necessary before writing to binding
                if unitSystem == "imperial" {
                    let cm = v * 2.54
                    value = cm
                } else {
                    value = v
                }
                errorText = nil
            } else {
                errorText = "\(Int(range.lowerBound)) - \(Int(range.upperBound)) \(unit)"
            }
        } else {
            errorText = "validation.invalid_value".localized
        }
    }
}

// MARK: - Preview
#Preview {
    MeasurementsStepView(data: .constant(OnboardingData())) {
        print("Next tapped")
    }
}
