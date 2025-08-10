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
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text(LocalizationKeys.Onboarding.measurementsTitle.localized)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text(LocalizationKeys.Onboarding.measurementsSubtitle.localized)
                    .font(.subheadline)
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
                            range: 25...50,
                            unit: "cm",
                            placeholder: LocalizationKeys.Onboarding.optional.localized
                        )
                        
                        MeasurementInput(
                            title: data.gender == "male" ?
                                LocalizationKeys.Onboarding.waistMaleLabel.localized :
                                LocalizationKeys.Onboarding.waistFemaleLabel.localized,
                            value: $data.waistCircumference,
                            range: 50...150,
                            unit: "cm",
                            placeholder: LocalizationKeys.Onboarding.optional.localized
                        )
                        
                        if data.gender == "female" {
                            MeasurementInput(
                                title: LocalizationKeys.Onboarding.hipLabel.localized,
                                value: $data.hipCircumference,
                                range: 70...150,
                                unit: "cm",
                                placeholder: LocalizationKeys.Onboarding.optional.localized
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
                Button(action: onNext) {
                    Text(LocalizationKeys.Onboarding.continueButton.localized)
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
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
    
    @State private var textValue: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            HStack {
                TextField(placeholder, text: $textValue)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: textValue) { _, newValue in
                        if let v = Double(newValue), range.contains(v) {
                            value = v
                        } else if newValue.isEmpty {
                            value = nil
                        }
                    }
                    .onAppear {
                        if let v = value {
                            textValue = String(format: "%.0f", v)
                        }
                    }
                Text(unit)
                    .foregroundColor(.secondary)
                    .padding(.trailing, 8)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    MeasurementsStepView(data: .constant(OnboardingData())) {
        print("Next tapped")
    }
}
