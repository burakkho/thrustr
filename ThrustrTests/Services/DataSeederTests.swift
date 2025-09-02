import XCTest
import SwiftData
@testable import Thrustr

/**
 * Comprehensive tests for DataSeeder
 * Tests CSV parsing, JSON parsing, database seeding, error handling, and data validation
 */
@MainActor
final class DataSeederTests: XCTestCase {
    
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
    
    // MARK: - DataSeederError Tests
    
    func testDataSeederErrorDescriptions() {
        // Given - Different error types
        let errors: [DataSeederError] = [
            .fileNotFound("test.csv"),
            .emptyFile("empty.csv"),
            .invalidDataFormat("Invalid CSV format"),
            .parsingError("JSON parsing failed"),
            .databaseError("Database connection failed")
        ]
        
        // When & Then
        for error in errors {
            let description = error.localizedDescription
            XCTAssertFalse(description.isEmpty, "Error \(error) should have description")
            
            switch error {
            case .fileNotFound(let filename):
                XCTAssertTrue(description.contains("File not found"))
                XCTAssertTrue(description.contains(filename))
            case .emptyFile(let filename):
                XCTAssertTrue(description.contains("File is empty"))
                XCTAssertTrue(description.contains(filename))
            case .invalidDataFormat(let message):
                XCTAssertTrue(description.contains("Invalid data format"))
                XCTAssertTrue(description.contains(message))
            case .parsingError(let message):
                XCTAssertTrue(description.contains("Parsing error"))
                XCTAssertTrue(description.contains(message))
            case .databaseError(let message):
                XCTAssertTrue(description.contains("Database error"))
                XCTAssertTrue(description.contains(message))
            }
        }
    }
    
    // MARK: - CSV Parser Tests
    
    func testCSVParseRow() {
        // Given - CSV row with different formats
        let testCases: [(String, [String])] = [
            ("apple,banana,cherry", ["apple", "banana", "cherry"]),
            ("\"quoted field\",normal,\"another quoted\"", ["quoted field", "normal", "another quoted"]),
            ("  spaced  ,  fields  ,  here  ", ["spaced", "fields", "here"]),
            ("empty,,fields", ["empty", "", "fields"]),
            ("single_field", ["single_field"])
        ]
        
        // When & Then
        for (input, expected) in testCases {
            let result = DataSeeder.CSVParser.parseCSVRow(input)
            XCTAssertEqual(result, expected, "Failed to parse: '\(input)'")
        }
    }
    
    func testCSVParseRowWithQuotes() {
        // Given - CSV with complex quoted fields
        let testRow = "\"Name with, comma\",123,\"Description with \"\"quotes\"\"\"",simple"
        
        // When
        let result = DataSeeder.CSVParser.parseCSVRow(testRow)
        
        // Then
        XCTAssertEqual(result.count, 4)
        XCTAssertEqual(result[0], "Name with, comma")
        XCTAssertEqual(result[1], "123")
        XCTAssertEqual(result[2], "Description with \"quotes\"")
        XCTAssertEqual(result[3], "simple")
    }
    
    func testCSVParseEmptyRow() {
        // Given - Empty and whitespace rows
        let testCases = ["", "   ", "\t", "   \t  "]
        
        // When & Then
        for testRow in testCases {
            let result = DataSeeder.CSVParser.parseCSVRow(testRow)
            // Empty rows should return array with empty string or be handled gracefully
            XCTAssertTrue(result.isEmpty || result.allSatisfy { $0.isEmpty })
        }
    }
    
    // MARK: - Database State Tests
    
    func testIsDatabaseEmpty() async {
        // Given - Empty database initially
        let isEmpty = await DataSeeder.isDatabaseEmpty(modelContext: modelContext)
        
        // Then
        XCTAssertTrue(isEmpty)
        
        // Given - Add an exercise
        let testExercise = Exercise(nameEN: "Test Exercise", nameTR: "Test Exercise", category: "test", equipment: "none")
        modelContext.insert(testExercise)
        try? modelContext.save()
        
        // When
        let isEmptyAfter = await DataSeeder.isDatabaseEmpty(modelContext: modelContext)
        
        // Then
        XCTAssertFalse(isEmptyAfter)
    }
    
    // MARK: - Exercise Creation Tests
    
    func testCreateExerciseFromCSVValidData() throws {
        // Given - Valid CSV data
        let validColumns = [
            "Push Up",           // nameEN
            "Şınav",            // nameTR
            "push",             // category
            "bodyweight",       // equipment
            "false",            // supportsWeight
            "true",             // supportsReps
            "true",             // supportsTime
            "false"             // supportsDistance
        ]
        
        // When
        let exercise = try DataSeeder.createExerciseFromCSV(columns: validColumns)
        
        // Then
        XCTAssertEqual(exercise.nameEN, "Push Up")
        XCTAssertEqual(exercise.nameTR, "Şınav")
        XCTAssertEqual(exercise.category, "push")
        XCTAssertEqual(exercise.equipment, "bodyweight")
        XCTAssertFalse(exercise.supportsWeight)
        XCTAssertTrue(exercise.supportsReps)
        XCTAssertTrue(exercise.supportsTime)
        XCTAssertFalse(exercise.supportsDistance)
    }
    
    func testCreateExerciseFromCSVMinimalData() throws {
        // Given - Minimal CSV data (only first 4 columns)
        let minimalColumns = ["Squat", "Çömelme", "legs", "barbell"]
        
        // When
        let exercise = try DataSeeder.createExerciseFromCSV(columns: minimalColumns)
        
        // Then
        XCTAssertEqual(exercise.nameEN, "Squat")
        XCTAssertEqual(exercise.nameTR, "Çömelme")
        XCTAssertEqual(exercise.category, "legs")
        XCTAssertEqual(exercise.equipment, "barbell")
        
        // Default values should be set (defaults in Exercise model)
        // These would be the model's default values
    }
    
    func testCreateExerciseFromCSVInvalidData() {
        // Given - Invalid CSV data
        let invalidCases: [[String]] = [
            [], // Empty
            ["Only one column"], // Too few columns
            ["", "Name", "category", "equipment"], // Empty name
            ["Name", "Turkish"] // Missing required fields
        ]
        
        for invalidColumns in invalidCases {
            // When & Then
            XCTAssertThrowsError(
                try DataSeeder.createExerciseFromCSV(columns: invalidColumns),
                "Should throw error for invalid data: \(invalidColumns)"
            ) { error in
                XCTAssertTrue(error is DataSeederError)
            }
        }
    }
    
    func testCreateExerciseFromCSVWithEmptyTurkishName() throws {
        // Given - CSV with empty Turkish name
        let columns = ["English Name", "", "category", "equipment", "true", "true", "false", "false"]
        
        // When
        let exercise = try DataSeeder.createExerciseFromCSV(columns: columns)
        
        // Then - Should use English name as fallback
        XCTAssertEqual(exercise.nameEN, "English Name")
        XCTAssertEqual(exercise.nameTR, "English Name")
    }
    
    // MARK: - Food Creation Tests
    
    func testCreateFoodFromCSVValidData() throws {
        // Given - Valid food CSV data
        let validColumns = [
            "Apple",          // nameEN
            "Elma",          // nameTR
            "Generic",       // brand
            "52",            // calories
            "0.3",           // protein
            "14",            // carbs
            "0.2",           // fat
            "fruits",        // category
            "100",           // servingSizeGrams
            "1 medium"       // servingName
        ]
        
        // When
        let food = try DataSeeder.createFoodFromCSV(columns: validColumns)
        
        // Then
        XCTAssertEqual(food.nameEN, "Apple")
        XCTAssertEqual(food.nameTR, "Elma")
        XCTAssertEqual(food.brand, "Generic")
        XCTAssertEqual(food.calories, 52.0)
        XCTAssertEqual(food.protein, 0.3)
        XCTAssertEqual(food.carbs, 14.0)
        XCTAssertEqual(food.fat, 0.2)
        XCTAssertEqual(food.categoryEnum, .fruits)
        XCTAssertEqual(food.servingSizeGrams, 100.0)
        XCTAssertEqual(food.servingName, "1 medium")
    }
    
    func testCreateFoodFromCSVMinimalData() throws {
        // Given - Minimal food CSV data (8 columns)
        let minimalColumns = [
            "Banana",        // nameEN
            "Muz",          // nameTR
            "",             // brand (empty)
            "89",           // calories
            "1.1",          // protein
            "23",           // carbs
            "0.3",          // fat
            "fruits"        // category
        ]
        
        // When
        let food = try DataSeeder.createFoodFromCSV(columns: minimalColumns)
        
        // Then
        XCTAssertEqual(food.nameEN, "Banana")
        XCTAssertEqual(food.nameTR, "Muz")
        XCTAssertNil(food.brand) // Empty brand should be nil
        XCTAssertEqual(food.calories, 89.0)
        XCTAssertEqual(food.categoryEnum, .fruits)
    }
    
    func testCreateFoodFromCSVInvalidData() {
        // Given - Invalid food CSV data
        let invalidCases: [[String]] = [
            [], // Empty
            ["Only", "Two", "Columns"], // Too few columns
            ["Name", "Turkish", "Brand"] // Missing nutrition data
        ]
        
        for invalidColumns in invalidCases {
            // When & Then
            XCTAssertThrowsError(
                try DataSeeder.createFoodFromCSV(columns: invalidColumns),
                "Should throw error for invalid food data: \(invalidColumns)"
            ) { error in
                XCTAssertTrue(error is DataSeederError)
            }
        }
    }
    
    // MARK: - FoodCategory Mapping Tests
    
    func testFoodCategoryFromString() {
        // Given - Category string mappings
        let testCases: [(String, FoodCategory)] = [
            ("meat", .meat),
            ("DAIRY", .dairy),
            ("Grains", .grains),
            ("vegetables", .vegetables),
            ("FRUITS", .fruits),
            ("nuts", .nuts),
            ("beverages", .beverages),
            ("snacks", .snacks),
            ("turkish", .turkish),
            ("fastfood", .fastfood),
            ("supplements", .supplements),
            ("condiments", .condiments),
            ("bakery", .bakery),
            ("seafood", .seafood),
            ("desserts", .desserts),
            ("unknown_category", .other),
            ("", .other)
        ]
        
        // When & Then
        for (input, expected) in testCases {
            let result = FoodCategory.fromString(input)
            XCTAssertEqual(result, expected, "Failed mapping: '\(input)' -> \(expected)")
        }
    }
    
    // MARK: - Fallback Seeding Tests
    
    func testFallbackSeeding() async {
        // Given - Empty database
        let initialCount = (try? modelContext.fetchCount(FetchDescriptor<Exercise>())) ?? 0
        XCTAssertEqual(initialCount, 0)
        
        // When
        await DataSeeder.fallbackSeeding(modelContext: modelContext)
        
        // Then
        let finalCount = (try? modelContext.fetchCount(FetchDescriptor<Exercise>())) ?? 0
        XCTAssertGreaterThan(finalCount, 0, "Fallback seeding should create some exercises")
        XCTAssertLessThanOrEqual(finalCount, 10, "Fallback seeding should create minimal exercises")
        
        // Verify specific exercises were created
        let descriptor = FetchDescriptor<Exercise>()
        let exercises = (try? modelContext.fetch(descriptor)) ?? []
        let exerciseNames = exercises.map { $0.nameEN }
        
        XCTAssertTrue(exerciseNames.contains("Squat"))
        XCTAssertTrue(exerciseNames.contains("Push Up"))
        XCTAssertTrue(exerciseNames.contains("Plank"))
    }
    
    // MARK: - Data Normalization Tests
    
    
    func testNormalizeExerciseCategoriesToPartTypes() async {
        // Given - Exercises with 'other' category
        let exercises = [
            Exercise(nameEN: "Unknown Exercise 1", nameTR: "Unknown Exercise 1", category: "other", equipment: "none"),
            Exercise(nameEN: "Unknown Exercise 2", nameTR: "Unknown Exercise 2", category: "other", equipment: "none"),
            Exercise(nameEN: "Known Exercise", nameTR: "Known Exercise", category: "strength", equipment: "barbell") // Should not change
        ]
        
        for exercise in exercises {
            modelContext.insert(exercise)
        }
        try? modelContext.save()
        
        // When
        await DataSeeder.normalizeExerciseCategoriesToPartTypes(modelContext: modelContext)
        
        // Then
        let updatedExercises = (try? modelContext.fetch(FetchDescriptor<Exercise>())) ?? []
        let otherCategoryCount = updatedExercises.filter { $0.category == "other" }.count
        let strengthCategoryCount = updatedExercises.filter { $0.category == ExerciseCategory.strength.rawValue }.count
        
        XCTAssertEqual(otherCategoryCount, 0, "No exercises should have 'other' category after normalization")
        XCTAssertEqual(strengthCategoryCount, 3, "All 'other' exercises should be converted to 'strength'")
    }
    
    func testNormalizeFoodData() async {
        // Given - Foods with missing Turkish names and miscategorized items
        let foods = [
            Food(nameEN: "Apple", nameTR: "", calories: 52, protein: 0.3, carbs: 14, fat: 0.2, category: .other),
            Food(nameEN: "Milk", nameTR: "   ", calories: 42, protein: 3.4, carbs: 5, fat: 1, category: .other),
            Food(nameEN: "Banana", nameTR: "Muz", calories: 89, protein: 1.1, carbs: 23, fat: 0.3, category: .fruits) // Should not change
        ]
        
        for food in foods {
            modelContext.insert(food)
        }
        try? modelContext.save()
        
        // When
        await DataSeeder.normalizeFoodData(modelContext: modelContext)
        
        // Then
        let updatedFoods = (try? modelContext.fetch(FetchDescriptor<Food>())) ?? []
        let foodsByName = Dictionary(uniqueKeysWithValues: updatedFoods.map { ($0.nameEN, $0) })
        
        // Check Turkish name normalization
        XCTAssertEqual(foodsByName["Apple"]?.nameTR, "Apple") // Should use English name as fallback
        XCTAssertEqual(foodsByName["Milk"]?.nameTR, "Milk") // Should use English name as fallback
        XCTAssertEqual(foodsByName["Banana"]?.nameTR, "Muz") // Should remain unchanged
        
        // Check category classification (would require the classification logic to work)
        // These tests depend on the actual classification algorithm
    }
    
    // MARK: - Exercise Resolution Tests
    
    func testExerciseResolver() {
        // Given - Some exercises in database
        let exercises = [
            Exercise(nameEN: "Bench Press", nameTR: "Bench Press", category: "push", equipment: "barbell"),
            Exercise(nameEN: "Squat", nameTR: "Çömelme", category: "legs", equipment: "barbell")
        ]
        
        for exercise in exercises {
            modelContext.insert(exercise)
        }
        try? modelContext.save()
        
        var resolver = DataSeeder.ExerciseResolver()
        
        // When
        let benchPressID = resolver.resolveExerciseID(name: "Bench Press", modelContext: modelContext)
        let squatID = resolver.resolveExerciseID(name: "Çömelme", modelContext: modelContext) // Turkish name
        let unknownID = resolver.resolveExerciseID(name: "Unknown Exercise", modelContext: modelContext)
        
        // Then
        XCTAssertNotNil(benchPressID)
        XCTAssertNotNil(squatID)
        XCTAssertNil(unknownID)
        
        // Test caching
        let benchPressIDCached = resolver.resolveExerciseID(name: "Bench Press", modelContext: modelContext)
        XCTAssertEqual(benchPressID, benchPressIDCached)
    }
    
    func testExerciseResolverMultiple() {
        // Given - Exercises in database
        let exercises = [
            Exercise(nameEN: "Push Up", nameTR: "Şınav", category: "push", equipment: "bodyweight"),
            Exercise(nameEN: "Pull Up", nameTR: "Barfiks", category: "pull", equipment: "bar")
        ]
        
        for exercise in exercises {
            modelContext.insert(exercise)
        }
        try? modelContext.save()
        
        var resolver = DataSeeder.ExerciseResolver()
        
        // When
        let names = ["Push Up", "Pull Up", "Unknown Exercise"]
        let resolvedIDs = resolver.resolveExerciseIDs(names: names, modelContext: modelContext)
        
        // Then
        XCTAssertEqual(resolvedIDs.count, 2) // Only 2 exercises should be found
    }
    
    // MARK: - Clear Database Tests
    
    func testClearExercisesOnly() {
        // Given - Database with exercises and foods
        let exercise = Exercise(nameEN: "Test Exercise", nameTR: "Test Exercise", category: "test", equipment: "none")
        let food = Food(nameEN: "Test Food", nameTR: "Test Food", calories: 100, protein: 10, carbs: 10, fat: 5, category: .other)
        
        modelContext.insert(exercise)
        modelContext.insert(food)
        try? modelContext.save()
        
        let initialExerciseCount = (try? modelContext.fetchCount(FetchDescriptor<Exercise>())) ?? 0
        let initialFoodCount = (try? modelContext.fetchCount(FetchDescriptor<Food>())) ?? 0
        
        XCTAssertGreaterThan(initialExerciseCount, 0)
        XCTAssertGreaterThan(initialFoodCount, 0)
        
        // When
        DataSeeder.clearExercisesOnly(modelContext: modelContext)
        
        // Then
        let finalExerciseCount = (try? modelContext.fetchCount(FetchDescriptor<Exercise>())) ?? 0
        let finalFoodCount = (try? modelContext.fetchCount(FetchDescriptor<Food>())) ?? 0
        
        XCTAssertEqual(finalExerciseCount, 0, "All exercises should be cleared")
        XCTAssertEqual(finalFoodCount, initialFoodCount, "Foods should be preserved")
    }
    
    // MARK: - Performance Tests
    
    func testCSVParsingPerformance() {
        // Given - Large CSV-like data
        let testRows = (1...1000).map { i in
            "Exercise \(i),Egzersiz \(i),strength,barbell,true,true,false,false"
        }
        
        // When & Then - Measure parsing performance
        measure {
            for row in testRows {
                let _ = DataSeeder.CSVParser.parseCSVRow(row)
            }
        }
    }
    
    func testMultipleExerciseCreationPerformance() {
        // Given - Multiple exercise data sets
        let exerciseData = (1...100).map { i in
            ["Exercise \(i)", "Egzersiz \(i)", "strength", "barbell", "true", "true", "false", "false"]
        }
        
        // When & Then - Measure exercise creation performance
        measure {
            for columns in exerciseData {
                do {
                    let _ = try DataSeeder.createExerciseFromCSV(columns: columns)
                } catch {
                    XCTFail("Exercise creation failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Integration Tests
    
    func testCompleteDataNormalizationWorkflow() async {
        // Test a complete data normalization workflow
        
        // Step 1: Add test data with various issues
        let exercises = [
            Exercise(nameEN: "Clean and Jerk", nameTR: "Clean and Jerk", category: "strength", equipment: "barbell"),
            Exercise(nameEN: "Unknown Movement", nameTR: "Unknown Movement", category: "other", equipment: "none")
        ]
        
        let foods = [
            Food(nameEN: "Apple", nameTR: "", calories: 52, protein: 0.3, carbs: 14, fat: 0.2, category: .other),
            Food(nameEN: "Yogurt", nameTR: "Yoğurt", calories: 59, protein: 10, carbs: 3.6, fat: 0.4, category: .other)
        ]
        
        for exercise in exercises {
            modelContext.insert(exercise)
        }
        for food in foods {
            modelContext.insert(food)
        }
        try? modelContext.save()
        
        // Step 2: Run normalization
        await DataSeeder.normalizeDataAfterSeeding(modelContext: modelContext)
        
        // Step 3: Verify results
        let updatedExercises = (try? modelContext.fetch(FetchDescriptor<Exercise>())) ?? []
        let updatedFoods = (try? modelContext.fetch(FetchDescriptor<Food>())) ?? []
        
        // Exercise normalization checks
        let cleanAndJerk = updatedExercises.first { $0.nameEN == "Clean and Jerk" }
        let unknownMovement = updatedExercises.first { $0.nameEN == "Unknown Movement" }
        
        XCTAssertEqual(cleanAndJerk?.category, ExerciseCategory.olympic.rawValue)
        XCTAssertEqual(unknownMovement?.category, ExerciseCategory.strength.rawValue)
        
        // Food normalization checks
        let apple = updatedFoods.first { $0.nameEN == "Apple" }
        let yogurt = updatedFoods.first { $0.nameEN == "Yogurt" }
        
        XCTAssertEqual(apple?.nameTR, "Apple") // Should use English as fallback
        XCTAssertEqual(yogurt?.nameTR, "Yoğurt") // Should remain unchanged
        
        print("Complete data normalization workflow test passed")
    }
    
    // MARK: - Edge Cases and Error Handling Tests
    
    func testEmptyCSVRowHandling() {
        // Given - Various empty or problematic CSV rows
        let problematicRows = [
            "",
            ",,,",
            "\"\",,\"\"",
            "   ,   ,   ",
            "\t\t\t"
        ]
        
        // When & Then - Should handle gracefully without crashing
        for row in problematicRows {
            let result = DataSeeder.CSVParser.parseCSVRow(row)
            XCTAssertNotNil(result, "Should return array for row: '\(row)'")
            
            // Should be empty or contain empty strings
            if !result.isEmpty {
                XCTAssertTrue(result.allSatisfy { $0.isEmpty || $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
            }
        }
    }
    
    func testLargeCSVFieldHandling() {
        // Given - CSV with very large fields
        let largeField = String(repeating: "A", count: 10000)
        let csvRow = "\"\(largeField)\",normal_field,another_normal_field"
        
        // When
        let result = DataSeeder.CSVParser.parseCSVRow(csvRow)
        
        // Then - Should handle large fields correctly
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0], largeField)
        XCTAssertEqual(result[1], "normal_field")
        XCTAssertEqual(result[2], "another_normal_field")
    }
    
    func testSpecialCharacterHandling() {
        // Given - CSV with special characters
        let specialCharsRow = "Café,Naïve,Résumé,Çiğköfte,Şırdan,Ğümüş"
        
        // When
        let result = DataSeeder.CSVParser.parseCSVRow(specialCharsRow)
        
        // Then - Should preserve special characters
        XCTAssertEqual(result.count, 6)
        XCTAssertEqual(result[0], "Café")
        XCTAssertEqual(result[1], "Naïve")
        XCTAssertEqual(result[2], "Résumé")
        XCTAssertEqual(result[3], "Çiğköfte")
        XCTAssertEqual(result[4], "Şırdan")
        XCTAssertEqual(result[5], "Ğümüş")
    }
    
    func testConcurrentDataAccess() async {
        // Test concurrent access to data seeding operations
        
        // Given - Multiple concurrent normalization tasks
        let tasks = (1...5).map { i in
            Task {
                let exercise = Exercise(nameEN: "Exercise \(i)", nameTR: "Egzersiz \(i)", category: "other", equipment: "none")
                modelContext.insert(exercise)
                try? modelContext.save()
                
                await DataSeeder.normalizeExerciseCategoriesToPartTypes(modelContext: modelContext)
                return i
            }
        }
        
        // When - Wait for all tasks to complete
        let results = await withTaskGroup(of: Int.self) { group in
            for task in tasks {
                group.addTask { await task.value }
            }
            
            var completedTasks: [Int] = []
            for await result in group {
                completedTasks.append(result)
            }
            return completedTasks
        }
        
        // Then - All tasks should complete successfully
        XCTAssertEqual(results.count, 5)
        XCTAssertEqual(Set(results), Set(1...5))
        
        // Verify final state
        let exercises = (try? modelContext.fetch(FetchDescriptor<Exercise>())) ?? []
        let otherCategoryCount = exercises.filter { $0.category == "other" }.count
        XCTAssertEqual(otherCategoryCount, 0, "All exercises should be normalized")
    }
}

// MARK: - Mock Data Helpers

extension DataSeederTests {
    
    /// Create mock CSV content for testing
    private func createMockExerciseCSV() -> String {
        return """
        nameEN,nameTR,category,equipment,supportsWeight,supportsReps,supportsTime,supportsDistance
        Push Up,Şınav,push,bodyweight,false,true,true,false
        Bench Press,Bench Press,push,barbell,true,true,false,false
        Squat,Çömelme,legs,barbell,true,true,false,false
        """
    }
    
    /// Create mock food CSV content for testing
    private func createMockFoodCSV() -> String {
        return """
        nameEN,nameTR,brand,calories,protein,carbs,fat,category,servingSizeGrams,servingName
        Apple,Elma,Generic,52,0.3,14,0.2,fruits,100,1 medium
        Chicken Breast,Tavuk Göğsü,Generic,165,31,0,3.6,meat,100,100g
        Rice,Pirinç,Generic,130,2.7,28,0.3,grains,100,0.5 cup
        """
    }
    
    /// Test with mock CSV data
    func testMockExerciseCSVParsing() {
        // Given
        let mockCSV = createMockExerciseCSV()
        let rows = mockCSV.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        // When
        let parsedRows = rows.map { DataSeeder.CSVParser.parseCSVRow($0) }
        
        // Then
        XCTAssertEqual(parsedRows.count, 4) // Header + 3 data rows
        
        let header = parsedRows[0]
        XCTAssertEqual(header[0], "nameEN")
        XCTAssertEqual(header[1], "nameTR")
        
        let firstExercise = parsedRows[1]
        XCTAssertEqual(firstExercise[0], "Push Up")
        XCTAssertEqual(firstExercise[1], "Şınav")
        XCTAssertEqual(firstExercise[2], "push")
        XCTAssertEqual(firstExercise[3], "bodyweight")
    }
    
    /// Test exercise creation from mock data
    func testCreateExercisesFromMockCSV() throws {
        // Given
        let mockCSV = createMockExerciseCSV()
        let rows = mockCSV.components(separatedBy: .newlines).filter { !$0.isEmpty }
        let dataRows = Array(rows.dropFirst()) // Skip header
        
        // When
        var createdExercises: [Exercise] = []
        for row in dataRows {
            let columns = DataSeeder.CSVParser.parseCSVRow(row)
            let exercise = try DataSeeder.createExerciseFromCSV(columns: columns)
            createdExercises.append(exercise)
        }
        
        // Then
        XCTAssertEqual(createdExercises.count, 3)
        
        let pushUp = createdExercises[0]
        XCTAssertEqual(pushUp.nameEN, "Push Up")
        XCTAssertEqual(pushUp.nameTR, "Şınav")
        XCTAssertFalse(pushUp.supportsWeight)
        XCTAssertTrue(pushUp.supportsReps)
        
        let benchPress = createdExercises[1]
        XCTAssertEqual(benchPress.nameEN, "Bench Press")
        XCTAssertTrue(benchPress.supportsWeight)
        XCTAssertFalse(benchPress.supportsDistance)
    }
}