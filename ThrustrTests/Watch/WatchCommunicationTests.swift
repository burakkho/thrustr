import XCTest
@testable import thrustr

// MARK: - Watch Communication Tests
final class WatchCommunicationTests: XCTestCase {

    // MARK: - Mock Communication Service
    class MockWatchCommunicationService: WatchCommunicationServiceProtocol {
        static var shouldSucceed = true
        static var lastSentMessage: WatchMessage?
        static var lastSentSession: WatchWorkoutSession?
        static var lastSentSettings: WatchUserSettings?

        static func sendMessage(_ message: WatchMessage) async throws -> WatchCommunicationResult {
            lastSentMessage = message
            return WatchCommunicationResult(
                isSuccess: shouldSucceed,
                errorMessage: shouldSucceed ? nil : "Mock error"
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
            return WatchHealthData(
                heartRate: 72,
                steps: 8500,
                calories: 245
            )
        }

        static var isConnected: Bool { shouldSucceed }
        static var connectionStatus: String { shouldSucceed ? "Connected" : "Disconnected" }

        static func reset() {
            shouldSucceed = true
            lastSentMessage = nil
            lastSentSession = nil
            lastSentSettings = nil
        }
    }

    override func setUp() {
        super.setUp()
        MockWatchCommunicationService.reset()
    }

    // MARK: - Message Communication Tests
    func testSendMessageSuccess() async throws {
        // Given
        MockWatchCommunicationService.shouldSucceed = true
        let message = WatchMessage(command: .startWorkout)

        // When
        let result = try await MockWatchCommunicationService.sendMessage(message)

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertNil(result.errorMessage)
        XCTAssertEqual(MockWatchCommunicationService.lastSentMessage?.command, .startWorkout)
    }

    func testSendMessageFailure() async throws {
        // Given
        MockWatchCommunicationService.shouldSucceed = false
        let message = WatchMessage(command: .stopWorkout)

        // When
        let result = try await MockWatchCommunicationService.sendMessage(message)

        // Then
        XCTAssertFalse(result.isSuccess)
        XCTAssertEqual(result.errorMessage, "Mock error")
        XCTAssertEqual(MockWatchCommunicationService.lastSentMessage?.command, .stopWorkout)
    }

    // MARK: - Workout Session Tests
    func testSendWorkoutSessionSuccess() async throws {
        // Given
        MockWatchCommunicationService.shouldSucceed = true
        let session = createMockWorkoutSession()

        // When
        let result = try await MockWatchCommunicationService.sendWorkoutSession(session)

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertNil(result.errorMessage)
        XCTAssertEqual(MockWatchCommunicationService.lastSentSession?.id, session.id)
        XCTAssertEqual(MockWatchCommunicationService.lastSentSession?.type, .strength)
    }

    func testSendWorkoutSessionFailure() async throws {
        // Given
        MockWatchCommunicationService.shouldSucceed = false
        let session = createMockWorkoutSession()

        // When
        let result = try await MockWatchCommunicationService.sendWorkoutSession(session)

        // Then
        XCTAssertFalse(result.isSuccess)
        XCTAssertEqual(result.errorMessage, "Mock session error")
    }

    // MARK: - User Settings Tests
    func testSyncUserSettingsSuccess() async throws {
        // Given
        MockWatchCommunicationService.shouldSucceed = true
        let settings = createMockUserSettings()

        // When
        let result = try await MockWatchCommunicationService.syncUserSettings(settings)

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertNil(result.errorMessage)
        XCTAssertEqual(MockWatchCommunicationService.lastSentSettings?.enableHapticFeedback, true)
        XCTAssertEqual(MockWatchCommunicationService.lastSentSettings?.autoStartWorkout, false)
    }

    // MARK: - Health Data Tests
    func testRequestHealthDataSuccess() async throws {
        // Given
        MockWatchCommunicationService.shouldSucceed = true

        // When
        let healthData = try await MockWatchCommunicationService.requestHealthData()

        // Then
        XCTAssertNotNil(healthData)
        XCTAssertEqual(healthData?.heartRate, 72)
        XCTAssertEqual(healthData?.steps, 8500)
        XCTAssertEqual(healthData?.calories, 245)
    }

    func testRequestHealthDataFailure() async throws {
        // Given
        MockWatchCommunicationService.shouldSucceed = false

        // When
        let healthData = try await MockWatchCommunicationService.requestHealthData()

        // Then
        XCTAssertNil(healthData)
    }

    // MARK: - Connection Status Tests
    func testConnectionStatus() {
        // Test connected state
        MockWatchCommunicationService.shouldSucceed = true
        XCTAssertTrue(MockWatchCommunicationService.isConnected)
        XCTAssertEqual(MockWatchCommunicationService.connectionStatus, "Connected")

        // Test disconnected state
        MockWatchCommunicationService.shouldSucceed = false
        XCTAssertFalse(MockWatchCommunicationService.isConnected)
        XCTAssertEqual(MockWatchCommunicationService.connectionStatus, "Disconnected")
    }

    // MARK: - Helper Methods
    private func createMockWorkoutSession() -> WatchWorkoutSession {
        return WatchWorkoutSession(
            id: UUID(),
            type: .strength,
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600),
            duration: 3600,
            isActive: false,
            heartRateReadings: [
                HeartRateReading(bpm: 120, timestamp: Date()),
                HeartRateReading(bpm: 130, timestamp: Date().addingTimeInterval(300))
            ],
            averageHeartRate: 125,
            maxHeartRate: 140,
            calories: 350,
            steps: 1200,
            exerciseCount: 5,
            notes: "Test workout session"
        )
    }

    private func createMockUserSettings() -> WatchUserSettings {
        return WatchUserSettings(
            preferredWorkoutTypes: [.strength, .cardio],
            enableHapticFeedback: true,
            autoStartWorkout: false,
            displayMetrics: WatchDisplayMetrics()
        )
    }
}