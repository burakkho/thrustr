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
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text(LocalizationKeys.Onboarding.Summary.title.localized)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text(LocalizationKeys.Onboarding.Summary.subtitle.localized)
                    .font(.subheadline)
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
                                value: "\(Int(data.height)) cm"
                            )
                            SummaryRow(
                                label: LocalizationKeys.Onboarding.Summary.Label.weight.localized,
                                value: "\(Int(data.weight)) kg"
                            )
                            if let targetWeight = data.targetWeight {
                                SummaryRow(
                                    label: LocalizationKeys.Onboarding.Summary.Label.targetWeight.localized,
                                    value: "\(Int(targetWeight)) kg"
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
            
            GradientButton(title: LocalizationKeys.Onboarding.Summary.startApp.localized, icon: "arrow.right") {
                onComplete()
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
    
    // MARK: - Calculations
    private func calculateBMR() -> Double {
        if canCalculateNavyMethod() {
            let bf = calculateNavyMethod() / 100.0
            let lbm = data.weight * (1 - bf)
            return 370 + 21.6 * lbm
        } else {
            let w = 10 * data.weight
            let h = 6.25 * data.height
            let a = 5 * Double(data.age)
            return data.gender == "male" ? (w + h - a + 5) : (w + h - a - 161)
        }
    }
    
    private func calculateTDEE() -> Double {
        let bmr = calculateBMR()
        switch data.activityLevel {
        case "sedentary": return bmr * 1.2
        case "light": return bmr * 1.375
        case "moderate": return bmr * 1.55
        case "active": return bmr * 1.725
        case "very_active": return bmr * 1.9
        default: return bmr * 1.55
        }
    }
    
    private func calculateCalorieGoal() -> Double {
        let t = calculateTDEE()
        switch data.fitnessGoal {
        case "cut": return t * 0.8
        case "bulk": return t * 1.1
        case "maintain": return t
        default: return t
        }
    }
    
    private func calculateMacros() -> (protein: Double, carbs: Double, fat: Double) {
        let cals = calculateCalorieGoal()
        let protein = data.weight * 2.0
        let fat = (cals * 0.25) / 9
        let carbs = (cals - protein * 4 - fat * 9) / 4
        return (protein, carbs, fat)
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
        let h = data.height
        if data.gender == "male" {
            let d = 1.0324 - 0.19077 * log10(waist - neck) + 0.15456 * log10(h)
            return max(0, min(50, 495 / d - 450))
        } else {
            guard let hip = data.hipCircumference else { return 0 }
            let d = 1.29579 - 0.35004 * log10(waist + hip - neck) + 0.22100 * log10(h)
            return max(0, min(50, 495 / d - 450))
        }
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
