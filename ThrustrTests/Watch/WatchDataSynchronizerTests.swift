import XCTest
import SwiftData
@testable import thrustr

// MARK: - Watch Data Synchronizer Tests
@MainActor
final class WatchDataSynchronizerTests: XCTestCase {

    var synchronizer: WatchDataSynchronizer!
    var mockContext: ModelContext!
    var mockHealthKitService: MockHealthKitService!

    override func setUp() async throws {
        super.setUp()

        // Create in-memory model container for testing
        let schema = Schema([User.self, LiftSession.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        mockContext = ModelContext(container)

        mockHealthKitService = MockHealthKitService()
        synchronizer = WatchDataSynchronizer(
            communicationService: MockWatchCommunicationService.self,
            modelContext: mockContext,
            healthKitService: mockHealthKitService
        )

        // Add test user to context
        let testUser = User(
            age: 30,
            weight: 75.0,
            activityLevel: .moderatelyActive,
            fitnessGoal: .strength
        )
        mockContext.insert(testUser)
        try mockContext.save()
    }

    override func tearDown() {
        synchronizer = nil
        mockContext = nil
        mockHealthKitService = nil
        MockWatchCommunicationService.reset()
        super.tearDown()
    }

    // MARK: - Initialization Tests
    func testInitialState() {
        XCTAssertEqual(synchronizer.syncStatus, .idle)
        XCTAssertEqual(synchronizer.syncProgress, 0.0)
        XCTAssertNil(synchronizer.errorMessage)
    }

    // MARK: - Manual Sync Tests
    func testSyncWithWatchSuccess() async {
        // Given
        MockWatchCommunicationService.shouldSucceed = true

        // When
        await synchronizer.syncWithWatch()

        // Then
        XCTAssertEqual(synchronizer.syncStatus, .completed)
        XCTAssertEqual(synchronizer.syncProgress, 1.0)
        XCTAssertNil(synchronizer.errorMessage)
        XCTAssertNotNil(synchronizer.lastSyncDate)
    }

    func testSyncWithWatchFailure() async {
        // Given
        MockWatchCommunicationService.shouldSucceed = false

        // When
        await synchronizer.syncWithWatch()

        // Then
        if case .failed(let message) = synchronizer.syncStatus {
            XCTAssertTrue(message.contains("Mock"))
        } else {
            XCTFail("Expected sync status to be failed")
        }
        XCTAssertNotNil(synchronizer.errorMessage)
    }

    func testSyncAlreadyInProgress() async {
        // Given - Start first sync
        let firstSyncTask = Task {
            await synchronizer.syncWithWatch()
        }

        // When - Try to start second sync while first is running
        await synchronizer.syncWithWatch()

        // Then - Second sync should be ignored
        await firstSyncTask.value
        XCTAssertEqual(synchronizer.syncStatus, .completed)
    }

    func testSyncProgress() async {
        // Given
        MockWatchCommunicationService.shouldSucceed = true
        var progressValues: [Double] = []

        // Monitor progress changes
        let progressExpectation = XCTestExpectation(description: "Progress updates")
        let cancellable = synchronizer.$syncProgress.sink { progress in
            progressValues.append(progress)
            if progress >= 1.0 {
                progressExpectation.fulfill()
            }
        }

        // When
        await synchronizer.syncWithWatch()

        // Then
        await fulfillment(of: [progressExpectation], timeout: 2.0)
        XCTAssertTrue(progressValues.contains(0.1)) // User settings sync
        XCTAssertTrue(progressValues.contains(0.3)) // Workouts sync
        XCTAssertTrue(progressValues.contains(0.5)) // Health data request
        XCTAssertTrue(progressValues.contains(0.8)) // Workouts from Watch
        XCTAssertTrue(progressValues.contains(1.0)) // Completion

        cancellable.cancel()
    }

    // MARK: - Incoming Workout Tests
    func testHandleIncomingWorkoutSessionNew() async {
        // Given
        let watchSession = createMockWatchWorkoutSession()

        // When
        await synchronizer.handleIncomingWorkoutSession(watchSession)

        // Then
        let descriptor = FetchDescriptor<LiftSession>()
        let sessions = try! mockContext.fetch(descriptor)
        XCTAssertEqual(sessions.count, 1)
        XCTAssertEqual(sessions.first?.id, watchSession.id)
    }

    func testHandleIncomingWorkoutSessionExisting() async {
        // Given - Create existing session
        let existingSession = LiftSession(
            id: UUID(),
            programExecution: nil,
            workout: nil
        )
        existingSession.startTime = Date()
        existingSession.totalCalories = 100.0
        mockContext.insert(existingSession)
        try! mockContext.save()

        // Create watch session with same ID but different data
        let watchSession = WatchWorkoutSession(
            id: existingSession.id,
            type: .strength,
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600),
            duration: 3600,
            isActive: false,
            heartRateReadings: [],
            averageHeartRate: 0,
            maxHeartRate: 0,
            calories: 300,
            steps: nil,
            exerciseCount: 5,
            notes: "Updated from Watch"
        )

        // When
        await synchronizer.handleIncomingWorkoutSession(watchSession)

        // Then
        let descriptor = FetchDescriptor<LiftSession>()
        let sessions = try! mockContext.fetch(descriptor)
        XCTAssertEqual(sessions.count, 1)
        XCTAssertEqual(sessions.first?.totalCalories, 300.0) // Should be updated
        XCTAssertTrue(sessions.first?.notes?.contains("Updated from Watch") ?? false)
    }

    // MARK: - Health Data Processing Tests
    func testProcessWatchHealthData() async {
        // Given
        let healthData = WatchHealthData(
            heartRate: 85,
            steps: 12000,
            calories: 450
        )

        // When
        await synchronizer.processWatchHealthData(healthData)

        // Then - Should post notification
        let expectation = XCTestExpectation(description: "Health data notification")
        let observer = NotificationCenter.default.addObserver(
            forName: .watchHealthDataUpdated,
            object: nil,
            queue: .main
        ) { notification in
            if let receivedData = notification.object as? WatchHealthData {
                XCTAssertEqual(receivedData.heartRate, 85)
                XCTAssertEqual(receivedData.steps, 12000)
                XCTAssertEqual(receivedData.calories, 450)
                expectation.fulfill()
            }
        }

        // Trigger the notification
        await synchronizer.processWatchHealthData(healthData)

        await fulfillment(of: [expectation], timeout: 1.0)
        NotificationCenter.default.removeObserver(observer)
    }

    // MARK: - Auto Sync Tests
    func testScheduleAutoSync() {
        // Given
        MockWatchCommunicationService.shouldSucceed = true

        // When
        synchronizer.scheduleAutoSync()

        // Then - Auto sync should be scheduled (we can't easily test Timer in unit tests)
        // This test mainly ensures the method doesn't crash
        XCTAssertEqual(synchronizer.syncStatus, .idle)
    }

    // MARK: - Error Handling Tests
    func testWatchSyncErrorTypes() {
        let noUserError = WatchSyncError.noUserFound
        let settingsError = WatchSyncError.settingsSyncFailed("Test error")
        let workoutError = WatchSyncError.workoutSyncFailed("Workout error")

        XCTAssertEqual(noUserError.errorDescription, "No user found in database")
        XCTAssertEqual(settingsError.errorDescription, "Settings sync failed: Test error")
        XCTAssertEqual(workoutError.errorDescription, "Workout sync failed: Workout error")
    }

    func testSyncStatusIsActive() {
        let idleStatus = WatchDataSynchronizer.SyncStatus.idle
        let syncingStatus = WatchDataSynchronizer.SyncStatus.syncing
        let completedStatus = WatchDataSynchronizer.SyncStatus.completed
        let failedStatus = WatchDataSynchronizer.SyncStatus.failed("Error")

        XCTAssertFalse(idleStatus.isActive)
        XCTAssertTrue(syncingStatus.isActive)
        XCTAssertFalse(completedStatus.isActive)
        XCTAssertFalse(failedStatus.isActive)
    }

    // MARK: - Helper Methods
    private func createMockWatchWorkoutSession() -> WatchWorkoutSession {
        return WatchWorkoutSession(
            id: UUID(),
            type: .strength,
            startTime: Date().addingTimeInterval(-3600),
            endTime: Date(),
            duration: 3600,
            isActive: false,
            heartRateReadings: [
                HeartRateReading(bpm: 120, timestamp: Date().addingTimeInterval(-1800)),
                HeartRateReading(bpm: 140, timestamp: Date().addingTimeInterval(-900))
            ],
            averageHeartRate: 130,
            maxHeartRate: 150,
            calories: 400,
            steps: 2000,
            exerciseCount: 6,
            notes: "Test workout from Watch"
        )
    }

    // MARK: - Mock Services
    class MockWatchCommunicationService: WatchCommunicationServiceProtocol {
        static var shouldSucceed = true
        static var lastSentSettings: WatchUserSettings?
        static var lastSentSession: WatchWorkoutSession?
        static var lastSentMessage: WatchMessage?

        static func sendMessage(_ message: WatchMessage) async throws -> WatchCommunicationResult {
            lastSentMessage = message
            return WatchCommunicationResult(
                isSuccess: shouldSucceed,
                errorMessage: shouldSucceed ? nil : "Mock communication error"
            )
        }

        static func sendWorkoutSession(_ session: WatchWorkoutSession) async throws -> WatchCommunicationResult {
            lastSentSession = session
            return WatchCommunicationResult(
                isSuccess: shouldSucceed,
                errorMessage: shouldSucceed ? nil : "Mock session error"
            )
        }

        static func syncUserSettings(_ settings: WatchUserSettings) async throws -> WatchCommunicationResult {
            lastSentSettings = settings
            return WatchCommunicationResult(
                isSuccess: shouldSucceed,
                errorMessage: shouldSucceed ? nil : "Mock settings error"
            )
        }

        static func requestHealthData() async throws -> WatchHealthData? {
            guard shouldSucceed else { return nil }
            return WatchHealthData(heartRate: 78, steps: 9500, calories: 280)
        }

        static var isConnected: Bool { shouldSucceed }
        static var connectionStatus: String { shouldSucceed ? "Connected" : "Disconnected" }

        static func reset() {
            shouldSucceed = true
            lastSentSettings = nil
            lastSentSession = nil
            lastSentMessage = nil
        }
    }

    class MockHealthKitService: HealthKitService {
        override func requestAuthorization() async throws {
            // Mock implementation
        }

        override func getStepsCount(for date: Date) async throws -> Double {
            return 8500.0
        }

        override func getCaloriesCount(for date: Date) async throws -> Double {
            return 250.0
        }
    }
}