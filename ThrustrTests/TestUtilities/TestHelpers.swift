import Foundation
import SwiftData
import XCTest
@testable import Thrustr

/**
 * Common test utilities and helpers
 */
final class TestHelpers {
    
    // MARK: - ModelContext Helpers
    
    /// Creates an in-memory ModelContext for testing
    static func createTestModelContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: User.self, Exercise.self, Food.self, NutritionEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }
    
    // MARK: - Test Data Factories
    
    /// Creates a test user with realistic data
    @MainActor
    static func createTestUser() -> User {
        return MockUserService.createTestUser()
    }
    
    /// Creates test exercise data
    static func createTestExercise(name: String = "Test Exercise") -> Exercise {
        return Exercise(
            nameEN: name,
            nameTR: name,
            category: ExerciseCategory.strength.rawValue,
            equipment: ExerciseEquipment.barbell.rawValue
        )
    }
    
    /// Creates test food data
    static func createTestFood(name: String = "Test Food") -> Food {
        return Food(
            nameEN: name,
            nameTR: name,
            calories: 100,
            protein: 10,
            carbs: 20,
            fat: 5,
            category: .grains
        )
    }
    
    // MARK: - Async Test Helpers
    
    /// Waits for a condition to be true with timeout
    static func waitForCondition(
        timeout: TimeInterval = 5.0,
        condition: @escaping () -> Bool
    ) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        
        while Date() < deadline {
            if condition() {
                return
            }
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        
        XCTFail("Condition not met within timeout of \(timeout) seconds")
    }
    
    /// Waits for an async condition with timeout
    static func waitForAsyncCondition(
        timeout: TimeInterval = 5.0,
        condition: @escaping () async -> Bool
    ) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        
        while Date() < deadline {
            if await condition() {
                return
            }
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        
        XCTFail("Async condition not met within timeout of \(timeout) seconds")
    }
}

// MARK: - XCTest Extensions

extension XCTestCase {
    
    /// Asserts that two doubles are approximately equal
    func XCTAssertApproximatelyEqual(
        _ expression1: Double,
        _ expression2: Double,
        accuracy: Double = 0.001,
        _ message: String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(expression1, expression2, accuracy: accuracy, message, file: file, line: line)
    }
    
    /// Asserts that a Result is success
    func XCTAssertSuccess<Success, Failure>(
        _ result: Result<Success, Failure>,
        _ message: String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Success? {
        switch result {
        case .success(let value):
            return value
        case .failure(let error):
            XCTFail("Expected success but got failure: \(error). \(message)", file: file, line: line)
            return nil
        }
    }
    
    /// Asserts that a Result is failure
    func XCTAssertFailure<Success, Failure>(
        _ result: Result<Success, Failure>,
        _ message: String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Failure? {
        switch result {
        case .success(let value):
            XCTFail("Expected failure but got success: \(value). \(message)", file: file, line: line)
            return nil
        case .failure(let error):
            return error
        }
    }
}