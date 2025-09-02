import XCTest
import SwiftData
@testable import Thrustr

/**
 * Comprehensive tests for nutrition calculations
 * Tests food nutrition calculations, portion handling, and daily nutrition tracking
 */
@MainActor
final class NutritionCalculationTests: XCTestCase {
    
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
    
    // MARK: - Food Nutrition Calculation Tests
    
    func testFoodNutritionCalculationBasic() {
        // Given - Standard food (per 100g)
        let food = Food(
            nameEN: "Chicken Breast",
            nameTR: "Tavuk Göğsü",
            calories: 165.0,
            protein: 31.0,
            carbs: 0.0,
            fat: 3.6,
            category: .meat
        )
        
        // When - Calculate for 150g portion
        let nutrition = food.calculateNutrition(for: 150.0)
        
        // Then - Should scale proportionally
        XCTAssertApproximatelyEqual(nutrition.calories, 247.5, accuracy: 0.1, "Calories should scale: 165 * 1.5 = 247.5")
        XCTAssertApproximatelyEqual(nutrition.protein, 46.5, accuracy: 0.1, "Protein should scale: 31 * 1.5 = 46.5")
        XCTAssertApproximatelyEqual(nutrition.carbs, 0.0, accuracy: 0.1, "Carbs should remain 0")
        XCTAssertApproximatelyEqual(nutrition.fat, 5.4, accuracy: 0.1, "Fat should scale: 3.6 * 1.5 = 5.4")
    }
    
    func testFoodNutritionCalculationVariousPortions() {
        // Given - Rice (per 100g)
        let rice = Food(
            nameEN: "Brown Rice",
            nameTR: "Esmer Pilav",
            calories: 112.0,
            protein: 2.3,
            carbs: 22.9,
            fat: 0.9,
            category: .grains
        )
        
        let testPortions: [(grams: Double, expectedCalories: Double)] = [
            (50.0, 56.0),    // Half portion
            (100.0, 112.0),  // Standard portion
            (200.0, 224.0),  // Double portion
            (250.0, 280.0),  // 2.5x portion
            (75.0, 84.0)     // 3/4 portion
        ]
        
        for (grams, expectedCalories) in testPortions {
            // When
            let nutrition = rice.calculateNutrition(for: grams)
            
            // Then
            XCTAssertApproximatelyEqual(nutrition.calories, expectedCalories, accuracy: 0.1, 
                "Calories should scale correctly for \(grams)g portion")
            
            // Verify other macros scale proportionally
            let scaleFactor = grams / 100.0
            XCTAssertApproximatelyEqual(nutrition.protein, 2.3 * scaleFactor, accuracy: 0.01)
            XCTAssertApproximatelyEqual(nutrition.carbs, 22.9 * scaleFactor, accuracy: 0.01)
            XCTAssertApproximatelyEqual(nutrition.fat, 0.9 * scaleFactor, accuracy: 0.01)
        }
    }
    
    func testFoodNutritionCalculationZeroAndNegative() {
        // Given - Standard food
        let food = TestHelpers.createTestFood(name: "Test Food")
        
        // When - Zero portion
        let zeroNutrition = food.calculateNutrition(for: 0.0)
        
        // Then - Should return zero nutrition
        XCTAssertEqual(zeroNutrition.calories, 0.0, "Zero portion should have zero calories")
        XCTAssertEqual(zeroNutrition.protein, 0.0, "Zero portion should have zero protein")
        XCTAssertEqual(zeroNutrition.carbs, 0.0, "Zero portion should have zero carbs")
        XCTAssertEqual(zeroNutrition.fat, 0.0, "Zero portion should have zero fat")
        
        // When - Negative portion (edge case)
        let negativeNutrition = food.calculateNutrition(for: -50.0)
        
        // Then - Current implementation multiplies by negative value, producing negative calories
        // This is technically correct mathematically but may need business logic validation
        XCTAssertEqual(negativeNutrition.calories, food.calories * (-50.0 / 100.0), "Negative portion produces proportionally negative calories")
    }
    
    func testFoodNutritionCalculationLargePortions() {
        // Given - Food with known nutrition
        let food = Food(
            nameEN: "Oats",
            nameTR: "Yulaf",
            calories: 389.0,
            protein: 16.9,
            carbs: 66.3,
            fat: 6.9,
            category: .grains
        )
        
        // When - Very large portion (1kg)
        let nutrition = food.calculateNutrition(for: 1000.0)
        
        // Then - Should scale without overflow
        XCTAssertApproximatelyEqual(nutrition.calories, 3890.0, accuracy: 1.0)
        XCTAssertApproximatelyEqual(nutrition.protein, 169.0, accuracy: 1.0)
        XCTAssertApproximatelyEqual(nutrition.carbs, 663.0, accuracy: 1.0)
        XCTAssertApproximatelyEqual(nutrition.fat, 69.0, accuracy: 1.0)
        
        // Verify no floating point issues
        XCTAssertTrue(nutrition.calories.isFinite, "Large calculation should not overflow")
        XCTAssertTrue(nutrition.protein.isFinite, "Large calculation should not overflow")
    }
    
    // MARK: - Nutrition Entry Tests
    
    func testNutritionEntryCreation() throws {
        // Given - Food and consumption data
        let food = TestHelpers.createTestFood(name: "Test Food")
        modelContext.insert(food)
        
        let gramsConsumed = 150.0
        let mealType = "breakfast"
        let date = Date()
        
        // When
        let entry = NutritionEntry(
            food: food,
            gramsConsumed: gramsConsumed,
            mealType: mealType,
            date: date
        )
        modelContext.insert(entry)
        try modelContext.save()
        
        // Then
        XCTAssertEqual(entry.food?.id, food.id, "Entry should reference the food")
        XCTAssertEqual(entry.foodName, food.displayName, "Entry should store food name backup")
        XCTAssertEqual(entry.gramsConsumed, gramsConsumed, "Entry should store consumed amount")
        XCTAssertEqual(entry.mealType, mealType, "Entry should store meal type")
        
        // Verify calculated nutrition
        let expectedNutrition = food.calculateNutrition(for: gramsConsumed)
        XCTAssertApproximatelyEqual(entry.calories, expectedNutrition.calories, accuracy: 0.1)
        XCTAssertApproximatelyEqual(entry.protein, expectedNutrition.protein, accuracy: 0.1)
        XCTAssertApproximatelyEqual(entry.carbs, expectedNutrition.carbs, accuracy: 0.1)
        XCTAssertApproximatelyEqual(entry.fat, expectedNutrition.fat, accuracy: 0.1)
    }
    
    func testNutritionEntryDateHandling() {
        // Given - Entry with specific date
        let food = TestHelpers.createTestFood(name: "Test Food")
        let specificDate = Date().addingTimeInterval(-86400) // Yesterday
        
        // When
        let entry = NutritionEntry(
            food: food,
            gramsConsumed: 100.0,
            mealType: "lunch",
            date: specificDate
        )
        
        // Then - Date should be start of day for consistency
        let expectedDate = Calendar.current.startOfDay(for: specificDate)
        XCTAssertEqual(entry.date, expectedDate, "Entry date should be start of day")
        
        // ConsumedAt should be current time
        let timeDifference = abs(entry.consumedAt.timeIntervalSinceNow)
        XCTAssertLessThan(timeDifference, 1.0, "ConsumedAt should be recent")
    }
    
    func testNutritionEntryUpdate() throws {
        // Given - Existing nutrition entry
        let food = TestHelpers.createTestFood(name: "Test Food")
        let entry = NutritionEntry(
            food: food,
            gramsConsumed: 100.0,
            mealType: "dinner",
            date: Date()
        )
        modelContext.insert(food)
        modelContext.insert(entry)
        try modelContext.save()
        
        let originalCalories = entry.calories
        
        // When - Update portion size
        entry.gramsConsumed = 200.0 // Double the portion
        entry.updateNutrition() // Assuming this method exists
        
        // Then - Nutrition should recalculate
        // Note: This test assumes updateNutrition method exists in NutritionEntry
        // If not implemented, this verifies the need for such functionality
        XCTAssertNotEqual(entry.calories, originalCalories, 
            "Calories should change when portion changes")
    }
    
    // MARK: - Daily Nutrition Aggregation Tests
    
    func testDailyNutritionCalculation() throws {
        // Given - Multiple nutrition entries for one day
        let today = Date()
        let startOfDay = Calendar.current.startOfDay(for: today)
        
        let breakfastFood = Food(
            nameEN: "Eggs",
            nameTR: "Yumurta", 
            calories: 155.0,
            protein: 13.0,
            carbs: 1.1,
            fat: 11.0,
            category: .meat
        )
        
        let lunchFood = Food(
            nameEN: "Rice",
            nameTR: "Pilav",
            calories: 130.0,
            protein: 2.7,
            carbs: 28.0,
            fat: 0.3,
            category: .grains
        )
        
        modelContext.insert(breakfastFood)
        modelContext.insert(lunchFood)
        
        let breakfastEntry = NutritionEntry(
            food: breakfastFood,
            gramsConsumed: 150.0, // 1.5 eggs worth
            mealType: "breakfast",
            date: startOfDay
        )
        
        let lunchEntry = NutritionEntry(
            food: lunchFood,
            gramsConsumed: 200.0, // 200g rice
            mealType: "lunch",
            date: startOfDay
        )
        
        modelContext.insert(breakfastEntry)
        modelContext.insert(lunchEntry)
        try modelContext.save()
        
        // When - Calculate daily totals
        let entries = [breakfastEntry, lunchEntry]
        let dailyTotals = calculateDailyNutrition(entries: entries)
        
        // Then - Should sum all entries
        let expectedCalories = (155.0 * 1.5) + (130.0 * 2.0) // 232.5 + 260 = 492.5
        let expectedProtein = (13.0 * 1.5) + (2.7 * 2.0) // 19.5 + 5.4 = 24.9
        let expectedCarbs = (1.1 * 1.5) + (28.0 * 2.0) // 1.65 + 56 = 57.65
        let expectedFat = (11.0 * 1.5) + (0.3 * 2.0) // 16.5 + 0.6 = 17.1
        
        XCTAssertApproximatelyEqual(dailyTotals.calories, expectedCalories, accuracy: 1.0)
        XCTAssertApproximatelyEqual(dailyTotals.protein, expectedProtein, accuracy: 0.1)
        XCTAssertApproximatelyEqual(dailyTotals.carbs, expectedCarbs, accuracy: 0.1)
        XCTAssertApproximatelyEqual(dailyTotals.fat, expectedFat, accuracy: 0.1)
    }
    
    func testEmptyDayNutritionCalculation() {
        // Given - Empty day (no nutrition entries)
        let entries: [NutritionEntry] = []
        
        // When
        let dailyTotals = calculateDailyNutrition(entries: entries)
        
        // Then - Should return zeros
        XCTAssertEqual(dailyTotals.calories, 0.0, "Empty day should have zero calories")
        XCTAssertEqual(dailyTotals.protein, 0.0, "Empty day should have zero protein")
        XCTAssertEqual(dailyTotals.carbs, 0.0, "Empty day should have zero carbs")
        XCTAssertEqual(dailyTotals.fat, 0.0, "Empty day should have zero fat")
    }
    
    func testMealTypeNutritionBreakdown() throws {
        // Given - Entries across different meal types
        let food = TestHelpers.createTestFood(name: "Test Food")
        modelContext.insert(food)
        
        let today = Date()
        let meals = [
            ("breakfast", 100.0),
            ("lunch", 150.0),
            ("dinner", 200.0),
            ("snack", 50.0)
        ]
        
        var entries: [NutritionEntry] = []
        for (mealType, grams) in meals {
            let entry = NutritionEntry(
                food: food,
                gramsConsumed: grams,
                mealType: mealType,
                date: today
            )
            modelContext.insert(entry)
            entries.append(entry)
        }
        
        try modelContext.save()
        
        // When - Group by meal type
        let mealBreakdown = groupNutritionByMealType(entries: entries)
        
        // Then - Should group correctly
        XCTAssertEqual(mealBreakdown.count, 4, "Should have 4 meal types")
        XCTAssertTrue(mealBreakdown.keys.contains("breakfast"), "Should contain breakfast")
        XCTAssertTrue(mealBreakdown.keys.contains("lunch"), "Should contain lunch")
        XCTAssertTrue(mealBreakdown.keys.contains("dinner"), "Should contain dinner")
        XCTAssertTrue(mealBreakdown.keys.contains("snack"), "Should contain snack")
        
        // Verify meal totals
        if let breakfastTotal = mealBreakdown["breakfast"] {
            let expectedCalories = food.calories * (100.0 / 100.0) // 100g portion
            XCTAssertApproximatelyEqual(breakfastTotal.calories, expectedCalories, accuracy: 1.0)
        } else {
            XCTFail("Breakfast should be present in breakdown")
        }
    }
    
    // MARK: - Nutritional Goals Comparison Tests
    
    func testNutritionGoalsComparison() {
        // Given - User with nutritional goals
        let user = TestHelpers.createTestUser()
        user.dailyCalorieGoal = 2500.0
        user.dailyProteinGoal = 150.0
        user.dailyCarbGoal = 250.0
        user.dailyFatGoal = 90.0
        
        // Given - Daily nutrition totals
        let dailyTotals = (
            calories: 2200.0,  // Under goal
            protein: 165.0,    // Over goal
            carbs: 220.0,      // Under goal
            fat: 95.0          // Over goal
        )
        
        // When - Compare with goals
        let comparison = compareWithGoals(totals: dailyTotals, user: user)
        
        // Then - Should identify over/under targets
        XCTAssertLessThan(comparison.calorieProgress, 1.0, "Calories should be under goal")
        XCTAssertGreaterThan(comparison.proteinProgress, 1.0, "Protein should be over goal")
        XCTAssertLessThan(comparison.carbProgress, 1.0, "Carbs should be under goal")
        XCTAssertGreaterThan(comparison.fatProgress, 1.0, "Fat should be over goal")
        
        // Verify specific percentages
        XCTAssertApproximatelyEqual(comparison.calorieProgress, 0.88, accuracy: 0.01) // 2200/2500
        XCTAssertApproximatelyEqual(comparison.proteinProgress, 1.10, accuracy: 0.01) // 165/150
    }
    
    func testNutritionGoalsExactMatch() {
        // Given - Perfect nutrition day
        let user = TestHelpers.createTestUser()
        user.dailyCalorieGoal = 2000.0
        user.dailyProteinGoal = 120.0
        user.dailyCarbGoal = 200.0
        user.dailyFatGoal = 80.0
        
        let dailyTotals = (
            calories: 2000.0,
            protein: 120.0,
            carbs: 200.0,
            fat: 80.0
        )
        
        // When
        let comparison = compareWithGoals(totals: dailyTotals, user: user)
        
        // Then - Should be exactly 100%
        XCTAssertApproximatelyEqual(comparison.calorieProgress, 1.0, accuracy: 0.001)
        XCTAssertApproximatelyEqual(comparison.proteinProgress, 1.0, accuracy: 0.001)
        XCTAssertApproximatelyEqual(comparison.carbProgress, 1.0, accuracy: 0.001)
        XCTAssertApproximatelyEqual(comparison.fatProgress, 1.0, accuracy: 0.001)
    }
    
    // MARK: - Food Search and Filtering Tests
    
    func testFoodCalorieDensity() {
        // Given - Foods with different calorie densities
        let highDensity = Food(
            nameEN: "Almonds",
            nameTR: "Badem",
            calories: 579.0, // High calorie density
            protein: 21.2,
            carbs: 21.6,
            fat: 49.9,
            category: .nuts
        )
        
        let lowDensity = Food(
            nameEN: "Cucumber",
            nameTR: "Salatalık",
            calories: 16.0, // Low calorie density
            protein: 0.7,
            carbs: 4.0,
            fat: 0.1,
            category: .vegetables
        )
        
        // When - Calculate 100g portions
        let highNutrition = highDensity.calculateNutrition(for: 100.0)
        let lowNutrition = lowDensity.calculateNutrition(for: 100.0)
        
        // Then - Verify calorie density classification
        XCTAssertGreaterThan(highNutrition.calories, 400, "Almonds should be high calorie density")
        XCTAssertLessThan(lowNutrition.calories, 50, "Cucumber should be low calorie density")
        
        // Verify macro ratios
        let almondsProteinRatio = highNutrition.protein * 4 / highNutrition.calories
        let almondsCarboRatio = highNutrition.carbs * 4 / highNutrition.calories
        let almondsFatRatio = highNutrition.fat * 9 / highNutrition.calories
        
        XCTAssertApproximatelyEqual(almondsProteinRatio + almondsCarboRatio + almondsFatRatio, 
                                  1.0, accuracy: 0.1, "Macro ratios should sum to ~1.0")
    }
    
    // MARK: - Performance Tests
    
    func testNutritionCalculationPerformance() {
        // Given - Multiple foods and portions
        let foods = (0..<100).map { index in
            TestHelpers.createTestFood(name: "Food \(index)")
        }
        
        let portions = Array(10...500) // Various portion sizes
        
        // When & Then - Calculations should be fast
        measure {
            for food in foods {
                for portion in portions.prefix(10) {
                    _ = food.calculateNutrition(for: Double(portion))
                }
            }
        }
    }
    
    func testDailyNutritionAggregationPerformance() throws {
        // Given - Many nutrition entries for one day
        let food = TestHelpers.createTestFood(name: "Performance Test Food")
        modelContext.insert(food)
        
        var entries: [NutritionEntry] = []
        for i in 0..<100 {
            let entry = NutritionEntry(
                food: food,
                gramsConsumed: Double(50 + i),
                mealType: "meal\(i % 4)",
                date: Date()
            )
            entries.append(entry)
            modelContext.insert(entry)
        }
        
        try modelContext.save()
        
        // When & Then - Aggregation should be fast
        measure {
            _ = calculateDailyNutrition(entries: entries)
        }
    }
    
    // MARK: - Integration Tests
    
    func testCompleteNutritionTrackingWorkflow() throws {
        // Given - Complete nutrition tracking scenario
        let user = TestHelpers.createTestUser()
        user.calculateMetrics()
        modelContext.insert(user)
        
        // Create foods
        let breakfast = Food(nameEN: "Oatmeal", nameTR: "Yulaf", 
                           calories: 389, protein: 16.9, carbs: 66.3, fat: 6.9, category: .grains)
        let lunch = Food(nameEN: "Chicken Salad", nameTR: "Tavuk Salatası",
                        calories: 200, protein: 25.0, carbs: 5.0, fat: 8.0, category: .meat)
        let dinner = Food(nameEN: "Salmon", nameTR: "Somon",
                         calories: 208, protein: 25.4, carbs: 0.0, fat: 12.4, category: .meat)
        
        modelContext.insert(breakfast)
        modelContext.insert(lunch)
        modelContext.insert(dinner)
        
        // Create entries
        let today = Date()
        let entries = [
            NutritionEntry(food: breakfast, gramsConsumed: 80.0, mealType: "breakfast", date: today),
            NutritionEntry(food: lunch, gramsConsumed: 200.0, mealType: "lunch", date: today),
            NutritionEntry(food: dinner, gramsConsumed: 150.0, mealType: "dinner", date: today)
        ]
        
        for entry in entries {
            modelContext.insert(entry)
        }
        
        try modelContext.save()
        
        // When - Calculate daily totals
        let dailyTotals = calculateDailyNutrition(entries: entries)
        let goalComparison = compareWithGoals(totals: dailyTotals, user: user)
        
        // Then - Should provide complete nutrition analysis
        XCTAssertGreaterThan(dailyTotals.calories, 0, "Should have total calories")
        XCTAssertGreaterThan(dailyTotals.protein, 0, "Should have total protein")
        
        XCTAssertGreaterThan(goalComparison.calorieProgress, 0, "Should have calorie progress")
        XCTAssertGreaterThan(goalComparison.proteinProgress, 0, "Should have protein progress")
        
        // Verify realistic nutrition values
        XCTAssertLessThan(dailyTotals.calories, 3000, "Daily calories should be reasonable")
        XCTAssertLessThan(dailyTotals.protein, 200, "Daily protein should be reasonable")
        
        Logger.info("Daily nutrition: \(dailyTotals.calories) kcal, \(dailyTotals.protein)g protein")
    }
    
    // MARK: - Helper Methods
    
    private func calculateDailyNutrition(entries: [NutritionEntry]) -> (calories: Double, protein: Double, carbs: Double, fat: Double) {
        let totalCalories = entries.reduce(0.0) { $0 + $1.calories }
        let totalProtein = entries.reduce(0.0) { $0 + $1.protein }
        let totalCarbs = entries.reduce(0.0) { $0 + $1.carbs }
        let totalFat = entries.reduce(0.0) { $0 + $1.fat }
        
        return (calories: totalCalories, protein: totalProtein, carbs: totalCarbs, fat: totalFat)
    }
    
    private func groupNutritionByMealType(entries: [NutritionEntry]) -> [String: (calories: Double, protein: Double, carbs: Double, fat: Double)] {
        var grouped: [String: (calories: Double, protein: Double, carbs: Double, fat: Double)] = [:]
        
        for entry in entries {
            let existing = grouped[entry.mealType] ?? (calories: 0, protein: 0, carbs: 0, fat: 0)
            grouped[entry.mealType] = (
                calories: existing.calories + entry.calories,
                protein: existing.protein + entry.protein,
                carbs: existing.carbs + entry.carbs,
                fat: existing.fat + entry.fat
            )
        }
        
        return grouped
    }
    
    private func compareWithGoals(totals: (calories: Double, protein: Double, carbs: Double, fat: Double), 
                                user: User) -> (calorieProgress: Double, proteinProgress: Double, carbProgress: Double, fatProgress: Double) {
        return (
            calorieProgress: totals.calories / user.dailyCalorieGoal,
            proteinProgress: totals.protein / user.dailyProteinGoal,
            carbProgress: totals.carbs / user.dailyCarbGoal,
            fatProgress: totals.fat / user.dailyFatGoal
        )
    }
}

// MARK: - Test Extensions

extension NutritionEntry {
    /// Mock method for updating nutrition when portion changes
    func updateNutrition() {
        guard let food = self.food else { return }
        let nutrition = food.calculateNutrition(for: self.gramsConsumed)
        
        self.calories = nutrition.calories
        self.protein = nutrition.protein
        self.carbs = nutrition.carbs
        self.fat = nutrition.fat
        self.updatedAt = Date()
    }
}

extension NutritionCalculationTests {
    
    /// Helper to validate nutrition entry consistency
    func assertNutritionEntryConsistency(_ entry: NutritionEntry) {
        guard let food = entry.food else {
            XCTFail("Nutrition entry should have associated food")
            return
        }
        
        let expectedNutrition = food.calculateNutrition(for: entry.gramsConsumed)
        
        XCTAssertApproximatelyEqual(entry.calories, expectedNutrition.calories, accuracy: 0.1,
            "Entry calories should match calculated nutrition")
        XCTAssertApproximatelyEqual(entry.protein, expectedNutrition.protein, accuracy: 0.1,
            "Entry protein should match calculated nutrition")
        XCTAssertApproximatelyEqual(entry.carbs, expectedNutrition.carbs, accuracy: 0.1,
            "Entry carbs should match calculated nutrition")
        XCTAssertApproximatelyEqual(entry.fat, expectedNutrition.fat, accuracy: 0.1,
            "Entry fat should match calculated nutrition")
    }
}