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
    var id: UUID = UUID()
    var name: String = ""
    var age: Int = 25
    var gender: String = "male" // Uses Gender enum rawValue
    var height: Double = 170.0 // cm
    var currentWeight: Double = 70.0 // kg
    
    // MARK: - Goals & Activity
    var fitnessGoal: String = "maintain" // Uses FitnessGoal enum rawValue
    var activityLevel: String = "moderate" // Uses ActivityLevel enum rawValue
    
    // MARK: - App Settings
    var selectedLanguage: String = "tr"
    var onboardingCompleted: Bool = false
    @Transient var profilePictureURL: String? // File system path for profile picture - LOCAL ONLY
    
    // MARK: - Legal / Consent (LOCAL ONLY for privacy)
    var consentAccepted: Bool = false
    var consentTimestamp: Date? = nil
    var marketingOptIn: Bool = false
    
    // MARK: - Account Information
    var createdAt: Date = Date()
    var lastActiveDate: Date = Date()
    
    // MARK: - Notification Settings  
    @Relationship(deleteRule: .cascade, inverse: \UserNotificationSettings.user) var notificationSettings: UserNotificationSettings?
    
    // MARK: - CloudKit Relationships (Single Direction Only)
    var activityEntries: [ActivityEntry]?
    var bodyMeasurements: [BodyMeasurement]?
    var cardioResults: [CardioResult]?
    @Relationship(inverse: \CardioSession.user) var cardioSessions: [CardioSession]?
    var goals: [Goal]?
    @Relationship(inverse: \LiftProgram.creator) var createdPrograms: [LiftProgram]?
    @Relationship(inverse: \LiftResult.user) var liftResults: [LiftResult]?
    @Relationship(inverse: \LiftSession.user) var liftSessions: [LiftSession]?
    @Relationship(inverse: \ProgramExecution.user) var programExecutions: [ProgramExecution]?
    var progressPhotos: [ProgressPhoto]?
    var weightEntries: [WeightEntry]?
    var wodResults: [WODResult]?
    
    // MARK: - Health Data Integration (LOCAL ONLY for privacy)
    @Transient var lastHealthKitSync: Date?
    
    // MARK: - Data Source Tracking (LOCAL ONLY for privacy)
    @Transient var weightSource: String = "manual"
    @Transient var weightLastUpdated: Date?
    
    // TODO: Add source tracking for other metrics as needed
    // var stepsSource: String = DataSource.healthKit.rawValue
    // var stepsLastUpdated: Date?
    
    // Note: healthKitSteps, healthKitCalories, healthKitWeight removed
    // These are now accessed directly from HealthKitService for real-time data
    
    // MARK: - Calculated Metrics (CloudKit Syncable)
    var bmr: Double = 0.0 // Basal Metabolic Rate
    var tdee: Double = 0.0 // Total Daily Energy Expenditure
    var dailyCalorieGoal: Double = 0.0
    var dailyProteinGoal: Double = 0.0 // grams
    var dailyCarbGoal: Double = 0.0 // grams
    var dailyFatGoal: Double = 0.0 // grams
    
    // MARK: - Workout Stats (CloudKit Syncable)
    var totalWorkouts: Int = 0
    var totalWorkoutTime: TimeInterval = 0.0 // seconds
    var totalVolume: Double = 0.0 // kg
    var lastWorkoutDate: Date? = nil
    var maxSetsInSingleWorkout: Int = 0 // maximum sets completed in one session
    var maxRepsInSingleSet: Int = 0 // maximum reps in a single set
    var longestWorkoutDuration: TimeInterval = 0.0 // longest single workout duration
    
    // MARK: - Cardio Stats (CloudKit Syncable)
    var totalCardioSessions: Int = 0
    var totalCardioTime: TimeInterval = 0.0 // seconds
    var totalCardioDistance: Double = 0.0 // meters - internal metric storage
    var lastCardioDate: Date? = nil
    var totalCardioCalories: Int = 0 // estimated calories burned in cardio
    var longestRun: Double = 0.0 // meters - internal metric storage
    
    // MARK: - Lift Stats (CloudKit Syncable)
    var totalLiftSessions: Int = 0
    var totalLiftTime: TimeInterval = 0.0 // seconds
    var totalLiftVolume: Double = 0.0 // kg - internal metric storage
    var lastLiftDate: Date? = nil
    
    // MARK: - Body Measurements (CloudKit Syncable)
    var chest: Double?
    var waist: Double?
    var hips: Double?
    var neck: Double?
    var bicep: Double?
    var thigh: Double?
    
    // MARK: - Lift Training Data (CloudKit Syncable)
    var squatOneRM: Double?
    var benchPressOneRM: Double?
    var deadliftOneRM: Double?
    var overheadPressOneRM: Double?
    var pullUpOneRM: Double?
    var oneRMLastUpdated: Date?
    
    // MARK: - Strength Test Data (CloudKit Syncable)
    var strengthTestLastCompleted: Date? = nil
    var strengthTestCompletionCount: Int = 0
    var strengthProfile: String? = nil // "balanced", "upper_dominant", "lower_dominant"
    var lastStrengthScore: Double = 0.0 // 0.0 - 1.0 overall test score
    
    // MARK: - Equipment Setup (CloudKit Syncable)
    var availablePlates: [Double] = [1.25, 2.5, 5, 10, 15, 20] // kg - metric plates
    var hasHomeGym: Bool = false
    var equipmentNotes: String? = nil
    
    // MARK: - Analytics & Performance Tracking (CloudKit Syncable)
    var currentWorkoutStreak: Int = 0
    var longestWorkoutStreak: Int = 0
    var lastStreakUpdate: Date? = nil
    
    // MARK: - User Goals (CloudKit Syncable)
    var monthlySessionGoal: Int = 16 // 4 sessions per week default
    var monthlyDistanceGoal: Double = 50000.0 // meters - 50km internal metric storage
    var goalCompletionRate: Double = 0.0
    
    // MARK: - Weekly Goals (CloudKit Syncable)
    var weeklyLiftGoal: Int = 4 // weekly lift sessions target
    var weeklyCardioGoal: Int = 3 // weekly cardio sessions target
    var weeklyDistanceGoal: Double = 12500.0 // meters - 12.5km internal metric storage
    var weeklySessionGoal: Int = 4 // total weekly sessions target (lift + cardio)
    
    // MARK: - PR Tracking (CloudKit Syncable)
    var totalPRsThisMonth: Int = 0
    var totalPRsAllTime: Int = 0
    var lastPRDate: Date? = nil
    
    // MARK: - Performance Analytics (CloudKit Syncable)
    var averageSessionDuration: TimeInterval = 0.0
    var lastAnalyticsUpdate: Date? = nil
    
    // MARK: - BMI Cache (LOCAL ONLY - Performance Optimization)
    @Transient private var _cachedBMI: Double?
    @Transient private var _bmiCacheTimestamp: Date?
    @Transient private var bmiCacheTimeout: TimeInterval = 3600
    
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
    
    var weightSourceEnum: DataSource {
        get { DataSource(rawValue: weightSource) ?? .manual }
        set { weightSource = newValue.rawValue }
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
        String(format: CommonKeys.PersonalInfoExtended.ageFormat.localized, age)
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
        
        // Data source tracking initialization (for @Transient properties)
        self.weightSource = DataSource.manual.rawValue
        self.weightLastUpdated = Date()
        
        // BMI cache initialization
        self.bmiCacheTimeout = 3600 // 1 hour cache
        
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
        self.maxSetsInSingleWorkout = 0
        self.maxRepsInSingleSet = 0
        self.longestWorkoutDuration = 0
        
        // Initialize cardio stats
        self.totalCardioSessions = 0
        self.totalCardioTime = 0
        self.totalCardioDistance = 0.0
        self.lastCardioDate = nil
        self.totalCardioCalories = 0
        self.longestRun = 0
        
        // Initialize lift stats
        self.totalLiftSessions = 0
        self.totalLiftTime = 0
        self.totalLiftVolume = 0.0
        self.lastLiftDate = nil
        
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
        self.weeklySessionGoal = 4 // total weekly sessions target
        
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
        
        // Run migration for existing data
        migrateLegacyHealthKitData()
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
    func updateHealthKitData(steps: Double?, calories: Double?, weight: Double?, timestamp: Date = Date()) {
        // Weight update using intelligent conflict resolution
        if let weight = weight {
            updateWeightIntelligently(weight, source: .healthKit, timestamp: timestamp)
        }
        
        // TODO: Add smart update logic for steps and calories when needed
        // For now, we don't store these as they're accessed directly from HealthKitService
        
        lastHealthKitSync = timestamp
        lastActiveDate = Date()
        
        print("✅ HealthKit data updated: weight=\(weight?.description ?? "nil"), timestamp=\(timestamp)")
    }
    
    /**
     * Updates weight from manual user entry with automatic bi-directional sync.
     * This method should be called when user manually enters their weight.
     */
    func updateWeightManually(_ weight: Double) {
        updateWeightIntelligently(weight, source: .manual, timestamp: Date())
        
        // Bi-directional sync to HealthKit
        Task { @MainActor in
            let success = await HealthKitService.shared.saveWeight(weight)
            if success {
                print("✅ Weight synced to HealthKit: \(weight)kg")
            } else {
                print("⚠️ Failed to sync weight to HealthKit")
            }
        }
    }
    
    // MARK: - Workout Stats Updates
    func addWorkoutStats(duration: TimeInterval, volume: Double) {
        totalWorkouts += 1
        totalWorkoutTime += duration
        totalVolume += volume
        lastWorkoutDate = Date()
        lastActiveDate = Date()
        
        // Update records if needed
        if duration > longestWorkoutDuration {
            longestWorkoutDuration = duration
        }
    }
    
    func updateWorkoutRecords(sets: Int, duration: TimeInterval) {
        if sets > maxSetsInSingleWorkout {
            maxSetsInSingleWorkout = sets
        }
        if duration > longestWorkoutDuration {
            longestWorkoutDuration = duration
        }
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
        
        // Update longest run record
        if distance > longestRun {
            longestRun = distance
        }
        
        lastActiveDate = Date()
    }
    
    func addLiftSession(duration: TimeInterval, volume: Double, sets: Int, reps: Int) {
        totalLiftSessions += 1
        totalLiftTime += duration
        totalLiftVolume += volume
        lastLiftDate = Date()
        lastActiveDate = Date()
        
        // Update personal records if applicable
        if duration > longestWorkoutDuration {
            longestWorkoutDuration = duration
        }
    }
    
    func updateCardioSession(oldDuration: TimeInterval, oldDistance: Double, newDuration: TimeInterval, newDistance: Double, oldCalories: Int? = nil, newCalories: Int? = nil) {
        // Remove old values
        totalCardioTime -= oldDuration
        totalCardioDistance -= oldDistance
        if let oldCal = oldCalories {
            totalCardioCalories -= oldCal
        }
        
        // Add new values
        totalCardioTime += newDuration
        totalCardioDistance += newDistance
        if let newCal = newCalories {
            totalCardioCalories += newCal
        }
        
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
    func calculateStartingWeights(unitSystem: UnitSystem = .metric) -> [String: Double] {
        var startingWeights: [String: Double] = [:]
        
        // Calculate starting weights at 65% of 1RM for main lifts
        if let squatMax = squatOneRM {
            let calculatedWeight = squatMax * 0.65
            startingWeights["squat"] = roundToPlateIncrement(calculatedWeight, system: unitSystem)
        }
        
        if let benchMax = benchPressOneRM {
            let calculatedBench = benchMax * 0.65
            startingWeights["bench"] = roundToPlateIncrement(calculatedBench, system: unitSystem)
            
            // Row starts at 65% of bench press 1RM (same as other lifts)
            let calculatedRow = benchMax * 0.65
            startingWeights["row"] = roundToPlateIncrement(calculatedRow, system: unitSystem)
        }
        
        if let deadliftMax = deadliftOneRM {
            let calculatedWeight = deadliftMax * 0.65
            startingWeights["deadlift"] = roundToPlateIncrement(calculatedWeight, system: unitSystem)
        }
        
        if let ohpMax = overheadPressOneRM {
            let calculatedWeight = ohpMax * 0.65
            startingWeights["ohp"] = roundToPlateIncrement(calculatedWeight, system: unitSystem)
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
    
    @MainActor
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
        
        print("✅ User.updateWithStrengthTest: Processing test with \(strengthTest.results?.count ?? 0) results")
        
        // Update 1RM values from test results with safety checks
        for result in strengthTest.results ?? [] {
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
    
    // MARK: - Computed Goal Properties
    var totalWeeklyGoal: Int {
        return weeklyLiftGoal + weeklyCardioGoal
    }
    
    // MARK: - Unit-aware formatting helpers
    
    func formattedWeight(system: UnitSystem) -> String {
        return UnitsFormatter.formatWeight(kg: currentWeight, system: system)
    }
    
    func formattedHeight(system: UnitSystem) -> String {
        return UnitsFormatter.formatHeight(cm: height, system: system)
    }
    
    // MARK: - Migration & Data Source Management
    
    /**
     * Migrates legacy HealthKit data fields to the new data source tracking system.
     * This method runs once during User initialization to handle existing users.
     * 
     * Migration Strategy:
     * 1. Check if migration already completed (weightLastUpdated exists)
     * 2. Detect data source based on available timestamps and data patterns
     * 3. Set appropriate source and timestamp
     * 4. Clean up any inconsistencies
     */
    private func migrateLegacyHealthKitData() {
        // Skip migration if already done (weightLastUpdated exists)
        if weightLastUpdated != nil {
            print("✅ Migration skipped - Already completed")
            return
        }
        
        var detectedSource: DataSource = .manual
        var detectedTimestamp: Date = Date()
        
        // Strategy 1: Check HealthKit sync patterns
        if let hkSyncDate = lastHealthKitSync {
            // User has HealthKit sync history
            let daysSinceSync = Calendar.current.dateComponents([.day], from: hkSyncDate, to: Date()).day ?? 0
            
            if daysSinceSync <= 7 {
                // Recent HealthKit activity suggests HealthKit source
                detectedSource = .healthKit
                detectedTimestamp = hkSyncDate
                print("📱 Migration: Detected active HealthKit usage (last sync: \(daysSinceSync) days ago)")
            } else {
                // Old HealthKit sync, likely manual now
                detectedSource = .manual
                detectedTimestamp = Date()
                print("📝 Migration: HealthKit inactive, defaulting to manual")
            }
        } else {
            // No HealthKit sync history - definitely manual
            detectedSource = .manual
            detectedTimestamp = createdAt
            print("📝 Migration: No HealthKit history, setting manual source")
        }
        
        // Strategy 2: Data consistency validation
        // Note: In future versions, this would check actual legacy fields
        // if let legacyHKWeight = healthKitWeight {
        //     if abs(legacyHKWeight - currentWeight) < 0.5 {
        //         detectedSource = .healthKit
        //     }
        // }
        
        // Apply migration results
        weightSource = detectedSource.rawValue
        weightLastUpdated = detectedTimestamp
        
        // Log migration completion
        let sourceIcon = detectedSource == .healthKit ? "⌚" : "📝"
        print("✅ User migration completed: \(sourceIcon) \(detectedSource.displayName) source detected")
        
        // Migration quality check
        validateMigrationIntegrity()
    }
    
    /**
     * Validates that migration completed successfully and data is consistent.
     */
    private func validateMigrationIntegrity() {
        guard let weightTimestamp = weightLastUpdated else {
            print("❌ Migration validation failed: weightLastUpdated is nil")
            return
        }
        
        let source = weightSourceEnum
        let now = Date()
        
        // Validate timestamp is reasonable
        if weightTimestamp > now {
            print("⚠️ Migration warning: Weight timestamp is in the future")
            weightLastUpdated = now
        }
        
        // Validate weight is reasonable
        if currentWeight < 10 || currentWeight > 500 {
            print("⚠️ Migration warning: Weight value seems unreasonable: \(currentWeight)kg")
        }
        
        // Validate source enum
        if DataSource(rawValue: weightSource) == nil {
            print("⚠️ Migration warning: Invalid weight source, resetting to manual")
            weightSource = DataSource.manual.rawValue
        }
        
        print("✅ Migration validation passed: \(source.displayName), \(String(format: "%.1f", currentWeight))kg")
    }
    
    /**
     * Updates weight with intelligent conflict resolution based on timestamp and source priority.
     * 
     * - Parameters:
     *   - newWeight: The new weight value in kilograms
     *   - source: The data source providing this weight
     *   - timestamp: When this weight was measured (defaults to current time)
     */
    func updateWeightIntelligently(_ newWeight: Double, source: DataSource, timestamp: Date = Date()) {
        // Validate weight range
        guard newWeight > 10 && newWeight < 500 else {
            print("❌ Invalid weight range: \(newWeight)kg")
            return
        }
        
        let currentTimestamp = weightLastUpdated ?? .distantPast
        let oldWeight = currentWeight
        let oldSource = weightSourceEnum
        
        // Determine if this update should win
        let shouldUpdate = source.shouldOverride(
            oldSource,
            thisTimestamp: timestamp,
            otherTimestamp: currentTimestamp
        )
        
        if shouldUpdate {
            // Update weight data
            currentWeight = newWeight
            weightSourceEnum = source
            weightLastUpdated = timestamp
            lastActiveDate = Date()
            
            // Invalidate BMI cache when weight changes
            _cachedBMI = nil
            _bmiCacheTimestamp = nil
            
            // Check for significant change (>1kg)
            let weightDifference = abs(newWeight - oldWeight)
            if weightDifference > 1.0 {
                print("⚖️ Weight updated: \(oldWeight)kg → \(newWeight)kg (\(source.displayName))")
                
                // Recalculate metrics for significant changes
                calculateMetrics()
                
                // Log the change for potential user notification
                notifyWeightChange(from: oldWeight, to: newWeight, source: source)
            } else {
                print("⚖️ Weight updated silently: \(oldWeight)kg → \(newWeight)kg (\(source.displayName))")
            }
        } else {
            print("⚖️ Weight update ignored: \(newWeight)kg from \(source.displayName) (older than current)")
        }
    }
    
    /**
     * Logs weight changes for potential user notification.
     * This method can be extended to trigger actual UI notifications.
     */
    private func notifyWeightChange(from oldWeight: Double, to newWeight: Double, source: DataSource) {
        let change = newWeight - oldWeight
        let direction = change > 0 ? "gained" : "lost"
        let amount = abs(change)
        
        // TODO: Implement actual notification system
        print("📊 Weight change notification: \(direction) \(String(format: "%.1f", amount))kg via \(source.displayName)")
        
        // This is where you would trigger toast notifications or other UI feedback
        // NotificationCenter.default.post(name: .weightUpdated, object: WeightChangeInfo(...))
    }
}
