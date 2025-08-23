//
//  GoalsStepView.swift
//  Thrustr
//
//  Goals Selection Step - Localized & Fixed
//

import SwiftUI
import SwiftData
// MARK: - Goals Step
struct GoalsStepView: View {
    @Binding var data: OnboardingData
    let onNext: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text(LocalizationKeys.Onboarding.Goals.title.localized)
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                Text(LocalizationKeys.Onboarding.Goals.subtitle.localized)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top)
            
            ScrollView {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(LocalizationKeys.Onboarding.Goals.mainGoal.localized)
                            .font(.headline)
                        VStack(spacing: 8) {
                            GoalOptionButton(
                                title: LocalizationKeys.Onboarding.Goals.Cut.title.localized,
                                subtitle: LocalizationKeys.Onboarding.Goals.Cut.subtitle.localized,
                                icon: "flame.fill",
                                color: .red,
                                isSelected: data.fitnessGoal == "cut"
                            ) {
                                data.fitnessGoal = "cut"
                            }
                            GoalOptionButton(
                                title: LocalizationKeys.Onboarding.Goals.Bulk.title.localized,
                                subtitle: LocalizationKeys.Onboarding.Goals.Bulk.subtitle.localized,
                                icon: "dumbbell.fill",
                                color: .blue,
                                isSelected: data.fitnessGoal == "bulk"
                            ) {
                                data.fitnessGoal = "bulk"
                            }
                            GoalOptionButton(
                                title: LocalizationKeys.Onboarding.Goals.Maintain.title.localized,
                                subtitle: LocalizationKeys.Onboarding.Goals.Maintain.subtitle.localized,
                                icon: "target",
                                color: .green,
                                isSelected: data.fitnessGoal == "maintain"
                            ) {
                                data.fitnessGoal = "maintain"
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text(LocalizationKeys.Onboarding.Goals.activityLevel.localized)
                            .font(.headline)
                        VStack(spacing: 8) {
                            ActivityLevelButton(
                                title: LocalizationKeys.Onboarding.Activity.sedentary.localized,
                                subtitle: LocalizationKeys.Onboarding.Activity.sedentaryDesc.localized,
                                isSelected: data.activityLevel == "sedentary"
                            ) {
                                data.activityLevel = "sedentary"
                            }
                            ActivityLevelButton(
                                title: LocalizationKeys.Onboarding.Activity.light.localized,
                                subtitle: LocalizationKeys.Onboarding.Activity.lightDesc.localized,
                                isSelected: data.activityLevel == "light"
                            ) {
                                data.activityLevel = "light"
                            }
                            ActivityLevelButton(
                                title: LocalizationKeys.Onboarding.Activity.moderate.localized,
                                subtitle: LocalizationKeys.Onboarding.Activity.moderateDesc.localized,
                                isSelected: data.activityLevel == "moderate"
                            ) {
                                data.activityLevel = "moderate"
                            }
                            ActivityLevelButton(
                                title: LocalizationKeys.Onboarding.Activity.active.localized,
                                subtitle: LocalizationKeys.Onboarding.Activity.activeDesc.localized,
                                isSelected: data.activityLevel == "active"
                            ) {
                                data.activityLevel = "active"
                            }
                            ActivityLevelButton(
                                title: LocalizationKeys.Onboarding.Activity.veryActive.localized,
                                subtitle: LocalizationKeys.Onboarding.Activity.veryActiveDesc.localized,
                                isSelected: data.activityLevel == "very_active"
                            ) {
                                data.activityLevel = "very_active"
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text(LocalizationKeys.Onboarding.Goals.targetWeight.localized)
                            .font(.headline)
                        VStack(spacing: 8) {
                            Toggle(LocalizationKeys.Onboarding.Goals.targetWeightToggle.localized, isOn: Binding(
                                get: { data.targetWeight != nil },
                                set: { isOn in data.targetWeight = isOn ? data.weight : nil }
                            ))
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            
                            if data.targetWeight != nil {
                                Group {
                                    if data.unitSystem == "imperial" {
                                        // Imperial: value in lb (internally stored as kg)
                                        let lbsBinding = Binding<Double>(
                                            get: { UnitsConverter.kgToLbs(data.targetWeight ?? data.weight) },
                                            set: { data.targetWeight = UnitsConverter.lbsToKg($0) }
                                        )
                                        HStack {
                                            Text("\(Int(lbsBinding.wrappedValue)) lb")
                                                .font(.title2)
                                                .fontWeight(.semibold)
                                                .frame(width: 80, alignment: .leading)
                                            Slider(value: lbsBinding, in: 90...330, step: 1)
                                        }
                                        .padding()
                                        .background(Color(.systemGray6))
                                        .cornerRadius(12)
                                    } else {
                                        // Metric: value in kg
                                        HStack {
                                            Text("\(Int(data.targetWeight ?? data.weight)) kg")
                                                .font(.title2)
                                                .fontWeight(.semibold)
                                                .frame(width: 80, alignment: .leading)
                                            Slider(value: Binding(
                                                get: { data.targetWeight ?? data.weight },
                                                set: { data.targetWeight = $0 }
                                            ), in: 40...150, step: 0.5)
                                        }
                                        .padding()
                                        .background(Color(.systemGray6))
                                        .cornerRadius(12)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            PrimaryButton(title: LocalizationKeys.Onboarding.continueAction.localized, icon: "arrow.right") {
                onNext()
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
}

// MARK: - Goal Option Button Component
struct GoalOptionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? color : .secondary)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(color)
                        .font(.title2)
                }
            }
            .padding()
            .background(isSelected ? color.opacity(0.1) : Color(.systemGray6))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? color : .clear, lineWidth: 2)
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(title))
        .accessibilityHint(Text(subtitle))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Activity Level Button Component
struct ActivityLevelButton: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Circle()
                    .fill(isSelected ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 12, height: 12)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? .blue : .clear, lineWidth: 2)
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(title))
        .accessibilityHint(Text(subtitle))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Preview
#Preview {
    GoalsStepView(data: .constant(OnboardingData())) {
        print("Next tapped")
    }
}
