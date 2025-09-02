import SwiftData
import Foundation

/**
 * Central user profile model that stores personal information, fitness goals, health data, and workout statistics.
 * 
 * This model serves as the primary data store for user-related information and integrates with HealthKit
 * for seamless health data synchronization. All metrics are stored in metric units internally and converted
 * for display based on user preferences.
 * 
 * Key features:
 * - Personal information and fitness goals
 * - HealthKit integration for steps, calories, and weight
 * - Calculated metrics (BMR, TDEE, daily goals)
 * - Comprehensive workout and performance tracking
 * - Body measurements and equipment preferences
 */
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
    
    // MARK: - Notification Settings
    @Relationship(deleteRule: .cascade) var notificationSettings: UserNotificationSettings?
    
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
    var pullUpOneRM: Double?
    var oneRMLastUpdated: Date?
    
    // MARK: - Strength Test Data
    var strengthTestLastCompleted: Date?
    var strengthTestCompletionCount: Int
    var strengthProfile: String? // "balanced", "upper_dominant", "lower_dominant"
    var lastStrengthScore: Double // 0.0 - 1.0 overall test score
    
    // MARK: - Equipment Setup
    var availablePlates: [Double] // Available weight plates in kg
    var hasHomeGym: Bool
    var equipmentNotes: String?
    
    // MARK: - Analytics & Performance Tracking
    var currentWorkoutStreak: Int
    var longestWorkoutStreak: Int
    var lastStreakUpdate: Date?
    
    // MARK: - User Goals (Customizable)
    var monthlySessionGoal: Int
    var monthlyDistanceGoal: Double // meters
    var goalCompletionRate: Double
    
    // MARK: - Weekly Goals (Dashboard)
    var weeklyLiftGoal: Int // weekly lift sessions target
    var weeklyCardioGoal: Int // weekly cardio sessions target
    var weeklyDistanceGoal: Double // meters per week
    
    // MARK: - PR Tracking (8 Specific Exercises)
    var totalPRsThisMonth: Int
    var totalPRsAllTime: Int
    var lastPRDate: Date?
    
    // MARK: - Performance Analytics
    var averageSessionDuration: TimeInterval
    var lastAnalyticsUpdate: Date?
    
    // MARK: - BMI Cache (Performance Optimization)
    private var _cachedBMI: Double?
    private var _bmiCacheTimestamp: Date?
    private var bmiCacheTimeout: TimeInterval = 3600 // 1 hour cache - performance optimization
    
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
        // Check cache validity first
        if let cached = _cachedBMI,
           let timestamp = _bmiCacheTimestamp,
           Date().timeIntervalSince(timestamp) < bmiCacheTimeout {
            return cached
        }
        
        // Calculate fresh BMI with validation
        guard height > 50 && height < 300,      // 50cm - 3m reasonable height range
              currentWeight > 10 && currentWeight < 500  // 10kg - 500kg reasonable weight range
        else { 
            _cachedBMI = 25.0
            _bmiCacheTimestamp = Date()
            return 25.0 
        }
        
        let heightInMeters = height / 100
        guard heightInMeters > 0 else { 
            _cachedBMI = 25.0
            _bmiCacheTimestamp = Date()
            return 25.0 
        }
        
        let calculatedBMI = currentWeight / (heightInMeters * heightInMeters)
        let result = max(10.0, min(80.0, calculatedBMI))  // Clamp to reasonable BMI range
        
        // Cache the result
        _cachedBMI = result
        _bmiCacheTimestamp = Date()
        
        return result
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
        self.pullUpOneRM = nil
        self.oneRMLastUpdated = nil
        
        // Initialize strength test data
        self.strengthTestLastCompleted = nil
        self.strengthTestCompletionCount = 0
        self.strengthProfile = nil
        self.lastStrengthScore = 0.0
        
        // Initialize equipment setup with common plates
        self.availablePlates = [1.25, 2.5, 5, 10, 15, 20] // Standard gym plates
        self.hasHomeGym = false
        
        // Initialize analytics & performance tracking
        self.currentWorkoutStreak = 0
        self.longestWorkoutStreak = 0
        self.lastStreakUpdate = nil
        
        // Initialize user goals (reasonable defaults)
        self.monthlySessionGoal = 16 // 4 sessions per week
        self.monthlyDistanceGoal = 50000 // 50km per month
        self.goalCompletionRate = 0.0
        
        // Initialize weekly goals (dashboard defaults)
        self.weeklyLiftGoal = 4 // 4 lift sessions per week
        self.weeklyCardioGoal = 3 // 3 cardio sessions per week
        self.weeklyDistanceGoal = 12500 // 12.5km per week (50km/4)
        
        // Initialize PR tracking
        self.totalPRsThisMonth = 0
        self.totalPRsAllTime = 0
        self.lastPRDate = nil
        
        // Initialize performance analytics
        self.averageSessionDuration = 0
        self.lastAnalyticsUpdate = nil
        self.equipmentNotes = nil
        
        // Calculate initial metrics
        calculateMetrics()
    }
    
    // MARK: - Methods
    
    /**
     * Recalculates all derived metrics (BMR, TDEE, daily goals) based on current user data.
     * 
     * This method should be called whenever user profile data changes to ensure
     * all calculated values remain accurate and up-to-date.
     */
    func calculateMetrics() {
        calculateBMR()
        calculateTDEE()
        calculateDailyGoals()
    }
    
    /**
     * Updates user profile information with optional parameters.
     * 
     * This method allows partial updates to user profile data while automatically
     * recalculating dependent metrics and updating the last active timestamp.
     * 
     * - Parameters:
     *   - name: User's display name
     *   - age: User's age in years
     *   - gender: User's gender (affects BMR calculation)
     *   - height: User's height in centimeters
     *   - weight: User's current weight in kilograms
     *   - fitnessGoal: User's primary fitness objective
     *   - activityLevel: User's typical activity level (affects TDEE)
     */
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
        if let height = height { 
            self.height = height
            // Invalidate BMI cache when height changes
            _cachedBMI = nil
            _bmiCacheTimestamp = nil
        }
        if let weight = weight { 
            self.currentWeight = weight
            // Invalidate BMI cache when weight changes
            _cachedBMI = nil
            _bmiCacheTimestamp = nil
        }
        if let fitnessGoal = fitnessGoal { self.fitnessGoalEnum = fitnessGoal }
        if let activityLevel = activityLevel { self.activityLevelEnum = activityLevel }
        
        self.lastActiveDate = Date()
        calculateMetrics()
    }
    
    // MARK: - BMR Calculation (Mifflin-St Jeor Equation)
    
    /**
     * Calculates Basal Metabolic Rate using the Mifflin-St Jeor equation.
     * 
     * BMR represents the number of calories needed to maintain basic physiological
     * functions at rest. This is the foundation for calculating TDEE and daily goals.
     */
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
            // Invalidate BMI cache when weight changes from HealthKit
            _cachedBMI = nil
            _bmiCacheTimestamp = nil
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
    
    func updateCardioSession(oldDuration: TimeInterval, oldDistance: Double, newDuration: TimeInterval, newDistance: Double) {
        // Remove old values
        totalCardioTime -= oldDuration
        totalCardioDistance -= oldDistance
        
        // Add new values
        totalCardioTime += newDuration
        totalCardioDistance += newDistance
        
        // Update last active date
        lastActiveDate = Date()
        lastCardioDate = Date()
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
        case "squat", "back_squat":
            squatOneRM = newMax
        case "bench", "benchpress", "bench_press":
            benchPressOneRM = newMax
        case "deadlift":
            deadliftOneRM = newMax
        case "ohp", "overheadpress", "overhead_press":
            overheadPressOneRM = newMax
        case "pullup", "pull_up":
            pullUpOneRM = newMax
        default:
            break
        }
        oneRMLastUpdated = Date()
    }
    
    var hasCompleteOneRMData: Bool {
        return squatOneRM != nil && 
               benchPressOneRM != nil && 
               deadliftOneRM != nil && 
               overheadPressOneRM != nil &&
               pullUpOneRM != nil
    }
    
    func roundToPlateIncrement(_ weight: Double) -> Double {
        let unitSystem = UnitSettings.shared.unitSystem
        return roundToPlateIncrement(weight, system: unitSystem)
    }
    
    func roundToPlateIncrement(_ weight: Double, system: UnitSystem) -> Double {
        let increment = system == .metric ? 2.5 : 5.0 // 2.5kg or 5lbs increments
        return round(weight / increment) * increment
    }
    
    // MARK: - Dashboard Properties
    
    /**
     * Days since user created their account.
     */
    var daysSinceCreation: Int {
        Calendar.current.dateComponents([.day], from: createdAt, to: Date()).day ?? 0
    }
    
    /**
     * Total count of all user activities across training types.
     */
    var totalActivitiesCount: Int {
        return totalWorkouts + totalCardioSessions
    }
    
    
    /**
     * Weekly lift progress as percentage (0.0 - 1.0).
     */
    var weeklyLiftProgress: Double {
        let weeklyTarget = 4.0 // Default weekly lift target
        let currentSessions = Double(min(totalWorkouts, Int(weeklyTarget)))
        return currentSessions / weeklyTarget
    }
    
    /**
     * Daily calorie progress as percentage (0.0 - 1.0).
     */
    var dailyCalorieProgress: Double {
        guard dailyCalorieGoal > 0 else { return 0.0 }
        // This would be calculated with today's nutrition data in ViewModel
        return 0.0 // Placeholder - actual calculation in ViewModel
    }
    
    /**
     * Formatted streak message for dashboard display.
     */
    var streakDisplayText: String {
        guard currentWorkoutStreak > 0 else { return "" }
        return "🔥\(currentWorkoutStreak)"
    }
    
    // MARK: - Strength Test Integration Methods
    
    /**
     * Updates user profile with strength test results.
     */
    func updateWithStrengthTest(_ strengthTest: StrengthTest) {
        guard strengthTest.isCompleted else { 
            print("❌ User.updateWithStrengthTest: Test not completed")
            return 
        }
        
        print("✅ User.updateWithStrengthTest: Processing test with \(strengthTest.results.count) results")
        
        // Update 1RM values from test results with safety checks
        for result in strengthTest.results {
            guard result.value > 0 && result.value.isFinite && !result.value.isNaN else {
                print("❌ User.updateWithStrengthTest: Invalid result value for \(result.exerciseType)")
                continue
            }
            updateOneRM(exercise: result.exerciseType, newMax: result.value)
        }
        
        // Update strength test tracking with safe values
        strengthTestLastCompleted = strengthTest.testDate
        strengthTestCompletionCount += 1
        strengthProfile = strengthTest.strengthProfile
        
        // Safely update score with validation
        if strengthTest.overallScore.isFinite && !strengthTest.overallScore.isNaN {
            lastStrengthScore = max(0.0, min(1.0, strengthTest.overallScore))
        } else {
            print("❌ User.updateWithStrengthTest: Invalid overall score")
            lastStrengthScore = 0.0
        }
        
        // Update activity tracking
        lastActiveDate = Date()
        
        // Recalculate metrics with new data
        calculateMetrics()
        
        print("✅ User.updateWithStrengthTest: Successfully updated user profile")
    }
    
    // MARK: - Lifetime Statistics Methods
    
    /**
     * Calculates total weight lifted across all lift sessions in kg.
     */
    func calculateTotalWeightLifted(from sessions: [LiftSession]) -> Double {
        return sessions
            .filter { $0.isCompleted }
            .reduce(0.0) { total, session in
                total + session.totalVolume
            }
    }
    
    /**
     * Calculates total distance covered across all cardio sessions in kilometers.
     */
    func calculateTotalDistanceCovered(from sessions: [CardioSession]) -> Double {
        return sessions
            .filter { $0.isCompleted }
            .reduce(0.0) { total, session in
                total + (session.totalDistance / 1000.0) // Convert meters to km
            }
    }
    
    /**
     * Calculates total number of completed workouts (lift + cardio).
     */
    func calculateTotalWorkouts(liftSessions: [LiftSession], cardioSessions: [CardioSession]) -> Int {
        let liftCount = liftSessions.filter { $0.isCompleted }.count
        let cardioCount = cardioSessions.filter { $0.isCompleted }.count
        return liftCount + cardioCount
    }
    
    /**
     * Calculates total active days (days with any completed workout).
     */
    func calculateActiveDays(liftSessions: [LiftSession], cardioSessions: [CardioSession]) -> Int {
        let liftDates = Set(liftSessions.filter { $0.isCompleted }.map { 
            Calendar.current.startOfDay(for: $0.startDate)
        })
        let cardioDates = Set(cardioSessions.filter { $0.isCompleted }.map {
            Calendar.current.startOfDay(for: $0.startDate)
        })
        
        return Set(liftDates.union(cardioDates)).count
    }
    
    /**
     * Gets current 1RM for a specific exercise type with safety validation.
     */
    func getCurrentOneRM(for exerciseType: StrengthExerciseType) -> Double? {
        let value: Double?
        
        switch exerciseType {
        case .benchPress:
            value = benchPressOneRM
        case .overheadPress:
            value = overheadPressOneRM
        case .pullUp:
            value = pullUpOneRM
        case .backSquat:
            value = squatOneRM
        case .deadlift:
            value = deadliftOneRM
        }
        
        // Return nil if value is invalid (NaN, infinite, or negative)
        if let val = value, val > 0 && val.isFinite && !val.isNaN {
            return val
        }
        
        return nil
    }
    
    /**
     * Checks if strength test is recommended based on last test date.
     */
    var isStrengthTestRecommended: Bool {
        guard let lastTest = strengthTestLastCompleted else { return true }
        
        // Recommend retest after 4-8 weeks based on experience level
        let weeksSinceTest = Calendar.current.dateComponents([.weekOfYear], from: lastTest, to: Date()).weekOfYear ?? 0
        let recommendedInterval = strengthTestCompletionCount < 3 ? 4 : 8
        
        return weeksSinceTest >= recommendedInterval
    }
    
    /**
     * Gets strength profile emoji for dashboard display.
     */
    var strengthProfileEmoji: String {
        switch strengthProfile {
        case "balanced":
            return "⚖️"
        case "upper_dominant":
            return "💪"
        case "lower_dominant":
            return "🦵"
        default:
            return "❓"
        }
    }
    
    // MARK: - Unit-aware formatting helpers
    
    func formattedWeight(system: UnitSystem) -> String {
        return UnitsFormatter.formatWeight(kg: currentWeight, system: system)
    }
    
    func formattedHeight(system: UnitSystem) -> String {
        return UnitsFormatter.formatHeight(cm: height, system: system)
    }
}
