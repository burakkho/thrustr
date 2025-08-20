//
//  PersonalInfoStepView.swift
//  SporHocam
//
//  Personal Information Step - Localized & Fixed
//

import SwiftUI
import SwiftData
// MARK: - Personal Info Step
struct PersonalInfoStepView: View {
    @Binding var data: OnboardingData
    let onNext: () -> Void
    @FocusState private var focusedField: Field?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("preferredUnitSystem") private var preferredUnitSystem: String = "metric" // persists globally
    @EnvironmentObject private var unitSettings: UnitSettings
		@State private var nameDebounceWork: DispatchWorkItem? = nil
    
    // Service-based validation
    @State private var validationErrors: [UserService.ValidationError] = []
    private let userService = UserService()
    
    private enum Field { case name }
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text(LocalizationKeys.Onboarding.PersonalInfo.title.localized)
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                Text(LocalizationKeys.Onboarding.PersonalInfo.subtitle.localized)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
            }
            .padding(.top)
            
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizationKeys.Onboarding.PersonalInfo.name.localized)
                            .font(.headline)
                        TextField(LocalizationKeys.Onboarding.PersonalInfo.namePlaceholder.localized, text: $data.name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textInputAutocapitalization(.words)
                            .textContentType(.name)
                            .disableAutocorrection(true)
                            .focused($focusedField, equals: .name)
                            .submitLabel(.next)
                            .accessibilityLabel(Text(LocalizationKeys.Onboarding.PersonalInfo.name.localized))
                            .accessibilityHint(Text("İsminizi girin"))
                            .onChange(of: data.name) { _, _ in
                                // Debounce validation to avoid stutter while typing
                                nameDebounceWork?.cancel()
                                let task = DispatchWorkItem { validateAndUpdateErrors() }
                                nameDebounceWork = task
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: task)
                            }
                        if let nameError = nameError {
                            Text(nameError)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizationKeys.Onboarding.PersonalInfo.age.localized)
                            .font(.headline)
                        Stepper(value: $data.age, in: 15...80) {
                            Text(String(format: LocalizationKeys.Onboarding.PersonalInfo.ageYears.localized, data.age))
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .accessibilityLabel(Text(LocalizationKeys.Onboarding.PersonalInfo.age.localized))
                        .accessibilityValue(Text("\(data.age)"))
                        .onChange(of: data.age) { _, _ in validateAndUpdateErrors() }
                        if let ageError = ageError {
                            Text(ageError)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }

                    // Unit System Selection (after Age, before Gender)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("onboarding.unit_system".localized)
                            .font(.headline)
                        Picker("onboarding.unit_system".localized, selection: Binding(
                            get: { data.unitSystem },
                            set: { newValue in
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    handleUnitSystemChange(newValue)
                                }
                            }
                        )) {
                            Text("units.metric".localized).tag("metric")
                            Text("units.imperial".localized).tag("imperial")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        Text(data.unitSystem == "metric" ? "units.metric_format".localized : "units.imperial_format".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .onAppear {
                        // Sync from global preference on first appear
                        let global = unitSettings.unitSystem.rawValue
                        if data.unitSystem != global { data.unitSystem = global }
                        syncImperialStatesFromMetric()
                    }
                    .onChange(of: preferredUnitSystem) { _, newValue in
                        if data.unitSystem != newValue {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                handleUnitSystemChange(newValue)
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizationKeys.Onboarding.PersonalInfo.gender.localized)
                            .font(.headline)
                        HStack(spacing: 12) {
                            GenderButton(
                                title: LocalizationKeys.Onboarding.PersonalInfo.genderMale.localized,
                                icon: "figure.stand",
                                isSelected: data.gender == "male"
                            ) {
                                data.gender = "male"
                            }
                            GenderButton(
                                title: LocalizationKeys.Onboarding.PersonalInfo.genderFemale.localized,
                                icon: "figure.stand.dress",
                                isSelected: data.gender == "female"
                            ) {
                                data.gender = "female"
                            }
                        }
                        .accessibilityElement(children: .contain)
                    }
                    
                    // Height Input - Metric or Imperial
                    Group {
                        if data.unitSystem == "metric" {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(LocalizationKeys.Onboarding.PersonalInfo.height.localized)
                                    .font(.headline)
                                HStack {
                                    Text("\(Int(data.height)) cm")
                                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                                        .frame(width: 80, alignment: .leading)
                                    Slider(value: $data.height, in: 140...220, step: 1)
                                        .accessibilityLabel(Text(LocalizationKeys.Onboarding.PersonalInfo.height.localized))
                                        .accessibilityValue(Text("\(Int(data.height)) cm"))
                                        .onChange(of: data.height) { _, _ in validateAndUpdateErrors() }
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                if let heightError = heightError {
                                    Text(heightError)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                            .transition(.opacity)
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(LocalizationKeys.Onboarding.PersonalInfo.height.localized)
                                    .font(.headline)
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("units.feet".localized)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Stepper(value: $heightFeet, in: 4...7) {
                                            Text("\(heightFeet) ft")
                                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                        }
                                        .onChange(of: heightFeet) { _, _ in updateMetricHeightFromImperial() }
                                    }
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("units.inches".localized)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Stepper(value: $heightInches, in: 0...11) {
                                            Text("\(heightInches) in")
                                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                        }
                                        .onChange(of: heightInches) { _, _ in updateMetricHeightFromImperial() }
                                    }
                                    Spacer()
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                Text("\(Int(data.height)) cm")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .transition(.opacity)
                        }
                    }
                    
                    // Weight Input - Metric or Imperial
                    Group {
                        if data.unitSystem == "metric" {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(LocalizationKeys.Onboarding.PersonalInfo.weight.localized)
                                    .font(.headline)
                                HStack {
                                    Text("\(Int(data.weight)) kg")
                                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                                        .frame(width: 80, alignment: .leading)
                                    Slider(value: $data.weight, in: 40...150, step: 0.5)
                                        .accessibilityLabel(Text(LocalizationKeys.Onboarding.PersonalInfo.weight.localized))
                                        .accessibilityValue(Text("\(Int(data.weight)) kg"))
                                        .onChange(of: data.weight) { _, _ in validateAndUpdateErrors() }
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                if let weightError = weightError {
                                    Text(weightError)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                            .transition(.opacity)
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(LocalizationKeys.Onboarding.PersonalInfo.weight.localized)
                                    .font(.headline)
                                HStack {
                                    TextField("units.lbs".localized, text: $weightLbsText)
                                        .keyboardType(.decimalPad)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .onChange(of: weightLbsText) { _, newValue in
                                            updateMetricWeightFromLbsText(newValue)
                                        }
                                    Text("units.lbs".localized)
                                        .foregroundColor(.secondary)
                                }
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                Text("\(String(format: "%.1f", data.weight)) kg")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .transition(.opacity)
                        }
                    }
                }
				.padding(.horizontal)
            }
			.scrollDismissesKeyboard(.immediately) // ✅ Daha güvenli keyboard handling
            
            PrimaryButton(title: LocalizationKeys.Onboarding.continueAction.localized, icon: "arrow.right", isEnabled: isFormValid) {
                validateAndUpdateErrors()
                if validationErrors.isEmpty { onNext() }
            }
            .disabled(!isFormValid)
            .padding(.horizontal)
            .padding(.bottom)
        }
			.onSubmit {
				if focusedField == .name {
					focusedField = nil
					validateAndUpdateErrors()
				}
			}
        .onAppear { validateAndUpdateErrors() }
        .onTapGesture {
            // ✅ Klavyeyi kapatmak için tap gesture
            focusedField = nil
        }
        .ignoresSafeArea(.keyboard, edges: .bottom) // ✅ Keyboard safe area'yı ignore et
    }

    // MARK: - Validation Helpers
    private var nameError: String? {
        validationErrors.compactMap { error in
            if case let .invalidName(message) = error { return message }
            return nil
        }.first
    }
    
    private var ageError: String? {
        validationErrors.compactMap { error in
            if case let .invalidAge(message) = error { return message }
            return nil
        }.first
    }
    
    private var heightError: String? {
        validationErrors.compactMap { error in
            if case let .invalidHeight(message) = error { return message }
            return nil
        }.first
    }
    
    private var weightError: String? {
        validationErrors.compactMap { error in
            if case let .invalidWeight(message) = error { return message }
            return nil
        }.first
    }
    
    private var isFormValid: Bool {
        validationErrors.isEmpty
    }
    
    private func validateAndUpdateErrors() {
        // Call centralized rules; collect errors from service
        do {
            try userService.validateUserInput(
                name: data.name,
                age: data.age,
                height: data.height,
                weight: data.weight
            )
            validationErrors = []
        } catch {
            validationErrors = userService.validationErrors
        }
    }

    // MARK: - Unit Handling & Conversions
    @State private var heightFeet: Int = 5
    @State private var heightInches: Int = 9
    @State private var weightLbsText: String = ""

    private func handleUnitSystemChange(_ newValue: String) {
        data.unitSystem = newValue
        preferredUnitSystem = newValue // persist globally
        unitSettings.unitSystem = UnitSystem(rawValue: newValue) ?? .metric
        if newValue == "imperial" {
            // derive imperial states from current metric values
            syncImperialStatesFromMetric()
        } else {
            // when switching back to metric, ensure metric stays authoritative
            // convert from current imperial inputs to metric and write
            updateMetricHeightFromImperial()
            updateMetricWeightFromLbsText(weightLbsText)
        }
    }

    private func syncImperialStatesFromMetric() {
        let (ft, inch) = cmToFeetInches(data.height)
        heightFeet = ft
        heightInches = inch
        let lbs = kgToLbs(data.weight)
        weightLbsText = String(format: "%.0f", lbs)
    }

    private func updateMetricHeightFromImperial() {
        let cm = feetInchesToCm(feet: heightFeet, inches: heightInches)
        data.height = min(max(cm, 140), 220) // keep within former slider bounds
        validateAndUpdateErrors()
    }

    private func updateMetricWeightFromLbsText(_ raw: String) {
        let normalized = raw.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces)
        if let lbs = Double(normalized) {
            let kg = lbsToKg(lbs)
            data.weight = min(max(kg, 40), 150) // keep within former slider bounds
        }
        validateAndUpdateErrors()
    }

    private func cmToFeetInches(_ cm: Double) -> (Int, Int) {
        let totalInches = cm / 2.54
        let feet = Int(totalInches / 12.0)
        let inches = Int((totalInches - Double(feet) * 12.0).rounded())
        return (feet, min(max(inches, 0), 11))
    }

    private func feetInchesToCm(feet: Int, inches: Int) -> Double {
        let totalInches = Double(feet) * 12.0 + Double(inches)
        return totalInches * 2.54
    }

    private func kgToLbs(_ kg: Double) -> Double { kg * 2.20462262 }
    private func lbsToKg(_ lbs: Double) -> Double { lbs * 0.45359237 }
}

// MARK: - Gender Button Component
struct GenderButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title)
                Text(title)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Color.blue.opacity(0.2) : Color(.systemGray6))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : .clear, lineWidth: 2)
            )
            .cornerRadius(12)
        }
        .foregroundColor(isSelected ? .blue : .primary)
        .accessibilityLabel(Text(title))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Preview
#Preview {
    PersonalInfoStepView(data: .constant(OnboardingData())) {
        print("Next tapped")
    }
}
