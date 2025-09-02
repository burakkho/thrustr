import XCTest
import SwiftData
@testable import Thrustr

/**
 * Comprehensive tests for StrengthTest and StrengthTestResult models
 * Tests strength test workflow, scoring calculations, and user integration
 */
@MainActor
final class StrengthTestTests: XCTestCase {
    
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
    
    // MARK: - StrengthTest Initialization Tests
    
    func testStrengthTestInitialization() {
        // Given - Strength test parameters
        let userAge = 30
        let userGender = Gender.male
        let userWeight = 75.0
        let environment = "gym"
        let notes = "First strength test"
        
        // When
        let strengthTest = StrengthTest(
            userAge: userAge,
            userGender: userGender,
            userWeight: userWeight,
            testEnvironment: environment,
            notes: notes
        )
        
        // Then - Basic properties
        XCTAssertEqual(strengthTest.userAge, userAge)
        XCTAssertEqual(strengthTest.userGenderEnum, userGender)
        XCTAssertEqual(strengthTest.userWeight, userWeight)
        XCTAssertEqual(strengthTest.testEnvironment, environment)
        XCTAssertEqual(strengthTest.notes, notes)
        
        // Then - Initial state
        XCTAssertFalse(strengthTest.isCompleted, "Test should not be completed initially")
        XCTAssertEqual(strengthTest.overallScore, 0.0, "Initial score should be 0")
        XCTAssertEqual(strengthTest.strengthProfile, "unknown", "Initial profile should be unknown")
        XCTAssertEqual(strengthTest.testDuration, 0, "Initial duration should be 0")
        XCTAssertEqual(strengthTest.results.count, 0, "Should have no results initially")
        XCTAssertFalse(strengthTest.wasNewOverallPR, "Should not be PR initially")
        XCTAssertNotNil(strengthTest.testDate)
    }
    
    func testStrengthTestMinimalInitialization() {
        // Given - Minimal parameters
        let strengthTest = StrengthTest(
            userAge: 25,
            userGender: .female,
            userWeight: 60.0
        )
        
        // Then
        XCTAssertEqual(strengthTest.userAge, 25)
        XCTAssertEqual(strengthTest.userGenderEnum, .female)
        XCTAssertEqual(strengthTest.userWeight, 60.0)
        XCTAssertNil(strengthTest.testEnvironment)
        XCTAssertNil(strengthTest.notes)
    }
    
    // MARK: - StrengthTestResult Tests
    
    func testStrengthTestResultInitialization() {
        // Given - Result parameters
        let exerciseType = StrengthExerciseType.benchPress
        let value = 100.0
        let strengthLevel = StrengthLevel.intermediate
        let percentileScore = 0.65
        let notes = "Good form"
        
        // When
        let result = StrengthTestResult(
            exerciseType: exerciseType,
            value: value,
            strengthLevel: strengthLevel,
            percentileScore: percentileScore,
            notes: notes,
            isPersonalRecord: true
        )
        
        // Then
        XCTAssertEqual(result.exerciseTypeEnum, exerciseType)
        XCTAssertEqual(result.value, value)
        XCTAssertEqual(result.strengthLevelEnum, strengthLevel)
        XCTAssertEqual(result.percentileScore, percentileScore)
        XCTAssertEqual(result.notes, notes)
        XCTAssertTrue(result.isPersonalRecord)
        XCTAssertFalse(result.isWeighted)
        XCTAssertNil(result.additionalWeight)
    }
    
    func testStrengthTestResultValidation() {
        // Given - Invalid input values
        let result = StrengthTestResult(
            exerciseType: .deadlift,
            value: -50.0, // Invalid negative value
            strengthLevel: StrengthLevel(rawValue: 10) ?? .elite, // Invalid level
            percentileScore: 2.0 // Invalid percentile > 1.0
        )
        
        // Then - Should sanitize values
        XCTAssertEqual(result.value, 0.0, "Negative value should be clamped to 0")
        XCTAssertEqual(result.strengthLevelEnum, .elite, "Invalid level should be clamped to elite")
        XCTAssertEqual(result.percentileScore, 1.0, "Percentile > 1.0 should be clamped to 1.0")
    }
    
    func testStrengthTestResultDisplayForWeights() {
        // Given - Weight-based exercise result
        let result = StrengthTestResult(
            exerciseType: .benchPress,
            value: 120.5
        )
        
        // When
        let displayValue = result.displayValue
        
        // Then - Should format to 1 decimal place
        XCTAssertTrue(displayValue.contains("120.5"), "Should show decimal for weight")
        XCTAssertTrue(displayValue.contains("strength.unit.kg".localized), "Should show kg unit")
    }
    
    func testStrengthTestResultDisplayForReps() {
        // Given - Repetition-based exercise result (pull-ups)
        let result = StrengthTestResult(
            exerciseType: .pullUp,
            value: 12.0
        )
        
        // When
        let displayValue = result.displayValue
        
        // Then - Should format to 0 decimal places
        XCTAssertTrue(displayValue.contains("12"), "Should show integer for reps")
        XCTAssertFalse(displayValue.contains("12.0"), "Should not show decimal for reps")
        XCTAssertTrue(displayValue.contains("strength.unit.reps".localized), "Should show reps unit")
    }
    
    func testWeightedPullUpCalculation() {
        // Given - Weighted pull-up result
        let bodyWeight = 80.0
        let additionalWeight = 20.0
        let reps = 8.0
        
        let result = StrengthTestResult(
            exerciseType: .pullUp,
            value: reps,
            isWeighted: true,
            additionalWeight: additionalWeight,
            bodyWeightAtTest: bodyWeight
        )
        
        // When
        let effectiveWeight = result.effectiveWeight
        
        // Then - Should calculate weighted pull-up equivalent
        let expected = (bodyWeight + additionalWeight) * reps / bodyWeight // (100 * 8) / 80 = 10
        XCTAssertEqual(effectiveWeight, expected, "Weighted pull-up calculation should be correct")
    }
    
    // MARK: - Test Result Addition and Management
    
    func testAddSingleResult() {
        // Given - Strength test and result
        let strengthTest = StrengthTest(
            userAge: 30,
            userGender: .male,
            userWeight: 80.0
        )
        
        let benchResult = StrengthTestResult(
            exerciseType: .benchPress,
            value: 100.0,
            strengthLevel: .intermediate,
            percentileScore: 0.6
        )
        
        // When
        strengthTest.addResult(benchResult)
        
        // Then
        XCTAssertEqual(strengthTest.results.count, 1)
        XCTAssertFalse(strengthTest.isCompleted, "Test should not be completed with 1/5 results")
        XCTAssertEqual(strengthTest.completionPercentage, 0.2, accuracy: 0.01) // 1/5 = 20%
        
        let retrievedResult = strengthTest.result(for: .benchPress)
        XCTAssertNotNil(retrievedResult)
        XCTAssertEqual(retrievedResult?.value, 100.0)
    }
    
    func testReplaceExistingResult() {
        // Given - Strength test with initial result
        let strengthTest = StrengthTest(
            userAge: 30,
            userGender: .male,
            userWeight: 80.0
        )
        
        let initialResult = StrengthTestResult(
            exerciseType: .benchPress,
            value: 90.0,
            strengthLevel: .novice
        )
        
        strengthTest.addResult(initialResult)
        
        // When - Add improved result for same exercise
        let improvedResult = StrengthTestResult(
            exerciseType: .benchPress,
            value: 110.0,
            strengthLevel: .intermediate,
            isPersonalRecord: true
        )
        
        strengthTest.addResult(improvedResult)
        
        // Then - Should replace, not add
        XCTAssertEqual(strengthTest.results.count, 1, "Should still have only 1 result")
        
        let currentResult = strengthTest.result(for: .benchPress)
        XCTAssertEqual(currentResult?.value, 110.0, "Should have updated value")
        XCTAssertTrue(currentResult?.isPersonalRecord ?? false, "Should be marked as PR")
    }
    
    func testCompleteTestWithAllResults() {
        // Given - Strength test and all 5 exercise results
        let strengthTest = StrengthTest(
            userAge: 30,
            userGender: .male,
            userWeight: 80.0
        )
        
        let results = [
            StrengthTestResult(exerciseType: .benchPress, value: 120.0, strengthLevel: .intermediate, percentileScore: 0.6),
            StrengthTestResult(exerciseType: .overheadPress, value: 70.0, strengthLevel: .advanced, percentileScore: 0.8),
            StrengthTestResult(exerciseType: .pullUp, value: 15.0, strengthLevel: .advanced, percentileScore: 0.75),
            StrengthTestResult(exerciseType: .backSquat, value: 140.0, strengthLevel: .intermediate, percentileScore: 0.5),
            StrengthTestResult(exerciseType: .deadlift, value: 180.0, strengthLevel: .intermediate, percentileScore: 0.55)
        ]
        
        // When - Add all results
        for result in results {
            strengthTest.addResult(result)
        }
        
        // Then - Test should be completed
        XCTAssertTrue(strengthTest.isCompleted, "Test should be completed with all 5 results")
        XCTAssertEqual(strengthTest.results.count, 5)
        XCTAssertEqual(strengthTest.completionPercentage, 1.0, "Completion should be 100%")
        
        // Overall score should be calculated (average of percentiles)
        let expectedScore = (0.6 + 0.8 + 0.75 + 0.5 + 0.55) / 5.0 // = 0.64
        XCTAssertApproximatelyEqual(strengthTest.overallScore, expectedScore, accuracy: 0.01)
        
        // Completed exercises should include all 5
        let completedTypes = strengthTest.completedExercises
        XCTAssertEqual(completedTypes.count, 5)
        XCTAssertTrue(completedTypes.contains(.benchPress))
        XCTAssertTrue(completedTypes.contains(.pullUp))
        
        // Remaining exercises should be empty
        XCTAssertEqual(strengthTest.remainingExercises.count, 0)
    }
    
    // MARK: - Strength Profile Calculation Tests
    
    func testBalancedStrengthProfile() {
        // Given - Test with balanced upper/lower scores
        let strengthTest = StrengthTest(
            userAge: 30,
            userGender: .male,
            userWeight: 80.0
        )
        
        let results = [
            // Upper body: average = (0.6 + 0.65 + 0.7) / 3 = 0.65
            StrengthTestResult(exerciseType: .benchPress, value: 120.0, percentileScore: 0.6),
            StrengthTestResult(exerciseType: .overheadPress, value: 70.0, percentileScore: 0.65),
            StrengthTestResult(exerciseType: .pullUp, value: 15.0, percentileScore: 0.7),
            // Lower body: average = (0.6 + 0.7) / 2 = 0.65
            StrengthTestResult(exerciseType: .backSquat, value: 140.0, percentileScore: 0.6),
            StrengthTestResult(exerciseType: .deadlift, value: 180.0, percentileScore: 0.7)
        ]
        
        // When
        results.forEach { strengthTest.addResult($0) }
        
        // Then
        XCTAssertEqual(strengthTest.strengthProfile, "balanced", "Should be balanced with similar upper/lower scores")
        XCTAssertEqual(strengthTest.strengthProfileEmoji, "⚖️")
    }
    
    func testUpperDominantProfile() {
        // Given - Test with higher upper body scores
        let strengthTest = StrengthTest(
            userAge: 30,
            userGender: .male,
            userWeight: 80.0
        )
        
        let results = [
            // Upper body: average = (0.9 + 0.85 + 0.8) / 3 = 0.85
            StrengthTestResult(exerciseType: .benchPress, value: 150.0, percentileScore: 0.9),
            StrengthTestResult(exerciseType: .overheadPress, value: 85.0, percentileScore: 0.85),
            StrengthTestResult(exerciseType: .pullUp, value: 20.0, percentileScore: 0.8),
            // Lower body: average = (0.4 + 0.5) / 2 = 0.45 (much lower)
            StrengthTestResult(exerciseType: .backSquat, value: 100.0, percentileScore: 0.4),
            StrengthTestResult(exerciseType: .deadlift, value: 120.0, percentileScore: 0.5)
        ]
        
        // When
        results.forEach { strengthTest.addResult($0) }
        
        // Then
        XCTAssertEqual(strengthTest.strengthProfile, "upper_dominant")
        XCTAssertEqual(strengthTest.strengthProfileEmoji, "💪")
    }
    
    func testLowerDominantProfile() {
        // Given - Test with higher lower body scores
        let strengthTest = StrengthTest(
            userAge: 30,
            userGender: .male,
            userWeight: 80.0
        )
        
        let results = [
            // Upper body: average = (0.4 + 0.45 + 0.3) / 3 = 0.38
            StrengthTestResult(exerciseType: .benchPress, value: 80.0, percentileScore: 0.4),
            StrengthTestResult(exerciseType: .overheadPress, value: 45.0, percentileScore: 0.45),
            StrengthTestResult(exerciseType: .pullUp, value: 8.0, percentileScore: 0.3),
            // Lower body: average = (0.8 + 0.85) / 2 = 0.825 (much higher)
            StrengthTestResult(exerciseType: .backSquat, value: 180.0, percentileScore: 0.8),
            StrengthTestResult(exerciseType: .deadlift, value: 220.0, percentileScore: 0.85)
        ]
        
        // When
        results.forEach { strengthTest.addResult($0) }
        
        // Then
        XCTAssertEqual(strengthTest.strengthProfile, "lower_dominant")
        XCTAssertEqual(strengthTest.strengthProfileEmoji, "🦵")
    }
    
    // MARK: - Average Strength Level Tests
    
    func testAverageStrengthLevelCalculation() {
        // Given - Test with mixed strength levels
        let strengthTest = StrengthTest(
            userAge: 30,
            userGender: .male,
            userWeight: 80.0
        )
        
        let results = [
            StrengthTestResult(exerciseType: .benchPress, value: 120.0, strengthLevel: .intermediate), // 2
            StrengthTestResult(exerciseType: .overheadPress, value: 70.0, strengthLevel: .advanced),   // 3
            StrengthTestResult(exerciseType: .pullUp, value: 15.0, strengthLevel: .advanced),         // 3
            StrengthTestResult(exerciseType: .backSquat, value: 140.0, strengthLevel: .novice),       // 1
            StrengthTestResult(exerciseType: .deadlift, value: 180.0, strengthLevel: .intermediate)   // 2
        ]
        
        // When
        results.forEach { strengthTest.addResult($0) }
        
        // Then - Average: (2 + 3 + 3 + 1 + 2) / 5 = 2.2, rounded = 2 (intermediate)
        XCTAssertEqual(strengthTest.averageStrengthLevel, .intermediate)
    }
    
    func testAverageStrengthLevelRounding() {
        // Given - Test with levels that round up
        let strengthTest = StrengthTest(
            userAge: 30,
            userGender: .male,
            userWeight: 80.0
        )
        
        let results = [
            StrengthTestResult(exerciseType: .benchPress, value: 120.0, strengthLevel: .intermediate), // 2
            StrengthTestResult(exerciseType: .overheadPress, value: 70.0, strengthLevel: .advanced),   // 3
            StrengthTestResult(exerciseType: .pullUp, value: 15.0, strengthLevel: .advanced)          // 3
        ]
        
        // When
        results.forEach { strengthTest.addResult($0) }
        
        // Then - Average: (2 + 3 + 3) / 3 = 2.67, rounded = 3 (advanced)
        XCTAssertEqual(strengthTest.averageStrengthLevel, .advanced)
    }
    
    // MARK: - Data Export Tests
    
    func testExportOneRMValues() {
        // Given - Completed strength test
        let strengthTest = StrengthTest(
            userAge: 30,
            userGender: .male,
            userWeight: 80.0
        )
        
        let results = [
            StrengthTestResult(exerciseType: .benchPress, value: 120.0),
            StrengthTestResult(exerciseType: .overheadPress, value: 70.0),
            StrengthTestResult(exerciseType: .pullUp, value: 15.0),
            StrengthTestResult(exerciseType: .backSquat, value: 140.0),
            StrengthTestResult(exerciseType: .deadlift, value: 180.0)
        ]
        
        results.forEach { strengthTest.addResult($0) }
        
        // When
        let oneRMValues = strengthTest.exportOneRMValues()
        
        // Then
        XCTAssertEqual(oneRMValues.count, 5)
        XCTAssertEqual(oneRMValues["bench_press"], 120.0)
        XCTAssertEqual(oneRMValues["overhead_press"], 70.0)
        XCTAssertEqual(oneRMValues["pull_up"], 15.0)
        XCTAssertEqual(oneRMValues["back_squat"], 140.0)
        XCTAssertEqual(oneRMValues["deadlift"], 180.0)
    }
    
    // MARK: - Test Summary and Formatting
    
    func testFormattedSummaryIncomplete() {
        // Given - Incomplete test
        let strengthTest = StrengthTest(
            userAge: 30,
            userGender: .male,
            userWeight: 80.0
        )
        
        // When
        let summary = strengthTest.formattedSummary()
        
        // Then
        XCTAssertEqual(summary, "Test in progress...")
    }
    
    func testFormattedSummaryComplete() {
        // Given - Complete test
        let strengthTest = StrengthTest(
            userAge: 30,
            userGender: .male,
            userWeight: 80.0
        )
        
        let results = [
            StrengthTestResult(exerciseType: .benchPress, value: 120.0, strengthLevel: .intermediate, percentileScore: 0.6),
            StrengthTestResult(exerciseType: .overheadPress, value: 70.0, strengthLevel: .advanced, percentileScore: 0.8),
            StrengthTestResult(exerciseType: .pullUp, value: 15.0, strengthLevel: .advanced, percentileScore: 0.75),
            StrengthTestResult(exerciseType: .backSquat, value: 140.0, strengthLevel: .intermediate, percentileScore: 0.5),
            StrengthTestResult(exerciseType: .deadlift, value: 180.0, strengthLevel: .intermediate, percentileScore: 0.55)
        ]
        
        results.forEach { strengthTest.addResult($0) }
        
        // When
        let summary = strengthTest.formattedSummary()
        
        // Then
        XCTAssertTrue(summary.contains("🏋️ Kuvvet Testi"), "Should contain test header")
        XCTAssertTrue(summary.contains("💪 Genel Seviye"), "Should contain level info")
        XCTAssertTrue(summary.contains("📊 Profil"), "Should contain profile info")
        XCTAssertTrue(summary.contains("🫁"), "Should contain chest muscle emoji for bench press")
    }
    
    // MARK: - Results by Exercise Dictionary
    
    func testResultsByExercise() {
        // Given - Strength test with some results
        let strengthTest = StrengthTest(
            userAge: 30,
            userGender: .male,
            userWeight: 80.0
        )
        
        let benchResult = StrengthTestResult(exerciseType: .benchPress, value: 120.0)
        let squatResult = StrengthTestResult(exerciseType: .backSquat, value: 140.0)
        
        strengthTest.addResult(benchResult)
        strengthTest.addResult(squatResult)
        
        // When
        let resultsByExercise = strengthTest.resultsByExercise
        
        // Then
        XCTAssertEqual(resultsByExercise.count, 2)
        XCTAssertEqual(resultsByExercise[.benchPress]?.value, 120.0)
        XCTAssertEqual(resultsByExercise[.backSquat]?.value, 140.0)
        XCTAssertNil(resultsByExercise[.deadlift])
    }
    
    func testRemainingExercises() {
        // Given - Partial strength test
        let strengthTest = StrengthTest(
            userAge: 30,
            userGender: .male,
            userWeight: 80.0
        )
        
        let benchResult = StrengthTestResult(exerciseType: .benchPress, value: 120.0)
        let pullUpResult = StrengthTestResult(exerciseType: .pullUp, value: 12.0)
        
        strengthTest.addResult(benchResult)
        strengthTest.addResult(pullUpResult)
        
        // When
        let remaining = strengthTest.remainingExercises
        let completed = strengthTest.completedExercises
        
        // Then
        XCTAssertEqual(completed.count, 2)
        XCTAssertTrue(completed.contains(.benchPress))
        XCTAssertTrue(completed.contains(.pullUp))
        
        XCTAssertEqual(remaining.count, 3)
        XCTAssertTrue(remaining.contains(.overheadPress))
        XCTAssertTrue(remaining.contains(.backSquat))
        XCTAssertTrue(remaining.contains(.deadlift))
    }
    
    // MARK: - SwiftData Integration Tests
    
    func testStrengthTestPersistence() throws {
        // Given - Strength test with results
        let strengthTest = StrengthTest(
            userAge: 30,
            userGender: .male,
            userWeight: 80.0,
            testEnvironment: "gym",
            notes: "First test"
        )
        
        let benchResult = StrengthTestResult(
            exerciseType: .benchPress,
            value: 120.0,
            strengthLevel: .intermediate,
            percentileScore: 0.65
        )
        
        strengthTest.addResult(benchResult)
        
        // When - Save to context
        modelContext.insert(strengthTest)
        try modelContext.save()
        
        // Then - Verify persistence
        let fetchDescriptor = FetchDescriptor<StrengthTest>()
        let savedTests = try modelContext.fetch(fetchDescriptor)
        
        XCTAssertEqual(savedTests.count, 1)
        let savedTest = savedTests.first!
        
        XCTAssertEqual(savedTest.userAge, 30)
        XCTAssertEqual(savedTest.userGenderEnum, .male)
        XCTAssertEqual(savedTest.userWeight, 80.0)
        XCTAssertEqual(savedTest.results.count, 1)
        XCTAssertEqual(savedTest.results.first?.value, 120.0)
    }
    
    func testStrengthTestResultUpdate() {
        // Given - Strength test result
        let result = StrengthTestResult(
            exerciseType: .deadlift,
            value: 150.0,
            strengthLevel: .novice,
            percentileScore: 0.4
        )
        
        let originalValue = result.value
        let originalLevel = result.strengthLevelEnum
        
        // When - Update result
        result.updateResult(
            newValue: 180.0,
            newLevel: .intermediate,
            newPercentile: 0.65
        )
        
        // Then
        XCTAssertEqual(result.value, 180.0)
        XCTAssertEqual(result.strengthLevelEnum, .intermediate)
        XCTAssertEqual(result.percentileScore, 0.65)
        XCTAssertTrue(result.isPersonalRecord, "Should be marked as PR when value improves")
        
        XCTAssertGreaterThan(result.value, originalValue)
        XCTAssertGreaterThan(result.strengthLevelEnum.rawValue, originalLevel.rawValue)
    }
    
    // MARK: - Edge Cases and Validation Tests
    
    func testEmptyTestAverageLevel() {
        // Given - Empty strength test
        let strengthTest = StrengthTest(
            userAge: 30,
            userGender: .male,
            userWeight: 80.0
        )
        
        // When
        let averageLevel = strengthTest.averageStrengthLevel
        
        // Then
        XCTAssertEqual(averageLevel, .beginner, "Empty test should default to beginner")
    }
    
    func testInvalidStrengthLevelHandling() {
        // Given - Result with invalid strength level data
        let result = StrengthTestResult(exerciseType: .benchPress, value: 100.0)
        
        // When - Manually set invalid level (simulating data corruption)
        result.strengthLevel = 99 // Invalid level
        
        // Then - Should auto-correct when accessed
        let level = result.strengthLevelEnum
        XCTAssertEqual(level, .elite, "Invalid level should be clamped to valid range")
        XCTAssertEqual(result.strengthLevel, 5, "Underlying value should be corrected")
    }
    
    func testIncompleteProfileCalculation() {
        // Given - Test with only upper body results
        let strengthTest = StrengthTest(
            userAge: 30,
            userGender: .male,
            userWeight: 80.0
        )
        
        let results = [
            StrengthTestResult(exerciseType: .benchPress, value: 120.0, percentileScore: 0.6),
            StrengthTestResult(exerciseType: .overheadPress, value: 70.0, percentileScore: 0.7)
            // Missing lower body exercises
        ]
        
        results.forEach { strengthTest.addResult($0) }
        
        // When - Force test completion manually for testing
        strengthTest.isCompleted = true
        let profile = strengthTest.strengthProfile
        
        // Then - Should handle incomplete data gracefully
        XCTAssertNotEqual(profile, "balanced", "Should not calculate profile with incomplete data")
    }
    
    // MARK: - Performance Tests
    
    func testStrengthTestCreationPerformance() {
        // Given - Large number of strength tests
        let testCount = 100
        
        // When & Then - Creation should be fast
        measure {
            for i in 0..<testCount {
                let strengthTest = StrengthTest(
                    userAge: 25 + (i % 40),
                    userGender: i % 2 == 0 ? .male : .female,
                    userWeight: Double(60 + (i % 40))
                )
                
                // Add a result to test the full workflow
                let result = StrengthTestResult(
                    exerciseType: .benchPress,
                    value: Double(80 + (i % 50))
                )
                strengthTest.addResult(result)
                
                // Access computed properties to test performance
                _ = strengthTest.completionPercentage
                _ = strengthTest.averageStrengthLevel
            }
        }
    }
    
    // MARK: - Real World Usage Tests
    
    func testTypicalUserWorkflow() {
        // Given - User starting strength test
        let strengthTest = StrengthTest(
            userAge: 28,
            userGender: .male,
            userWeight: 75.0,
            testEnvironment: "gym",
            notes: "Using StrongLifts progression"
        )
        
        // When - User completes exercises over time
        let exercises: [(StrengthExerciseType, Double, StrengthLevel)] = [
            (.benchPress, 100.0, .intermediate),
            (.backSquat, 120.0, .intermediate),
            (.deadlift, 140.0, .novice),
            (.overheadPress, 60.0, .intermediate),
            (.pullUp, 10.0, .novice)
        ]
        
        for (i, (exercise, value, level)) in exercises.enumerated() {
            let result = StrengthTestResult(
                exerciseType: exercise,
                value: value,
                strengthLevel: level,
                percentileScore: Double(0.4 + i) / 10.0 // Varying percentiles
            )
            strengthTest.addResult(result)
            
            // Test should not be complete until last exercise
            if i < exercises.count - 1 {
                XCTAssertFalse(strengthTest.isCompleted, "Test should not complete until all exercises done")
            }
        }
        
        // Then - Test should be completed and analyzed
        XCTAssertTrue(strengthTest.isCompleted, "Test should be completed")
        XCTAssertGreaterThan(strengthTest.overallScore, 0, "Should have calculated overall score")
        XCTAssertNotEqual(strengthTest.strengthProfile, "unknown", "Should have determined strength profile")
        
        // Should be able to export 1RMs for user profile update
        let oneRMs = strengthTest.exportOneRMValues()
        XCTAssertEqual(oneRMs.count, 5, "Should export all 1RM values")
        
        // Summary should be comprehensive
        let summary = strengthTest.formattedSummary()
        XCTAssertTrue(summary.contains("🏋️"), "Summary should be properly formatted")
    }
    
    // MARK: - Helper Methods
    
    private func createTestStrengthTest() -> StrengthTest {
        return StrengthTest(
            userAge: 30,
            userGender: .male,
            userWeight: 80.0,
            testEnvironment: "test_gym"
        )
    }
    
    private func addAllTestResults(_ strengthTest: StrengthTest) {
        let results = [
            StrengthTestResult(exerciseType: .benchPress, value: 100.0, strengthLevel: .intermediate, percentileScore: 0.5),
            StrengthTestResult(exerciseType: .overheadPress, value: 60.0, strengthLevel: .intermediate, percentileScore: 0.55),
            StrengthTestResult(exerciseType: .pullUp, value: 12.0, strengthLevel: .intermediate, percentileScore: 0.6),
            StrengthTestResult(exerciseType: .backSquat, value: 120.0, strengthLevel: .intermediate, percentileScore: 0.45),
            StrengthTestResult(exerciseType: .deadlift, value: 150.0, strengthLevel: .intermediate, percentileScore: 0.5)
        ]
        
        results.forEach { strengthTest.addResult($0) }
    }
}

// MARK: - Test Extensions for StrengthExerciseType

extension StrengthTestTests {
    
    func testStrengthExerciseTypeProperties() {
        // Test all exercise types have proper properties
        for exerciseType in StrengthExerciseType.allCases {
            XCTAssertFalse(exerciseType.name.isEmpty, "\(exerciseType) should have non-empty name")
            XCTAssertFalse(exerciseType.icon.isEmpty, "\(exerciseType) should have non-empty icon")
            XCTAssertFalse(exerciseType.unit.isEmpty, "\(exerciseType) should have non-empty unit")
            XCTAssertGreaterThan(exerciseType.baseStandards.count, 0, "\(exerciseType) should have base standards")
            XCTAssertEqual(exerciseType.baseStandards.count, 6, "\(exerciseType) should have 6 standards (beginner to elite)")
        }
    }
    
    func testRMFormulaCalculations() {
        // Test 1RM calculations for different formulas
        let weight = 100.0
        let reps = 5
        
        let brzycki = RMFormula.brzycki.calculate(weight: weight, reps: reps)
        let epley = RMFormula.epley.calculate(weight: weight, reps: reps)
        let lander = RMFormula.lander.calculate(weight: weight, reps: reps)
        
        // All formulas should produce reasonable results > original weight
        XCTAssertGreaterThan(brzycki, weight, "Brzycki 1RM should exceed working weight")
        XCTAssertGreaterThan(epley, weight, "Epley 1RM should exceed working weight")
        XCTAssertGreaterThan(lander, weight, "Lander 1RM should exceed working weight")
        
        // Results should be in reasonable range (5 reps ~= 85-90% of 1RM)
        XCTAssertLessThan(brzycki, weight * 1.25, "Brzycki should be reasonable")
        XCTAssertLessThan(epley, weight * 1.25, "Epley should be reasonable")
        XCTAssertLessThan(lander, weight * 1.25, "Lander should be reasonable")
    }
    
    func testPullUpSpecialHandling() {
        // Pull-ups are repetition-based and have special handling
        let pullUpType = StrengthExerciseType.pullUp
        
        XCTAssertTrue(pullUpType.isRepetitionBased, "Pull-ups should be repetition-based")
        XCTAssertEqual(pullUpType.unit, "strength.unit.reps".localized, "Pull-ups should use reps unit")
        
        // Pull-up 1RM calculation should just return reps
        let oneRM = pullUpType.calculateOneRM(weight: 0, reps: 12)
        XCTAssertEqual(oneRM, 12.0, "Pull-up 1RM should equal rep count")
    }
}