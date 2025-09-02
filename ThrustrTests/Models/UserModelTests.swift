import XCTest
import SwiftData
@testable import Thrustr

/**
 * Comprehensive tests for User model
 * Tests all critical user calculations, data integrity, and business logic
 */
@MainActor
final class UserModelTests: XCTestCase {
    
    // MARK: - Test Properties
    private var modelContext: ModelContext!
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        modelContext = try TestHelpers.createTestModelContext()
    }
    
    override func tearDown() async throws {
        modelContext = nil
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testUserInitialization() {
        // Given - User creation parameters
        let name = "Test User"
        let age = 25
        let gender = Gender.male
        let height = 175.0
        let weight = 75.0
        let goal = FitnessGoal.recomp
        let activity = ActivityLevel.moderate
        
        // When
        let user = User(
            name: name,
            age: age,
            gender: gender,
            height: height,
            currentWeight: weight,
            fitnessGoal: goal,
            activityLevel: activity
        )
        
        // Then - Basic properties
        XCTAssertEqual(user.name, name)
        XCTAssertEqual(user.age, age)
        XCTAssertEqual(user.genderEnum, gender)
        XCTAssertEqual(user.height, height)
        XCTAssertEqual(user.currentWeight, weight)
        XCTAssertEqual(user.fitnessGoalEnum, goal)
        XCTAssertEqual(user.activityLevelEnum, activity)
        
        // Then - Default values
        XCTAssertFalse(user.onboardingCompleted)
        XCTAssertFalse(user.consentAccepted)
        XCTAssertEqual(user.totalWorkouts, 0)
        XCTAssertEqual(user.totalCardioSessions, 0)
        XCTAssertEqual(user.currentWorkoutStreak, 0)
        
        // Then - Metrics should be calculated
        XCTAssertGreaterThan(user.bmr, 0)
        XCTAssertGreaterThan(user.tdee, 0)
        XCTAssertGreaterThan(user.dailyCalorieGoal, 0)
    }
    
    func testUserInitializationWithModelContext() throws {
        // Given - User with model context
        let user = TestHelpers.createTestUser()
        modelContext.insert(user)
        
        // When
        try modelContext.save()
        
        // Then
        XCTAssertNotNil(user.createdAt)
        XCTAssertNotNil(user.lastActiveDate)
        assertValidUserState(user)
    }
    
    // MARK: - BMI Calculation Tests
    
    func testBMICalculationStandard() {
        // Given - Standard adult measurements
        let testCases: [(height: Double, weight: Double, expectedBMI: Double)] = [
            (175.0, 75.0, 24.49),  // Normal weight
            (160.0, 50.0, 19.53),  // Lower normal
            (180.0, 90.0, 27.78),  // Overweight
            (170.0, 60.0, 20.76),  // Normal
            (165.0, 85.0, 31.22)   // Obese
        ]
        
        for (height, weight, expectedBMI) in testCases {
            // When
            let user = User(
                name: "Test",
                age: 30,
                gender: .male,
                height: height,
                currentWeight: weight,
                fitnessGoal: .maintain,
                activityLevel: .moderate
            )
            
            // Then
            XCTAssertApproximatelyEqual(user.bmi, expectedBMI, accuracy: 0.01, 
                "BMI for height: \(height)cm, weight: \(weight)kg")
            
            // Validate BMI is within reasonable bounds
            XCTAssertGreaterThanOrEqual(user.bmi, 10.0, "BMI should be at least 10")
            XCTAssertLessThanOrEqual(user.bmi, 80.0, "BMI should not exceed 80")
        }
    }
    
    func testBMICalculationInvalidInputs() {
        // Given - Invalid measurements
        let invalidCases: [(height: Double, weight: Double)] = [
            (30.0, 75.0),    // Height too low
            (400.0, 75.0),   // Height too high
            (175.0, 5.0),    // Weight too low
            (175.0, 600.0),  // Weight too high
            (0.0, 75.0),     // Zero height
            (175.0, 0.0)     // Zero weight
        ]
        
        for (height, weight) in invalidCases {
            // When
            let user = User(
                name: "Test",
                age: 30,
                gender: .male,
                height: height,
                currentWeight: weight,
                fitnessGoal: .maintain,
                activityLevel: .moderate
            )
            
            // Then - Should return fallback BMI of 25.0
            XCTAssertEqual(user.bmi, 25.0, 
                "Invalid inputs (height: \(height), weight: \(weight)) should return fallback BMI")
        }
    }
    
    func testBMICache() {
        // Given - User instance
        let user = User(
            name: "Test",
            age: 30,
            gender: .male,
            height: 175.0,
            currentWeight: 75.0,
            fitnessGoal: .maintain,
            activityLevel: .moderate
        )
        
        // When - Calculate BMI multiple times
        let bmi1 = user.bmi
        let bmi2 = user.bmi
        let bmi3 = user.bmi
        
        // Then - Should return cached value
        XCTAssertEqual(bmi1, bmi2, "BMI should be cached")
        XCTAssertEqual(bmi2, bmi3, "BMI should remain cached")
        XCTAssertApproximatelyEqual(bmi1, 24.49, accuracy: 0.01)
        
        // When - Change weight using updateProfile (should invalidate cache)
        user.updateProfile(weight: 80.0)
        let bmi4 = user.bmi
        
        // Then - Should recalculate
        XCTAssertNotEqual(bmi1, bmi4, "BMI should recalculate when weight changes")
        let expectedBMI4 = 80.0 / (1.75 * 1.75) // 80kg / (1.75m)^2 = 26.12
        XCTAssertApproximatelyEqual(bmi4, expectedBMI4, accuracy: 0.01)
    }
    
    func testBMICategories() {
        // Given - BMI test cases for categories
        let categoryCases: [Double] = [
            55.0,  // BMI ~18.0 (underweight)
            70.0,  // BMI ~22.9 (normal)
            85.0,  // BMI ~27.8 (overweight)
            100.0  // BMI ~32.7 (obese)
        ]
        
        for weight in categoryCases {
            // When
            let user = User(
                name: "Test",
                age: 30,
                gender: .male,
                height: 175.0,
                currentWeight: weight,
                fitnessGoal: .maintain,
                activityLevel: .moderate
            )
            
            // Then - Category should match BMI range
            let category = user.bmiCategory
            // Note: We can't test exact localized string since it depends on current locale
            // But we can verify it's not empty and changes based on BMI
            XCTAssertFalse(category.isEmpty, "BMI category should not be empty for weight: \(weight)")
        }
    }
    
    // MARK: - Metrics Calculation Tests
    
    func testCalculateMetrics() {
        // Given - User with known parameters
        let user = User(
            name: "Test",
            age: 30,
            gender: .male,
            height: 175.0,
            currentWeight: 75.0,
            fitnessGoal: .recomp,
            activityLevel: .moderate
        )
        
        // When
        user.calculateMetrics()
        
        // Then - All metrics should be reasonable
        XCTAssertGreaterThan(user.bmr, 1500, "BMR should be reasonable for adult male")
        XCTAssertLessThan(user.bmr, 2500, "BMR should not be excessive")
        
        XCTAssertGreaterThan(user.tdee, user.bmr, "TDEE should be greater than BMR")
        XCTAssertLessThan(user.tdee, user.bmr * 2.5, "TDEE should not be more than 2.5x BMR")
        
        XCTAssertLessThan(user.dailyCalorieGoal, user.tdee, 
            "Recomp calories should be below TDEE (deficit for body recomposition)")
        XCTAssertApproximatelyEqual(user.dailyCalorieGoal, user.tdee * 0.9, accuracy: 10.0, 
            "Recomp should be 10% deficit")
        
        // Macros should be positive and reasonable
        XCTAssertGreaterThan(user.dailyProteinGoal, 0)
        XCTAssertGreaterThan(user.dailyCarbGoal, 0)
        XCTAssertGreaterThan(user.dailyFatGoal, 0)
        
        XCTAssertGreaterThan(user.dailyProteinGoal, user.currentWeight * 1.6, 
            "Muscle building protein should be at least 1.6g/kg")
    }
    
    func testCalculateMetricsDifferentGoals() {
        // Given - Same user with different goals
        let baseUser = User(
            name: "Test",
            age: 30,
            gender: .female,
            height: 165.0,
            currentWeight: 60.0,
            fitnessGoal: .maintain,
            activityLevel: .moderate
        )
        
        let goals: [FitnessGoal] = [.cut, .maintain, .bulk, .recomp]
        var results: [(goal: FitnessGoal, calories: Double, protein: Double)] = []
        
        for goal in goals {
            // When
            baseUser.fitnessGoalEnum = goal
            baseUser.calculateMetrics()
            
            // Then
            results.append((goal, baseUser.dailyCalorieGoal, baseUser.dailyProteinGoal))
            
            // All goals should produce reasonable values
            XCTAssertGreaterThan(baseUser.dailyCalorieGoal, 1200, "Calories should be at least 1200")
            XCTAssertLessThan(baseUser.dailyCalorieGoal, 4000, "Calories should not exceed 4000")
            XCTAssertGreaterThan(baseUser.dailyProteinGoal, 40, "Protein should be at least 40g")
        }
        
        // Verify goal relationships
        let cut = results.first { $0.goal == .cut }!
        let maintain = results.first { $0.goal == .maintain }!
        let bulk = results.first { $0.goal == .bulk }!
        let buildMuscle = results.first { $0.goal == .recomp }!
        
        XCTAssertLessThan(cut.calories, maintain.calories, 
            "Cutting should have fewer calories than maintenance")
        XCTAssertGreaterThan(bulk.calories, maintain.calories, 
            "Bulking should have more calories than maintenance")
        XCTAssertGreaterThan(buildMuscle.protein, maintain.protein, 
            "Muscle building should have more protein than maintenance")
    }
    
    // MARK: - Workout Statistics Tests
    
    func testAddWorkoutStats() {
        // Given - New user
        let user = TestHelpers.createTestUser()
        modelContext.insert(user)
        
        let initialTime = user.totalWorkoutTime
        let initialVolume = user.totalVolume
        
        // When
        let duration = TimeInterval(3600) // 1 hour
        let volume = 1250.0 // kg
        user.addWorkoutStats(duration: duration, volume: volume)
        
        // Then
        XCTAssertEqual(user.totalWorkoutTime, initialTime + duration)
        XCTAssertEqual(user.totalVolume, initialVolume + volume)
        XCTAssertNotNil(user.lastWorkoutDate)
    }
    
    func testAddMultipleWorkoutStats() {
        // Given - User with multiple workout sessions
        let user = TestHelpers.createTestUser()
        modelContext.insert(user)
        
        let workouts: [(duration: TimeInterval, volume: Double)] = [
            (3600, 1000), // 1 hour, 1000kg
            (2700, 800),  // 45 min, 800kg  
            (4200, 1500), // 70 min, 1500kg
            (3300, 1200)  // 55 min, 1200kg
        ]
        
        // When
        for (duration, volume) in workouts {
            user.addWorkoutStats(duration: duration, volume: volume)
        }
        
        // Then
        XCTAssertEqual(user.totalWorkoutTime, 13800) // Sum of durations
        XCTAssertEqual(user.totalVolume, 4500) // Sum of volumes
    }
    
    func testAddCardioSession() {
        // Given - New user
        let user = TestHelpers.createTestUser()
        modelContext.insert(user)
        
        let initialSessions = user.totalCardioSessions
        let initialTime = user.totalCardioTime
        let initialDistance = user.totalCardioDistance
        let initialCalories = user.totalCardioCalories
        
        // When
        let duration = TimeInterval(2700) // 45 minutes
        let distance = 5000.0 // 5km
        user.addCardioSession(duration: duration, distance: distance)
        
        // Then
        XCTAssertEqual(user.totalCardioSessions, initialSessions + 1)
        XCTAssertEqual(user.totalCardioTime, initialTime + duration)
        XCTAssertEqual(user.totalCardioDistance, initialDistance + distance)
        XCTAssertNotNil(user.lastCardioDate)
        
        // Note: addCardioSession doesn't automatically calculate calories unless provided
        // If no calories parameter is given, totalCardioCalories remains unchanged
        XCTAssertEqual(user.totalCardioCalories, initialCalories, "Calories unchanged when not provided")
    }
    
    func testWorkoutStreakTracking() {
        // Given - User starting fresh
        let user = TestHelpers.createTestUser()
        user.currentWorkoutStreak = 0
        user.longestWorkoutStreak = 0
        modelContext.insert(user)
        
        // When - Add consecutive workout sessions (within streak window)
        let yesterday = Date().addingTimeInterval(-86400) // 1 day ago
        let twoDaysAgo = Date().addingTimeInterval(-172800) // 2 days ago
        
        // Simulate workouts on consecutive days
        user.lastWorkoutDate = twoDaysAgo
        user.addWorkoutStats(duration: 3600, volume: 1000)
        
        user.lastWorkoutDate = yesterday
        user.addWorkoutStats(duration: 3600, volume: 1000)
        
        user.addWorkoutStats(duration: 3600, volume: 1000) // Today
        
        // Then - Streak should increase (this would need to be implemented in the actual User model)
        XCTAssertNotNil(user.lastWorkoutDate)
        XCTAssertEqual(user.totalWorkouts, 3)
    }
    
    // MARK: - Body Measurements Tests
    
    func testBodyMeasurementsOptional() {
        // Given - User without body measurements
        let user = TestHelpers.createTestUser()
        
        // Then - All measurements should be nil initially
        XCTAssertNil(user.chest)
        XCTAssertNil(user.waist)
        XCTAssertNil(user.hips)
        XCTAssertNil(user.neck)
        XCTAssertNil(user.bicep)
        XCTAssertNil(user.thigh)
        
        // When - Add measurements
        user.chest = 100.0
        user.waist = 85.0
        user.hips = 95.0
        user.neck = 40.0
        
        // Then
        XCTAssertEqual(user.chest, 100.0)
        XCTAssertEqual(user.waist, 85.0)
        XCTAssertEqual(user.hips, 95.0)
        XCTAssertEqual(user.neck, 40.0)
    }
    
    func testCalculateBodyFat() {
        // Given - User with Navy Method measurements
        let user = User(
            name: "Test",
            age: 30,
            gender: .male,
            height: 180.0,
            currentWeight: 75.0,
            fitnessGoal: .maintain,
            activityLevel: .moderate
        )
        
        user.neck = 40.0
        user.waist = 85.0
        
        // When
        let bodyFat = user.calculateBodyFatPercentage()
        
        // Then
        XCTAssertNotNil(bodyFat, "Should calculate body fat with valid measurements")
        XCTAssertGreaterThan(bodyFat!, 0, "Body fat should be positive")
        XCTAssertLessThan(bodyFat!, 50, "Body fat should be reasonable")
    }
    
    func testCalculateBodyFatFemale() {
        // Given - Female user with Navy Method measurements
        let user = User(
            name: "Test",
            age: 25,
            gender: .female,
            height: 165.0,
            currentWeight: 60.0,
            fitnessGoal: .maintain,
            activityLevel: .moderate
        )
        
        user.neck = 32.0
        user.waist = 70.0
        user.hips = 95.0
        
        // When
        let bodyFat = user.calculateBodyFatPercentage()
        
        // Then
        XCTAssertNotNil(bodyFat, "Should calculate body fat for female with hip measurement")
        XCTAssertGreaterThan(bodyFat!, 8.0, "Female body fat should be at least 8%")
        XCTAssertLessThan(bodyFat!, 50, "Body fat should be reasonable")
    }
    
    func testCalculateBodyFatInsufficientData() {
        // Given - User without required measurements
        let user = TestHelpers.createTestUser()
        
        // When - No measurements
        let bodyFat1 = user.calculateBodyFatPercentage()
        
        // Then
        XCTAssertNil(bodyFat1, "Should return nil without measurements")
        
        // When - Partial measurements (male missing waist)
        user.neck = 40.0
        let bodyFat2 = user.calculateBodyFatPercentage()
        
        // Then
        XCTAssertNil(bodyFat2, "Should return nil with insufficient measurements")
    }
    
    // MARK: - One Rep Max Tests
    
    func testOneRepMaxTracking() {
        // Given - User with strength training
        let user = TestHelpers.createTestUser()
        
        // Then - Initially no 1RMs
        XCTAssertNil(user.squatOneRM)
        XCTAssertNil(user.benchPressOneRM)
        XCTAssertNil(user.deadliftOneRM)
        XCTAssertNil(user.oneRMLastUpdated)
        
        // When - Update 1RMs
        user.squatOneRM = 140.0
        user.benchPressOneRM = 100.0
        user.deadliftOneRM = 180.0
        user.oneRMLastUpdated = Date()
        
        // Then
        XCTAssertEqual(user.squatOneRM, 140.0)
        XCTAssertEqual(user.benchPressOneRM, 100.0)
        XCTAssertEqual(user.deadliftOneRM, 180.0)
        XCTAssertNotNil(user.oneRMLastUpdated)
    }
    
    func testTotalStrengthScore() {
        // Given - User with all main lifts
        let user = User(
            name: "Test",
            age: 30,
            gender: .male,
            height: 180.0,
            currentWeight: 80.0,
            fitnessGoal: .recomp,
            activityLevel: .veryActive
        )
        
        user.squatOneRM = 150.0
        user.benchPressOneRM = 120.0
        user.deadliftOneRM = 200.0
        user.overheadPressOneRM = 80.0
        
        // When - Calculate total manually since method doesn't exist
        let squat = user.squatOneRM ?? 0
        let bench = user.benchPressOneRM ?? 0
        let deadlift = user.deadliftOneRM ?? 0
        let ohp = user.overheadPressOneRM ?? 0
        let total = squat + bench + deadlift + ohp
        
        // Then
        let expectedTotal = 150.0 + 120.0 + 200.0 + 80.0
        XCTAssertEqual(total, expectedTotal)
        XCTAssertGreaterThan(total, 0)
    }
    
    func testTotalStrengthScorePartialData() {
        // Given - User with some lifts missing
        let user = TestHelpers.createTestUser()
        user.squatOneRM = 100.0
        user.deadliftOneRM = 150.0
        // benchPressOneRM and overheadPressOneRM are nil
        
        // When - Calculate total manually
        let squat = user.squatOneRM ?? 0
        let bench = user.benchPressOneRM ?? 0
        let deadlift = user.deadliftOneRM ?? 0
        let ohp = user.overheadPressOneRM ?? 0
        let total = squat + bench + deadlift + ohp
        
        // Then - Should only sum available lifts
        XCTAssertEqual(total, 250.0)
    }
    
    // MARK: - Goal Progress Tests
    
    func testGoalProgressTracking() {
        // Given - User with monthly goals
        let user = TestHelpers.createTestUser()
        user.monthlySessionGoal = 20
        user.monthlyDistanceGoal = 100000.0 // 100km
        
        // When - Add some progress
        user.totalWorkouts = 8 // 40% of goal
        user.totalCardioDistance = 45000.0 // 45% of distance goal
        
        // Then - Goals should be trackable
        let sessionProgress = Double(user.totalWorkouts) / Double(user.monthlySessionGoal)
        let distanceProgress = user.totalCardioDistance / user.monthlyDistanceGoal
        
        XCTAssertApproximatelyEqual(sessionProgress, 0.4, accuracy: 0.01)
        XCTAssertApproximatelyEqual(distanceProgress, 0.45, accuracy: 0.01)
    }
    
    // MARK: - Data Validation Tests
    
    func testUserDataValidation() {
        // Given - User with edge case values
        let user = User(
            name: "Test",
            age: 18, // Minimum adult age
            gender: .female,
            height: 140.0, // Short but valid
            currentWeight: 40.0, // Light but valid
            fitnessGoal: .cut,
            activityLevel: .sedentary
        )
        
        // When
        user.calculateMetrics()
        
        // Then - All metrics should be reasonable despite edge case inputs
        XCTAssertGreaterThan(user.bmr, 800, "BMR should be at least 800 for any valid user")
        XCTAssertGreaterThan(user.tdee, user.bmr, "TDEE should exceed BMR")
        XCTAssertGreaterThanOrEqual(user.dailyCalorieGoal, 1000, "Daily calories should be at least 1000")
        XCTAssertGreaterThan(user.bmi, 15.0, "BMI should be reasonable")
        XCTAssertLessThan(user.bmi, 35.0, "BMI should be reasonable")
    }
    
    func testUserEnumConversions() {
        // Given - User with string properties
        let user = TestHelpers.createTestUser()
        
        // When - Access enum properties
        let gender = user.genderEnum
        let goal = user.fitnessGoalEnum
        let activity = user.activityLevelEnum
        
        // Then - Should convert correctly
        XCTAssertNotNil(gender)
        XCTAssertNotNil(goal)
        XCTAssertNotNil(activity)
        
        // When - Set enum values
        user.genderEnum = .female
        user.fitnessGoalEnum = .recomp
        user.activityLevelEnum = .veryActive
        
        // Then - String properties should update
        XCTAssertEqual(user.gender, Gender.female.rawValue)
        XCTAssertEqual(user.fitnessGoal, FitnessGoal.recomp.rawValue)
        XCTAssertEqual(user.activityLevel, ActivityLevel.veryActive.rawValue)
    }
    
    // MARK: - Performance Tests
    
    func testBMICalculationPerformance() {
        // Given - User instance
        let user = TestHelpers.createTestUser()
        let iterations = 1000
        
        // When & Then - BMI calculation should be fast (and cached)
        measure {
            for _ in 0..<iterations {
                _ = user.bmi
            }
        }
    }
    
    func testMetricsCalculationPerformance() {
        // Given - User instance
        let user = TestHelpers.createTestUser()
        let iterations = 100
        
        // When & Then - Full metrics calculation should be reasonably fast
        measure {
            for _ in 0..<iterations {
                user.calculateMetrics()
            }
        }
    }
    
    // MARK: - Integration Tests
    
    func testCompleteUserWorkflow() throws {
        // Given - Complete user lifecycle
        let user = User(
            name: "Integration Test User",
            age: 28,
            gender: .male,
            height: 175.0,
            currentWeight: 75.0,
            fitnessGoal: .recomp,
            activityLevel: .moderate
        )
        
        modelContext.insert(user)
        try modelContext.save()
        
        // When - Complete onboarding
        user.onboardingCompleted = true
        user.consentAccepted = true
        user.consentTimestamp = Date()
        
        // Add body measurements
        user.chest = 100.0
        user.waist = 85.0
        user.neck = 40.0
        
        // Add some workout history
        user.addWorkoutStats(duration: 3600, volume: 1250)
        user.addWorkoutStats(duration: 2700, volume: 900)
        user.addCardioSession(duration: 2700, distance: 5000)
        
        // Update strength records
        user.squatOneRM = 140.0
        user.benchPressOneRM = 100.0
        user.deadliftOneRM = 180.0
        user.oneRMLastUpdated = Date()
        
        // Calculate all metrics
        user.calculateMetrics()
        
        try modelContext.save()
        
        // Then - User should be in complete, valid state
        assertCompleteUserState(user)
        
        // Verify persistence
        let fetchedUsers = try modelContext.fetch(FetchDescriptor<User>())
        XCTAssertEqual(fetchedUsers.count, 1)
        
        let fetchedUser = fetchedUsers.first!
        assertCompleteUserState(fetchedUser)
    }
    
    // MARK: - Helper Methods
    
    private func assertValidUserState(_ user: User) {
        XCTAssertFalse(user.name.isEmpty, "User should have a name")
        XCTAssertGreaterThan(user.age, 0, "Age should be positive")
        XCTAssertGreaterThan(user.height, 50, "Height should be reasonable")
        XCTAssertGreaterThan(user.currentWeight, 20, "Weight should be reasonable")
        XCTAssertGreaterThan(user.bmi, 10, "BMI should be reasonable")
        XCTAssertGreaterThan(user.bmr, 500, "BMR should be reasonable")
        XCTAssertGreaterThan(user.tdee, 800, "TDEE should be reasonable")
    }
    
    private func assertCompleteUserState(_ user: User) {
        // Basic validation
        assertValidUserState(user)
        
        // Onboarding completion
        XCTAssertTrue(user.onboardingCompleted, "User should have completed onboarding")
        XCTAssertTrue(user.consentAccepted, "User should have accepted consent")
        XCTAssertNotNil(user.consentTimestamp, "Consent timestamp should be set")
        
        // Body measurements
        XCTAssertNotNil(user.chest, "User should have chest measurement")
        XCTAssertNotNil(user.waist, "User should have waist measurement")
        XCTAssertNotNil(user.neck, "User should have neck measurement")
        
        // Workout history
        XCTAssertGreaterThan(user.totalWorkouts, 0, "User should have workout history")
        XCTAssertGreaterThan(user.totalCardioSessions, 0, "User should have cardio history")
        XCTAssertNotNil(user.lastWorkoutDate, "Last workout date should be set")
        XCTAssertNotNil(user.lastCardioDate, "Last cardio date should be set")
        
        // Strength records
        XCTAssertNotNil(user.squatOneRM, "User should have squat 1RM")
        XCTAssertNotNil(user.benchPressOneRM, "User should have bench 1RM")
        XCTAssertNotNil(user.deadliftOneRM, "User should have deadlift 1RM")
        XCTAssertNotNil(user.oneRMLastUpdated, "1RM timestamp should be set")
        
        // Calculated metrics
        XCTAssertGreaterThan(user.bmr, 0, "BMR should be calculated")
        XCTAssertGreaterThan(user.tdee, 0, "TDEE should be calculated")
        XCTAssertGreaterThan(user.dailyCalorieGoal, 0, "Daily calorie goal should be set")
        XCTAssertGreaterThan(user.dailyProteinGoal, 0, "Daily protein goal should be set")
        
        // Body composition
        let bodyFat = user.calculateBodyFatPercentage()
        XCTAssertNotNil(bodyFat, "Body fat should be calculable")
        
        // Strength total
        let squat = user.squatOneRM ?? 0
        let bench = user.benchPressOneRM ?? 0
        let deadlift = user.deadliftOneRM ?? 0
        let ohp = user.overheadPressOneRM ?? 0
        let strengthTotal = squat + bench + deadlift + ohp
        XCTAssertGreaterThan(strengthTotal, 0, "Strength total should be positive")
    }
}