import XCTest
import SwiftData
import SwiftUI
@testable import Thrustr

/**
 * Comprehensive tests for BodyTrackingModels
 * Tests WeightEntry, BodyMeasurement, ProgressPhoto, Goal models and their enums
 */
@MainActor
final class BodyTrackingModelsTests: XCTestCase {
    
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
    
    // MARK: - WeightEntry Tests
    
    func testWeightEntryInitialization() {
        // Given
        let weight = 75.5
        let date = Date()
        let notes = "Post-workout weight"
        let bodyFat = 15.0
        let muscleMass = 55.0
        let mood = "Energetic"
        let energyLevel = 8
        
        // When
        let weightEntry = WeightEntry(
            weight: weight,
            date: date,
            notes: notes,
            bodyFat: bodyFat,
            muscleMass: muscleMass,
            mood: mood,
            energyLevel: energyLevel
        )
        
        // Then
        XCTAssertNotNil(weightEntry.id)
        XCTAssertEqual(weightEntry.weight, weight)
        XCTAssertEqual(weightEntry.date, date)
        XCTAssertEqual(weightEntry.notes, notes)
        XCTAssertEqual(weightEntry.bodyFat, bodyFat)
        XCTAssertEqual(weightEntry.muscleMass, muscleMass)
        XCTAssertEqual(weightEntry.mood, mood)
        XCTAssertEqual(weightEntry.energyLevel, energyLevel)
        XCTAssertNotNil(weightEntry.createdAt)
    }
    
    func testWeightEntryMinimalInitialization() {
        // Given
        let weight = 80.0
        let date = Date()
        
        // When
        let weightEntry = WeightEntry(weight: weight, date: date)
        
        // Then
        XCTAssertEqual(weightEntry.weight, weight)
        XCTAssertEqual(weightEntry.date, date)
        XCTAssertNil(weightEntry.notes)
        XCTAssertNil(weightEntry.bodyFat)
        XCTAssertNil(weightEntry.muscleMass)
        XCTAssertNil(weightEntry.mood)
        XCTAssertNil(weightEntry.energyLevel)
    }
    
    func testWeightEntryBMICalculation() {
        // Given
        let weightEntry = WeightEntry(weight: 75.0, date: Date())
        weightEntry.user = testUser // User has height 180cm
        
        // When
        let bmi = weightEntry.bmi
        
        // Then
        XCTAssertNotNil(bmi)
        XCTAssertEqual(bmi!, 23.15, accuracy: 0.01) // 75 / (1.8 * 1.8)
    }
    
    func testWeightEntryBMIWithoutUser() {
        // Given
        let weightEntry = WeightEntry(weight: 75.0, date: Date())
        // No user assigned
        
        // When
        let bmi = weightEntry.bmi
        
        // Then
        XCTAssertNil(bmi)
    }
    
    func testWeightEntryBMICategory() {
        // Given - User with different weights
        let testCases: [(Double, String)] = [
            (50.0, "bmi_underweight"),  // BMI ~15.4
            (65.0, "bmi_normal"),      // BMI ~20.1
            (85.0, "bmi_overweight"),  // BMI ~26.2
            (110.0, "bmi_obese")       // BMI ~34.0
        ]
        
        for (weight, expectedCategory) in testCases {
            // When
            let weightEntry = WeightEntry(weight: weight, date: Date())
            weightEntry.user = testUser
            
            // Then
            let category = weightEntry.bmiCategory
            XCTAssertNotNil(category)
            XCTAssertTrue(category!.contains(expectedCategory.replacingOccurrences(of: "bmi_", with: "")))
        }
    }
    
    func testWeightEntryBMIColor() {
        // Given - Different BMI values
        let testCases: [(Double, Color)] = [
            (50.0, .blue),     // Underweight
            (65.0, .green),    // Normal
            (85.0, .yellow),   // Overweight
            (110.0, .red)      // Obese
        ]
        
        for (weight, expectedColor) in testCases {
            // When
            let weightEntry = WeightEntry(weight: weight, date: Date())
            weightEntry.user = testUser
            
            // Then
            let color = weightEntry.bmiColor
            XCTAssertEqual(color, expectedColor)
        }
    }
    
    func testWeightEntryDisplayDate() {
        // Given
        let date = Date()
        let weightEntry = WeightEntry(weight: 75.0, date: date)
        
        // When
        let displayDate = weightEntry.displayDate
        
        // Then
        XCTAssertFalse(displayDate.isEmpty)
        
        // Should be formatted as medium date
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        let expectedDate = formatter.string(from: date)
        
        XCTAssertEqual(displayDate, expectedDate)
    }
    
    // MARK: - BodyMeasurement Tests
    
    func testBodyMeasurementInitialization() {
        // Given
        let type = "chest"
        let value = 102.0
        let date = Date()
        let notes = "Post-workout measurement"
        let leftValue = 35.0
        let rightValue = 35.5
        
        // When
        let measurement = BodyMeasurement(
            type: type,
            value: value,
            date: date,
            notes: notes,
            leftValue: leftValue,
            rightValue: rightValue
        )
        
        // Then
        XCTAssertNotNil(measurement.id)
        XCTAssertEqual(measurement.type, type)
        XCTAssertEqual(measurement.value, value)
        XCTAssertEqual(measurement.date, date)
        XCTAssertEqual(measurement.notes, notes)
        XCTAssertEqual(measurement.leftValue, leftValue)
        XCTAssertEqual(measurement.rightValue, rightValue)
        XCTAssertNotNil(measurement.createdAt)
    }
    
    func testBodyMeasurementTypeEnum() {
        // Given
        let measurement = BodyMeasurement(type: "chest", value: 100.0, date: Date())
        
        // When
        let typeEnum = measurement.typeEnum
        
        // Then
        XCTAssertEqual(typeEnum, .chest)
        
        // Test invalid type fallback
        measurement.type = "invalid_type"
        XCTAssertEqual(measurement.typeEnum, .chest) // Fallback
    }
    
    func testBodyMeasurementAverageValue() {
        // Given - Paired measurement
        let pairedMeasurement = BodyMeasurement(
            type: "left_arm",
            value: 0, // Not used for paired measurements
            date: Date(),
            leftValue: 34.0,
            rightValue: 36.0
        )
        
        // When
        let averageValue = pairedMeasurement.averageValue
        
        // Then
        XCTAssertEqual(averageValue, 35.0) // (34 + 36) / 2
        
        // Given - Single measurement
        let singleMeasurement = BodyMeasurement(type: "chest", value: 102.0, date: Date())
        
        // When
        let singleValue = singleMeasurement.averageValue
        
        // Then
        XCTAssertEqual(singleValue, 102.0)
    }
    
    func testBodyMeasurementIsPaired() {
        // Given - Paired measurement
        let pairedMeasurement = BodyMeasurement(
            type: "left_arm",
            value: 0,
            date: Date(),
            leftValue: 34.0,
            rightValue: 36.0
        )
        
        // When & Then
        XCTAssertTrue(pairedMeasurement.isPaired)
        
        // Given - Single measurement
        let singleMeasurement = BodyMeasurement(type: "chest", value: 102.0, date: Date())
        
        // When & Then
        XCTAssertFalse(singleMeasurement.isPaired)
    }
    
    func testBodyMeasurementSymmetryPercentage() {
        // Given - Symmetric measurements
        let symmetricMeasurement = BodyMeasurement(
            type: "left_arm",
            value: 0,
            date: Date(),
            leftValue: 35.0,
            rightValue: 35.0
        )
        
        // When
        let symmetricPercentage = symmetricMeasurement.symmetryPercentage
        
        // Then
        XCTAssertEqual(symmetricPercentage, 100.0)
        
        // Given - Asymmetric measurements
        let asymmetricMeasurement = BodyMeasurement(
            type: "left_arm",
            value: 0,
            date: Date(),
            leftValue: 32.0,
            rightValue: 36.0
        )
        
        // When
        let asymmetricPercentage = asymmetricMeasurement.symmetryPercentage
        
        // Then
        XCTAssertEqual(asymmetricPercentage!, 88.89, accuracy: 0.01) // (32/36) * 100
    }
    
    func testBodyMeasurementDisplayValue() {
        // Given - Paired measurement
        let pairedMeasurement = BodyMeasurement(
            type: "left_arm",
            value: 0,
            date: Date(),
            leftValue: 34.5,
            rightValue: 35.5
        )
        
        // When
        let pairedDisplay = pairedMeasurement.displayValue
        
        // Then
        XCTAssertEqual(pairedDisplay, "L: 34.5 cm, R: 35.5 cm")
        
        // Given - Single measurement
        let singleMeasurement = BodyMeasurement(type: "chest", value: 102.5, date: Date())
        
        // When
        let singleDisplay = singleMeasurement.displayValue
        
        // Then
        XCTAssertEqual(singleDisplay, "102.5 cm")
    }
    
    // MARK: - ProgressPhoto Tests
    
    func testProgressPhotoInitialization() {
        // Given
        let type = "front"
        let imageData = Data([0x01, 0x02, 0x03, 0x04])
        let date = Date()
        let notes = "Progress after 3 months"
        let weight = 75.0
        let bodyFat = 15.0
        
        // When
        let photo = ProgressPhoto(
            type: type,
            imageData: imageData,
            date: date,
            notes: notes,
            weight: weight,
            bodyFat: bodyFat,
            isVisible: true,
            isFavorite: true
        )
        
        // Then
        XCTAssertNotNil(photo.id)
        XCTAssertEqual(photo.type, type)
        XCTAssertEqual(photo.imageData, imageData)
        XCTAssertEqual(photo.date, date)
        XCTAssertEqual(photo.notes, notes)
        XCTAssertEqual(photo.weight, weight)
        XCTAssertEqual(photo.bodyFat, bodyFat)
        XCTAssertTrue(photo.isVisible)
        XCTAssertTrue(photo.isFavorite)
        XCTAssertNotNil(photo.createdAt)
    }
    
    func testProgressPhotoMinimalInitialization() {
        // Given
        let type = "side"
        let imageData = Data([0x01, 0x02])
        let date = Date()
        
        // When
        let photo = ProgressPhoto(type: type, imageData: imageData, date: date)
        
        // Then
        XCTAssertEqual(photo.type, type)
        XCTAssertEqual(photo.imageData, imageData)
        XCTAssertEqual(photo.date, date)
        XCTAssertNil(photo.notes)
        XCTAssertNil(photo.weight)
        XCTAssertNil(photo.bodyFat)
        XCTAssertTrue(photo.isVisible) // Default
        XCTAssertFalse(photo.isFavorite) // Default
    }
    
    func testProgressPhotoTypeEnum() {
        // Given
        let photo = ProgressPhoto(type: "front", imageData: nil, date: Date())
        
        // When
        let typeEnum = photo.typeEnum
        
        // Then
        XCTAssertEqual(typeEnum, .front)
        
        // Test invalid type fallback
        photo.type = "invalid_type"
        XCTAssertEqual(photo.typeEnum, .front) // Fallback
    }
    
    func testProgressPhotoFileSizeMB() {
        // Given - 1KB data
        let oneKBData = Data(repeating: 0x01, count: 1024)
        let photo = ProgressPhoto(type: "front", imageData: oneKBData, date: Date())
        
        // When
        let fileSizeMB = photo.fileSizeMB
        
        // Then
        XCTAssertEqual(fileSizeMB, 0.0009765625, accuracy: 0.0001) // 1KB in MB
        
        // Given - No data
        let emptyPhoto = ProgressPhoto(type: "front", imageData: nil, date: Date())
        
        // When
        let emptyFileSize = emptyPhoto.fileSizeMB
        
        // Then
        XCTAssertEqual(emptyFileSize, 0.0)
    }
    
    func testProgressPhotoHasMetadata() {
        // Given - Photo with metadata
        let photoWithMetadata = ProgressPhoto(
            type: "front",
            imageData: nil,
            date: Date(),
            notes: "Progress notes",
            weight: 75.0
        )
        
        // When & Then
        XCTAssertTrue(photoWithMetadata.hasMetadata)
        
        // Given - Photo without metadata
        let photoWithoutMetadata = ProgressPhoto(type: "front", imageData: nil, date: Date())
        
        // When & Then
        XCTAssertFalse(photoWithoutMetadata.hasMetadata)
    }
    
    // MARK: - Goal Tests
    
    func testGoalInitialization() {
        // Given
        let title = "Lose 5kg"
        let description = "Target weight for summer"
        let type = GoalType.weight
        let targetValue = 70.0
        let currentValue = 75.0
        let deadline = Calendar.current.date(byAdding: .month, value: 3, to: Date())!
        let priority = 5
        let category = "health"
        
        // When
        let goal = Goal(
            title: title,
            description: description,
            type: type,
            targetValue: targetValue,
            currentValue: currentValue,
            deadline: deadline,
            priority: priority,
            category: category
        )
        
        // Then
        XCTAssertNotNil(goal.id)
        XCTAssertEqual(goal.title, title)
        XCTAssertEqual(goal.goalDescription, description)
        XCTAssertEqual(goal.type, type.rawValue)
        XCTAssertEqual(goal.targetValue, targetValue)
        XCTAssertEqual(goal.currentValue, currentValue)
        XCTAssertEqual(goal.deadline, deadline)
        XCTAssertEqual(goal.priority, priority)
        XCTAssertEqual(goal.category, category)
        XCTAssertTrue(goal.isActive)
        XCTAssertFalse(goal.isCompleted)
        XCTAssertTrue(goal.reminderEnabled)
        XCTAssertNotNil(goal.createdDate)
        XCTAssertNil(goal.completedDate)
    }
    
    func testGoalMinimalInitialization() {
        // Given
        let title = "Basic Goal"
        let type = GoalType.strength
        let targetValue = 100.0
        
        // When
        let goal = Goal(title: title, type: type, targetValue: targetValue)
        
        // Then
        XCTAssertEqual(goal.title, title)
        XCTAssertEqual(goal.typeEnum, type)
        XCTAssertEqual(goal.targetValue, targetValue)
        XCTAssertEqual(goal.currentValue, 0.0) // Default
        XCTAssertNil(goal.deadline)
        XCTAssertEqual(goal.priority, 3) // Default
        XCTAssertEqual(goal.category, "general") // Default
    }
    
    func testGoalProgressPercentage() {
        // Given
        let goal = Goal(title: "Test Goal", type: .weight, targetValue: 100.0, currentValue: 25.0)
        
        // When
        let progress = goal.progressPercentage
        
        // Then
        XCTAssertEqual(progress, 25.0)
        
        // Test over 100%
        goal.currentValue = 120.0
        XCTAssertEqual(goal.progressPercentage, 100.0) // Capped at 100%
        
        // Test negative progress
        goal.currentValue = -10.0
        XCTAssertEqual(goal.progressPercentage, 0.0) // Floored at 0%
    }
    
    func testGoalIsExpired() {
        // Given - Future deadline
        let futureGoal = Goal(
            title: "Future Goal",
            type: .weight,
            targetValue: 70.0,
            deadline: Calendar.current.date(byAdding: .day, value: 30, to: Date())!
        )
        
        // When & Then
        XCTAssertFalse(futureGoal.isExpired)
        
        // Given - Past deadline
        let expiredGoal = Goal(
            title: "Expired Goal",
            type: .weight,
            targetValue: 70.0,
            deadline: Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        )
        
        // When & Then
        XCTAssertTrue(expiredGoal.isExpired)
        
        // Given - Completed goal with past deadline
        expiredGoal.markAsCompleted()
        XCTAssertFalse(expiredGoal.isExpired) // Completed goals are not expired
    }
    
    func testGoalRemainingValue() {
        // Given
        let goal = Goal(title: "Test Goal", type: .weight, targetValue: 100.0, currentValue: 30.0)
        
        // When
        let remaining = goal.remainingValue
        
        // Then
        XCTAssertEqual(remaining, 70.0)
        
        // Test completed goal
        goal.currentValue = 100.0
        XCTAssertEqual(goal.remainingValue, 0.0)
        
        // Test over-completed goal
        goal.currentValue = 110.0
        XCTAssertEqual(goal.remainingValue, 0.0)
    }
    
    func testGoalDaysRemaining() {
        // Given - Goal with deadline
        let futureDate = Calendar.current.date(byAdding: .day, value: 15, to: Date())!
        let goal = Goal(title: "Test Goal", type: .weight, targetValue: 70.0, deadline: futureDate)
        
        // When
        let daysRemaining = goal.daysRemaining
        
        // Then
        XCTAssertNotNil(daysRemaining)
        XCTAssertEqual(daysRemaining!, 15, accuracy: 1) // Allow 1 day accuracy due to timing
        
        // Given - Goal without deadline
        let goalWithoutDeadline = Goal(title: "No Deadline", type: .weight, targetValue: 70.0)
        
        // When & Then
        XCTAssertNil(goalWithoutDeadline.daysRemaining)
    }
    
    func testGoalPriorityEmoji() {
        // Test all priority levels
        let testCases: [(Int, String)] = [
            (1, "⚪"),
            (2, "💡"),
            (3, "📌"),
            (4, "⭐"),
            (5, "🔥")
        ]
        
        for (priority, expectedEmoji) in testCases {
            // Given
            let goal = Goal(title: "Test", type: .weight, targetValue: 70.0, priority: priority)
            
            // When & Then
            XCTAssertEqual(goal.priorityEmoji, expectedEmoji)
        }
    }
    
    func testGoalPriorityColor() {
        // Test priority colors
        let testCases: [(Int, Color)] = [
            (1, .gray),
            (2, .green),
            (3, .blue),
            (4, .orange),
            (5, .red)
        ]
        
        for (priority, expectedColor) in testCases {
            // Given
            let goal = Goal(title: "Test", type: .weight, targetValue: 70.0, priority: priority)
            
            // When & Then
            XCTAssertEqual(goal.priorityColor, expectedColor)
        }
    }
    
    func testGoalUpdateProgress() {
        // Given
        let goal = Goal(title: "Test Goal", type: .weight, targetValue: 100.0, currentValue: 25.0)
        XCTAssertFalse(goal.isCompleted)
        
        // When - Update progress
        goal.updateProgress(50.0)
        
        // Then
        XCTAssertEqual(goal.currentValue, 50.0)
        XCTAssertFalse(goal.isCompleted)
        
        // When - Complete goal
        goal.updateProgress(100.0)
        
        // Then
        XCTAssertEqual(goal.currentValue, 100.0)
        XCTAssertTrue(goal.isCompleted)
        XCTAssertNotNil(goal.completedDate)
    }
    
    func testGoalMarkAsCompleted() {
        // Given
        let goal = Goal(title: "Test Goal", type: .weight, targetValue: 100.0, currentValue: 75.0)
        XCTAssertFalse(goal.isCompleted)
        XCTAssertNil(goal.completedDate)
        
        // When
        goal.markAsCompleted()
        
        // Then
        XCTAssertTrue(goal.isCompleted)
        XCTAssertNotNil(goal.completedDate)
        XCTAssertEqual(goal.currentValue, 100.0) // Set to target value
    }
    
    func testGoalReset() {
        // Given - Completed goal
        let goal = Goal(title: "Test Goal", type: .weight, targetValue: 100.0)
        goal.markAsCompleted()
        goal.isActive = false
        
        XCTAssertTrue(goal.isCompleted)
        XCTAssertFalse(goal.isActive)
        
        // When
        goal.reset()
        
        // Then
        XCTAssertEqual(goal.currentValue, 0.0)
        XCTAssertFalse(goal.isCompleted)
        XCTAssertNil(goal.completedDate)
        XCTAssertTrue(goal.isActive)
    }
    
    // MARK: - Enum Tests
    
    func testMeasurementTypeProperties() {
        // Test all measurement types have required properties
        for type in MeasurementType.allCases {
            XCTAssertFalse(type.displayName.isEmpty, "Type \(type) should have display name")
            XCTAssertFalse(type.icon.isEmpty, "Type \(type) should have icon")
            XCTAssertNotNil(type.color, "Type \(type) should have color")
            XCTAssertNotNil(type.category, "Type \(type) should have category")
        }
    }
    
    func testMeasurementTypeSymmetry() {
        // Test symmetry properties
        let symmetricalTypes: [MeasurementType] = [.leftArm, .rightArm, .leftThigh, .rightThigh, .forearm, .calf]
        let nonSymmetricalTypes: [MeasurementType] = [.chest, .waist, .hips, .neck, .shoulders]
        
        for type in symmetricalTypes {
            XCTAssertTrue(type.isSymmetrical, "Type \(type) should be symmetrical")
        }
        
        for type in nonSymmetricalTypes {
            XCTAssertFalse(type.isSymmetrical, "Type \(type) should not be symmetrical")
        }
    }
    
    func testMeasurementCategories() {
        // Test category mappings
        let torsoTypes: [MeasurementType] = [.chest, .waist, .hips, .shoulders]
        let armTypes: [MeasurementType] = [.leftArm, .rightArm, .forearm]
        let legTypes: [MeasurementType] = [.leftThigh, .rightThigh, .calf]
        let headTypes: [MeasurementType] = [.neck]
        
        for type in torsoTypes {
            XCTAssertEqual(type.category, .torso)
        }
        for type in armTypes {
            XCTAssertEqual(type.category, .arms)
        }
        for type in legTypes {
            XCTAssertEqual(type.category, .legs)
        }
        for type in headTypes {
            XCTAssertEqual(type.category, .head)
        }
    }
    
    func testPhotoTypeProperties() {
        // Test all photo types have required properties
        for type in PhotoType.allCases {
            XCTAssertFalse(type.displayName.isEmpty, "Photo type \(type) should have display name")
            XCTAssertFalse(type.instruction.isEmpty, "Photo type \(type) should have instruction")
            XCTAssertFalse(type.icon.isEmpty, "Photo type \(type) should have icon")
            XCTAssertNotNil(type.color, "Photo type \(type) should have color")
        }
    }
    
    func testGoalTypeProperties() {
        // Test all goal types have required properties
        for type in GoalType.allCases {
            XCTAssertFalse(type.displayName.isEmpty, "Goal type \(type) should have display name")
            XCTAssertFalse(type.unit.isEmpty, "Goal type \(type) should have unit")
            XCTAssertFalse(type.icon.isEmpty, "Goal type \(type) should have icon")
            XCTAssertNotNil(type.color, "Goal type \(type) should have color")
        }
    }
    
    func testMeasurementCategoryProperties() {
        // Test all measurement categories have required properties
        for category in MeasurementCategory.allCases {
            XCTAssertFalse(category.displayName.isEmpty, "Category \(category) should have display name")
            XCTAssertFalse(category.icon.isEmpty, "Category \(category) should have icon")
        }
    }
    
    // MARK: - Predicate Tests
    
    func testWeightEntryRecentPredicate() throws {
        // Given - Weight entries from different dates
        let now = Date()
        let recentEntry = WeightEntry(weight: 75.0, date: now.addingTimeInterval(-2 * 24 * 3600)) // 2 days ago
        let oldEntry = WeightEntry(weight: 76.0, date: now.addingTimeInterval(-10 * 24 * 3600)) // 10 days ago
        
        modelContext.insert(recentEntry)
        modelContext.insert(oldEntry)
        try modelContext.save()
        
        // When - Fetch recent entries (7 days)
        let predicate = WeightEntry.recentEntriesPredicate(days: 7)
        let fetchDescriptor = FetchDescriptor<WeightEntry>(predicate: predicate)
        let recentEntries = try modelContext.fetch(fetchDescriptor)
        
        // Then
        XCTAssertEqual(recentEntries.count, 1)
        XCTAssertEqual(recentEntries.first?.weight, 75.0)
    }
    
    func testBodyMeasurementTypePredicate() throws {
        // Given - Different measurement types
        let chestMeasurement = BodyMeasurement(type: "chest", value: 102.0, date: Date())
        let waistMeasurement = BodyMeasurement(type: "waist", value: 85.0, date: Date())
        
        modelContext.insert(chestMeasurement)
        modelContext.insert(waistMeasurement)
        try modelContext.save()
        
        // When - Fetch chest measurements only
        let predicate = BodyMeasurement.typePredicate(.chest)
        let fetchDescriptor = FetchDescriptor<BodyMeasurement>(predicate: predicate)
        let chestMeasurements = try modelContext.fetch(fetchDescriptor)
        
        // Then
        XCTAssertEqual(chestMeasurements.count, 1)
        XCTAssertEqual(chestMeasurements.first?.type, "chest")
    }
    
    func testProgressPhotoVisiblePredicate() throws {
        // Given - Visible and hidden photos
        let visiblePhoto = ProgressPhoto(type: "front", imageData: nil, date: Date(), isVisible: true)
        let hiddenPhoto = ProgressPhoto(type: "back", imageData: nil, date: Date(), isVisible: false)
        
        modelContext.insert(visiblePhoto)
        modelContext.insert(hiddenPhoto)
        try modelContext.save()
        
        // When - Fetch visible photos only
        let predicate = ProgressPhoto.visiblePhotosPredicate
        let fetchDescriptor = FetchDescriptor<ProgressPhoto>(predicate: predicate)
        let visiblePhotos = try modelContext.fetch(fetchDescriptor)
        
        // Then
        XCTAssertEqual(visiblePhotos.count, 1)
        XCTAssertTrue(visiblePhotos.first!.isVisible)
    }
    
    func testGoalActiveAndCompletedPredicates() throws {
        // Given - Active and completed goals
        let activeGoal = Goal(title: "Active Goal", type: .weight, targetValue: 70.0)
        let completedGoal = Goal(title: "Completed Goal", type: .strength, targetValue: 100.0)
        completedGoal.markAsCompleted()
        let inactiveGoal = Goal(title: "Inactive Goal", type: .bodyFat, targetValue: 15.0)
        inactiveGoal.isActive = false
        
        modelContext.insert(activeGoal)
        modelContext.insert(completedGoal)
        modelContext.insert(inactiveGoal)
        try modelContext.save()
        
        // When - Fetch active goals
        let activePredicate = Goal.activeGoalsPredicate
        let activeDescriptor = FetchDescriptor<Goal>(predicate: activePredicate)
        let activeGoals = try modelContext.fetch(activeDescriptor)
        
        // Then
        XCTAssertEqual(activeGoals.count, 1)
        XCTAssertEqual(activeGoals.first?.title, "Active Goal")
        
        // When - Fetch completed goals
        let completedPredicate = Goal.completedGoalsPredicate
        let completedDescriptor = FetchDescriptor<Goal>(predicate: completedPredicate)
        let completedGoals = try modelContext.fetch(completedDescriptor)
        
        // Then
        XCTAssertEqual(completedGoals.count, 1)
        XCTAssertEqual(completedGoals.first?.title, "Completed Goal")
    }
    
    func testGoalHighPriorityPredicate() throws {
        // Given - Goals with different priorities
        let lowPriorityGoal = Goal(title: "Low Priority", type: .weight, targetValue: 70.0, priority: 2)
        let highPriorityGoal = Goal(title: "High Priority", type: .strength, targetValue: 100.0, priority: 5)
        let mediumPriorityGoal = Goal(title: "Medium Priority", type: .endurance, targetValue: 50.0, priority: 3)
        
        modelContext.insert(lowPriorityGoal)
        modelContext.insert(highPriorityGoal)
        modelContext.insert(mediumPriorityGoal)
        try modelContext.save()
        
        // When - Fetch high priority goals (priority >= 4)
        let predicate = Goal.highPriorityGoalsPredicate
        let fetchDescriptor = FetchDescriptor<Goal>(predicate: predicate)
        let highPriorityGoals = try modelContext.fetch(fetchDescriptor)
        
        // Then
        XCTAssertEqual(highPriorityGoals.count, 1)
        XCTAssertEqual(highPriorityGoals.first?.title, "High Priority")
    }
    
    // MARK: - SwiftData Integration Tests
    
    func testBodyTrackingModelsPersistence() throws {
        // Given - Various body tracking models
        let weightEntry = WeightEntry(weight: 75.0, date: Date(), notes: "Test weight", bodyFat: 15.0)
        let bodyMeasurement = BodyMeasurement(type: "chest", value: 102.0, date: Date())
        let progressPhoto = ProgressPhoto(type: "front", imageData: Data([0x01, 0x02]), date: Date())
        let goal = Goal(title: "Test Goal", type: .weight, targetValue: 70.0)
        
        weightEntry.user = testUser
        bodyMeasurement.user = testUser
        progressPhoto.user = testUser
        goal.user = testUser
        
        // When
        modelContext.insert(weightEntry)
        modelContext.insert(bodyMeasurement)
        modelContext.insert(progressPhoto)
        modelContext.insert(goal)
        try modelContext.save()
        
        // Then - Verify all models are saved
        let weightEntries = try modelContext.fetch(FetchDescriptor<WeightEntry>())
        let bodyMeasurements = try modelContext.fetch(FetchDescriptor<BodyMeasurement>())
        let progressPhotos = try modelContext.fetch(FetchDescriptor<ProgressPhoto>())
        let goals = try modelContext.fetch(FetchDescriptor<Goal>())
        
        XCTAssertEqual(weightEntries.count, 1)
        XCTAssertEqual(bodyMeasurements.count, 1)
        XCTAssertEqual(progressPhotos.count, 1)
        XCTAssertEqual(goals.count, 1)
        
        // Verify relationships
        XCTAssertEqual(weightEntries.first?.user, testUser)
        XCTAssertEqual(bodyMeasurements.first?.user, testUser)
        XCTAssertEqual(progressPhotos.first?.user, testUser)
        XCTAssertEqual(goals.first?.user, testUser)
    }
    
    // MARK: - Performance Tests
    
    func testBulkWeightEntryInsertion() {
        measure {
            let entries = (1...50).map { i in
                WeightEntry(
                    weight: 75.0 + Double(i) * 0.1,
                    date: Date().addingTimeInterval(TimeInterval(i * 24 * 3600)),
                    notes: "Entry \(i)"
                )
            }
            
            for entry in entries {
                modelContext.insert(entry)
            }
            
            do {
                try modelContext.save()
            } catch {
                XCTFail("Failed to save weight entries: \(error)")
            }
        }
    }
    
    func testComplexGoalOperations() {
        measure {
            for i in 1...20 {
                let goal = Goal(
                    title: "Goal \(i)",
                    type: GoalType.allCases.randomElement()!,
                    targetValue: Double(50 + i),
                    currentValue: Double(i),
                    priority: (i % 5) + 1
                )
                
                // Perform various operations
                let _ = goal.progressPercentage
                let _ = goal.remainingValue
                let _ = goal.statusText
                let _ = goal.priorityEmoji
                let _ = goal.priorityColor
                
                if i % 3 == 0 {
                    goal.updateProgress(Double(25 + i))
                }
                
                if i % 5 == 0 {
                    goal.markAsCompleted()
                }
            }
        }
    }
    
    // MARK: - Integration Tests
    
    func testCompleteBodyTrackingWorkflow() throws {
        // Test a complete body tracking workflow
        
        // Step 1: Add initial weight entry
        let initialWeight = WeightEntry(weight: 80.0, date: Date(), notes: "Starting weight")
        initialWeight.user = testUser
        modelContext.insert(initialWeight)
        
        // Step 2: Add initial measurements
        let chestMeasurement = BodyMeasurement(type: "chest", value: 105.0, date: Date())
        chestMeasurement.user = testUser
        modelContext.insert(chestMeasurement)
        
        // Step 3: Take progress photo
        let progressPhoto = ProgressPhoto(
            type: "front",
            imageData: Data(repeating: 0x01, count: 100),
            date: Date(),
            weight: 80.0,
            isFavorite: true
        )
        progressPhoto.user = testUser
        modelContext.insert(progressPhoto)
        
        // Step 4: Set weight loss goal
        let weightGoal = Goal(
            title: "Lose 10kg",
            description: "Target weight for health",
            type: .weight,
            targetValue: 70.0,
            currentValue: 80.0,
            deadline: Calendar.current.date(byAdding: .month, value: 6, to: Date()),
            priority: 5
        )
        weightGoal.user = testUser
        modelContext.insert(weightGoal)
        
        // Step 5: Save all data
        try modelContext.save()
        
        // Step 6: Simulate progress - update weight
        let updatedWeight = WeightEntry(weight: 75.0, date: Date().addingTimeInterval(30 * 24 * 3600))
        updatedWeight.user = testUser
        modelContext.insert(updatedWeight)
        
        // Step 7: Update goal progress
        weightGoal.updateProgress(75.0)
        
        // Step 8: Add new measurements
        let updatedChest = BodyMeasurement(type: "chest", value: 100.0, date: Date().addingTimeInterval(30 * 24 * 3600))
        updatedChest.user = testUser
        modelContext.insert(updatedChest)
        
        // Step 9: Save progress
        try modelContext.save()
        
        // Step 10: Verify complete workflow
        let allWeightEntries = try modelContext.fetch(FetchDescriptor<WeightEntry>(
            sortBy: [SortDescriptor(\.date)]
        ))
        let allMeasurements = try modelContext.fetch(FetchDescriptor<BodyMeasurement>(
            sortBy: [SortDescriptor(\.date)]
        ))
        let allPhotos = try modelContext.fetch(FetchDescriptor<ProgressPhoto>())
        let allGoals = try modelContext.fetch(FetchDescriptor<Goal>())
        
        // Verify data integrity
        XCTAssertEqual(allWeightEntries.count, 2)
        XCTAssertEqual(allMeasurements.count, 2)
        XCTAssertEqual(allPhotos.count, 1)
        XCTAssertEqual(allGoals.count, 1)
        
        // Verify progress tracking
        let latestWeight = allWeightEntries.last!
        XCTAssertEqual(latestWeight.weight, 75.0)
        
        let goal = allGoals.first!
        XCTAssertEqual(goal.currentValue, 75.0)
        XCTAssertFalse(goal.isCompleted) // Still 5kg to go
        
        let progressPercentage = (80.0 - 75.0) / (80.0 - 70.0) * 100 // 50% progress
        XCTAssertEqual(goal.progressPercentage, 50.0, accuracy: 0.1)
        
        print("Complete body tracking workflow test passed")
    }
}

// MARK: - Test Extensions

extension BodyTrackingModelsTests {
    
    /// Helper method to create test measurement with specific type
    private func createTestMeasurement(type: MeasurementType, value: Double) -> BodyMeasurement {
        let measurement = BodyMeasurement(type: type.rawValue, value: value, date: Date())
        measurement.user = testUser
        return measurement
    }
    
    /// Test measurement grouping by category
    func testMeasurementGroupingByCategory() throws {
        // Given - Measurements from different categories
        let measurements = [
            createTestMeasurement(type: .chest, value: 102.0),
            createTestMeasurement(type: .waist, value: 85.0),
            createTestMeasurement(type: .leftArm, value: 35.0),
            createTestMeasurement(type: .rightThigh, value: 58.0),
            createTestMeasurement(type: .neck, value: 37.0)
        ]
        
        for measurement in measurements {
            modelContext.insert(measurement)
        }
        try modelContext.save()
        
        // When - Group by categories
        let torsoMeasurements = measurements.filter { $0.typeEnum.category == .torso }
        let armMeasurements = measurements.filter { $0.typeEnum.category == .arms }
        let legMeasurements = measurements.filter { $0.typeEnum.category == .legs }
        let headMeasurements = measurements.filter { $0.typeEnum.category == .head }
        
        // Then
        XCTAssertEqual(torsoMeasurements.count, 2) // chest, waist
        XCTAssertEqual(armMeasurements.count, 1)  // leftArm
        XCTAssertEqual(legMeasurements.count, 1)  // rightThigh
        XCTAssertEqual(headMeasurements.count, 1) // neck
    }
}