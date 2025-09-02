import XCTest
@testable import Thrustr

/**
 * Comprehensive tests for HealthCalculator
 * Tests all critical fitness calculations with scientific validation
 */
final class HealthCalculatorTests: XCTestCase {
    
    // MARK: - BMR Calculation Tests
    
    func testBMRCalculationMaleStandard() {
        // Given - Standard adult male (Mifflin-St Jeor)
        let gender = Gender.male
        let age = 30
        let height = 175.0 // cm
        let weight = 75.0  // kg
        
        // When
        let bmr = HealthCalculator.calculateBMR(
            gender: gender, 
            age: age, 
            heightCm: height, 
            weightKg: weight, 
            bodyFatPercentage: nil
        )
        
        // Then - Expected BMR = 10*75 + 6.25*175 - 5*30 + 5 = 1698.75
        XCTAssertApproximatelyEqual(bmr, 1698.75, accuracy: 1.0)
        XCTAssertGreaterThanOrEqual(bmr, 800)  // Minimum bound
        XCTAssertLessThanOrEqual(bmr, 4000)   // Maximum bound
    }
    
    func testBMRCalculationFemaleStandard() {
        // Given - Standard adult female (Mifflin-St Jeor)
        let gender = Gender.female
        let age = 25
        let height = 165.0 // cm
        let weight = 60.0  // kg
        
        // When
        let bmr = HealthCalculator.calculateBMR(
            gender: gender, 
            age: age, 
            heightCm: height, 
            weightKg: weight, 
            bodyFatPercentage: nil
        )
        
        // Then - Expected BMR = 10*60 + 6.25*165 - 5*25 - 161 = 1345.25
        XCTAssertApproximatelyEqual(bmr, 1345.25, accuracy: 1.0)
        XCTAssertGreaterThanOrEqual(bmr, 800)
        XCTAssertLessThanOrEqual(bmr, 4000)
    }
    
    func testBMRCalculationWithBodyFatKatchMcArdle() {
        // Given - Using Katch-McArdle when body fat is available
        let gender = Gender.male
        let age = 30
        let height = 175.0 // cm
        let weight = 75.0  // kg
        let bodyFat = 15.0 // %
        
        // When
        let bmr = HealthCalculator.calculateBMR(
            gender: gender, 
            age: age, 
            heightCm: height, 
            weightKg: weight, 
            bodyFatPercentage: bodyFat
        )
        
        // Then - Expected BMR = 370 + 21.6 * (75 * (1 - 0.15)) = 370 + 21.6 * 63.75 = 1747
        XCTAssertApproximatelyEqual(bmr, 1747.0, accuracy: 5.0)
        XCTAssertGreaterThanOrEqual(bmr, 800)
        XCTAssertLessThanOrEqual(bmr, 4000)
    }
    
    func testBMRCalculationInvalidInputs() {
        // Given - Invalid inputs
        let testCases: [(Gender, Int, Double, Double, Double?)] = [
            (.male, 5, 175.0, 75.0, nil),      // Age too low
            (.male, 150, 175.0, 75.0, nil),    // Age too high
            (.male, 30, 50.0, 75.0, nil),      // Height too low
            (.male, 30, 300.0, 75.0, nil),     // Height too high
            (.male, 30, 175.0, 10.0, nil),     // Weight too low
            (.male, 30, 175.0, 400.0, nil),    // Weight too high
            (.female, 5, 165.0, 60.0, nil)     // Age too low
        ]
        
        for (gender, age, height, weight, bodyFat) in testCases {
            // When
            let bmr = HealthCalculator.calculateBMR(
                gender: gender, 
                age: age, 
                heightCm: height, 
                weightKg: weight, 
                bodyFatPercentage: bodyFat
            )
            
            // Then - Should return conservative fallback values
            if gender == .male {
                XCTAssertEqual(bmr, 1800, "Male BMR fallback should be 1800")
            } else {
                XCTAssertEqual(bmr, 1500, "Female BMR fallback should be 1500")
            }
        }
    }
    
    func testBMRCalculationBoundaryValues() {
        // Given - Boundary test cases
        let testCases: [(Gender, Int, Double, Double)] = [
            (.male, 10, 100.0, 30.0),    // Minimum valid values
            (.male, 120, 250.0, 300.0), // Maximum valid values
            (.female, 18, 150.0, 45.0), // Young female
            (.male, 80, 180.0, 80.0)    // Senior male
        ]
        
        for (gender, age, height, weight) in testCases {
            // When
            let bmr = HealthCalculator.calculateBMR(
                gender: gender, 
                age: age, 
                heightCm: height, 
                weightKg: weight, 
                bodyFatPercentage: nil
            )
            
            // Then
            XCTAssertGreaterThanOrEqual(bmr, 800, "BMR should never be below 800")
            XCTAssertLessThanOrEqual(bmr, 4000, "BMR should never exceed 4000")
        }
    }
    
    // MARK: - TDEE Calculation Tests
    
    func testTDEECalculationAllActivityLevels() {
        // Given - Standard BMR
        let bmr = 1750.0
        
        let expectedTDEE: [(ActivityLevel, Double)] = [
            (.sedentary, bmr * 1.2),      // 2100
            (.light, bmr * 1.375), // 2406.25
            (.moderate, bmr * 1.55), // 2712.5
            (.active, bmr * 1.725),    // 3018.75
            (.veryActive, bmr * 1.9)      // 3325
        ]
        
        for (activityLevel, expectedValue) in expectedTDEE {
            // When
            let tdee = HealthCalculator.calculateTDEE(bmr: bmr, activityLevel: activityLevel)
            
            // Then
            XCTAssertApproximatelyEqual(tdee, expectedValue, accuracy: 1.0)
            XCTAssertGreaterThanOrEqual(tdee, 1000, "TDEE should never be below 1000")
            XCTAssertLessThanOrEqual(tdee, 6000, "TDEE should never exceed 6000")
        }
    }
    
    func testTDEECalculationInvalidBMR() {
        // Given - Invalid BMR values
        let invalidBMRs = [500.0, 5000.0, -100.0, 0.0]
        
        for invalidBMR in invalidBMRs {
            // When
            let tdee = HealthCalculator.calculateTDEE(bmr: invalidBMR, activityLevel: .moderate)
            
            // Then
            XCTAssertEqual(tdee, 2000, "Invalid BMR should return default TDEE of 2000")
        }
    }
    
    // MARK: - Daily Calories Calculation Tests
    
    func testDailyCaloriesCalculationAllGoals() {
        // Given - Standard TDEE
        let tdee = 2500.0
        
        let expectedCalories: [(FitnessGoal, Double)] = [
            (.cut, tdee * 0.8),        // 2000 (20% deficit)
            (.maintain, tdee * 1.0),    // 2500 (maintenance)
            (.bulk, tdee * 1.15),       // 2875 (15% surplus)
            (.recomp, tdee * 0.9)        // 2250 (10% deficit for recomp)
        ]
        
        for (goal, expectedValue) in expectedCalories {
            // When
            let dailyCalories = HealthCalculator.calculateDailyCalories(tdee: tdee, goal: goal)
            
            // Then
            XCTAssertApproximatelyEqual(dailyCalories, expectedValue, accuracy: 1.0)
            XCTAssertGreaterThanOrEqual(dailyCalories, 1000, "Daily calories should never be below 1000")
            XCTAssertLessThanOrEqual(dailyCalories, 5000, "Daily calories should never exceed 5000")
        }
    }
    
    func testDailyCaloriesCalculationInvalidTDEE() {
        // Given - Invalid TDEE values
        let invalidTDEEs = [500.0, 7000.0, -200.0]
        
        for invalidTDEE in invalidTDEEs {
            // When
            let dailyCalories = HealthCalculator.calculateDailyCalories(tdee: invalidTDEE, goal: .maintain)
            
            // Then
            XCTAssertEqual(dailyCalories, 2000, "Invalid TDEE should return default 2000 calories")
        }
    }
    
    // MARK: - Macros Calculation Tests
    
    func testMacrosCalculationStandardCase() {
        // Given - Standard values for muscle building
        let weight = 75.0 // kg
        let dailyCalories = 2750.0
        let goal = FitnessGoal.recomp
        
        // When
        let macros = HealthCalculator.calculateMacros(
            weightKg: weight, 
            dailyCalories: dailyCalories, 
            goal: goal
        )
        
        // Then - Validate macro ranges and calorie balance
        XCTAssertGreaterThanOrEqual(macros.protein, 50, "Protein should be at least 50g")
        XCTAssertLessThanOrEqual(macros.protein, 300, "Protein should not exceed 300g")
        XCTAssertGreaterThanOrEqual(macros.fat, 30, "Fat should be at least 30g")
        XCTAssertLessThanOrEqual(macros.fat, 150, "Fat should not exceed 150g")
        XCTAssertGreaterThanOrEqual(macros.carbs, 50, "Carbs should be at least 50g")
        
        // Validate total calories approximately match
        let totalCalories = (macros.protein * 4) + (macros.carbs * 4) + (macros.fat * 9)
        XCTAssertApproximatelyEqual(totalCalories, dailyCalories, accuracy: 100, "Macros should sum close to daily calories")
    }
    
    func testMacrosCalculationDifferentGoals() {
        // Given - Same person, different goals
        let weight = 70.0
        let dailyCalories = 2200.0
        
        let goals: [FitnessGoal] = [.cut, .maintain, .bulk, .recomp]
        
        for goal in goals {
            // When
            let macros = HealthCalculator.calculateMacros(
                weightKg: weight, 
                dailyCalories: dailyCalories, 
                goal: goal
            )
            
            // Then - All goals should produce valid macros
            XCTAssertGreaterThan(macros.protein, 0, "Protein should be positive for goal: \(goal)")
            XCTAssertGreaterThan(macros.fat, 0, "Fat should be positive for goal: \(goal)")  
            XCTAssertGreaterThan(macros.carbs, 0, "Carbs should be positive for goal: \(goal)")
            
            // Protein should vary by goal (higher for muscle building)
            if goal == .recomp {
                XCTAssertGreaterThan(macros.protein, weight * 1.8, "Muscle building should have high protein")
            }
        }
    }
    
    func testMacrosCalculationInvalidInputs() {
        // Given - Invalid inputs
        let invalidCases: [(Double, Double)] = [
            (20.0, 2000.0),   // Weight too low
            (400.0, 2000.0),  // Weight too high
            (75.0, 500.0),    // Calories too low
            (75.0, 6000.0)    // Calories too high
        ]
        
        for (weight, calories) in invalidCases {
            // When
            let macros = HealthCalculator.calculateMacros(
                weightKg: weight, 
                dailyCalories: calories, 
                goal: .maintain
            )
            
            // Then - Should return conservative fallback macros
            XCTAssertEqual(macros.protein, 100, "Invalid inputs should return 100g protein")
            XCTAssertEqual(macros.carbs, 200, "Invalid inputs should return 200g carbs")
            XCTAssertEqual(macros.fat, 70, "Invalid inputs should return 70g fat")
        }
    }
    
    // MARK: - Navy Method Body Fat Tests
    
    func testNavyMethodMaleStandard() {
        // Given - Standard male measurements  
        let gender = Gender.male
        let height = 180.0 // cm
        let neck = 40.0    // cm
        let waist = 85.0   // cm
        
        // When
        let bodyFat = HealthCalculator.calculateBodyFatNavy(
            gender: gender, 
            heightCm: height, 
            neckCm: neck, 
            waistCm: waist, 
            hipCm: nil
        )
        
        // Then
        XCTAssertNotNil(bodyFat, "Should calculate body fat for valid male measurements")
        XCTAssertGreaterThanOrEqual(bodyFat!, 2.0, "Male body fat should be at least 2%")
        XCTAssertLessThanOrEqual(bodyFat!, 50.0, "Male body fat should not exceed 50%")
    }
    
    func testNavyMethodFemaleStandard() {
        // Given - Standard female measurements
        let gender = Gender.female
        let height = 165.0 // cm
        let neck = 32.0    // cm
        let waist = 70.0   // cm
        let hip = 95.0     // cm
        
        // When
        let bodyFat = HealthCalculator.calculateBodyFatNavy(
            gender: gender, 
            heightCm: height, 
            neckCm: neck, 
            waistCm: waist, 
            hipCm: hip
        )
        
        // Then
        XCTAssertNotNil(bodyFat, "Should calculate body fat for valid female measurements")
        XCTAssertGreaterThanOrEqual(bodyFat!, 8.0, "Female body fat should be at least 8%")
        XCTAssertLessThanOrEqual(bodyFat!, 50.0, "Female body fat should not exceed 50%")
    }
    
    func testNavyMethodInvalidMeasurements() {
        // Given - Invalid measurement cases
        let invalidCases: [(Gender, Double, Double?, Double?, Double?)] = [
            (.male, 180.0, nil, 85.0, nil),      // Missing neck
            (.male, 180.0, 40.0, nil, nil),      // Missing waist
            (.female, 165.0, 32.0, 70.0, nil),   // Missing hip for female
            (.male, 50.0, 40.0, 85.0, nil),      // Height too low
            (.male, 300.0, 40.0, 85.0, nil),     // Height too high
            (.male, 180.0, 10.0, 85.0, nil),     // Neck too small
            (.male, 180.0, 70.0, 85.0, nil),     // Neck too large
            (.male, 180.0, 40.0, 30.0, nil),     // Waist too small
            (.male, 180.0, 40.0, 250.0, nil),    // Waist too large
            (.male, 180.0, 50.0, 40.0, nil),     // Waist smaller than neck (impossible)
        ]
        
        for (gender, height, neck, waist, hip) in invalidCases {
            // When
            let bodyFat = HealthCalculator.calculateBodyFatNavy(
                gender: gender, 
                heightCm: height, 
                neckCm: neck, 
                waistCm: waist, 
                hipCm: hip
            )
            
            // Then
            XCTAssertNil(bodyFat, "Invalid measurements should return nil")
        }
    }
    
    func testNavyMethodBoundaryValues() {
        // Given - Edge case measurements that should work
        let validCases: [(Gender, Double, Double, Double, Double?)] = [
            (.male, 100.0, 20.0, 50.0, nil),      // Minimum valid values
            (.male, 250.0, 59.0, 199.0, nil),      // Maximum valid values  
            (.female, 165.0, 25.0, 60.0, 60.0),   // Female minimum
            (.female, 170.0, 35.0, 90.0, 110.0)    // Female standard
        ]
        
        for (gender, height, neck, waist, hip) in validCases {
            // When
            let bodyFat = HealthCalculator.calculateBodyFatNavy(
                gender: gender, 
                heightCm: height, 
                neckCm: neck, 
                waistCm: waist, 
                hipCm: hip
            )
            
            // Then - Should return reasonable values or nil for extreme cases
            if let bf = bodyFat {
                XCTAssertGreaterThanOrEqual(bf, gender == .male ? 2.0 : 8.0)
                XCTAssertLessThanOrEqual(bf, 50.0)
            }
        }
    }
    
    // MARK: - Integration Tests
    
    func testCompleteHealthCalculationFlow() {
        // Given - Complete user profile for calculation flow
        let gender = Gender.male
        let age = 28
        let height = 177.0
        let weight = 78.0
        let bodyFat = 12.0
        let activityLevel = ActivityLevel.moderate
        let goal = FitnessGoal.recomp
        
        // When - Full calculation chain
        let bmr = HealthCalculator.calculateBMR(
            gender: gender, 
            age: age, 
            heightCm: height, 
            weightKg: weight, 
            bodyFatPercentage: bodyFat
        )
        
        let tdee = HealthCalculator.calculateTDEE(bmr: bmr, activityLevel: activityLevel)
        let dailyCalories = HealthCalculator.calculateDailyCalories(tdee: tdee, goal: goal)
        let macros = HealthCalculator.calculateMacros(weightKg: weight, dailyCalories: dailyCalories, goal: goal)
        
        // Then - All calculations should be reasonable and connected
        XCTAssertGreaterThan(bmr, 1500, "BMR should be reasonable for adult male")
        XCTAssertGreaterThan(tdee, bmr, "TDEE should be greater than BMR")
        // RECOMP goal actually uses 0.9 multiplier (10% deficit for body recomposition)
        XCTAssertLessThan(dailyCalories, tdee, "Recomp calories should be slightly below TDEE")
        XCTAssertApproximatelyEqual(dailyCalories, tdee * 0.9, accuracy: 10, "Recomp should be 10% deficit")
        
        // Validate macro balance
        let totalCalories = (macros.protein * 4) + (macros.carbs * 4) + (macros.fat * 9)
        XCTAssertApproximatelyEqual(totalCalories, dailyCalories, accuracy: 150, "Macros should balance with daily calories")
        
        // Validate muscle building protein target
        XCTAssertGreaterThan(macros.protein, weight * 1.6, "Muscle building should have adequate protein")
    }
    
    // MARK: - Performance Tests
    
    func testCalculationPerformance() {
        // Given - Standard test parameters
        let gender = Gender.male
        let age = 30
        let height = 175.0
        let weight = 75.0
        let iterations = 1000
        
        // When & Then - BMR calculation should be fast
        measure {
            for _ in 0..<iterations {
                _ = HealthCalculator.calculateBMR(
                    gender: gender, 
                    age: age, 
                    heightCm: height, 
                    weightKg: weight, 
                    bodyFatPercentage: 15.0
                )
            }
        }
    }
    
    func testNavyMethodPerformance() {
        // Given - Navy method parameters
        let gender = Gender.female
        let height = 165.0
        let neck = 32.0
        let waist = 70.0
        let hip = 95.0
        let iterations = 1000
        
        // When & Then - Navy method should be fast
        measure {
            for _ in 0..<iterations {
                _ = HealthCalculator.calculateBodyFatNavy(
                    gender: gender, 
                    heightCm: height, 
                    neckCm: neck, 
                    waistCm: waist, 
                    hipCm: hip
                )
            }
        }
    }
}

// MARK: - Test Extensions

extension HealthCalculatorTests {
    
    /// Helper to validate macro balance
    func assertMacroBalance(_ macros: (protein: Double, carbs: Double, fat: Double), targetCalories: Double, accuracy: Double = 100) {
        let totalCalories = (macros.protein * 4) + (macros.carbs * 4) + (macros.fat * 9)
        XCTAssertApproximatelyEqual(
            totalCalories, 
            targetCalories, 
            accuracy: accuracy, 
            "Macros should sum to target calories"
        )
    }
    
    /// Helper to validate reasonable macro ranges
    func assertReasonableMacros(_ macros: (protein: Double, carbs: Double, fat: Double)) {
        XCTAssertGreaterThan(macros.protein, 0, "Protein should be positive")
        XCTAssertGreaterThan(macros.carbs, 0, "Carbs should be positive")
        XCTAssertGreaterThan(macros.fat, 0, "Fat should be positive")
        
        XCTAssertLessThan(macros.protein, 400, "Protein should be reasonable")
        XCTAssertLessThan(macros.carbs, 800, "Carbs should be reasonable")
        XCTAssertLessThan(macros.fat, 200, "Fat should be reasonable")
    }
}