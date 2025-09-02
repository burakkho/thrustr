import Foundation
@testable import Thrustr

/**
 * Mock HealthKitService for testing
 * Provides predictable test data without requiring actual HealthKit permissions
 */
final class MockHealthKitService {
    
    // MARK: - Test Data Properties
    var mockSteps: Double = 8500
    var mockCalories: Double = 2200
    var mockWeight: Double = 75.0
    var mockWeightDate: Date = Date()
    
    // MARK: - Test Behavior Controls
    var shouldFailAuth = false
    var shouldFailDataFetch = false
    var mockAuthResult = true
    
    // MARK: - Mock Methods
    
    func requestPermissions() async -> Bool {
        if shouldFailAuth {
            return false
        }
        return mockAuthResult
    }
    
    func fetchTodaysSteps() async -> Double {
        if shouldFailDataFetch {
            return 0
        }
        return mockSteps
    }
    
    func fetchTodaysCalories() async -> Double {
        if shouldFailDataFetch {
            return 0
        }
        return mockCalories
    }
    
    func fetchLatestWeight() async -> Double? {
        if shouldFailDataFetch {
            return nil
        }
        return mockWeight
    }
    
    // MARK: - Test Helpers
    
    func setMockData(steps: Double = 8500, calories: Double = 2200, weight: Double = 75.0) {
        mockSteps = steps
        mockCalories = calories
        mockWeight = weight
    }
    
    func simulateFailure() {
        shouldFailDataFetch = true
    }
    
    func simulateSuccess() {
        shouldFailDataFetch = false
    }
    
    func simulateAuthDenied() {
        shouldFailAuth = true
        mockAuthResult = false
    }
}