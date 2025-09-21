import XCTest
@testable import thrustr

// MARK: - Watch Workout ViewModel Tests
@MainActor
final class WatchWorkoutViewModelTests: XCTestCase {

    var viewModel: WatchWorkoutViewModel!
    var mockCommunicationService: MockWatchCommunicationService!

    override func setUp() {
        super.setUp()
        mockCommunicationService = MockWatchCommunicationService()
        viewModel = WatchWorkoutViewModel(communicationService: MockWatchCommunicationService.self)
    }

    override func tearDown() {
        viewModel = nil
        mockCommunicationService = nil
        MockWatchCommunicationService.reset()
        super.tearDown()
    }

    // MARK: - Initialization Tests
    func testInitialState() {
        XCTAssertNil(viewModel.currentSession)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.workoutSessions.count, 0)
    }

    // MARK: - Start Workout Tests
    func testStartWorkoutSuccess() async {
        // Given
        MockWatchCommunicationService.shouldSucceed = true
        let workoutType = WatchWorkoutType.strength

        // When
        await viewModel.startWorkout(type: workoutType)

        // Then
        XCTAssertNotNil(viewModel.currentSession)
        XCTAssertEqual(viewModel.currentSession?.type, workoutType)
        XCTAssertTrue(viewModel.currentSession?.isActive ?? false)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testStartWorkoutFailure() async {
        // Given
        MockWatchCommunicationService.shouldSucceed = false
        let workoutType = WatchWorkoutType.cardio

        // When
        await viewModel.startWorkout(type: workoutType)

        // Then
        XCTAssertNil(viewModel.currentSession)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage?.contains("Failed to start workout") ?? false)
    }

    func testStartWorkoutWhileAlreadyActive() async {
        // Given - Start first workout
        MockWatchCommunicationService.shouldSucceed = true
        await viewModel.startWorkout(type: .strength)
        let firstSessionId = viewModel.currentSession?.id

        // When - Try to start second workout
        await viewModel.startWorkout(type: .cardio)

        // Then - Should not change current session
        XCTAssertEqual(viewModel.currentSession?.id, firstSessionId)
        XCTAssertEqual(viewModel.currentSession?.type, .strength)
    }

    // MARK: - Stop Workout Tests
    func testStopWorkoutSuccess() async {
        // Given - Start a workout first
        MockWatchCommunicationService.shouldSucceed = true
        await viewModel.startWorkout(type: .strength)
        XCTAssertNotNil(viewModel.currentSession)

        // When
        await viewModel.stopWorkout()

        // Then
        XCTAssertNil(viewModel.currentSession)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.workoutSessions.count, 1)
    }

    func testStopWorkoutWhenNoneActive() async {
        // Given - No active workout
        XCTAssertNil(viewModel.currentSession)

        // When
        await viewModel.stopWorkout()

        // Then - Should handle gracefully
        XCTAssertNil(viewModel.currentSession)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.workoutSessions.count, 0)
    }

    func testStopWorkoutFailure() async {
        // Given - Start workout
        MockWatchCommunicationService.shouldSucceed = true
        await viewModel.startWorkout(type: .strength)

        // Set failure for stop
        MockWatchCommunicationService.shouldSucceed = false

        // When
        await viewModel.stopWorkout()

        // Then - Should still stop locally but show error
        XCTAssertNil(viewModel.currentSession)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage?.contains("Failed to sync workout completion") ?? false)
    }

    // MARK: - Pause/Resume Tests
    func testPauseWorkout() async {
        // Given - Start workout
        MockWatchCommunicationService.shouldSucceed = true
        await viewModel.startWorkout(type: .cardio)

        // When
        await viewModel.pauseWorkout()

        // Then
        XCTAssertNotNil(viewModel.currentSession)
        XCTAssertFalse(viewModel.currentSession?.isActive ?? true)
    }

    func testResumeWorkout() async {
        // Given - Start and pause workout
        MockWatchCommunicationService.shouldSucceed = true
        await viewModel.startWorkout(type: .cardio)
        await viewModel.pauseWorkout()

        // When
        await viewModel.resumeWorkout()

        // Then
        XCTAssertNotNil(viewModel.currentSession)
        XCTAssertTrue(viewModel.currentSession?.isActive ?? false)
    }

    // MARK: - Heart Rate Tests
    func testUpdateHeartRate() {
        // Given - Start workout
        let expectation = XCTestExpectation(description: "Start workout")
        Task {
            await viewModel.startWorkout(type: .strength)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // When
        let heartRateReading = HeartRateReading(bpm: 145, timestamp: Date())
        viewModel.updateHeartRate(heartRateReading)

        // Then
        XCTAssertEqual(viewModel.currentSession?.heartRateReadings.count, 1)
        XCTAssertEqual(viewModel.currentSession?.heartRateReadings.first?.bpm, 145)
        XCTAssertEqual(viewModel.currentSession?.averageHeartRate, 145)
        XCTAssertEqual(viewModel.currentSession?.maxHeartRate, 145)
    }

    func testUpdateHeartRateMultipleReadings() {
        // Given - Start workout
        let expectation = XCTestExpectation(description: "Start workout")
        Task {
            await viewModel.startWorkout(type: .cardio)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // When
        viewModel.updateHeartRate(HeartRateReading(bpm: 120, timestamp: Date()))
        viewModel.updateHeartRate(HeartRateReading(bpm: 150, timestamp: Date()))
        viewModel.updateHeartRate(HeartRateReading(bpm: 135, timestamp: Date()))

        // Then
        XCTAssertEqual(viewModel.currentSession?.heartRateReadings.count, 3)
        XCTAssertEqual(viewModel.currentSession?.averageHeartRate, 135) // (120+150+135)/3
        XCTAssertEqual(viewModel.currentSession?.maxHeartRate, 150)
    }

    // MARK: - Session History Tests
    func testSessionHistoryPersistence() async {
        // Given
        MockWatchCommunicationService.shouldSucceed = true

        // When - Complete multiple workouts
        await viewModel.startWorkout(type: .strength)
        await viewModel.stopWorkout()

        await viewModel.startWorkout(type: .cardio)
        await viewModel.stopWorkout()

        // Then
        XCTAssertEqual(viewModel.workoutSessions.count, 2)
        XCTAssertEqual(viewModel.workoutSessions[0].type, .cardio) // Most recent first
        XCTAssertEqual(viewModel.workoutSessions[1].type, .strength)
    }

    func testLoadWorkoutSessions() async {
        // Given - Some existing sessions
        let mockSession1 = createMockWorkoutSession(type: .strength)
        let mockSession2 = createMockWorkoutSession(type: .cardio)

        // When
        await viewModel.loadWorkoutSessions()

        // Then - Should load from storage service
        // Note: This would require WatchStorageService to be properly mocked
        // For now, we verify the method doesn't crash
        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - Error Handling Tests
    func testErrorMessageClearing() async {
        // Given - Set an error
        MockWatchCommunicationService.shouldSucceed = false
        await viewModel.startWorkout(type: .strength)
        XCTAssertNotNil(viewModel.errorMessage)

        // When - Clear error
        viewModel.clearError()

        // Then
        XCTAssertNil(viewModel.errorMessage)
    }

    // MARK: - Loading State Tests
    func testLoadingStatesDuringWorkoutStart() async {
        // Given
        MockWatchCommunicationService.shouldSucceed = true

        // When - Start workout (should set loading to true briefly)
        let startTask = Task {
            await viewModel.startWorkout(type: .strength)
        }

        // Then - Loading should be false after completion
        await startTask.value
        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - Helper Methods
    private func createMockWorkoutSession(type: WatchWorkoutType) -> WatchWorkoutSession {
        return WatchWorkoutSession(
            id: UUID(),
            type: type,
            startTime: Date(),
            endTime: Date().addingTimeInterval(1800),
            duration: 1800,
            isActive: false,
            heartRateReadings: [],
            averageHeartRate: 0,
            maxHeartRate: 0,
            calories: 200,
            steps: nil,
            exerciseCount: 3,
            notes: "Mock session"
        )
    }

    // MARK: - Mock Communication Service
    class MockWatchCommunicationService: WatchCommunicationServiceProtocol {
        static var shouldSucceed = true
        static var lastSentMessage: WatchMessage?
        static var lastSentSession: WatchWorkoutSession?

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
                errorMessage: shouldSucceed ? nil : "Mock session sync error"
            )
        }

        static func syncUserSettings(_ settings: WatchUserSettings) async throws -> WatchCommunicationResult {
            return WatchCommunicationResult(
                isSuccess: shouldSucceed,
                errorMessage: shouldSucceed ? nil : "Mock settings error"
            )
        }

        static func requestHealthData() async throws -> WatchHealthData? {
            guard shouldSucceed else { return nil }
            return WatchHealthData(heartRate: 75, steps: 5000, calories: 150)
        }

        static var isConnected: Bool { shouldSucceed }
        static var connectionStatus: String { shouldSucceed ? "Connected" : "Disconnected" }

        static func reset() {
            shouldSucceed = true
            lastSentMessage = nil
            lastSentSession = nil
        }
    }
}