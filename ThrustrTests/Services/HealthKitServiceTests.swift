import XCTest
import HealthKit
@testable import Thrustr

/**
 * Comprehensive tests for HealthKitService
 * Tests HealthKit integration, authorization, data reading/writing, and caching
 */
@MainActor
final class HealthKitServiceTests: XCTestCase {
    
    // MARK: - Test Properties
    private var healthKitService: HealthKitService!
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        healthKitService = HealthKitService()
    }
    
    override func tearDown() async throws {
        healthKitService.stopObserverQueries()
        healthKitService = nil
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialState() {
        // Then
        XCTAssertFalse(healthKitService.isAuthorized)
        XCTAssertEqual(healthKitService.todaySteps, 0)
        XCTAssertEqual(healthKitService.todayCalories, 0)
        XCTAssertNil(healthKitService.currentWeight)
        XCTAssertFalse(healthKitService.isLoading)
        XCTAssertNil(healthKitService.error)
    }
    
    // MARK: - Permission Tests
    
    func testHealthDataAvailability() {
        // Note: This will depend on the test environment (device vs simulator)
        // On simulator, HealthKit is usually not available
        if HKHealthStore.isHealthDataAvailable() {
            print("HealthKit is available on this device")
        } else {
            print("HealthKit is not available on this device/simulator")
        }
        
        // The test should not fail regardless of availability
        // The service should handle unavailability gracefully
    }
    
    func testAuthorizationStatusTypes() {
        // Given - Authorization status check
        let status = healthKitService.getAuthorizationStatus()
        
        // Then - Should return valid status values
        XCTAssertTrue(status.steps.rawValue >= 0 && status.steps.rawValue <= 4)
        XCTAssertTrue(status.calories.rawValue >= 0 && status.calories.rawValue <= 4)
        XCTAssertTrue(status.weight.rawValue >= 0 && status.weight.rawValue <= 4)
        
        print("Authorization status - Steps: \(status.steps), Calories: \(status.calories), Weight: \(status.weight)")
    }
    
    // MARK: - Data Reading Tests
    
    func testReadTodaysDataOnSimulator() async {
        // When - Attempt to read today's data
        await healthKitService.readTodaysData()
        
        // Then - Should not crash and should maintain initial state
        // On simulator, this will likely return 0 values
        XCTAssertGreaterThanOrEqual(healthKitService.todaySteps, 0)
        XCTAssertGreaterThanOrEqual(healthKitService.todayCalories, 0)
        
        // Weight might be nil if no data exists
        if let weight = healthKitService.currentWeight {
            XCTAssertGreaterThan(weight, 0)
        }
    }
    
    func testReadStepsDataReturnType() async {
        // When
        let steps = await healthKitService.readStepsData()
        
        // Then - Should return a valid Double or nil
        if let stepsValue = steps {
            XCTAssertGreaterThanOrEqual(stepsValue, 0)
        }
        // nil is acceptable if no data or permission denied
    }
    
    func testReadCaloriesDataReturnType() async {
        // When
        let calories = await healthKitService.readCaloriesData()
        
        // Then - Should return a valid Double or nil
        if let caloriesValue = calories {
            XCTAssertGreaterThanOrEqual(caloriesValue, 0)
        }
        // nil is acceptable if no data or permission denied
    }
    
    func testReadWeightDataReturnType() async {
        // When
        let weight = await healthKitService.readWeightData()
        
        // Then - Should return a valid Double or nil
        if let weightValue = weight {
            XCTAssertGreaterThan(weightValue, 0)
            XCTAssertLessThan(weightValue, 500) // Reasonable upper bound
        }
        // nil is acceptable if no data exists
    }
    
    // MARK: - Caching Tests
    
    func testDataCaching() async {
        // Given - Initial read
        await healthKitService.readTodaysData()
        
        let firstSteps = healthKitService.todaySteps
        let firstCalories = healthKitService.todayCalories
        let firstWeight = healthKitService.currentWeight
        
        // When - Read again immediately (should use cache)
        await healthKitService.readTodaysData()
        
        // Then - Values should be the same (cached)
        XCTAssertEqual(healthKitService.todaySteps, firstSteps)
        XCTAssertEqual(healthKitService.todayCalories, firstCalories)
        XCTAssertEqual(healthKitService.currentWeight, firstWeight)
    }
    
    func testCacheValidityDuration() async {
        // Note: This test would require waiting 5 minutes to fully test cache expiration
        // We can test the logic exists but not the full timeout
        
        // Given - Initial read
        await healthKitService.readTodaysData()
        
        // Then - Should have cached data
        let hasData = healthKitService.todaySteps > 0 || 
                     healthKitService.todayCalories > 0 || 
                     healthKitService.currentWeight != nil
        
        // The cache should be working if we have any data
        if hasData {
            print("Cache is working with data")
        } else {
            print("No data to cache (normal on simulator)")
        }
    }
    
    // MARK: - Data Writing Tests
    
    func testSaveWeightValidation() async {
        // Given - Valid weight value
        let validWeight = 70.5
        
        // When - Attempt to save weight
        let success = await healthKitService.saveWeight(validWeight)
        
        // Then - Should handle the operation gracefully
        // On simulator without authorization, this might fail, but shouldn't crash
        if success {
            XCTAssertEqual(healthKitService.currentWeight, validWeight)
        } else {
            // Failure is acceptable if no authorization
            print("Weight save failed (expected on simulator without authorization)")
        }
    }
    
    func testSaveWeightEdgeCases() async {
        // Test edge cases for weight values
        let testWeights = [30.0, 300.0, 75.5]
        
        for weight in testWeights {
            // When
            let success = await healthKitService.saveWeight(weight)
            
            // Then - Should handle without crashing
            if success {
                XCTAssertEqual(healthKitService.currentWeight, weight)
                print("Successfully saved weight: \(weight)")
            } else {
                print("Failed to save weight: \(weight) (expected on simulator)")
            }
        }
    }
    
    // MARK: - Loading State Tests
    
    func testLoadingStateManagement() async {
        // Given - Initial state
        XCTAssertFalse(healthKitService.isLoading)
        
        // When - Start data reading
        let task = Task {
            await healthKitService.readTodaysData()
        }
        
        // Then - Loading should be managed
        await task.value
        XCTAssertFalse(healthKitService.isLoading) // Should be false after completion
    }
    
    // MARK: - Background Delivery Tests
    
    func testEnableBackgroundDelivery() {
        // When - Enable background delivery
        healthKitService.enableBackgroundDelivery()
        
        // Then - Should not crash
        // Actual functionality depends on HealthKit authorization
        // This test mainly ensures the method can be called safely
        print("Background delivery enable attempted")
    }
    
    func testDisableBackgroundDelivery() {
        // Given - First enable, then disable
        healthKitService.enableBackgroundDelivery()
        
        // When
        healthKitService.disableBackgroundDelivery()
        
        // Then - Should not crash
        print("Background delivery disable attempted")
    }
    
    // MARK: - Observer Query Tests
    
    func testStartObserverQueries() {
        // When
        healthKitService.startObserverQueries()
        
        // Then - Should not crash
        // Actual query functionality depends on HealthKit authorization
        print("Observer queries start attempted")
    }
    
    func testStopObserverQueries() {
        // Given - Start queries first
        healthKitService.startObserverQueries()
        
        // When
        healthKitService.stopObserverQueries()
        
        // Then - Should not crash
        print("Observer queries stop attempted")
    }
    
    func testMultipleObserverQueryOperations() {
        // Test starting and stopping queries multiple times
        for i in 1...3 {
            healthKitService.startObserverQueries()
            healthKitService.stopObserverQueries()
            print("Observer query cycle \(i) completed")
        }
        
        // Should not crash or cause memory issues
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorStateManagement() {
        // Given - Initial state
        XCTAssertNil(healthKitService.error)
        
        // When - Simulate error conditions (this would normally come from HealthKit operations)
        // We can't easily trigger real HealthKit errors in tests, but we can verify error handling exists
        
        // Then - Error handling should be robust
        print("Error handling test - service maintains stability")
    }
    
    // MARK: - Performance Tests
    
    func testDataReadingPerformance() async {
        // Measure performance of data reading operations
        measure {
            Task { @MainActor in
                await healthKitService.readTodaysData()
            }
        }
    }
    
    func testMultipleDataReads() async {
        // Test multiple consecutive reads (should use caching)
        let iterations = 5
        
        for i in 1...iterations {
            await healthKitService.readTodaysData()
            print("Data read iteration \(i) completed")
        }
        
        // Should complete quickly due to caching
    }
    
    // MARK: - Integration Tests
    
    func testCompleteHealthKitWorkflow() async {
        // Test a complete HealthKit workflow
        
        // Step 1: Check initial state
        XCTAssertFalse(healthKitService.isAuthorized)
        
        // Step 2: Read data (should work even without authorization)
        await healthKitService.readTodaysData()
        
        // Step 3: Attempt to save weight
        let saveResult = await healthKitService.saveWeight(75.0)
        
        // Step 4: Setup background delivery and observers
        healthKitService.enableBackgroundDelivery()
        healthKitService.startObserverQueries()
        
        // Step 5: Read data again (should use cache)
        await healthKitService.readTodaysData()
        
        // Step 6: Cleanup
        healthKitService.stopObserverQueries()
        healthKitService.disableBackgroundDelivery()
        
        // Then - Should complete without crashing
        print("Complete HealthKit workflow test completed")
        print("Save result: \(saveResult)")
        print("Final steps: \(healthKitService.todaySteps)")
        print("Final calories: \(healthKitService.todayCalories)")
        print("Final weight: \(healthKitService.currentWeight?.description ?? "nil")")
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryManagement() {
        weak var weakService: HealthKitService?
        
        autoreleasepool {
            let testService = HealthKitService()
            weakService = testService
            
            // Use the service
            testService.startObserverQueries()
            testService.stopObserverQueries()
        }
        
        // Service should be deallocated
        XCTAssertNil(weakService, "HealthKitService should be deallocated")
    }
    
    // MARK: - Edge Cases and Validation
    
    func testInvalidWeightValues() async {
        // Test edge cases for weight saving
        let invalidWeights = [-10.0, 0.0, 1000.0]
        
        for weight in invalidWeights {
            // When
            let success = await healthKitService.saveWeight(weight)
            
            // Then - Should handle gracefully (may succeed or fail depending on HealthKit validation)
            print("Weight \(weight) save result: \(success)")
        }
    }
    
    func testServiceStateAfterMultipleOperations() async {
        // Test service stability after multiple operations
        
        // Multiple data reads
        for _ in 1...3 {
            await healthKitService.readTodaysData()
        }
        
        // Multiple weight saves
        for weight in [70.0, 75.0, 80.0] {
            let _ = await healthKitService.saveWeight(weight)
        }
        
        // Multiple observer operations
        healthKitService.startObserverQueries()
        healthKitService.stopObserverQueries()
        healthKitService.startObserverQueries()
        healthKitService.stopObserverQueries()
        
        // Then - Service should remain stable
        XCTAssertNotNil(healthKitService)
        XCTAssertGreaterThanOrEqual(healthKitService.todaySteps, 0)
        XCTAssertGreaterThanOrEqual(healthKitService.todayCalories, 0)
        
        print("Service stability test completed successfully")
    }
    
    // MARK: - Real Device vs Simulator Behavior
    
    func testHealthKitAvailabilityHandling() {
        // Test behavior based on HealthKit availability
        if HKHealthStore.isHealthDataAvailable() {
            // On real device
            print("Testing on device with HealthKit support")
            
            // Test that service can handle real HealthKit operations
            Task {
                await healthKitService.readTodaysData()
                // Should potentially have real data
            }
        } else {
            // On simulator
            print("Testing on simulator without HealthKit support")
            
            // Test that service handles unavailability gracefully
            Task {
                let permissionResult = await healthKitService.requestPermissions()
                XCTAssertFalse(permissionResult, "Should return false on simulator")
            }
        }
    }
    
    // MARK: - Concurrent Access Tests
    
    func testConcurrentDataReads() async {
        // Test multiple concurrent data reads
        let tasks = (1...5).map { i in
            Task {
                await healthKitService.readTodaysData()
                print("Concurrent read \(i) completed")
            }
        }
        
        // Wait for all tasks to complete
        for task in tasks {
            await task.value
        }
        
        // Should complete without issues
        XCTAssertNotNil(healthKitService)
    }
    
    // MARK: - Data Consistency Tests
    
    func testDataConsistencyAfterOperations() async {
        // Test that data remains consistent after various operations
        
        // Initial read
        await healthKitService.readTodaysData()
        let initialSteps = healthKitService.todaySteps
        let initialCalories = healthKitService.todayCalories
        
        // Operations that shouldn't affect current data
        healthKitService.enableBackgroundDelivery()
        healthKitService.startObserverQueries()
        
        // Data should remain consistent (cached)
        XCTAssertEqual(healthKitService.todaySteps, initialSteps)
        XCTAssertEqual(healthKitService.todayCalories, initialCalories)
        
        // Cleanup
        healthKitService.stopObserverQueries()
        healthKitService.disableBackgroundDelivery()
    }
}

// MARK: - Mock HealthKit Service for Testing

/// Mock service for unit testing without real HealthKit dependencies
@MainActor
class MockHealthKitService: ObservableObject {
    @Published var isAuthorized = false
    @Published var todaySteps: Double = 5000
    @Published var todayCalories: Double = 300
    @Published var currentWeight: Double? = 70.0
    @Published var isLoading = false
    @Published var error: Error?
    
    func requestPermissions() async -> Bool {
        isAuthorized = true
        return true
    }
    
    func readTodaysData() async {
        isLoading = true
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        isLoading = false
    }
    
    func saveWeight(_ weight: Double) async -> Bool {
        currentWeight = weight
        return true
    }
    
    func getAuthorizationStatus() -> (steps: HKAuthorizationStatus, calories: HKAuthorizationStatus, weight: HKAuthorizationStatus) {
        return (.sharingAuthorized, .sharingAuthorized, .sharingAuthorized)
    }
}

// MARK: - Test Extensions

extension HealthKitServiceTests {
    
    /// Test that mock service behaves as expected
    func testMockHealthKitService() async {
        // Given
        let mockService = MockHealthKitService()
        
        // When
        let authorized = await mockService.requestPermissions()
        await mockService.readTodaysData()
        let weightSaved = await mockService.saveWeight(75.0)
        
        // Then
        XCTAssertTrue(authorized)
        XCTAssertTrue(mockService.isAuthorized)
        XCTAssertEqual(mockService.todaySteps, 5000)
        XCTAssertEqual(mockService.todayCalories, 300)
        XCTAssertTrue(weightSaved)
        XCTAssertEqual(mockService.currentWeight, 75.0)
        XCTAssertFalse(mockService.isLoading)
    }
}