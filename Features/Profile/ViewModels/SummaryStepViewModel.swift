import SwiftUI
import SwiftData
import Foundation

/**
 * ViewModel for SummaryStepView with clean separation of concerns.
 *
 * Manages health calculations, display formatting, and coordinates with HealthCalculator service.
 * Follows modern @Observable pattern for iOS 17+ with automatic UI updates.
 */
@MainActor
@Observable
class SummaryStepViewModel {

    // MARK: - Calculated State
    var calculatedBMR: Double = 0
    var calculatedTDEE: Double = 0
    var calculatedCalorieGoal: Double = 0
    var calculatedMacros: MacroBreakdown = MacroBreakdown()
    var calculatedBodyFat: Double?
    var calculatedLeanBodyMass: Double?
    
    // MARK: - Dependencies
    private let unitSettings: UnitSettings
    
    // MARK: - Private Properties
    private var onboardingData: OnboardingData?
    
    // MARK: - Computed Properties
    
    /**
     * Whether Navy Method can be calculated with current data.
     */
    var canCalculateNavyMethod: Bool {
        guard let data = onboardingData else { return false }
        
        if data.gender == "male" {
            return data.neckCircumference != nil && data.waistCircumference != nil
        } else {
            return data.neckCircumference != nil && 
                   data.waistCircumference != nil && 
                   data.hipCircumference != nil
        }
    }
    
    /**
     * Formatted BMR display text.
     */
    var formattedBMR: String {
        return "\(Int(calculatedBMR)) kcal"
    }
    
    /**
     * Formatted TDEE display text.
     */
    var formattedTDEE: String {
        return "\(Int(calculatedTDEE)) kcal"
    }
    
    /**
     * Formatted calorie goal display text.
     */
    var formattedCalorieGoal: String {
        return "\(Int(calculatedCalorieGoal)) kcal"
    }
    
    /**
     * Formatted body fat percentage if available.
     */
    var formattedBodyFat: String? {
        guard let bodyFat = calculatedBodyFat else { return nil }
        return "%\(String(format: "%.1f", bodyFat))"
    }
    
    /**
     * Formatted lean body mass if available.
     */
    var formattedLeanBodyMass: String? {
        guard let lbm = calculatedLeanBodyMass,
              onboardingData != nil else { return nil }
        return UnitsFormatter.formatWeight(kg: lbm, system: unitSettings.unitSystem)
    }
    
    /**
     * BMR method description based on whether Navy Method is used.
     */
    var bmrMethodDescription: String {
        return canCalculateNavyMethod ? 
            CommonKeys.Onboarding.labelBMRKatch.localized : 
            CommonKeys.Onboarding.labelBMRMifflin.localized
    }
    
    // MARK: - Initialization
    
    init(unitSettings: UnitSettings = UnitSettings.shared) {
        self.unitSettings = unitSettings
    }
    
    // MARK: - Public Methods
    
    /**
     * Sets the onboarding data and triggers calculations.
     */
    func setOnboardingData(_ data: OnboardingData) {
        self.onboardingData = data
        calculateAllMetrics()
    }
    
    /**
     * Recalculates all health metrics.
     */
    func calculateAllMetrics() {
        guard onboardingData != nil else { return }
        
        calculatedBMR = calculateBMR()
        calculatedTDEE = calculateTDEE()
        calculatedCalorieGoal = calculateCalorieGoal()
        calculatedMacros = calculateMacros()
        
        if canCalculateNavyMethod {
            calculatedBodyFat = calculateNavyMethodBodyFat()
            calculatedLeanBodyMass = calculateLeanBodyMass()
        } else {
            calculatedBodyFat = nil
            calculatedLeanBodyMass = nil
        }
    }
    
    /**
     * Gets display name for fitness goal.
     */
    func goalDisplayName(_ goal: String) -> String {
        switch goal {
        case "cut": return CommonKeys.Onboarding.goalCutTitle.localized
        case "bulk": return CommonKeys.Onboarding.goalBulkTitle.localized
        case "maintain": return CommonKeys.Onboarding.goalMaintainTitle.localized
        default: return "common.unknown".localized
        }
    }
    
    /**
     * Gets display name for activity level.
     */
    func activityDisplayName(_ activity: String) -> String {
        switch activity {
        case "sedentary": return CommonKeys.Onboarding.activitySedentary.localized
        case "light": return CommonKeys.Onboarding.activityLight.localized
        case "moderate": return CommonKeys.Onboarding.activityModerate.localized
        case "active": return CommonKeys.Onboarding.activityActive.localized
        case "very_active": return CommonKeys.Onboarding.activityVeryActive.localized
        default: return "common.unknown".localized
        }
    }
    
    /**
     * Gets info description based on Navy Method availability.
     */
    var infoDescription: String {
        return canCalculateNavyMethod ?
            CommonKeys.Onboarding.infoWithNavy.localized :
            CommonKeys.Onboarding.infoWithoutNavy.localized
    }
    
    // MARK: - Private Calculation Methods
    
    private func calculateBMR() -> Double {
        guard let data = onboardingData else { return 0 }
        
        let gender = Gender(rawValue: data.gender) ?? .male
        let bodyFat = canCalculateNavyMethod ? calculateNavyMethodBodyFat() : nil
        
        return HealthCalculator.calculateBMR(
            gender: gender,
            age: data.age,
            heightCm: data.height,
            weightKg: data.weight,
            bodyFatPercentage: bodyFat
        )
    }
    
    private func calculateTDEE() -> Double {
        guard let data = onboardingData else { return 0 }
        
        let activity = ActivityLevel(rawValue: data.activityLevel) ?? .moderate
        return HealthCalculator.calculateTDEE(bmr: calculatedBMR, activityLevel: activity)
    }
    
    private func calculateCalorieGoal() -> Double {
        guard let data = onboardingData else { return 0 }
        
        let goal = FitnessGoal(rawValue: data.fitnessGoal) ?? .maintain
        return HealthCalculator.calculateDailyCalories(tdee: calculatedTDEE, goal: goal)
    }
    
    private func calculateMacros() -> MacroBreakdown {
        guard let data = onboardingData else { return MacroBreakdown() }
        
        let goal = FitnessGoal(rawValue: data.fitnessGoal) ?? .maintain
        let macros = HealthCalculator.calculateMacros(
            weightKg: data.weight,
            dailyCalories: calculatedCalorieGoal,
            goal: goal
        )
        
        return MacroBreakdown(
            protein: macros.protein,
            carbs: macros.carbs,
            fat: macros.fat
        )
    }
    
    private func calculateNavyMethodBodyFat() -> Double? {
        guard let data = onboardingData,
              let neck = data.neckCircumference,
              let waist = data.waistCircumference else { return nil }
        
        let gender = Gender(rawValue: data.gender) ?? .male
        
        return HealthCalculator.calculateBodyFatNavy(
            gender: gender,
            heightCm: data.height,
            neckCm: neck,
            waistCm: waist,
            hipCm: data.hipCircumference
        )
    }
    
    private func calculateLeanBodyMass() -> Double? {
        guard let data = onboardingData,
              let bodyFat = calculatedBodyFat else { return nil }
        
        return data.weight * (1 - bodyFat / 100.0)
    }
}

// MARK: - Supporting Types

/**
 * Macro breakdown structure for display.
 */
struct MacroBreakdown {
    let protein: Double
    let carbs: Double
    let fat: Double
    
    init(protein: Double = 0, carbs: Double = 0, fat: Double = 0) {
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
    }
    
    /**
     * Formatted protein display.
     */
    var formattedProtein: String {
        return "\(Int(protein))g"
    }
    
    /**
     * Formatted carbs display.
     */
    var formattedCarbs: String {
        return "\(Int(carbs))g"
    }
    
    /**
     * Formatted fat display.
     */
    var formattedFat: String {
        return "\(Int(fat))g"
    }
}