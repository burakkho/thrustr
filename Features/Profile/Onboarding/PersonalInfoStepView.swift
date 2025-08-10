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
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text(LocalizationKeys.Onboarding.PersonalInfo.title.localized)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text(LocalizationKeys.Onboarding.PersonalInfo.subtitle.localized)
                    .font(.subheadline)
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
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizationKeys.Onboarding.PersonalInfo.age.localized)
                            .font(.headline)
                        Stepper(value: $data.age, in: 15...80) {
                            Text(String(format: LocalizationKeys.Onboarding.PersonalInfo.ageYears.localized, data.age))
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
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
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizationKeys.Onboarding.PersonalInfo.height.localized)
                            .font(.headline)
                        HStack {
                            Text("\(Int(data.height)) cm")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .frame(width: 80, alignment: .leading)
                            Slider(value: $data.height, in: 140...220, step: 1)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizationKeys.Onboarding.PersonalInfo.weight.localized)
                            .font(.headline)
                        HStack {
                            Text("\(Int(data.weight)) kg")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .frame(width: 80, alignment: .leading)
                            Slider(value: $data.weight, in: 40...150, step: 0.5)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
            }
            
            Button(action: { if !data.name.isEmpty { onNext() } }) {
                Text(LocalizationKeys.Onboarding.continueAction.localized)
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(data.name.isEmpty ? Color.gray : Color.blue)
                    .cornerRadius(12)
            }
            .disabled(data.name.isEmpty)
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
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
    }
}

// MARK: - Preview
#Preview {
    PersonalInfoStepView(data: .constant(OnboardingData())) {
        print("Next tapped")
    }
}
