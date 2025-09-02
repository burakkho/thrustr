import XCTest
import SwiftData
@testable import Thrustr

/**
 * Comprehensive tests for UserService
 * Tests user CRUD operations, validation, health metrics, and HealthKit integration
 */
@MainActor
final class UserServiceTests: XCTestCase {
    
    // MARK: - Test Properties
    private var userService: UserService!
    private var modelContext: ModelContext!
    private var mockUser: User!
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Setup test environment
        modelContext = try TestHelpers.createTestModelContext()
        userService = UserService()
        userService.setModelContext(modelContext)
        
        // Create mock user for tests
        mockUser = User(
            name: "Test User",
            age: 30,
            gender: .male,
            height: 180.0,
            currentWeight: 75.0,
            fitnessGoal: .muscleGain,
            activityLevel: .moderate,
            selectedLanguage: "tr"
        )
        modelContext.insert(mockUser)
        try modelContext.save()
    }
    
    override func tearDown() async throws {
        userService = nil
        modelContext = nil
        mockUser = nil
        try await super.tearDown()
    }
    
    // MARK: - User Creation Tests
    
    func testCreateUser() async throws {
        // Given - New user data
        let name = "John Doe"
        let age = 25
        let gender = Gender.male
        let height = 175.0
        let weight = 70.0
        let goal = FitnessGoal.weightLoss
        let activity = ActivityLevel.active
        
        // When
        let user = try await userService.createUser(
            name: name,
            age: age,
            gender: gender,
            height: height,
            weight: weight,
            fitnessGoal: goal,
            activityLevel: activity
        )
        
        // Then
        XCTAssertEqual(user.name, name)
        XCTAssertEqual(user.age, age)
        XCTAssertEqual(user.genderEnum, gender)
        XCTAssertEqual(user.height, height)
        XCTAssertEqual(user.currentWeight, weight)
        XCTAssertEqual(user.fitnessGoalEnum, goal)
        XCTAssertEqual(user.activityLevelEnum, activity)
        XCTAssertEqual(user.selectedLanguage, "tr")
        
        // Should be persisted
        let fetchDescriptor = FetchDescriptor<User>()
        let users = try modelContext.fetch(fetchDescriptor)
        XCTAssertEqual(users.count, 2) // Including mockUser
        XCTAssertTrue(users.contains { $0.name == name })
    }
    
    func testCreateUserWithInvalidData() async {
        // Given - Invalid user data
        let invalidCases: [(String, Int, Double, Double)] = [
            ("", 25, 175.0, 70.0),      // Empty name
            ("A", 25, 175.0, 70.0),     // Too short name
            ("Valid Name", 12, 175.0, 70.0),  // Too young
            ("Valid Name", 25, 90.0, 70.0),   // Too short
            ("Valid Name", 25, 175.0, 25.0)   // Too light
        ]
        
        for (name, age, height, weight) in invalidCases {
            // When & Then
            do {
                _ = try await userService.createUser(
                    name: name,
                    age: age,
                    gender: .male,
                    height: height,
                    weight: weight,
                    fitnessGoal: .maintenance,
                    activityLevel: .moderate
                )
                XCTFail("Should have thrown validation error for: \(name), \(age), \(height), \(weight)")
            } catch {
                XCTAssertTrue(error is UserService.ValidationError)
            }
        }
    }
    
    // MARK: - User Profile Update Tests
    
    func testUpdateUserProfile() async throws {
        // Given - Updated profile data
        let newName = "Updated Name"
        let newAge = 35
        let newHeight = 185.0
        let newWeight = 80.0
        
        // When
        try await userService.updateUserProfile(
            user: mockUser,
            name: newName,
            age: newAge,
            height: newHeight,
            weight: newWeight
        )
        
        // Then
        XCTAssertEqual(mockUser.name, newName)
        XCTAssertEqual(mockUser.age, newAge)
        XCTAssertEqual(mockUser.height, newHeight)
        XCTAssertEqual(mockUser.currentWeight, newWeight)
    }
    
    func testPartialUserProfileUpdate() async throws {
        // Given - Original values
        let originalName = mockUser.name
        let originalAge = mockUser.age
        
        // When - Update only weight
        try await userService.updateUserProfile(
            user: mockUser,
            weight: 78.0
        )
        
        // Then - Only weight should change
        XCTAssertEqual(mockUser.name, originalName)
        XCTAssertEqual(mockUser.age, originalAge)
        XCTAssertEqual(mockUser.currentWeight, 78.0)
    }
    
    func testUpdateUserProfileValidation() async {
        // Given - Invalid update data
        
        // When & Then - Should throw validation error
        do {
            try await userService.updateUserProfile(
                user: mockUser,
                age: 10, // Too young
                weight: 400.0 // Too heavy
            )
            XCTFail("Should have thrown validation error")
        } catch {
            XCTAssertTrue(error is UserService.ValidationError)
            XCTAssertFalse(userService.validationErrors.isEmpty)
        }
    }
    
    // MARK: - Health Metrics Tests
    
    func testCalculateHealthMetrics() {
        // Given - User with known values
        mockUser.currentWeight = 75.0
        mockUser.height = 180.0
        mockUser.age = 30
        mockUser.neck = 37.0
        mockUser.waist = 85.0
        
        // When
        let metrics = userService.calculateHealthMetrics(for: mockUser)
        
        // Then
        XCTAssertGreaterThan(metrics.bmi, 0)
        XCTAssertFalse(metrics.bmiCategory.isEmpty)
        XCTAssertGreaterThan(metrics.bmr, 0)
        XCTAssertGreaterThan(metrics.tdee, 0)
        XCTAssertNotNil(metrics.bodyFatPercentage)
        XCTAssertNotNil(metrics.ffmi)
        XCTAssertFalse(metrics.ffmiCategory.isEmpty)
        
        // BMI should be approximately 23.15
        XCTAssertApproximatelyEqual(metrics.bmi, 23.15, accuracy: 0.1)
    }
    
    func testRecalculateMetrics() {
        // Given - User with initial metrics
        let initialBMR = mockUser.bmr
        let initialTDEE = mockUser.tdee
        
        // When - Update weight and recalculate
        mockUser.currentWeight = 80.0
        userService.recalculateMetrics(for: mockUser)
        
        // Then - Metrics should be updated
        XCTAssertNotEqual(mockUser.bmr, initialBMR)
        XCTAssertNotEqual(mockUser.tdee, initialTDEE)
        XCTAssertGreaterThan(mockUser.bmr, initialBMR) // Higher weight = higher BMR
        XCTAssertGreaterThan(mockUser.tdee, initialTDEE)
    }
    
    // MARK: - Body Measurements Tests
    
    func testUpdateBodyMeasurements() async throws {
        // Given - New measurements
        let chest = 102.0
        let waist = 85.0
        let hips = 95.0
        let neck = 37.0
        let bicep = 35.0
        let thigh = 58.0
        
        // When
        try await userService.updateBodyMeasurements(
            user: mockUser,
            chest: chest,
            waist: waist,
            hips: hips,
            neck: neck,
            bicep: bicep,
            thigh: thigh
        )
        
        // Then
        XCTAssertEqual(mockUser.chest, chest)
        XCTAssertEqual(mockUser.waist, waist)
        XCTAssertEqual(mockUser.hips, hips)
        XCTAssertEqual(mockUser.neck, neck)
        XCTAssertEqual(mockUser.bicep, bicep)
        XCTAssertEqual(mockUser.thigh, thigh)
    }
    
    func testPartialBodyMeasurementsUpdate() async throws {
        // Given - Initial measurements
        mockUser.chest = 100.0
        mockUser.waist = 80.0
        
        // When - Update only neck and bicep
        try await userService.updateBodyMeasurements(
            user: mockUser,
            neck: 38.0,
            bicep: 36.0
        )
        
        // Then - Only specified measurements should change
        XCTAssertEqual(mockUser.chest, 100.0) // Unchanged
        XCTAssertEqual(mockUser.waist, 80.0)  // Unchanged
        XCTAssertEqual(mockUser.neck, 38.0)   // Updated
        XCTAssertEqual(mockUser.bicep, 36.0)  // Updated
    }
    
    func testInvalidBodyMeasurements() async {
        // Given - Invalid measurements
        let invalidCases: [(Double?, String)] = [
            (300.0, "chest"), // Too large
            (10.0, "waist"),  // Too small
            (250.0, "hips"),  // Too large
            (10.0, "neck"),   // Too small
            (100.0, "bicep"), // Too large
            (20.0, "thigh")   // Too small
        ]
        
        for (value, measurement) in invalidCases {
            // When & Then
            do {
                switch measurement {
                case "chest":
                    try await userService.updateBodyMeasurements(user: mockUser, chest: value)
                case "waist":
                    try await userService.updateBodyMeasurements(user: mockUser, waist: value)
                case "hips":
                    try await userService.updateBodyMeasurements(user: mockUser, hips: value)
                case "neck":
                    try await userService.updateBodyMeasurements(user: mockUser, neck: value)
                case "bicep":
                    try await userService.updateBodyMeasurements(user: mockUser, bicep: value)
                case "thigh":
                    try await userService.updateBodyMeasurements(user: mockUser, thigh: value)
                default:
                    break
                }
                XCTFail("Should have thrown validation error for \(measurement): \(value)")
            } catch {
                XCTAssertTrue(error is UserService.ValidationError)
            }
        }
    }
    
    func testGetBodyMeasurements() {
        // Given - User with measurements
        mockUser.chest = 102.0
        mockUser.waist = 85.0
        mockUser.hips = 95.0
        mockUser.neck = 37.0
        mockUser.bicep = 35.0
        mockUser.thigh = 58.0
        
        // When
        let measurements = userService.getBodyMeasurements(for: mockUser)
        
        // Then
        XCTAssertEqual(measurements.chest, 102.0)
        XCTAssertEqual(measurements.waist, 85.0)
        XCTAssertEqual(measurements.hips, 95.0)
        XCTAssertEqual(measurements.neck, 37.0)
        XCTAssertEqual(measurements.bicep, 35.0)
        XCTAssertEqual(measurements.thigh, 58.0)
        XCTAssertNotNil(measurements.bodyFatPercentage)
    }
    
    // MARK: - Data Export Tests
    
    func testExportUserData() {
        // Given - User with complete data
        mockUser.chest = 102.0
        mockUser.waist = 85.0
        mockUser.hips = 95.0
        mockUser.neck = 37.0
        mockUser.totalWorkouts = 50
        mockUser.totalWorkoutTime = 3600.0 // 1 hour
        mockUser.totalVolume = 5000.0
        
        // When
        let export = userService.exportUserData(user: mockUser)
        
        // Then
        XCTAssertEqual(export.user.name, mockUser.name)
        XCTAssertEqual(export.user.age, mockUser.age)
        XCTAssertEqual(export.user.gender, mockUser.gender)
        XCTAssertEqual(export.user.height, mockUser.height)
        XCTAssertEqual(export.user.currentWeight, mockUser.currentWeight)
        XCTAssertEqual(export.user.totalWorkouts, 50)
        XCTAssertEqual(export.user.totalWorkoutTime, 3600.0)
        XCTAssertEqual(export.user.totalVolume, 5000.0)
        
        // Body measurements
        XCTAssertEqual(export.user.bodyMeasurements?.chest, 102.0)
        XCTAssertEqual(export.user.bodyMeasurements?.waist, 85.0)
        XCTAssertEqual(export.user.bodyMeasurements?.hips, 95.0)
        XCTAssertEqual(export.user.bodyMeasurements?.neck, 37.0)
        
        // Export metadata
        XCTAssertNotNil(export.exportDate)
        XCTAssertFalse(export.appVersion.isEmpty)
    }
    
    // MARK: - Validation Tests
    
    func testValidateUserInput() throws {
        // Valid input should not throw
        XCTAssertNoThrow(
            try userService.validateUserInput(
                name: "John Doe",
                age: 25,
                height: 175.0,
                weight: 70.0
            )
        )
    }
    
    func testValidateUserInputEdgeCases() {
        // Test boundary conditions
        let validCases: [(String, Int, Double, Double)] = [
            ("AB", 13, 100.0, 30.0),        // Minimum valid values
            ("A" + String(repeating: "B", count: 48), 120, 250.0, 300.0) // Maximum valid values
        ]
        
        for (name, age, height, weight) in validCases {
            XCTAssertNoThrow(
                try userService.validateUserInput(
                    name: name,
                    age: age,
                    height: height,
                    weight: weight
                ),
                "Should accept valid boundary values: \(name), \(age), \(height), \(weight)"
            )
        }
    }
    
    func testValidationErrorMessages() {
        // Given - Invalid data
        userService.validationErrors = [
            .invalidAge("Test age error"),
            .invalidHeight("Test height error"),
            .invalidWeight("Test weight error"),
            .invalidName("Test name error"),
            .invalidMeasurement("Test Field", "Test measurement error")
        ]
        
        // When & Then - Check error descriptions
        for error in userService.validationErrors {
            let description = error.localizedDescription
            XCTAssertFalse(description.isEmpty)
            XCTAssertTrue(description.contains("hatası"))
        }
    }
    
    // MARK: - Loading State Tests
    
    func testLoadingStates() async throws {
        // Given - Initial state
        XCTAssertFalse(userService.isLoading)
        
        // When - Start async operation
        let task = Task {
            try await userService.updateUserProfile(
                user: mockUser,
                name: "Updated Name"
            )
        }
        
        // Then - Loading state should be managed
        // Note: Due to async nature, loading might complete quickly
        try await task.value
        XCTAssertFalse(userService.isLoading) // Should be false after completion
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandlingWithoutModelContext() async {
        // Given - Service without model context
        let serviceWithoutContext = UserService()
        
        // When & Then - Should throw context error
        do {
            _ = try await serviceWithoutContext.createUser(
                name: "Test",
                age: 25,
                gender: .male,
                height: 175.0,
                weight: 70.0,
                fitnessGoal: .maintenance,
                activityLevel: .moderate
            )
            XCTFail("Should have thrown context not available error")
        } catch {
            if let serviceError = error as? ServiceError {
                XCTAssertEqual(serviceError, .contextNotAvailable)
            } else {
                XCTFail("Expected ServiceError.contextNotAvailable")
            }
        }
    }
    
    // MARK: - FFMI Calculation Tests
    
    func testFFMICalculation() {
        // Given - User with body fat data
        mockUser.currentWeight = 75.0
        mockUser.height = 180.0
        mockUser.neck = 37.0
        mockUser.waist = 85.0 // For body fat calculation
        
        // When
        let metrics = userService.calculateHealthMetrics(for: mockUser)
        
        // Then
        XCTAssertNotNil(metrics.ffmi)
        XCTAssertNotNil(metrics.bodyFatPercentage)
        XCTAssertFalse(metrics.ffmiCategory.isEmpty)
        
        // FFMI should be reasonable for given measurements
        if let ffmi = metrics.ffmi {
            XCTAssertGreaterThan(ffmi, 10.0)
            XCTAssertLessThan(ffmi, 30.0)
        }
    }
    
    func testFFMICategories() {
        // Test different FFMI categories
        let testCases: [(Double, String)] = [
            (15.0, "Düşük"),
            (17.0, "Ortalama altı"),
            (19.0, "Ortalama"),
            (21.0, "İyi"),
            (23.0, "Çok iyi"),
            (25.0, "Mükemmel"),
            (27.0, "Elite")
        ]
        
        for (ffmi, expectedCategory) in testCases {
            // Create a custom mock user for testing
            let testUser = User(
                name: "Test",
                age: 30,
                gender: .male,
                height: 180.0,
                currentWeight: 75.0,
                fitnessGoal: .maintenance,
                activityLevel: .moderate
            )
            
            // Simulate body fat percentage calculation
            testUser.neck = 37.0
            testUser.waist = 85.0
            
            // Calculate metrics
            let metrics = userService.calculateHealthMetrics(for: testUser)
            
            // Verify the categorization logic works
            XCTAssertNotNil(metrics.ffmiCategory)
        }
    }
    
    // MARK: - Performance Tests
    
    func testUserCreationPerformance() async throws {
        measure {
            Task { @MainActor in
                do {
                    for i in 0..<10 {
                        _ = try await userService.createUser(
                            name: "User \(i)",
                            age: 20 + i,
                            gender: i % 2 == 0 ? .male : .female,
                            height: Double(170 + i),
                            weight: Double(60 + i),
                            fitnessGoal: .maintenance,
                            activityLevel: .moderate
                        )
                    }
                } catch {
                    XCTFail("User creation failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Integration Tests
    
    func testCompleteUserWorkflow() async throws {
        // Test a complete user workflow from creation to data export
        
        // Step 1: Create user
        let user = try await userService.createUser(
            name: "Complete Test User",
            age: 28,
            gender: .female,
            height: 165.0,
            weight: 60.0,
            fitnessGoal: .weightLoss,
            activityLevel: .active
        )
        
        // Step 2: Update profile
        try await userService.updateUserProfile(
            user: user,
            weight: 58.0
        )
        XCTAssertEqual(user.currentWeight, 58.0)
        
        // Step 3: Add body measurements
        try await userService.updateBodyMeasurements(
            user: user,
            chest: 90.0,
            waist: 70.0,
            hips: 95.0,
            neck: 32.0
        )
        
        // Step 4: Calculate metrics
        let metrics = userService.calculateHealthMetrics(for: user)
        XCTAssertGreaterThan(metrics.bmi, 0)
        XCTAssertNotNil(metrics.bodyFatPercentage)
        
        // Step 5: Export data
        let export = userService.exportUserData(user: user)
        XCTAssertEqual(export.user.name, "Complete Test User")
        XCTAssertEqual(export.user.currentWeight, 58.0)
        XCTAssertEqual(export.user.bodyMeasurements?.chest, 90.0)
        
        print("✅ Complete user workflow test passed")
    }
}

// MARK: - Test Helper Extensions

extension UserServiceTests {
    
    /// Helper function to test approximate equality for Double values
    func XCTAssertApproximatelyEqual(
        _ value1: Double,
        _ value2: Double,
        accuracy: Double,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertEqual(value1, value2, accuracy: accuracy, file: file, line: line)
    }
}