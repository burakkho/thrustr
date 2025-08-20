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
    
    // MARK: - Cardio Stats
    var totalCardioSessions: Int
    var totalCardioTime: TimeInterval // seconds
    var totalCardioDistance: Double // meters
    var lastCardioDate: Date?
    var totalCardioCalories: Int // estimated calories burned in cardio
    
    // MARK: - Body Measurements (Optional)
    var chest: Double?
    var waist: Double?
    var hips: Double?
    var neck: Double?
    var bicep: Double?
    var thigh: Double?
    
    // MARK: - Lift Training Data
    var squatOneRM: Double?
    var benchPressOneRM: Double?
    var deadliftOneRM: Double?
    var overheadPressOneRM: Double?
    var oneRMLastUpdated: Date?
    
    // MARK: - Equipment Setup
    var availablePlates: [Double] // Available weight plates in kg
    var hasHomeGym: Bool
    var equipmentNotes: String?
    
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
        // FIXED: BMI calculation with validation
        guard height > 50 && height < 300,      // 50cm - 3m reasonable height range
              currentWeight > 10 && currentWeight < 500  // 10kg - 500kg reasonable weight range
        else { return 25.0 }  // Return normal BMI for invalid inputs
        
        let heightInMeters = height / 100
        guard heightInMeters > 0 else { return 25.0 }  // Prevent division by zero
        
        let calculatedBMI = currentWeight / (heightInMeters * heightInMeters)
        return max(10.0, min(80.0, calculatedBMI))  // Clamp to reasonable BMI range
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
        
        // Initialize cardio stats
        self.totalCardioSessions = 0
        self.totalCardioTime = 0
        self.totalCardioDistance = 0.0
        self.lastCardioDate = nil
        self.totalCardioCalories = 0
        
        // Initialize lift training data
        self.squatOneRM = nil
        self.benchPressOneRM = nil
        self.deadliftOneRM = nil
        self.overheadPressOneRM = nil
        self.oneRMLastUpdated = nil
        
        // Initialize equipment setup with common plates
        self.availablePlates = [1.25, 2.5, 5, 10, 15, 20] // Standard gym plates
        self.hasHomeGym = false
        self.equipmentNotes = nil
        
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
        if let weight = weight, weight > 10 && weight < 500 {  // FIXED: Validate weight range
            healthKitWeight = weight
            // Update current weight if HealthKit has newer data
            currentWeight = weight
            calculateMetrics()  // Recalculate with new weight
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
    
    // MARK: - Cardio Stats Updates
    func addCardioSession(duration: TimeInterval, distance: Double, calories: Int? = nil) {
        totalCardioSessions += 1
        totalCardioTime += duration
        totalCardioDistance += distance
        lastCardioDate = Date()
        if let calories = calories {
            totalCardioCalories += calories
        }
        lastActiveDate = Date()
    }
    
    func updateCardioStats(sessions: Int, totalTime: TimeInterval, totalDistance: Double, calories: Int) {
        totalCardioSessions += sessions
        totalCardioTime += totalTime
        totalCardioDistance += totalDistance
        totalCardioCalories += calories
        lastCardioDate = Date()
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
    
    // MARK: - Cardio Display Methods
    func displayTotalCardioTime() -> String {
        let hours = Int(totalCardioTime) / 3600
        let minutes = (Int(totalCardioTime) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    func displayTotalCardioDistance() -> String {
        if totalCardioDistance >= 1000 {
            let km = totalCardioDistance / 1000.0
            return String(format: "%.1f km", km)
        } else {
            return String(format: "%.0f m", totalCardioDistance)
        }
    }
    
    func displayCardioSessionsThisWeek() -> Int {
        // This would require a more complex query to count sessions in the last 7 days
        // For now, return total sessions as a placeholder
        return totalCardioSessions
    }
    
    func displayAverageCardioDistance() -> String {
        guard totalCardioSessions > 0 else { return "0 km" }
        let average = totalCardioDistance / Double(totalCardioSessions)
        if average >= 1000 {
            let km = average / 1000.0
            return String(format: "%.1f km", km)
        } else {
            return String(format: "%.0f m", average)
        }
    }
    
    func displayAverageCardioDuration() -> String {
        guard totalCardioSessions > 0 else { return "0m" }
        let average = totalCardioTime / Double(totalCardioSessions)
        let minutes = Int(average) / 60
        return "\(minutes)m"
    }
    
    // MARK: - Body Fat Calculation (Navy Method)
    func calculateBodyFatPercentage() -> Double? {
        // FIXED: Use HealthCalculator for consistent Navy Method calculation
        // All measurements are in CM (no unit conversion needed)
        return HealthCalculator.calculateBodyFatNavy(
            gender: genderEnum,
            heightCm: height,
            neckCm: neck,
            waistCm: waist,
            hipCm: hips
        )
    }
    
    // MARK: - Lift Training Methods
    func calculateStartingWeights() -> [String: Double] {
        var startingWeights: [String: Double] = [:]
        
        // Calculate starting weights at 65% of 1RM for main lifts
        if let squatMax = squatOneRM {
            let calculatedWeight = squatMax * 0.65
            startingWeights["squat"] = roundToPlateIncrement(calculatedWeight)
        }
        
        if let benchMax = benchPressOneRM {
            let calculatedBench = benchMax * 0.65
            startingWeights["bench"] = roundToPlateIncrement(calculatedBench)
            
            // Row starts at 65% of bench press 1RM (same as other lifts)
            let calculatedRow = benchMax * 0.65
            startingWeights["row"] = roundToPlateIncrement(calculatedRow)
        }
        
        if let deadliftMax = deadliftOneRM {
            let calculatedWeight = deadliftMax * 0.65
            startingWeights["deadlift"] = roundToPlateIncrement(calculatedWeight)
        }
        
        if let ohpMax = overheadPressOneRM {
            let calculatedWeight = ohpMax * 0.65
            startingWeights["ohp"] = roundToPlateIncrement(calculatedWeight)
        }
        
        return startingWeights
    }
    
    func calculateWarmupWeights(workingWeight: Double) -> [(weight: Double, reps: Int)] {
        return [
            (weight: workingWeight * 0.40, reps: 5), // 40% for 5 reps
            (weight: workingWeight * 0.60, reps: 3), // 60% for 3 reps  
            (weight: workingWeight * 0.80, reps: 1)  // 80% for 1 rep
        ]
    }
    
    func updateOneRM(exercise: String, newMax: Double) {
        switch exercise.lowercased() {
        case "squat":
            squatOneRM = newMax
        case "bench", "benchpress":
            benchPressOneRM = newMax
        case "deadlift":
            deadliftOneRM = newMax
        case "ohp", "overheadpress":
            overheadPressOneRM = newMax
        default:
            break
        }
        oneRMLastUpdated = Date()
    }
    
    var hasCompleteOneRMData: Bool {
        return squatOneRM != nil && 
               benchPressOneRM != nil && 
               deadliftOneRM != nil && 
               overheadPressOneRM != nil
    }
    
    func roundToPlateIncrement(_ weight: Double) -> Double {
        // TODO: Get unit system from UnitSettings when available
        // For now, assume metric (kg) system and round to 2.5kg increments
        return round(weight / 2.5) * 2.5
    }
}
