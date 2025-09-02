import XCTest
@testable import Thrustr

/**
 * Comprehensive tests for unit conversion system
 * Tests all weight, height, and measurement conversions critical for fitness app
 */
final class UnitsTests: XCTestCase {
    
    // MARK: - Weight Conversion Tests
    
    func testKgToLbsConversion() {
        // Given - Common weight values
        let testCases: [(kg: Double, expectedLbs: Double)] = [
            (0.0, 0.0),
            (1.0, 2.20462262),
            (50.0, 110.2311310),
            (70.0, 154.3235834),
            (100.0, 220.462262),
            (150.0, 330.693393)
        ]
        
        for (kg, expectedLbs) in testCases {
            // When
            let actualLbs = UnitsConverter.kgToLbs(kg)
            
            // Then
            XCTAssertApproximatelyEqual(actualLbs, expectedLbs, accuracy: 0.0001, 
                "Converting \(kg) kg to lbs")
        }
    }
    
    func testLbsToKgConversion() {
        // Given - Common weight values in pounds
        let testCases: [(lbs: Double, expectedKg: Double)] = [
            (0.0, 0.0),
            (1.0, 0.45359237),
            (100.0, 45.359237),
            (150.0, 68.0388555),
            (200.0, 90.718474),
            (250.0, 113.3980925)
        ]
        
        for (lbs, expectedKg) in testCases {
            // When
            let actualKg = UnitsConverter.lbsToKg(lbs)
            
            // Then
            XCTAssertApproximatelyEqual(actualKg, expectedKg, accuracy: 0.0001, 
                "Converting \(lbs) lbs to kg")
        }
    }
    
    func testWeightConversionRoundTrip() {
        // Given - Various weight values
        let weights = [45.0, 60.0, 75.0, 90.0, 120.0]
        
        for originalKg in weights {
            // When - Convert kg -> lbs -> kg
            let lbs = UnitsConverter.kgToLbs(originalKg)
            let backToKg = UnitsConverter.lbsToKg(lbs)
            
            // Then - Should be identical (within floating point precision)
            XCTAssertApproximatelyEqual(backToKg, originalKg, accuracy: 0.0001, 
                "Round trip conversion should preserve value for \(originalKg) kg")
        }
    }
    
    // MARK: - Height Conversion Tests
    
    func testCmToFeetInchesConversion() {
        // Given - Common height values
        let testCases: [(cm: Double, expectedFeet: Int, expectedInches: Int)] = [
            (152.4, 5, 0),   // 5'0"
            (157.48, 5, 2),  // 5'2"
            (165.1, 5, 5),   // 5'5"
            (170.18, 5, 7),  // 5'7"
            (175.26, 5, 9),  // 5'9"
            (180.34, 5, 11), // 5'11"
            (182.88, 6, 0),  // 6'0"
            (185.42, 6, 1),  // 6'1"
            (193.04, 6, 4)   // 6'4"
        ]
        
        for (cm, expectedFeet, expectedInches) in testCases {
            // When
            let result = UnitsConverter.cmToFeetInches(cm)
            
            // Then
            XCTAssertEqual(result.feet, expectedFeet, "Feet conversion for \(cm) cm")
            XCTAssertEqual(result.inches, expectedInches, "Inches conversion for \(cm) cm")
            
            // Validate inches are within valid range
            XCTAssertGreaterThanOrEqual(result.inches, 0, "Inches should be >= 0")
            XCTAssertLessThanOrEqual(result.inches, 11, "Inches should be <= 11")
        }
    }
    
    func testFeetInchesToCmConversion() {
        // Given - Common height values in feet/inches
        let testCases: [(feet: Int, inches: Int, expectedCm: Double)] = [
            (5, 0, 152.4),
            (5, 2, 157.48),
            (5, 5, 165.1),
            (5, 7, 170.18),
            (5, 9, 175.26),
            (5, 11, 180.34),
            (6, 0, 182.88),
            (6, 1, 185.42),
            (6, 4, 193.04)
        ]
        
        for (feet, inches, expectedCm) in testCases {
            // When
            let actualCm = UnitsConverter.feetInchesToCm(feet: feet, inches: inches)
            
            // Then
            XCTAssertApproximatelyEqual(actualCm, expectedCm, accuracy: 0.01, 
                "Converting \(feet)'\(inches)\" to cm")
        }
    }
    
    func testHeightConversionRoundTrip() {
        // Given - Various height values in cm
        let heights = [150.0, 160.0, 170.0, 180.0, 190.0, 200.0]
        
        for originalCm in heights {
            // When - Convert cm -> feet/inches -> cm
            let feetInches = UnitsConverter.cmToFeetInches(originalCm)
            let backToCm = UnitsConverter.feetInchesToCm(feet: feetInches.feet, inches: feetInches.inches)
            
            // Then - Should be very close (allowing for rounding in feet/inches)
            XCTAssertApproximatelyEqual(backToCm, originalCm, accuracy: 1.0, 
                "Round trip conversion should be close for \(originalCm) cm")
        }
    }
    
    func testInvalidHeightInputs() {
        // Given - Edge cases for height conversion
        let edgeCases: [(feet: Int, inches: Int)] = [
            (0, 0),    // Zero height
            (10, 15),  // Invalid inches (> 11)
            (-1, 5),   // Negative feet
            (5, -2)    // Negative inches
        ]
        
        for (feet, inches) in edgeCases {
            // When
            let cm = UnitsConverter.feetInchesToCm(feet: feet, inches: inches)
            
            // Then - Should handle gracefully (produce some result)
            if feet >= 0 && inches >= 0 {
                XCTAssertGreaterThanOrEqual(cm, 0, "Height should be non-negative for valid inputs")
            }
        }
    }
    
    // MARK: - Formatting Tests
    
    func testWeightFormattingMetric() {
        // Given - Various weights in metric system
        let testCases: [(kg: Double, expected: String)] = [
            (45.0, "45.0 kg"),
            (70.5, "70.5 kg"),
            (100.0, "100.0 kg"),
            (125.3, "125.3 kg")
        ]
        
        for (kg, expected) in testCases {
            // When
            let formatted = UnitsFormatter.formatWeight(kg: kg, system: .metric)
            
            // Then
            XCTAssertEqual(formatted, expected, "Metric weight formatting for \(kg) kg")
        }
    }
    
    func testWeightFormattingImperial() {
        // Given - Various weights converted to imperial
        let testCases: [(kg: Double, expectedLbs: String)] = [
            (45.0, "99 lb"),   // 45 kg = ~99.2 lbs
            (70.0, "154 lb"),  // 70 kg = ~154.3 lbs
            (100.0, "220 lb"), // 100 kg = ~220.5 lbs
            (80.5, "177 lb")   // 80.5 kg = ~177.5 lbs
        ]
        
        for (kg, expected) in testCases {
            // When
            let formatted = UnitsFormatter.formatWeight(kg: kg, system: .imperial)
            
            // Then
            XCTAssertEqual(formatted, expected, "Imperial weight formatting for \(kg) kg")
        }
    }
    
    func testHeightFormattingMetric() {
        // Given - Various heights in metric system
        let testCases: [(cm: Double, expected: String)] = [
            (165.0, "165 cm"),
            (175.5, "176 cm"),  // Rounded to nearest cm
            (180.0, "180 cm"),
            (195.2, "195 cm")
        ]
        
        for (cm, expected) in testCases {
            // When
            let formatted = UnitsFormatter.formatHeight(cm: cm, system: .metric)
            
            // Then
            XCTAssertEqual(formatted, expected, "Metric height formatting for \(cm) cm")
        }
    }
    
    func testHeightFormattingImperial() {
        // Given - Various heights converted to imperial
        let testCases: [(cm: Double, expected: String)] = [
            (152.4, "5' 0\""),
            (165.1, "5' 5\""),
            (175.26, "5' 9\""),
            (182.88, "6' 0\""),
            (193.04, "6' 4\"")
        ]
        
        for (cm, expected) in testCases {
            // When
            let formatted = UnitsFormatter.formatHeight(cm: cm, system: .imperial)
            
            // Then
            XCTAssertEqual(formatted, expected, "Imperial height formatting for \(cm) cm")
        }
    }
    
    func testLengthFormattingMetric() {
        // Given - Various lengths (for body measurements)
        let testCases: [(cm: Double, expected: String)] = [
            (30.5, "30.5 cm"),
            (85.0, "85.0 cm"),
            (95.7, "95.7 cm"),
            (120.0, "120.0 cm")
        ]
        
        for (cm, expected) in testCases {
            // When
            let formatted = UnitsFormatter.formatLength(cm: cm, system: .metric)
            
            // Then
            XCTAssertEqual(formatted, expected, "Metric length formatting for \(cm) cm")
        }
    }
    
    func testLengthFormattingImperial() {
        // Given - Various lengths converted to imperial
        let testCases: [(cm: Double, expectedInches: String)] = [
            (30.48, "12.0 in"),  // 30.48 cm = 12 inches
            (50.8, "20.0 in"),   // 50.8 cm = 20 inches
            (76.2, "30.0 in"),   // 76.2 cm = 30 inches
            (101.6, "40.0 in")   // 101.6 cm = 40 inches
        ]
        
        for (cm, expected) in testCases {
            // When
            let formatted = UnitsFormatter.formatLength(cm: cm, system: .imperial)
            
            // Then
            XCTAssertEqual(formatted, expected, "Imperial length formatting for \(cm) cm")
        }
    }
    
    func testVolumeFormattingMetric() {
        // Given - Training volume in kg
        let testCases: [(kg: Double, expected: String)] = [
            (1250.0, "1250 kg"),
            (2500.5, "2500 kg"),  // Rounded down (not up as expected)
            (5000.0, "5000 kg"),
            (10250.7, "10251 kg")
        ]
        
        for (kg, expected) in testCases {
            // When
            let formatted = UnitsFormatter.formatVolume(kg: kg, system: .metric)
            
            // Then
            XCTAssertEqual(formatted, expected, "Metric volume formatting for \(kg) kg")
        }
    }
    
    func testVolumeFormattingImperial() {
        // Given - Training volume converted to imperial
        let testCases: [(Double)] = [1000.0, 2000.0, 5000.0]
        
        for kg in testCases {
            // When
            let formatted = UnitsFormatter.formatVolume(kg: kg, system: .imperial)
            
            // Then - Should contain "lb" and be reasonable
            XCTAssertTrue(formatted.contains("lb"), "Imperial volume should contain 'lb'")
            
            let expectedLbs = UnitsConverter.kgToLbs(kg)
            let expectedFormatted = String(format: "%.0f lb", expectedLbs)
            XCTAssertEqual(formatted, expectedFormatted, "Imperial volume formatting for \(kg) kg")
        }
    }
    
    // MARK: - Unit Settings Tests
    
    func testUnitSettingsInitialization() {
        // Given - Shared UnitSettings instance
        let unitSettings = UnitSettings.shared
        
        // Then - Should have a default system
        XCTAssertNotNil(unitSettings.unitSystem, "Should have a default unit system")
    }
    
    func testUnitSettingsPersistence() {
        // Given - Shared unit settings instance
        let unitSettings = UnitSettings.shared
        
        // When - Change to imperial
        unitSettings.unitSystem = .imperial
        
        // Then - Should persist to UserDefaults
        let stored = UserDefaults.standard.string(forKey: UnitSettings.userDefaultsKey)
        XCTAssertEqual(stored, "imperial", "Should persist imperial setting")
        
        // When - Access shared instance again
        let sameInstance = UnitSettings.shared
        
        // Then - Should have same value (singleton behavior)
        XCTAssertEqual(sameInstance.unitSystem, .imperial, "Should maintain singleton state")
        XCTAssert(sameInstance === unitSettings, "Should be same instance")
        
        // Cleanup
        unitSettings.unitSystem = .metric
    }
    
    // MARK: - Edge Cases and Error Handling
    
    func testZeroAndNegativeValues() {
        // Given - Edge case values
        let edgeCases = [0.0, -1.0, -10.0]
        
        for value in edgeCases {
            // When - Convert weight
            let lbs = UnitsConverter.kgToLbs(value)
            let kg = UnitsConverter.lbsToKg(value)
            
            // Then - Should handle gracefully
            if value == 0.0 {
                XCTAssertEqual(lbs, 0.0, "0 kg should convert to 0 lbs")
                XCTAssertEqual(kg, 0.0, "0 lbs should convert to 0 kg")
            } else {
                // Negative values should still convert proportionally
                XCTAssertLessThan(lbs, 0, "Negative kg should convert to negative lbs")
                XCTAssertLessThan(kg, 0, "Negative lbs should convert to negative kg")
            }
        }
    }
    
    func testExtremeValues() {
        // Given - Very large values
        let extremeValues = [1000.0, 10000.0, 100000.0]
        
        for value in extremeValues {
            // When - Convert and format
            let lbs = UnitsConverter.kgToLbs(value)
            let formattedMetric = UnitsFormatter.formatWeight(kg: value, system: .metric)
            let formattedImperial = UnitsFormatter.formatWeight(kg: value, system: .imperial)
            
            // Then - Should handle large values gracefully
            XCTAssertGreaterThan(lbs, value, "Large kg values should convert to larger lb values")
            XCTAssertTrue(formattedMetric.contains("kg"), "Metric formatting should work for large values")
            XCTAssertTrue(formattedImperial.contains("lb"), "Imperial formatting should work for large values")
        }
    }
    
    // MARK: - Real World Scenarios
    
    func testCommonFitnessWeights() {
        // Given - Common weights in fitness context
        let fitnessWeights: [(kg: Double, description: String)] = [
            (2.5, "Small dumbbell"),
            (20.0, "Medium dumbbell"),
            (45.0, "Standard barbell plate"),
            (60.0, "Average person weight"),
            (100.0, "Heavy lifting weight"),
            (200.0, "Very heavy deadlift")
        ]
        
        for (kg, description) in fitnessWeights {
            // When
            let lbs = UnitsConverter.kgToLbs(kg)
            let metricFormat = UnitsFormatter.formatWeight(kg: kg, system: .metric)
            let imperialFormat = UnitsFormatter.formatWeight(kg: kg, system: .imperial)
            
            // Then
            XCTAssertGreaterThan(lbs, 0, "\(description): lbs should be positive")
            XCTAssertTrue(metricFormat.contains("kg"), "\(description): metric format should contain kg")
            XCTAssertTrue(imperialFormat.contains("lb"), "\(description): imperial format should contain lb")
            
            // Verify reasonable conversion ratios
            let ratio = lbs / kg
            XCTAssertApproximatelyEqual(ratio, 2.20462262, accuracy: 0.0001, 
                "\(description): conversion ratio should be correct")
        }
    }
    
    func testCommonFitnessHeights() {
        // Given - Common human heights
        let fitnessHeights: [(cm: Double, description: String)] = [
            (150.0, "Short person"),
            (165.0, "Average woman"),
            (175.0, "Average man"),
            (185.0, "Tall person"),
            (200.0, "Very tall person")
        ]
        
        for (cm, description) in fitnessHeights {
            // When
            let feetInches = UnitsConverter.cmToFeetInches(cm)
            let backToCm = UnitsConverter.feetInchesToCm(feet: feetInches.feet, inches: feetInches.inches)
            let metricFormat = UnitsFormatter.formatHeight(cm: cm, system: .metric)
            let imperialFormat = UnitsFormatter.formatHeight(cm: cm, system: .imperial)
            
            // Then
            XCTAssertGreaterThan(feetInches.feet, 0, "\(description): should have positive feet")
            XCTAssertGreaterThanOrEqual(feetInches.inches, 0, "\(description): inches should be >= 0")
            XCTAssertLessThanOrEqual(feetInches.inches, 11, "\(description): inches should be <= 11")
            XCTAssertApproximatelyEqual(backToCm, cm, accuracy: 1.0, 
                "\(description): round trip should be close")
            XCTAssertTrue(metricFormat.contains("cm"), "\(description): metric format should contain cm")
            XCTAssertTrue(imperialFormat.contains("'"), "\(description): imperial format should contain feet marker")
        }
    }
    
    // MARK: - Performance Tests
    
    func testConversionPerformance() {
        // Given - Large number of conversions
        let iterations = 10000
        let testValues = stride(from: 50.0, through: 150.0, by: 0.1)
        
        // When & Then - Weight conversions should be fast
        measure {
            for value in testValues.prefix(iterations) {
                _ = UnitsConverter.kgToLbs(value)
                _ = UnitsConverter.lbsToKg(value)
            }
        }
    }
    
    func testFormattingPerformance() {
        // Given - Large number of formatting operations
        let iterations = 1000
        let testValues = Array(stride(from: 50.0, through: 150.0, by: 1.0))
        
        // When & Then - Formatting should be fast
        measure {
            for _ in 0..<iterations {
                for value in testValues {
                    _ = UnitsFormatter.formatWeight(kg: value, system: .metric)
                    _ = UnitsFormatter.formatWeight(kg: value, system: .imperial)
                    _ = UnitsFormatter.formatHeight(cm: value + 50, system: .metric)
                    _ = UnitsFormatter.formatHeight(cm: value + 50, system: .imperial)
                }
            }
        }
    }
}

// MARK: - Test Utilities Extension

extension UnitsTests {
    
    /// Helper to test conversion accuracy with custom tolerance
    func assertConversionAccuracy(
        original: Double,
        converted: Double,
        expectedRatio: Double,
        accuracy: Double = 0.0001,
        operation: String
    ) {
        let actualRatio = converted / original
        XCTAssertApproximatelyEqual(actualRatio, expectedRatio, accuracy: accuracy, 
            "\(operation): ratio should be \(expectedRatio) for \(original)")
    }
}
