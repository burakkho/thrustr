//
//  SummaryStepView.swift
//  Thrustr
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
    @Environment(UnitSettings.self) var unitSettings
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text(CommonKeys.Onboarding.summaryTitle.localized)
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                Text(CommonKeys.Onboarding.summarySubtitle.localized)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top)
            
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(CommonKeys.Onboarding.profileSummary.localized)
                                .font(.headline)
                            Spacer()
                            Image(systemName: "person.crop.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title2)
                        }
                        VStack(spacing: 8) {
                            SummaryRow(
                                label: CommonKeys.Onboarding.labelName.localized,
                                value: data.name
                            )
                            SummaryRow(
                                label: CommonKeys.Onboarding.labelAge.localized,
                                value: String(format: CommonKeys.Onboarding.ageFormat.localized, data.age)
                            )
                            SummaryRow(
                                label: CommonKeys.Onboarding.labelGender.localized,
                                value: data.gender == "male" ? CommonKeys.Onboarding.genderMale.localized : CommonKeys.Onboarding.genderFemale.localized
                            )
                            SummaryRow(
                                label: CommonKeys.Onboarding.labelHeight.localized,
                                value: UnitsFormatter.formatHeight(cm: data.height, system: unitSettings.unitSystem)
                            )
                            SummaryRow(
                                label: CommonKeys.Onboarding.labelWeight.localized,
                                value: UnitsFormatter.formatWeight(kg: data.weight, system: unitSettings.unitSystem)
                            )
                            if let targetWeight = data.targetWeight {
                                SummaryRow(
                                    label: CommonKeys.Onboarding.labelTargetWeight.localized,
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
                            Text(CommonKeys.Onboarding.goals.localized)
                                .font(.headline)
                            Spacer()
                            Image(systemName: "target")
                                .foregroundColor(.green)
                                .font(.title2)
                        }
                        VStack(spacing: 8) {
                            SummaryRow(
                                label: CommonKeys.Onboarding.labelMainGoal.localized,
                                value: goalDisplayName(data.fitnessGoal)
                            )
                            SummaryRow(
                                label: CommonKeys.Onboarding.labelActivity.localized,
                                value: activityDisplayName(data.activityLevel)
                            )
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(CommonKeys.Onboarding.calculatedValues.localized)
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
                                label: usesNavy ? CommonKeys.Onboarding.labelBMRKatch.localized : CommonKeys.Onboarding.labelBMRMifflin.localized,
                                value: "\(Int(bmr)) kcal"
                            )
                            
                            if usesNavy {
                                let bf = calculateNavyMethod()
                                let lbm = data.weight * (1 - bf / 100.0)
                                SummaryRow(
                                    label: CommonKeys.Onboarding.labelLBM.localized,
                                    value: UnitsFormatter.formatWeight(kg: lbm, system: unitSettings.unitSystem)
                                )
                                SummaryRow(
                                    label: CommonKeys.Onboarding.labelBodyFat.localized,
                                    value: "%\(String(format: "%.1f", bf))"
                                )
                            }
                            
                            SummaryRow(
                                label: CommonKeys.Onboarding.labelTDEE.localized,
                                value: "\(Int(calculateTDEE())) kcal"
                            )
                            SummaryRow(
                                label: CommonKeys.Onboarding.labelDailyCalorie.localized,
                                value: "\(Int(calculateCalorieGoal())) kcal"
                            )
                        }
                        
                        Divider()
                        
                        Text(CommonKeys.Onboarding.macroGoals.localized)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        let macros = calculateMacros()
                        VStack(spacing: 8) {
                            SummaryRow(
                                label: CommonKeys.Onboarding.labelProtein.localized,
                                value: "\(Int(macros.protein))g"
                            )
                            SummaryRow(
                                label: CommonKeys.Onboarding.labelCarbs.localized,
                                value: "\(Int(macros.carbs))g"
                            )
                            SummaryRow(
                                label: CommonKeys.Onboarding.labelFat.localized,
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
                            Text(CommonKeys.Onboarding.infoTitle.localized)
                                .font(.headline)
                            Spacer()
                        }
                        Text(canCalculateNavyMethod() ?
                             CommonKeys.Onboarding.infoWithNavy.localized :
                             CommonKeys.Onboarding.infoWithoutNavy.localized)
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
            
            PrimaryButton(title: CommonKeys.Onboarding.startApp.localized, icon: "arrow.right") {
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
        case "cut": return CommonKeys.Onboarding.goalCutTitle.localized
        case "bulk": return CommonKeys.Onboarding.goalBulkTitle.localized
        case "maintain": return CommonKeys.Onboarding.goalMaintainTitle.localized
        default: return "common.unknown".localized
        }
    }
    
    private func activityDisplayName(_ a: String) -> String {
        switch a {
        case "sedentary": return CommonKeys.Onboarding.activitySedentary.localized
        case "light": return CommonKeys.Onboarding.activityLight.localized
        case "moderate": return CommonKeys.Onboarding.activityModerate.localized
        case "active": return CommonKeys.Onboarding.activityActive.localized
        case "very_active": return CommonKeys.Onboarding.activityVeryActive.localized
        default: return "common.unknown".localized
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
