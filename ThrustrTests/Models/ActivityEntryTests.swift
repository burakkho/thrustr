import XCTest
import SwiftData
@testable import Thrustr

/**
 * Comprehensive tests for ActivityEntry model
 * Tests activity logging, metadata handling, time formatting, and factory methods
 */
@MainActor
final class ActivityEntryTests: XCTestCase {
    
    // MARK: - Test Properties
    private var modelContext: ModelContext!
    private var testUser: User!
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        
        modelContext = try TestHelpers.createTestModelContext()
        
        // Create test user
        testUser = User(
            name: "Test User",
            age: 30,
            gender: .male,
            height: 180.0,
            currentWeight: 75.0,
            fitnessGoal: .muscleGain,
            activityLevel: .moderate,
            selectedLanguage: "tr"
        )
        modelContext.insert(testUser)
        try modelContext.save()
    }
    
    override func tearDown() async throws {
        testUser = nil
        modelContext = nil
        try await super.tearDown()
    }
    
    // MARK: - ActivityEntry Initialization Tests
    
    func testActivityEntryInitialization() {
        // Given
        let type = ActivityType.workoutCompleted
        let title = "Push Day"
        let subtitle = "45 dk | 3 set | 24 reps"
        let icon = "dumbbell.fill"
        let metadata = ActivityMetadata()
        
        // When
        let activity = ActivityEntry(
            type: type,
            title: title,
            subtitle: subtitle,
            icon: icon,
            metadata: metadata,
            user: testUser
        )
        
        // Then
        XCTAssertEqual(activity.typeEnum, type)
        XCTAssertEqual(activity.type, type.rawValue)
        XCTAssertEqual(activity.title, title)
        XCTAssertEqual(activity.subtitle, subtitle)
        XCTAssertEqual(activity.icon, icon)
        XCTAssertEqual(activity.displayIcon, icon)
        XCTAssertEqual(activity.user, testUser)
        XCTAssertFalse(activity.isArchived)
        XCTAssertNotNil(activity.timestamp)
        XCTAssertFalse(activity.timeAgo.isEmpty)
    }
    
    func testActivityEntryMinimalInitialization() {
        // Given
        let type = ActivityType.nutritionLogged
        let title = "Kahvaltı"
        
        // When
        let activity = ActivityEntry(
            type: type,
            title: title,
            user: testUser
        )
        
        // Then
        XCTAssertEqual(activity.typeEnum, type)
        XCTAssertEqual(activity.title, title)
        XCTAssertNil(activity.subtitle)
        XCTAssertEqual(activity.displayIcon, type.defaultIcon)
        XCTAssertEqual(activity.user, testUser)
    }
    
    func testActivityEntryWithInvalidType() {
        // Given - Invalid type stored in database
        let activity = ActivityEntry(
            type: .workoutCompleted,
            title: "Test",
            user: testUser
        )
        activity.type = "invalid_type" // Simulate corrupted data
        
        // When
        let typeEnum = activity.typeEnum
        
        // Then - Should fallback to default
        XCTAssertEqual(typeEnum, .workoutCompleted)
    }
    
    // MARK: - Computed Properties Tests
    
    func testDisplayIcon() {
        // Given - Activity with empty icon
        let activity = ActivityEntry(
            type: .cardioCompleted,
            title: "Running",
            icon: "",
            user: testUser
        )
        
        // When
        let displayIcon = activity.displayIcon
        
        // Then - Should use default icon
        XCTAssertEqual(displayIcon, ActivityType.cardioCompleted.defaultIcon)
        
        // Given - Activity with custom icon
        activity.icon = "custom.icon"
        
        // When
        let customDisplayIcon = activity.displayIcon
        
        // Then - Should use custom icon
        XCTAssertEqual(customDisplayIcon, "custom.icon")
    }
    
    func testTimeAgo() {
        // Given - Activity from different times
        let now = Date()
        let activities = [
            (now.addingTimeInterval(-30), "şimdi"), // 30 seconds ago
            (now.addingTimeInterval(-300), "5 dk önce"), // 5 minutes ago
            (now.addingTimeInterval(-3600), "1 saat önce"), // 1 hour ago
            (now.addingTimeInterval(-7200), "2 saat önce") // 2 hours ago
        ]
        
        for (timestamp, expectedPattern) in activities {
            // When
            let activity = ActivityEntry(type: .workoutCompleted, title: "Test", user: testUser)
            activity.timestamp = timestamp
            
            // Then
            let timeAgo = activity.timeAgo
            XCTAssertFalse(timeAgo.isEmpty, "Time ago should not be empty")
            
            // For relative times, check if it contains expected elements
            if expectedPattern.contains("dk") {
                XCTAssertTrue(timeAgo.contains("dk"), "Should contain minutes")
            }
            if expectedPattern.contains("saat") {
                XCTAssertTrue(timeAgo.contains("saat"), "Should contain hours")
            }
        }
    }
    
    // MARK: - Factory Methods Tests
    
    func testWorkoutCompletedFactory() {
        // Given
        let workoutType = "Push Day"
        let duration: TimeInterval = 2700 // 45 minutes
        let volume: Double = 2500
        let sets = 12
        let reps = 96
        
        // When
        let activity = ActivityEntry.workoutCompleted(
            workoutType: workoutType,
            duration: duration,
            volume: volume,
            sets: sets,
            reps: reps,
            user: testUser
        )
        
        // Then
        XCTAssertEqual(activity.typeEnum, .workoutCompleted)
        XCTAssertEqual(activity.title, workoutType)
        XCTAssertNotNil(activity.subtitle)
        XCTAssertEqual(activity.icon, "dumbbell.fill")
        XCTAssertEqual(activity.user, testUser)
        
        // Check metadata
        XCTAssertEqual(activity.metadata.duration, duration)
        XCTAssertEqual(activity.metadata.volume, volume)
        XCTAssertEqual(activity.metadata.sets, sets)
        XCTAssertEqual(activity.metadata.reps, reps)
        
        // Check subtitle formatting
        XCTAssertTrue(activity.subtitle!.contains("12 set"))
        XCTAssertTrue(activity.subtitle!.contains("96 reps"))
        XCTAssertTrue(activity.subtitle!.contains("45dk"))
    }
    
    func testWorkoutCompletedMinimalFactory() {
        // Given
        let workoutType = "Cardio"
        let duration: TimeInterval = 1800 // 30 minutes
        
        // When
        let activity = ActivityEntry.workoutCompleted(
            workoutType: workoutType,
            duration: duration,
            user: testUser
        )
        
        // Then
        XCTAssertEqual(activity.typeEnum, .workoutCompleted)
        XCTAssertEqual(activity.title, workoutType)
        XCTAssertNotNil(activity.subtitle)
        XCTAssertEqual(activity.metadata.duration, duration)
        XCTAssertNil(activity.metadata.volume)
        XCTAssertNil(activity.metadata.sets)
        XCTAssertNil(activity.metadata.reps)
    }
    
    func testNutritionLoggedFactory() {
        // Given
        let mealType = "Kahvaltı"
        let calories: Double = 450
        let protein: Double = 25
        let carbs: Double = 45
        let fat: Double = 20
        
        // When
        let activity = ActivityEntry.nutritionLogged(
            mealType: mealType,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            user: testUser
        )
        
        // Then
        XCTAssertEqual(activity.typeEnum, .nutritionLogged)
        XCTAssertEqual(activity.title, mealType)
        XCTAssertNotNil(activity.subtitle)
        XCTAssertEqual(activity.icon, "sunrise.fill") // Breakfast icon
        XCTAssertEqual(activity.user, testUser)
        
        // Check metadata
        XCTAssertEqual(activity.metadata.calories, calories)
        XCTAssertEqual(activity.metadata.protein, protein)
        XCTAssertEqual(activity.metadata.carbs, carbs)
        XCTAssertEqual(activity.metadata.fat, fat)
        
        // Check subtitle formatting
        XCTAssertTrue(activity.subtitle!.contains("450 cal"))
        XCTAssertTrue(activity.subtitle!.contains("25g P"))
        XCTAssertTrue(activity.subtitle!.contains("45g C"))
        XCTAssertTrue(activity.subtitle!.contains("20g F"))
    }
    
    func testMeasurementUpdatedFactory() {
        // Given
        let measurementType = "Kilo"
        let value: Double = 75.5
        let previousValue: Double = 76.0
        let unit = "kg"
        
        // When
        let activity = ActivityEntry.measurementUpdated(
            measurementType: measurementType,
            value: value,
            previousValue: previousValue,
            unit: unit,
            user: testUser
        )
        
        // Then
        XCTAssertEqual(activity.typeEnum, .measurementUpdated)
        XCTAssertEqual(activity.title, measurementType)
        XCTAssertNotNil(activity.subtitle)
        XCTAssertEqual(activity.user, testUser)
        
        // Check metadata
        XCTAssertEqual(activity.metadata.value, value)
        XCTAssertEqual(activity.metadata.previousValue, previousValue)
        XCTAssertEqual(activity.metadata.unit, unit)
        
        // Check subtitle formatting (should show change)
        XCTAssertTrue(activity.subtitle!.contains("75.5kg"))
        XCTAssertTrue(activity.subtitle!.contains("76.0kg"))
        XCTAssertTrue(activity.subtitle!.contains("→"))
    }
    
    func testMeasurementUpdatedWithoutPrevious() {
        // Given
        let measurementType = "Boy"
        let value: Double = 180.0
        let unit = "cm"
        
        // When
        let activity = ActivityEntry.measurementUpdated(
            measurementType: measurementType,
            value: value,
            unit: unit,
            user: testUser
        )
        
        // Then
        XCTAssertEqual(activity.metadata.value, value)
        XCTAssertNil(activity.metadata.previousValue)
        XCTAssertEqual(activity.metadata.unit, unit)
        
        // Subtitle should only show current value
        XCTAssertTrue(activity.subtitle!.contains("180cm"))
        XCTAssertFalse(activity.subtitle!.contains("→"))
    }
    
    func testMealCompletedFactory() {
        // Given
        let mealType = "Öğle Yemeği"
        let foodCount = 4
        let calories: Double = 650
        let protein: Double = 35
        let carbs: Double = 70
        let fat: Double = 25
        
        // When
        let activity = ActivityEntry.mealCompleted(
            mealType: mealType,
            foodCount: foodCount,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            user: testUser
        )
        
        // Then
        XCTAssertEqual(activity.typeEnum, .mealCompleted)
        XCTAssertEqual(activity.title, "Öğle Yemeği tamamlandı")
        XCTAssertEqual(activity.icon, "sun.max.fill") // Lunch icon
        XCTAssertNotNil(activity.subtitle)
        
        // Check metadata
        XCTAssertEqual(activity.metadata.calories, calories)
        XCTAssertEqual(activity.metadata.protein, protein)
        XCTAssertEqual(activity.metadata.carbs, carbs)
        XCTAssertEqual(activity.metadata.fat, fat)
        
        // Check subtitle formatting
        XCTAssertTrue(activity.subtitle!.contains("4 yiyecek"))
        XCTAssertTrue(activity.subtitle!.contains("650 kcal"))
    }
    
    // MARK: - ActivityType Tests
    
    func testActivityTypeDefaultIcons() {
        // Test that all activity types have valid icons
        for activityType in ActivityType.allCases {
            let icon = activityType.defaultIcon
            XCTAssertFalse(icon.isEmpty, "Activity type \(activityType) should have default icon")
            XCTAssertTrue(icon.contains("."), "Icon should be a valid SF Symbol name")
        }
    }
    
    func testActivityTypePriorities() {
        // Test priority ordering
        let priorities = ActivityType.allCases.map { $0.priority }
        let uniquePriorities = Set(priorities)
        
        // Priorities should be reasonable
        XCTAssertTrue(priorities.allSatisfy { $0 >= 1 && $0 <= 10 })
        
        // Personal record should have highest priority
        XCTAssertEqual(ActivityType.personalRecord.priority, 10)
        
        // Settings should have lowest priority
        XCTAssertEqual(ActivityType.settingsUpdated.priority, 1)
    }
    
    func testMealTypeIcons() {
        // Test meal type icon mapping
        let testCases: [(String, String)] = [
            ("Kahvaltı", "sunrise.fill"),
            ("breakfast", "sunrise.fill"),
            ("Öğle Yemeği", "sun.max.fill"),
            ("lunch", "sun.max.fill"),
            ("Akşam Yemeği", "moon.fill"),
            ("dinner", "moon.fill"),
            ("Atıştırmalık", "leaf.fill"),
            ("snack", "leaf.fill"),
            ("Unknown Meal", "fork.knife")
        ]
        
        for (mealType, expectedIcon) in testCases {
            let icon = ActivityType.nutritionLogged.iconForMeal(mealType)
            XCTAssertEqual(icon, expectedIcon, "Failed for meal type: \(mealType)")
        }
    }
    
    // MARK: - ActivityMetadata Tests
    
    func testActivityMetadataInitialization() {
        // Given
        let duration: TimeInterval = 3600
        let volume: Double = 5000
        let sets = 5
        let reps = 25
        let calories: Double = 300
        
        // When
        let metadata = ActivityMetadata(
            duration: duration,
            volume: volume,
            sets: sets,
            reps: reps,
            calories: calories
        )
        
        // Then
        XCTAssertEqual(metadata.duration, duration)
        XCTAssertEqual(metadata.volume, volume)
        XCTAssertEqual(metadata.sets, sets)
        XCTAssertEqual(metadata.reps, reps)
        XCTAssertEqual(metadata.calories, calories)
        XCTAssertNil(metadata.protein) // Not set
        XCTAssertNil(metadata.customData) // Not set
    }
    
    func testActivityMetadataFactoryMethods() {
        // Test workout factory
        let workoutMetadata = ActivityMetadata.workout(
            duration: 2700,
            volume: 3000,
            sets: 8,
            reps: 40
        )
        
        XCTAssertEqual(workoutMetadata.duration, 2700)
        XCTAssertEqual(workoutMetadata.volume, 3000)
        XCTAssertEqual(workoutMetadata.sets, 8)
        XCTAssertEqual(workoutMetadata.reps, 40)
        XCTAssertNil(workoutMetadata.calories)
        
        // Test nutrition factory
        let nutritionMetadata = ActivityMetadata.nutrition(
            calories: 500,
            protein: 30,
            carbs: 60,
            fat: 15
        )
        
        XCTAssertEqual(nutritionMetadata.calories, 500)
        XCTAssertEqual(nutritionMetadata.protein, 30)
        XCTAssertEqual(nutritionMetadata.carbs, 60)
        XCTAssertEqual(nutritionMetadata.fat, 15)
        XCTAssertNil(nutritionMetadata.duration)
        
        // Test measurement factory
        let measurementMetadata = ActivityMetadata.measurement(
            value: 75.5,
            previousValue: 76.0,
            unit: "kg"
        )
        
        XCTAssertEqual(measurementMetadata.value, 75.5)
        XCTAssertEqual(measurementMetadata.previousValue, 76.0)
        XCTAssertEqual(measurementMetadata.unit, "kg")
        
        // Test goal factory
        let goalMetadata = ActivityMetadata.goal(
            goalName: "Daily Steps",
            targetValue: 10000,
            currentValue: 8500,
            isCompleted: false
        )
        
        XCTAssertEqual(goalMetadata.goalName, "Daily Steps")
        XCTAssertEqual(goalMetadata.targetValue, 10000)
        XCTAssertEqual(goalMetadata.currentValue, 8500)
        XCTAssertEqual(goalMetadata.isCompleted, false)
    }
    
    // MARK: - ActivityTimeFormatter Tests
    
    func testTimeAgoFormatting() {
        // Given - Different time intervals
        let now = Date()
        let testCases: [(Date, String)] = [
            (now.addingTimeInterval(-30), "0 dk önce"), // 30 seconds ago
            (now.addingTimeInterval(-300), "5 dk önce"), // 5 minutes ago
            (now.addingTimeInterval(-3600), "1 saat önce"), // 1 hour ago
            (now.addingTimeInterval(-7200), "2 saat önce"), // 2 hours ago
            (Calendar.current.date(byAdding: .day, value: -1, to: now)!, "dün") // Yesterday
        ]
        
        for (date, expectedPattern) in testCases {
            // When
            let timeAgo = ActivityTimeFormatter.timeAgo(from: date)
            
            // Then
            XCTAssertFalse(timeAgo.isEmpty)
            
            if expectedPattern.contains("dk") {
                XCTAssertTrue(timeAgo.contains("dk"))
            }
            if expectedPattern.contains("saat") {
                XCTAssertTrue(timeAgo.contains("saat"))
            }
            if expectedPattern.contains("dün") {
                XCTAssertTrue(timeAgo.contains("dün"))
            }
        }
    }
    
    // MARK: - SwiftData Integration Tests
    
    func testActivityEntryPersistence() throws {
        // Given
        let activity = ActivityEntry.workoutCompleted(
            workoutType: "Full Body",
            duration: 3600,
            volume: 4000,
            sets: 15,
            reps: 75,
            user: testUser
        )
        
        // When
        modelContext.insert(activity)
        try modelContext.save()
        
        // Then
        let fetchDescriptor = FetchDescriptor<ActivityEntry>()
        let savedActivities = try modelContext.fetch(fetchDescriptor)
        
        XCTAssertEqual(savedActivities.count, 1)
        let savedActivity = savedActivities.first!
        
        XCTAssertEqual(savedActivity.typeEnum, .workoutCompleted)
        XCTAssertEqual(savedActivity.title, "Full Body")
        XCTAssertEqual(savedActivity.metadata.duration, 3600)
        XCTAssertEqual(savedActivity.metadata.volume, 4000)
        XCTAssertEqual(savedActivity.metadata.sets, 15)
        XCTAssertEqual(savedActivity.metadata.reps, 75)
        XCTAssertEqual(savedActivity.user, testUser)
    }
    
    func testMultipleActivitiesPersistence() throws {
        // Given
        let activities = [
            ActivityEntry.workoutCompleted(workoutType: "Push", duration: 2700, user: testUser),
            ActivityEntry.nutritionLogged(mealType: "Kahvaltı", calories: 400, protein: 20, carbs: 40, fat: 15, user: testUser),
            ActivityEntry.measurementUpdated(measurementType: "Kilo", value: 75.0, unit: "kg", user: testUser)
        ]
        
        // When
        for activity in activities {
            modelContext.insert(activity)
        }
        try modelContext.save()
        
        // Then
        let fetchDescriptor = FetchDescriptor<ActivityEntry>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        let savedActivities = try modelContext.fetch(fetchDescriptor)
        
        XCTAssertEqual(savedActivities.count, 3)
        
        let types = savedActivities.map { $0.typeEnum }
        XCTAssertTrue(types.contains(.workoutCompleted))
        XCTAssertTrue(types.contains(.nutritionLogged))
        XCTAssertTrue(types.contains(.measurementUpdated))
    }
    
    // MARK: - Archive Functionality Tests
    
    func testArchiveActivity() throws {
        // Given
        let activity = ActivityEntry.workoutCompleted(
            workoutType: "Test Workout",
            duration: 1800,
            user: testUser
        )
        modelContext.insert(activity)
        try modelContext.save()
        
        XCTAssertFalse(activity.isArchived)
        
        // When
        activity.isArchived = true
        try modelContext.save()
        
        // Then
        let fetchDescriptor = FetchDescriptor<ActivityEntry>()
        let activities = try modelContext.fetch(fetchDescriptor)
        let savedActivity = activities.first!
        
        XCTAssertTrue(savedActivity.isArchived)
    }
    
    func testFilterArchivedActivities() throws {
        // Given
        let activeActivity = ActivityEntry.workoutCompleted(workoutType: "Active", duration: 1800, user: testUser)
        let archivedActivity = ActivityEntry.nutritionLogged(mealType: "Archived", calories: 300, protein: 15, carbs: 30, fat: 10, user: testUser)
        archivedActivity.isArchived = true
        
        modelContext.insert(activeActivity)
        modelContext.insert(archivedActivity)
        try modelContext.save()
        
        // When - Fetch only non-archived activities
        let activeDescriptor = FetchDescriptor<ActivityEntry>(
            predicate: #Predicate<ActivityEntry> { !$0.isArchived }
        )
        let activeActivities = try modelContext.fetch(activeDescriptor)
        
        // Then
        XCTAssertEqual(activeActivities.count, 1)
        XCTAssertEqual(activeActivities.first?.title, "Active")
        XCTAssertFalse(activeActivities.first!.isArchived)
    }
    
    // MARK: - Edge Cases Tests
    
    func testActivityWithEmptyTitle() {
        // Given
        let activity = ActivityEntry(
            type: .workoutCompleted,
            title: "",
            user: testUser
        )
        
        // Then
        XCTAssertEqual(activity.title, "")
        XCTAssertEqual(activity.typeEnum, .workoutCompleted)
    }
    
    func testActivityWithNilUser() {
        // Given
        let activity = ActivityEntry(
            type: .nutritionLogged,
            title: "Test Meal",
            user: nil
        )
        
        // Then
        XCTAssertNil(activity.user)
        XCTAssertEqual(activity.title, "Test Meal")
    }
    
    func testActivityWithLargeValues() {
        // Given - Activity with very large metadata values
        let metadata = ActivityMetadata(
            duration: 86400, // 24 hours
            volume: 50000, // 50 tons
            calories: 10000 // 10k calories
        )
        
        let activity = ActivityEntry(
            type: .workoutCompleted,
            title: "Extreme Workout",
            metadata: metadata,
            user: testUser
        )
        
        // Then
        XCTAssertEqual(activity.metadata.duration, 86400)
        XCTAssertEqual(activity.metadata.volume, 50000)
        XCTAssertEqual(activity.metadata.calories, 10000)
    }
    
    // MARK: - Performance Tests
    
    func testActivityCreationPerformance() {
        measure {
            for i in 1...100 {
                let activity = ActivityEntry.workoutCompleted(
                    workoutType: "Workout \(i)",
                    duration: TimeInterval(1800 + i),
                    volume: Double(2000 + i),
                    sets: 3 + (i % 5),
                    reps: 10 * (3 + (i % 5)),
                    user: testUser
                )
                
                // Access computed properties to test performance
                let _ = activity.typeEnum
                let _ = activity.displayIcon
                let _ = activity.timeAgo
            }
        }
    }
    
    func testBatchActivityInsertion() {
        measure {
            let activities = (1...50).map { i in
                ActivityEntry.workoutCompleted(
                    workoutType: "Batch Workout \(i)",
                    duration: TimeInterval(1800 + i),
                    user: testUser
                )
            }
            
            for activity in activities {
                modelContext.insert(activity)
            }
            
            do {
                try modelContext.save()
            } catch {
                XCTFail("Failed to save batch activities: \(error)")
            }
        }
    }
    
    // MARK: - Integration Tests
    
    func testCompleteActivityWorkflow() throws {
        // Test a complete activity logging workflow
        
        // Step 1: Create workout activity
        let workoutActivity = ActivityEntry.workoutCompleted(
            workoutType: "Full Body Strength",
            duration: 3600,
            volume: 5000,
            sets: 18,
            reps: 90,
            user: testUser
        )
        modelContext.insert(workoutActivity)
        
        // Step 2: Create nutrition activity
        let nutritionActivity = ActivityEntry.nutritionLogged(
            mealType: "Post-Workout",
            calories: 400,
            protein: 30,
            carbs: 45,
            fat: 12,
            user: testUser
        )
        modelContext.insert(nutritionActivity)
        
        // Step 3: Create measurement activity
        let measurementActivity = ActivityEntry.measurementUpdated(
            measurementType: "Body Weight",
            value: 75.2,
            previousValue: 75.5,
            unit: "kg",
            user: testUser
        )
        modelContext.insert(measurementActivity)
        
        // Step 4: Save all activities
        try modelContext.save()
        
        // Step 5: Fetch and verify
        let fetchDescriptor = FetchDescriptor<ActivityEntry>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        let activities = try modelContext.fetch(fetchDescriptor)
        
        XCTAssertEqual(activities.count, 3)
        
        // Verify workout activity
        let workout = activities.first { $0.typeEnum == .workoutCompleted }!
        XCTAssertEqual(workout.title, "Full Body Strength")
        XCTAssertEqual(workout.metadata.duration, 3600)
        XCTAssertEqual(workout.metadata.volume, 5000)
        
        // Verify nutrition activity
        let nutrition = activities.first { $0.typeEnum == .nutritionLogged }!
        XCTAssertEqual(nutrition.title, "Post-Workout")
        XCTAssertEqual(nutrition.metadata.calories, 400)
        XCTAssertEqual(nutrition.metadata.protein, 30)
        
        // Verify measurement activity
        let measurement = activities.first { $0.typeEnum == .measurementUpdated }!
        XCTAssertEqual(measurement.title, "Body Weight")
        XCTAssertEqual(measurement.metadata.value, 75.2)
        XCTAssertEqual(measurement.metadata.previousValue, 75.5)
        
        print("Complete activity workflow test passed")
    }
}

// MARK: - Test Extensions

extension ActivityEntryTests {
    
    /// Helper method to create a test activity with timestamp
    private func createTestActivity(
        type: ActivityType,
        title: String,
        timestamp: Date
    ) -> ActivityEntry {
        let activity = ActivityEntry(type: type, title: title, user: testUser)
        activity.timestamp = timestamp
        return activity
    }
    
    /// Test activity sorting by timestamp
    func testActivitySortingByTimestamp() throws {
        // Given - Activities with different timestamps
        let now = Date()
        let activities = [
            createTestActivity(type: .workoutCompleted, title: "Oldest", timestamp: now.addingTimeInterval(-7200)),
            createTestActivity(type: .nutritionLogged, title: "Newest", timestamp: now),
            createTestActivity(type: .measurementUpdated, title: "Middle", timestamp: now.addingTimeInterval(-3600))
        ]
        
        for activity in activities {
            modelContext.insert(activity)
        }
        try modelContext.save()
        
        // When - Fetch with timestamp sorting (newest first)
        let fetchDescriptor = FetchDescriptor<ActivityEntry>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        let sortedActivities = try modelContext.fetch(fetchDescriptor)
        
        // Then
        XCTAssertEqual(sortedActivities.count, 3)
        XCTAssertEqual(sortedActivities[0].title, "Newest")
        XCTAssertEqual(sortedActivities[1].title, "Middle")
        XCTAssertEqual(sortedActivities[2].title, "Oldest")
    }
}