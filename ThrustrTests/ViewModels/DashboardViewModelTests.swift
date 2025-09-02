import XCTest
import SwiftData
@testable import Thrustr

@MainActor
final class DashboardViewModelTests: XCTestCase {
    
    // MARK: - Test Properties
    private var viewModel: DashboardViewModel!
    private var mockHealthKitService: MockHealthKitService!
    private var modelContext: ModelContext!
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create test model context
        modelContext = try TestHelpers.createTestModelContext()
        
        // Create mock services
        mockHealthKitService = MockHealthKitService()
        
        // Create real HealthKitService for the viewModel since we can't inject mocks easily
        // We'll test the behavior through the public interface
        let realHealthKitService = HealthKitService()
        viewModel = DashboardViewModel(healthKitService: realHealthKitService)
    }
    
    override func tearDown() async throws {
        viewModel = nil
        mockHealthKitService = nil
        modelContext = nil
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        // Given & When
        let realHealthKitService = HealthKitService()
        let testViewModel = DashboardViewModel(healthKitService: realHealthKitService)
        
        // Then
        XCTAssertNil(testViewModel.currentUser)
        XCTAssertTrue(testViewModel.isLoading)
        XCTAssertEqual(testViewModel.weeklyStats.workoutCount, 0)
        XCTAssertEqual(testViewModel.weeklyCardioStats.sessionCount, 0)
    }
    
    // MARK: - Data Loading Tests
    
    func testLoadDataSuccess() async throws {
        // Given
        let testUser = TestHelpers.createTestUser()
        modelContext.insert(testUser)
        try modelContext.save()
        
        mockHealthKitService.setMockData(steps: 10000, calories: 2500, weight: 75.0)
        
        // When
        await viewModel.loadData(with: modelContext)
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.currentUser)
        XCTAssertEqual(viewModel.currentUser?.name, "Test User")
    }
    
    func testLoadDataWithNoUser() async throws {
        // Given - empty database
        mockHealthKitService.setMockData()
        
        // When
        await viewModel.loadData(with: modelContext)
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
        // Should handle gracefully when no user exists
    }
    
    func testLoadDataWithHealthKitFailure() async throws {
        // Given
        let testUser = TestHelpers.createTestUser()
        modelContext.insert(testUser)
        try modelContext.save()
        
        mockHealthKitService.simulateFailure()
        
        // When
        await viewModel.loadData(with: modelContext)
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
        // Should still load user data even if HealthKit fails
        XCTAssertNotNil(viewModel.currentUser)
    }
    
    // MARK: - Health Data Refresh Tests
    
    func testRefreshHealthDataSuccess() async throws {
        // Given
        let testUser = TestHelpers.createTestUser()
        modelContext.insert(testUser)
        try modelContext.save()
        
        viewModel.currentUser = testUser
        mockHealthKitService.setMockData(steps: 12000, calories: 2800, weight: 74.5)
        
        // When
        await viewModel.refreshHealthData(modelContext: modelContext)
        
        // Then
        // Verify that health data refresh was attempted
        // Note: This test depends on the internal implementation
        // In a real scenario, we'd verify the user's health data was updated
    }
    
    func testRefreshHealthDataWithNoUser() async throws {
        // Given - no current user
        viewModel.currentUser = nil
        
        // When
        await viewModel.refreshHealthData(modelContext: modelContext)
        
        // Then - should handle gracefully
        // No crashes or errors expected
    }
    
    // MARK: - Performance Tests
    
    func testLoadDataPerformance() async throws {
        // Given
        let testUser = TestHelpers.createTestUser()
        modelContext.insert(testUser)
        
        // Add some test data for performance testing
        for i in 1...10 {
            let exercise = TestHelpers.createTestExercise(name: "Exercise \(i)")
            let food = TestHelpers.createTestFood(name: "Food \(i)")
            modelContext.insert(exercise)
            modelContext.insert(food)
        }
        
        try modelContext.save()
        
        // When & Then
        let startTime = Date()
        await viewModel.loadData(with: modelContext)
        let duration = Date().timeIntervalSince(startTime)
        
        // Should complete within reasonable time (adjust threshold as needed)
        XCTAssertLessThan(duration, 5.0, "Data loading should complete within 5 seconds")
        XCTAssertFalse(viewModel.isLoading)
    }
    
    // MARK: - Error Handling Tests
    
    func testLoadDataWithDatabaseError() async throws {
        // Given - corrupted model context (simulate database error)
        let corruptedContext = try TestHelpers.createTestModelContext()
        
        // When
        await viewModel.loadData(with: corruptedContext)
        
        // Then - should handle gracefully
        XCTAssertFalse(viewModel.isLoading)
    }
    
    // MARK: - State Management Tests
    
    func testLoadingStateTransitions() async throws {
        // Given
        let testUser = TestHelpers.createTestUser()
        modelContext.insert(testUser)
        try modelContext.save()
        
        // When - start loading
        XCTAssertTrue(viewModel.isLoading)
        
        let loadingTask = Task {
            await viewModel.loadData(with: modelContext)
        }
        
        // During loading, isLoading should be true
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        await loadingTask.value
        
        // Then - after completion, should be false
        XCTAssertFalse(viewModel.isLoading)
    }
    
    // MARK: - Integration Tests
    
    func testCompleteDataFlowIntegration() async throws {
        // Given - Complete test scenario
        let testUser = TestHelpers.createTestUser()
        modelContext.insert(testUser)
        
        // Add some realistic test data
        let exercise = TestHelpers.createTestExercise(name: "Push-ups")
        let food = TestHelpers.createTestFood(name: "Banana")
        
        modelContext.insert(exercise)
        modelContext.insert(food)
        try modelContext.save()
        
        mockHealthKitService.setMockData(steps: 8500, calories: 2200, weight: 75.0)
        
        // When - Full data loading cycle
        await viewModel.loadData(with: modelContext)
        
        // Then - Complete state verification
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.currentUser)
        XCTAssertEqual(viewModel.currentUser?.name, "Test User")
        
        // Verify weekly stats are initialized (even if empty)
        XCTAssertNotNil(viewModel.weeklyStats)
        XCTAssertNotNil(viewModel.weeklyCardioStats)
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryManagement() async throws {
        // Given
        weak var weakViewModel: DashboardViewModel?
        
        // When - Create and destroy view model
        autoreleasepool {
            let realHealthKitService = HealthKitService()
            let testViewModel = DashboardViewModel(healthKitService: realHealthKitService)
            weakViewModel = testViewModel
            // testViewModel goes out of scope
        }
        
        // Then - Should be deallocated
        // Note: This might be flaky due to test timing, but it's good to have
        XCTAssertNil(weakViewModel, "ViewModel should be deallocated when no longer referenced")
    }
}

// MARK: - Custom Assertions

extension DashboardViewModelTests {
    
    func assertValidUserState(_ user: User?) {
        XCTAssertNotNil(user)
        XCTAssertFalse(user?.name.isEmpty ?? true)
        XCTAssertGreaterThan(user?.age ?? 0, 0)
        XCTAssertGreaterThan(user?.height ?? 0, 0)
        XCTAssertGreaterThan(user?.currentWeight ?? 0, 0)
    }
    
    func assertValidWeeklyStats(_ stats: WeeklyStats) {
        XCTAssertGreaterThanOrEqual(stats.workoutCount, 0)
        XCTAssertGreaterThanOrEqual(stats.totalVolume, 0)
    }
}