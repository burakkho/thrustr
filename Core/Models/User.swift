import SwiftData
import Foundation

@Model
final class User {
    // MARK: - Personal Information
    var name: String
    var age: Int
    var gender: String // Uses Gender enum rawValue
    var height: Double // cm
    var currentWeight: Double // kg
    
    // MARK: - Goals & Activity
    var fitnessGoal: String // Uses FitnessGoal enum rawValue
    var activityLevel: String // Uses ActivityLevel enum rawValue
    
    // MARK: - App Settings
    var selectedLanguage: String
    var onboardingCompleted: Bool
    var profilePictureData: Data?
    
    // MARK: - Legal / Consent
    var consentAccepted: Bool
    var consentTimestamp: Date?
    var marketingOptIn: Bool
    
    // MARK: - Account Information
    var createdAt: Date // MISSING PROPERTY ADDED
    var lastActiveDate: Date
    
    // MARK: - Health Data Integration
    var lastHealthKitSync: Date?
    var healthKitSteps: Double?
    var healthKitCalories: Double?
    var healthKitWeight: Double?
    
    // MARK: - Calculated Metrics (Auto-updated)
    var bmr: Double // Basal Metabolic Rate
    var tdee: Double // Total Daily Energy Expenditure
    var dailyCalorieGoal: Double
    var dailyProteinGoal: Double // grams
    var dailyCarbGoal: Double // grams
    var dailyFatGoal: Double // grams
    
    // MARK: - Workout Stats
    var totalWorkouts: Int
    var totalWorkoutTime: TimeInterval // seconds
    var totalVolume: Double // kg
    var lastWorkoutDate: Date?
    
    // MARK: - Body Measurements (Optional)
    var chest: Double?
    var waist: Double?
    var hips: Double?
    var neck: Double?
    var bicep: Double?
    var thigh: Double?
    
    // MARK: - Computed Properties Using Enums
    var genderEnum: Gender {
        get { Gender(rawValue: gender) ?? .male }
        set { gender = newValue.rawValue }
    }
    
    var fitnessGoalEnum: FitnessGoal {
        get { FitnessGoal(rawValue: fitnessGoal) ?? .maintain }
        set { fitnessGoal = newValue.rawValue }
    }
    
    var activityLevelEnum: ActivityLevel {
        get { ActivityLevel(rawValue: activityLevel) ?? .moderate }
        set { activityLevel = newValue.rawValue }
    }
    
    // MARK: - Convenience Properties
    var displayWeight: String {
        String(format: "%.1f kg", currentWeight)
    }
    
    var displayHeight: String {
        // Deprecated: UI should use UnitsFormatter via environment
        String(format: "%.0f cm", height)
    }
    
    var displayAge: String {
        "\(age) yaş"
    }
    
    var bmi: Double {
        let heightInMeters = height / 100
        return currentWeight / (heightInMeters * heightInMeters)
    }
    
    var bmiCategory: String {
        switch bmi {
        case ..<18.5: return "bmi_underweight".localized
        case 18.5..<25: return "bmi_normal".localized
        case 25..<30: return "bmi_overweight".localized
        default: return "bmi_obese".localized
        }
    }
    
    // MARK: - Initialization
    init(
        name: String = "",
        age: Int = 25,
        gender: Gender = .male,
        height: Double = 170,
        currentWeight: Double = 70,
        fitnessGoal: FitnessGoal = .maintain,
        activityLevel: ActivityLevel = .moderate,
        selectedLanguage: String = "tr",
        consentAccepted: Bool = false,
        marketingOptIn: Bool = false,
        consentTimestamp: Date? = nil
    ) {
        self.name = name
        self.age = age
        self.gender = gender.rawValue
        self.height = height
        self.currentWeight = currentWeight
        self.fitnessGoal = fitnessGoal.rawValue
        self.activityLevel = activityLevel.rawValue
        self.selectedLanguage = selectedLanguage
        self.onboardingCompleted = false
        self.consentAccepted = consentAccepted
        self.marketingOptIn = marketingOptIn
        self.consentTimestamp = consentTimestamp
        
        // Account info
        self.createdAt = Date()
        self.lastActiveDate = Date()
        
        // Initialize calculated values
        self.bmr = 0
        self.tdee = 0
        self.dailyCalorieGoal = 0
        self.dailyProteinGoal = 0
        self.dailyCarbGoal = 0
        self.dailyFatGoal = 0
        
        // Initialize workout stats
        self.totalWorkouts = 0
        self.totalWorkoutTime = 0
        self.totalVolume = 0
        
        // Calculate initial metrics
        calculateMetrics()
    }
    
    // MARK: - Methods
    func calculateMetrics() {
        calculateBMR()
        calculateTDEE()
        calculateDailyGoals()
    }
    
    func updateProfile(
        name: String? = nil,
        age: Int? = nil,
        gender: Gender? = nil,
        height: Double? = nil,
        weight: Double? = nil,
        fitnessGoal: FitnessGoal? = nil,
        activityLevel: ActivityLevel? = nil
    ) {
        if let name = name { self.name = name }
        if let age = age { self.age = age }
        if let gender = gender { self.genderEnum = gender }
        if let height = height { self.height = height }
        if let weight = weight { self.currentWeight = weight }
        if let fitnessGoal = fitnessGoal { self.fitnessGoalEnum = fitnessGoal }
        if let activityLevel = activityLevel { self.activityLevelEnum = activityLevel }
        
        self.lastActiveDate = Date()
        calculateMetrics()
    }
    
    // MARK: - BMR Calculation (Mifflin-St Jeor Equation)
    private func calculateBMR() {
        bmr = HealthCalculator.calculateBMR(
            gender: genderEnum,
            age: age,
            heightCm: height,
            weightKg: currentWeight,
            bodyFatPercentage: calculateBodyFatPercentage()
        )
    }
    
    // MARK: - TDEE Calculation
    private func calculateTDEE() {
        tdee = HealthCalculator.calculateTDEE(bmr: bmr, activityLevel: activityLevelEnum)
    }
    
    // MARK: - Daily Goals Calculation
    private func calculateDailyGoals() {
        dailyCalorieGoal = HealthCalculator.calculateDailyCalories(
            tdee: tdee,
            goal: fitnessGoalEnum
        )
        let macros = HealthCalculator.calculateMacros(
            weightKg: currentWeight,
            dailyCalories: dailyCalorieGoal,
            goal: fitnessGoalEnum
        )
        dailyProteinGoal = macros.protein
        dailyCarbGoal = macros.carbs
        dailyFatGoal = macros.fat
    }
    
    // MARK: - HealthKit Integration
    func updateHealthKitData(steps: Double?, calories: Double?, weight: Double?) {
        if let steps = steps { healthKitSteps = steps }
        if let calories = calories { healthKitCalories = calories }
        if let weight = weight {
            healthKitWeight = weight
            // Update current weight if HealthKit has newer data
            currentWeight = weight
            calculateMetrics()
        }
        lastHealthKitSync = Date()
        lastActiveDate = Date()
    }
    
    // MARK: - Workout Stats Updates
    func addWorkoutStats(duration: TimeInterval, volume: Double) {
        totalWorkouts += 1
        totalWorkoutTime += duration
        totalVolume += volume
        lastWorkoutDate = Date()
        lastActiveDate = Date()
    }
    
    // MARK: - Display Methods
    func displayBMR() -> String {
        String(format: "%.0f kcal", bmr)
    }
    
    func displayTDEE() -> String {
        String(format: "%.0f kcal", tdee)
    }
    
    func displayDailyCalories() -> String {
        String(format: "%.0f kcal", dailyCalorieGoal)
    }
    
    func displayMacros() -> (protein: String, carbs: String, fat: String) {
        let protein = String(format: "%.0fg", dailyProteinGoal)
        let carbs = String(format: "%.0fg", dailyCarbGoal)
        let fat = String(format: "%.0fg", dailyFatGoal)
        return (protein: protein, carbs: carbs, fat: fat)
    }
    
    // MARK: - Body Fat Calculation (Navy Method)
    func calculateBodyFatPercentage() -> Double? {
        guard let waist = waist, let neck = neck else { return nil }
        
        let heightInches = height / 2.54 // Convert cm to inches
        let waistInches = waist / 2.54
        let neckInches = neck / 2.54
        
        if genderEnum == .male {
            return 495 / (1.0324 - 0.19077 * log10(waistInches - neckInches) + 0.15456 * log10(heightInches)) - 450
        } else {
            guard let hips = hips else { return nil }
            let hipsInches = hips / 2.54
            return 495 / (1.29579 - 0.35004 * log10(waistInches + hipsInches - neckInches) + 0.22100 * log10(heightInches)) - 450
        }
    }
}
