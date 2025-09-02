import XCTest
import SwiftData
@testable import Thrustr

/**
 * Comprehensive tests for Exercise model
 * Tests exercise creation, localization, categorization, and tracking capabilities
 */
@MainActor
final class ExerciseTests: XCTestCase {
    
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
    
    func testExerciseInitialization() {
        // Given - Exercise creation parameters
        let nameEN = "Bench Press"
        let nameTR = "Göğüs İtmesi"
        let category = "push"
        let equipment = "barbell"
        
        // When
        let exercise = Exercise(
            nameEN: nameEN,
            nameTR: nameTR,
            category: category,
            equipment: equipment
        )
        
        // Then - Basic properties
        XCTAssertEqual(exercise.nameEN, nameEN)
        XCTAssertEqual(exercise.nameTR, nameTR)
        XCTAssertEqual(exercise.category, category)
        XCTAssertEqual(exercise.equipment, equipment)
        XCTAssertNotNil(exercise.id)
        
        // Then - Default tracking capabilities
        XCTAssertTrue(exercise.supportsWeight, "Should support weight by default")
        XCTAssertTrue(exercise.supportsReps, "Should support reps by default")
        XCTAssertFalse(exercise.supportsTime, "Should not support time by default")
        XCTAssertFalse(exercise.supportsDistance, "Should not support distance by default")
        
        // Then - Default state
        XCTAssertFalse(exercise.isFavorite, "Should not be favorite by default")
        XCTAssertTrue(exercise.isActive, "Should be active by default")
        XCTAssertNil(exercise.instructions)
        XCTAssertNotNil(exercise.createdAt)
        XCTAssertNotNil(exercise.updatedAt)
    }
    
    func testExerciseInitializationWithMinimalData() {
        // Given - Minimal exercise data
        let exercise = Exercise(
            nameEN: "Squat",
            nameTR: "Çömelme",
            category: "legs"
        )
        
        // Then
        XCTAssertEqual(exercise.nameEN, "Squat")
        XCTAssertEqual(exercise.nameTR, "Çömelme")
        XCTAssertEqual(exercise.category, "legs")
        XCTAssertEqual(exercise.equipment, "", "Equipment should default to empty string")
    }
    
    // MARK: - Localization Tests
    
    func testLocalizedNameEnglish() {
        // Given - Exercise with both language names
        let exercise = Exercise(
            nameEN: "Push Up",
            nameTR: "Şınav",
            category: "push"
        )
        
        // When
        let localizedName = exercise.localizedName
        
        // Then - Should default to English when both are available
        XCTAssertEqual(localizedName, "Push Up")
    }
    
    func testLocalizedNameFallback() {
        // Given - Exercise with only Turkish name
        let exercise = Exercise(
            nameEN: "",
            nameTR: "Şınav",
            category: "push"
        )
        
        // When
        let localizedName = exercise.localizedName
        
        // Then - Should fallback to Turkish
        XCTAssertEqual(localizedName, "Şınav")
    }
    
    func testGetNameByLanguage() {
        // Given - Exercise with both language names
        let exercise = Exercise(
            nameEN: "Deadlift",
            nameTR: "Ölü Kaldırma",
            category: "pull"
        )
        
        // When & Then - English
        XCTAssertEqual(exercise.getName(language: "en"), "Deadlift")
        XCTAssertEqual(exercise.getName(language: "english"), "Deadlift")
        XCTAssertEqual(exercise.getName(), "Deadlift") // Default
        
        // When & Then - Turkish
        XCTAssertEqual(exercise.getName(language: "tr"), "Ölü Kaldırma")
        XCTAssertEqual(exercise.getName(language: "turkish"), "Ölü Kaldırma")
        XCTAssertEqual(exercise.getName(language: "TR"), "Ölü Kaldırma")
    }
    
    func testGetNameFallbacks() {
        // Given - Exercise with missing Turkish name
        let exerciseEN = Exercise(
            nameEN: "Plank",
            nameTR: "",
            category: "core"
        )
        
        // When & Then - Should fallback to English when Turkish requested
        XCTAssertEqual(exerciseEN.getName(language: "tr"), "Plank")
        
        // Given - Exercise with missing English name
        let exerciseTR = Exercise(
            nameEN: "",
            nameTR: "Mekik",
            category: "core"
        )
        
        // When & Then - Should fallback to Turkish when English requested
        XCTAssertEqual(exerciseTR.getName(language: "en"), "Mekik")
    }
    
    // MARK: - Category Display Tests
    
    func testCategoryDisplay() {
        // Given - Various categories
        let categories = [
            ("push", "Push"),
            ("pull", "Pull"), 
            ("legs", "Legs"),
            ("core", "Core"),
            ("strength", "Strength"),
            ("isolation", "Isolation"),
            ("olympic", "Olympic"),
            ("functional", "Functional"),
            ("plyometric", "Plyometric"),
            ("custom_category", "Custom_category") // Unknown category
        ]
        
        for (rawCategory, expectedDisplay) in categories {
            // When
            let exercise = Exercise(
                nameEN: "Test",
                nameTR: "Test",
                category: rawCategory
            )
            
            // Then
            XCTAssertEqual(exercise.categoryDisplay, expectedDisplay, 
                "Category display for '\(rawCategory)' should be '\(expectedDisplay)'")
        }
    }
    
    // MARK: - Equipment Display Tests
    
    func testEquipmentDisplay() {
        // Given - Various equipment types
        let equipmentTypes = [
            ("barbell", "Barbell"),
            ("dumbbell", "Dumbbell"),
            ("cable", "Cable"),
            ("machine", "Machine"),
            ("bodyweight", "Bodyweight"),
            ("kettlebell", "Kettlebell"),
            ("pullup_bar", "Pull-up Bar"),
            ("other", "Other"),
            ("custom_equipment", "Custom_equipment") // Unknown equipment
        ]
        
        for (rawEquipment, expectedDisplay) in equipmentTypes {
            // When
            let exercise = Exercise(
                nameEN: "Test",
                nameTR: "Test",
                category: "test",
                equipment: rawEquipment
            )
            
            // Then
            XCTAssertEqual(exercise.equipmentDisplay, expectedDisplay,
                "Equipment display for '\(rawEquipment)' should be '\(expectedDisplay)'")
        }
    }
    
    func testCategoryEquipmentDisplay() {
        // Given - Exercise with category and equipment
        let exercise = Exercise(
            nameEN: "Barbell Squat",
            nameTR: "Barbell Çökmelme",
            category: "legs",
            equipment: "barbell"
        )
        
        // When
        let display = exercise.categoryEquipmentDisplay
        
        // Then
        XCTAssertEqual(display, "Legs • Barbell")
    }
    
    // MARK: - Tracking Capabilities Tests
    
    func testDefaultTrackingCapabilities() {
        // Given - Standard exercise
        let exercise = Exercise(
            nameEN: "Bicep Curl",
            nameTR: "Bicep Curl",
            category: "isolation"
        )
        
        // Then - Default tracking capabilities
        XCTAssertTrue(exercise.canTrackWeight)
        XCTAssertTrue(exercise.canTrackReps)
        XCTAssertFalse(exercise.canTrackTime)
        XCTAssertFalse(exercise.canTrackDistance)
    }
    
    func testCustomTrackingCapabilities() {
        // Given - Exercise with custom tracking settings
        let exercise = Exercise(
            nameEN: "Plank",
            nameTR: "Plank",
            category: "core"
        )
        
        // When - Configure for time-based exercise
        exercise.supportsWeight = false
        exercise.supportsReps = false
        exercise.supportsTime = true
        exercise.supportsDistance = false
        
        // Then
        XCTAssertFalse(exercise.canTrackWeight)
        XCTAssertFalse(exercise.canTrackReps)
        XCTAssertTrue(exercise.canTrackTime)
        XCTAssertFalse(exercise.canTrackDistance)
    }
    
    func testCardioExerciseCapabilities() {
        // Given - Cardio exercise setup
        let exercise = Exercise(
            nameEN: "Running",
            nameTR: "Koşu",
            category: "cardio"
        )
        
        // When - Configure for cardio tracking
        exercise.supportsWeight = false
        exercise.supportsReps = false
        exercise.supportsTime = true
        exercise.supportsDistance = true
        
        // Then
        XCTAssertFalse(exercise.canTrackWeight, "Cardio should not track weight")
        XCTAssertFalse(exercise.canTrackReps, "Cardio should not track reps")
        XCTAssertTrue(exercise.canTrackTime, "Cardio should track time")
        XCTAssertTrue(exercise.canTrackDistance, "Cardio should track distance")
    }
    
    // MARK: - Exercise State Management Tests
    
    func testExerciseFavoriteToggle() {
        // Given - Exercise initially not favorite
        let exercise = Exercise(
            nameEN: "Overhead Press",
            nameTR: "Omuz İtmesi",
            category: "push"
        )
        
        XCTAssertFalse(exercise.isFavorite)
        
        // When - Toggle favorite
        exercise.isFavorite = true
        
        // Then
        XCTAssertTrue(exercise.isFavorite)
    }
    
    func testExerciseActivationToggle() {
        // Given - Exercise initially active
        let exercise = Exercise(
            nameEN: "Pull Up",
            nameTR: "Barfiks",
            category: "pull"
        )
        
        XCTAssertTrue(exercise.isActive)
        
        // When - Deactivate exercise
        exercise.isActive = false
        
        // Then
        XCTAssertFalse(exercise.isActive)
    }
    
    // MARK: - Exercise Instructions Tests
    
    func testExerciseInstructions() {
        // Given - Exercise with instructions
        let exercise = Exercise(
            nameEN: "Squat",
            nameTR: "Çömelme", 
            category: "legs"
        )
        
        let instructions = "Stand with feet shoulder-width apart. Lower body by bending knees and hips."
        
        // When
        exercise.instructions = instructions
        
        // Then
        XCTAssertEqual(exercise.instructions, instructions)
    }
    
    // MARK: - SwiftData Integration Tests
    
    func testExercisePersistence() throws {
        // Given - Exercise to persist
        let exercise = Exercise(
            nameEN: "Romanian Deadlift",
            nameTR: "Rumen Ölü Kaldırma",
            category: "pull",
            equipment: "barbell"
        )
        
        exercise.instructions = "Keep legs straight, hinge at hips"
        exercise.isFavorite = true
        
        // When - Save to context
        modelContext.insert(exercise)
        try modelContext.save()
        
        // Then - Verify persistence
        let fetchDescriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate { $0.nameEN == "Romanian Deadlift" }
        )
        let savedExercises = try modelContext.fetch(fetchDescriptor)
        
        XCTAssertEqual(savedExercises.count, 1)
        let savedExercise = savedExercises.first!
        
        XCTAssertEqual(savedExercise.nameEN, "Romanian Deadlift")
        XCTAssertEqual(savedExercise.nameTR, "Rumen Ölü Kaldırma")
        XCTAssertEqual(savedExercise.category, "pull")
        XCTAssertEqual(savedExercise.equipment, "barbell")
        XCTAssertEqual(savedExercise.instructions, "Keep legs straight, hinge at hips")
        XCTAssertTrue(savedExercise.isFavorite)
    }
    
    func testMultipleExercisesPersistence() throws {
        // Given - Multiple exercises
        let exercises = [
            Exercise(nameEN: "Squat", nameTR: "Çömelme", category: "legs", equipment: "barbell"),
            Exercise(nameEN: "Bench Press", nameTR: "Göğüs İtmesi", category: "push", equipment: "barbell"),
            Exercise(nameEN: "Deadlift", nameTR: "Ölü Kaldırma", category: "pull", equipment: "barbell")
        ]
        
        // When - Save all exercises
        for exercise in exercises {
            modelContext.insert(exercise)
        }
        try modelContext.save()
        
        // Then - Verify all saved
        let fetchDescriptor = FetchDescriptor<Exercise>()
        let savedExercises = try modelContext.fetch(fetchDescriptor)
        
        XCTAssertEqual(savedExercises.count, 3)
        
        let exerciseNames = savedExercises.map { $0.nameEN }.sorted()
        let expectedNames = ["Bench Press", "Deadlift", "Squat"]
        XCTAssertEqual(exerciseNames, expectedNames)
    }
    
    // MARK: - Real World Usage Tests
    
    func testExerciseForStrengthTraining() {
        // Given - Typical strength training exercise
        let exercise = Exercise(
            nameEN: "Barbell Row",
            nameTR: "Barbell Kürek",
            category: "pull",
            equipment: "barbell"
        )
        
        // Then - Should have appropriate tracking capabilities
        XCTAssertTrue(exercise.canTrackWeight, "Strength exercises should track weight")
        XCTAssertTrue(exercise.canTrackReps, "Strength exercises should track reps")
        XCTAssertFalse(exercise.canTrackDistance, "Strength exercises don't track distance")
        
        // And appropriate display
        XCTAssertEqual(exercise.categoryDisplay, "Pull")
        XCTAssertEqual(exercise.equipmentDisplay, "Barbell")
    }
    
    func testExerciseForCardioWorkout() {
        // Given - Cardio exercise
        let exercise = Exercise(
            nameEN: "Treadmill Run",
            nameTR: "Koşu Bandı",
            category: "cardio",
            equipment: "machine"
        )
        
        // When - Configure for cardio tracking
        exercise.supportsWeight = false
        exercise.supportsReps = false
        exercise.supportsTime = true
        exercise.supportsDistance = true
        
        // Then
        XCTAssertFalse(exercise.canTrackWeight, "Cardio exercises don't track weight")
        XCTAssertFalse(exercise.canTrackReps, "Cardio exercises don't track reps")
        XCTAssertTrue(exercise.canTrackTime, "Cardio exercises should track time")
        XCTAssertTrue(exercise.canTrackDistance, "Cardio exercises should track distance")
    }
    
    func testExerciseForBodyweightWorkout() {
        // Given - Bodyweight exercise
        let exercise = Exercise(
            nameEN: "Push Up",
            nameTR: "Şınav",
            category: "push",
            equipment: "bodyweight"
        )
        
        // When - Configure for bodyweight tracking (no weight, but reps and maybe time)
        exercise.supportsWeight = false
        exercise.supportsReps = true
        exercise.supportsTime = true
        exercise.supportsDistance = false
        
        // Then
        XCTAssertFalse(exercise.canTrackWeight, "Bodyweight exercises don't track weight")
        XCTAssertTrue(exercise.canTrackReps, "Bodyweight exercises should track reps")
        XCTAssertTrue(exercise.canTrackTime, "Bodyweight exercises can track time")
        XCTAssertFalse(exercise.canTrackDistance, "Bodyweight exercises don't track distance")
        XCTAssertEqual(exercise.equipmentDisplay, "Bodyweight")
    }
    
    // MARK: - Edge Cases and Validation Tests
    
    func testExerciseWithEmptyNames() {
        // Given - Exercise with empty names
        let exercise = Exercise(
            nameEN: "",
            nameTR: "",
            category: "test"
        )
        
        // Then - Should handle gracefully
        XCTAssertEqual(exercise.nameEN, "")
        XCTAssertEqual(exercise.nameTR, "")
        // localizedName will return Turkish (empty) when English is also empty
        XCTAssertEqual(exercise.localizedName, "")
    }
    
    func testExerciseWithSpecialCharacters() {
        // Given - Exercise names with special characters
        let exercise = Exercise(
            nameEN: "90° Cable Fly",
            nameTR: "90° Kablo Açılışı",
            category: "isolation",
            equipment: "cable"
        )
        
        // Then - Should handle special characters correctly
        XCTAssertEqual(exercise.nameEN, "90° Cable Fly")
        XCTAssertEqual(exercise.nameTR, "90° Kablo Açılışı")
        XCTAssertEqual(exercise.localizedName, "90° Cable Fly")
    }
    
    func testExerciseUpdateTimestamp() {
        // Given - Exercise with initial timestamp
        let exercise = Exercise(
            nameEN: "Test Exercise",
            nameTR: "Test Egzersiz",
            category: "test"
        )
        
        let initialTimestamp = exercise.updatedAt
        
        // When - Modify exercise (simulate update)
        exercise.isFavorite = true
        exercise.updatedAt = Date()
        
        // Then - Timestamp should be updated
        XCTAssertGreaterThan(exercise.updatedAt, initialTimestamp)
    }
    
    // MARK: - Performance Tests
    
    func testExerciseCreationPerformance() {
        // Given - Large number of exercise creations
        let exerciseCount = 1000
        
        // When & Then - Exercise creation should be fast
        measure {
            for i in 0..<exerciseCount {
                let exercise = Exercise(
                    nameEN: "Exercise \(i)",
                    nameTR: "Egzersiz \(i)",
                    category: "test"
                )
                // Use the exercise to prevent optimization
                _ = exercise.localizedName
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestExercise(name: String = "Test Exercise") -> Exercise {
        return Exercise(
            nameEN: name,
            nameTR: "\(name) TR",
            category: "test",
            equipment: "test_equipment"
        )
    }
    
    private func assertExerciseDefaults(_ exercise: Exercise) {
        XCTAssertTrue(exercise.isActive, "Exercise should be active by default")
        XCTAssertFalse(exercise.isFavorite, "Exercise should not be favorite by default")
        XCTAssertTrue(exercise.supportsWeight, "Exercise should support weight by default")
        XCTAssertTrue(exercise.supportsReps, "Exercise should support reps by default")
        XCTAssertFalse(exercise.supportsTime, "Exercise should not support time by default")
        XCTAssertFalse(exercise.supportsDistance, "Exercise should not support distance by default")
    }
}

// MARK: - Test Extensions

extension ExerciseTests {
    
    /// Helper to validate exercise basic properties
    func assertExerciseBasics(_ exercise: Exercise, nameEN: String, nameTR: String, category: String, equipment: String = "") {
        XCTAssertEqual(exercise.nameEN, nameEN)
        XCTAssertEqual(exercise.nameTR, nameTR)
        XCTAssertEqual(exercise.category, category)
        XCTAssertEqual(exercise.equipment, equipment)
        XCTAssertNotNil(exercise.id)
        XCTAssertNotNil(exercise.createdAt)
        XCTAssertNotNil(exercise.updatedAt)
    }
    
    /// Helper to create a fully configured strength exercise
    func createStrengthExercise(name: String = "Strength Exercise") -> Exercise {
        let exercise = Exercise(
            nameEN: name,
            nameTR: "\(name) TR",
            category: "strength",
            equipment: "barbell"
        )
        exercise.supportsWeight = true
        exercise.supportsReps = true
        exercise.supportsTime = false
        exercise.supportsDistance = false
        return exercise
    }
    
    /// Helper to create a fully configured cardio exercise
    func createCardioExercise(name: String = "Cardio Exercise") -> Exercise {
        let exercise = Exercise(
            nameEN: name,
            nameTR: "\(name) TR",
            category: "cardio",
            equipment: "machine"
        )
        exercise.supportsWeight = false
        exercise.supportsReps = false
        exercise.supportsTime = true
        exercise.supportsDistance = true
        return exercise
    }
}