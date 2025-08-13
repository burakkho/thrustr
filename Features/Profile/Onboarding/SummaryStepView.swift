//
//  SummaryStepView.swift
//  SporHocam
//
//  Summary Step - Localized & Fixed
//

import SwiftUI
import SwiftData
// MARK: - Summary Step
struct SummaryStepView: View {
    let data: OnboardingData
    let onComplete: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var unitSettings: UnitSettings
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text(LocalizationKeys.Onboarding.Summary.title.localized)
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                Text(LocalizationKeys.Onboarding.Summary.subtitle.localized)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top)
            
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(LocalizationKeys.Onboarding.Summary.profile.localized)
                                .font(.headline)
                            Spacer()
                            Image(systemName: "person.crop.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title2)
                        }
                        VStack(spacing: 8) {
                            SummaryRow(
                                label: LocalizationKeys.Onboarding.Summary.Label.name.localized,
                                value: data.name
                            )
                            SummaryRow(
                                label: LocalizationKeys.Onboarding.Summary.Label.age.localized,
                                value: "\(data.age) yaş"
                            )
                            SummaryRow(
                                label: LocalizationKeys.Onboarding.Summary.Label.gender.localized,
                                value: data.gender == "male" ? LocalizationKeys.Onboarding.PersonalInfo.genderMale.localized : LocalizationKeys.Onboarding.PersonalInfo.genderFemale.localized
                            )
                            SummaryRow(
                                label: LocalizationKeys.Onboarding.Summary.Label.height.localized,
                                value: UnitsFormatter.formatHeight(cm: data.height, system: unitSettings.unitSystem)
                            )
                            SummaryRow(
                                label: LocalizationKeys.Onboarding.Summary.Label.weight.localized,
                                value: UnitsFormatter.formatWeight(kg: data.weight, system: unitSettings.unitSystem)
                            )
                            if let targetWeight = data.targetWeight {
                                SummaryRow(
                                    label: LocalizationKeys.Onboarding.Summary.Label.targetWeight.localized,
                                    value: UnitsFormatter.formatWeight(kg: targetWeight, system: unitSettings.unitSystem)
                                )
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(LocalizationKeys.Onboarding.Summary.goals.localized)
                                .font(.headline)
                            Spacer()
                            Image(systemName: "target")
                                .foregroundColor(.green)
                                .font(.title2)
                        }
                        VStack(spacing: 8) {
                            SummaryRow(
                                label: LocalizationKeys.Onboarding.Summary.Label.mainGoal.localized,
                                value: goalDisplayName(data.fitnessGoal)
                            )
                            SummaryRow(
                                label: LocalizationKeys.Onboarding.Summary.Label.activity.localized,
                                value: activityDisplayName(data.activityLevel)
                            )
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(LocalizationKeys.Onboarding.Summary.calculatedValues.localized)
                                .font(.headline)
                            Spacer()
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundColor(.orange)
                                .font(.title2)
                        }
                        VStack(spacing: 8) {
                            let bmr = calculateBMR()
                            let usesNavy = canCalculateNavyMethod()
                            
                            SummaryRow(
                                label: usesNavy ? LocalizationKeys.Onboarding.Summary.Label.bmrKatch.localized : LocalizationKeys.Onboarding.Summary.Label.bmrMifflin.localized,
                                value: "\(Int(bmr)) kcal"
                            )
                            
                            if usesNavy {
                                let bf = calculateNavyMethod()
                                let lbm = data.weight * (1 - bf / 100.0)
                                SummaryRow(
                                    label: LocalizationKeys.Onboarding.Summary.Label.lbm.localized,
                                    value: "\(String(format: "%.1f", lbm)) kg"
                                )
                                SummaryRow(
                                    label: LocalizationKeys.Onboarding.Summary.Label.bodyFat.localized,
                                    value: "%\(String(format: "%.1f", bf))"
                                )
                            }
                            
                            SummaryRow(
                                label: LocalizationKeys.Onboarding.Summary.Label.tdee.localized,
                                value: "\(Int(calculateTDEE())) kcal"
                            )
                            SummaryRow(
                                label: LocalizationKeys.Onboarding.Summary.Label.dailyCalorie.localized,
                                value: "\(Int(calculateCalorieGoal())) kcal"
                            )
                        }
                        
                        Divider()
                        
                        Text(LocalizationKeys.Onboarding.Summary.macroGoals.localized)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        let macros = calculateMacros()
                        VStack(spacing: 8) {
                            SummaryRow(
                                label: LocalizationKeys.Onboarding.Summary.Label.protein.localized,
                                value: "\(Int(macros.protein))g"
                            )
                            SummaryRow(
                                label: LocalizationKeys.Onboarding.Summary.Label.carbs.localized,
                                value: "\(Int(macros.carbs))g"
                            )
                            SummaryRow(
                                label: LocalizationKeys.Onboarding.Summary.Label.fat.localized,
                                value: "\(Int(macros.fat))g"
                            )
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text(LocalizationKeys.Onboarding.Summary.Info.title.localized)
                                .font(.headline)
                            Spacer()
                        }
                        Text(canCalculateNavyMethod() ?
                             LocalizationKeys.Onboarding.Summary.Info.withNavy.localized :
                             LocalizationKeys.Onboarding.Summary.Info.withoutNavy.localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            
            PrimaryButton(title: LocalizationKeys.Onboarding.Summary.startApp.localized, icon: "arrow.right") {
                onComplete()
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
    
    // MARK: - Calculations
    private func calculateBMR() -> Double {
        let gender = Gender(rawValue: data.gender) ?? .male
        let bodyFat = canCalculateNavyMethod() ? calculateNavyMethod() : nil
        return HealthCalculator.calculateBMR(
            gender: gender,
            age: data.age,
            heightCm: data.height,
            weightKg: data.weight,
            bodyFatPercentage: bodyFat
        )
    }
    
    private func calculateTDEE() -> Double {
        let bmr = calculateBMR()
        let activity = ActivityLevel(rawValue: data.activityLevel) ?? .moderate
        return HealthCalculator.calculateTDEE(bmr: bmr, activityLevel: activity)
    }
    
    private func calculateCalorieGoal() -> Double {
        let t = calculateTDEE()
        let goal = FitnessGoal(rawValue: data.fitnessGoal) ?? .maintain
        return HealthCalculator.calculateDailyCalories(tdee: t, goal: goal)
    }
    
    private func calculateMacros() -> (protein: Double, carbs: Double, fat: Double) {
        let cals = calculateCalorieGoal()
        let goal = FitnessGoal(rawValue: data.fitnessGoal) ?? .maintain
        return HealthCalculator.calculateMacros(weightKg: data.weight, dailyCalories: cals, goal: goal)
    }
    
    private func canCalculateNavyMethod() -> Bool {
        if data.gender == "male" {
            return data.neckCircumference != nil && data.waistCircumference != nil
        } else {
            return data.neckCircumference != nil && data.waistCircumference != nil && data.hipCircumference != nil
        }
    }
    
    private func calculateNavyMethod() -> Double {
        let gender = Gender(rawValue: data.gender) ?? .male
        let bf = HealthCalculator.calculateBodyFatNavy(
            gender: gender,
            heightCm: data.height,
            neckCm: data.neckCircumference,
            waistCm: data.waistCircumference,
            hipCm: data.hipCircumference
        )
        return bf ?? 0
    }
    
    private func goalDisplayName(_ g: String) -> String {
        switch g {
        case "cut": return LocalizationKeys.Onboarding.Goals.Cut.title.localized
        case "bulk": return LocalizationKeys.Onboarding.Goals.Bulk.title.localized
        case "maintain": return LocalizationKeys.Onboarding.Goals.Maintain.title.localized
        default: return "Unknown"
        }
    }
    
    private func activityDisplayName(_ a: String) -> String {
        switch a {
        case "sedentary": return LocalizationKeys.Onboarding.Activity.sedentary.localized
        case "light": return LocalizationKeys.Onboarding.Activity.light.localized
        case "moderate": return LocalizationKeys.Onboarding.Activity.moderate.localized
        case "active": return LocalizationKeys.Onboarding.Activity.active.localized
        case "very_active": return LocalizationKeys.Onboarding.Activity.veryActive.localized
        default: return "Unknown"
        }
    }
}

// MARK: - Summary Row Component
struct SummaryRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
}

// MARK: - Preview
#Preview {
    SummaryStepView(data: OnboardingData()) {
        print("Complete tapped")
    }
}
