import XCTest
@testable import thrustr

// MARK: - Watch Models Tests
final class WatchModelsTests: XCTestCase {

    // MARK: - WatchWorkoutSession Tests
    func testWatchWorkoutSessionInitialization() {
        // Given
        let id = UUID()
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(3600)
        let heartRateReadings = [
            HeartRateReading(bpm: 120, timestamp: startTime),
            HeartRateReading(bpm: 140, timestamp: startTime.addingTimeInterval(1800))
        ]

        // When
        let session = WatchWorkoutSession(
            id: id,
            type: .strength,
            startTime: startTime,
            endTime: endTime,
            duration: 3600,
            isActive: false,
            heartRateReadings: heartRateReadings,
            averageHeartRate: 130,
            maxHeartRate: 145,
            calories: 350,
            steps: 1500,
            exerciseCount: 5,
            notes: "Test workout"
        )

        // Then
        XCTAssertEqual(session.id, id)
        XCTAssertEqual(session.type, .strength)
        XCTAssertEqual(session.startTime, startTime)
        XCTAssertEqual(session.endTime, endTime)
        XCTAssertEqual(session.duration, 3600)
        XCTAssertFalse(session.isActive)
        XCTAssertEqual(session.heartRateReadings.count, 2)
        XCTAssertEqual(session.averageHeartRate, 130)
        XCTAssertEqual(session.maxHeartRate, 145)
        XCTAssertEqual(session.calories, 350)
        XCTAssertEqual(session.steps, 1500)
        XCTAssertEqual(session.exerciseCount, 5)
        XCTAssertEqual(session.notes, "Test workout")
    }

    func testWatchWorkoutSessionCodable() throws {
        // Given
        let originalSession = WatchWorkoutSession(
            id: UUID(),
            type: .cardio,
            startTime: Date(),
            endTime: Date().addingTimeInterval(1800),
            duration: 1800,
            isActive: true,
            heartRateReadings: [HeartRateReading(bpm: 150, timestamp: Date())],
            averageHeartRate: 145,
            maxHeartRate: 160,
            calories: 250,
            steps: 3000,
            exerciseCount: 1,
            notes: "Cardio session"
        )

        // When
        let encoded = try JSONEncoder().encode(originalSession)
        let decoded = try JSONDecoder().decode(WatchWorkoutSession.self, from: encoded)

        // Then
        XCTAssertEqual(decoded.id, originalSession.id)
        XCTAssertEqual(decoded.type, originalSession.type)
        XCTAssertEqual(decoded.duration, originalSession.duration)
        XCTAssertEqual(decoded.isActive, originalSession.isActive)
        XCTAssertEqual(decoded.calories, originalSession.calories)
        XCTAssertEqual(decoded.notes, originalSession.notes)
    }

    // MARK: - WatchWorkoutType Tests
    func testWatchWorkoutTypeProperties() {
        // Test strength
        XCTAssertEqual(WatchWorkoutType.strength.displayName, "Strength Training")
        XCTAssertEqual(WatchWorkoutType.strength.systemIcon, "dumbbell.fill")
        XCTAssertEqual(WatchWorkoutType.strength.accentColor, UIColor.blue)

        // Test cardio
        XCTAssertEqual(WatchWorkoutType.cardio.displayName, "Cardio")
        XCTAssertEqual(WatchWorkoutType.cardio.systemIcon, "heart.fill")
        XCTAssertEqual(WatchWorkoutType.cardio.accentColor, UIColor.red)

        // Test WOD
        XCTAssertEqual(WatchWorkoutType.wod.displayName, "WOD")
        XCTAssertEqual(WatchWorkoutType.wod.systemIcon, "flame.fill")
        XCTAssertEqual(WatchWorkoutType.wod.accentColor, UIColor.orange)

        // Test other
        XCTAssertEqual(WatchWorkoutType.other.displayName, "Other")
        XCTAssertEqual(WatchWorkoutType.other.systemIcon, "figure.run")
        XCTAssertEqual(WatchWorkoutType.other.accentColor, UIColor.gray)
    }

    func testWatchWorkoutTypeAllCases() {
        let allCases = WatchWorkoutType.allCases
        XCTAssertEqual(allCases.count, 4)
        XCTAssertTrue(allCases.contains(.strength))
        XCTAssertTrue(allCases.contains(.cardio))
        XCTAssertTrue(allCases.contains(.wod))
        XCTAssertTrue(allCases.contains(.other))
    }

    // MARK: - HeartRateReading Tests
    func testHeartRateReadingInitialization() {
        // Given
        let timestamp = Date()

        // When
        let reading = HeartRateReading(bpm: 142, timestamp: timestamp)

        // Then
        XCTAssertEqual(reading.bpm, 142)
        XCTAssertEqual(reading.timestamp, timestamp)
    }

    func testHeartRateReadingCodable() throws {
        // Given
        let originalReading = HeartRateReading(bpm: 135, timestamp: Date())

        // When
        let encoded = try JSONEncoder().encode(originalReading)
        let decoded = try JSONDecoder().decode(HeartRateReading.self, from: encoded)

        // Then
        XCTAssertEqual(decoded.bpm, originalReading.bpm)
        XCTAssertEqual(decoded.timestamp.timeIntervalSince1970,
                      originalReading.timestamp.timeIntervalSince1970,
                      accuracy: 0.001)
    }

    // MARK: - WatchHealthData Tests
    func testWatchHealthDataInitialization() {
        // When
        let healthData = WatchHealthData(
            heartRate: 85,
            steps: 12500,
            calories: 380
        )

        // Then
        XCTAssertEqual(healthData.heartRate, 85)
        XCTAssertEqual(healthData.steps, 12500)
        XCTAssertEqual(healthData.calories, 380)
        XCTAssertTrue(abs(healthData.timestamp.timeIntervalSinceNow) < 1.0) // Should be recent
    }

    func testWatchHealthDataCodable() throws {
        // Given
        let originalData = WatchHealthData(
            heartRate: 92,
            steps: 8750,
            calories: 290
        )

        // When
        let encoded = try JSONEncoder().encode(originalData)
        let decoded = try JSONDecoder().decode(WatchHealthData.self, from: encoded)

        // Then
        XCTAssertEqual(decoded.heartRate, originalData.heartRate)
        XCTAssertEqual(decoded.steps, originalData.steps)
        XCTAssertEqual(decoded.calories, originalData.calories)
    }

    // MARK: - WatchUserSettings Tests
    func testWatchUserSettingsDefaultInitialization() {
        // When
        let settings = WatchUserSettings()

        // Then
        XCTAssertTrue(settings.preferredWorkoutTypes.contains(.strength))
        XCTAssertTrue(settings.preferredWorkoutTypes.contains(.cardio))
        XCTAssertTrue(settings.enableHapticFeedback)
        XCTAssertFalse(settings.autoStartWorkout)
        XCTAssertNotNil(settings.displayMetrics)
    }

    func testWatchUserSettingsCustomInitialization() {
        // Given
        let displayMetrics = WatchDisplayMetrics()

        // When
        let settings = WatchUserSettings(
            preferredWorkoutTypes: [.wod, .other],
            enableHapticFeedback: false,
            autoStartWorkout: true,
            displayMetrics: displayMetrics
        )

        // Then
        XCTAssertEqual(settings.preferredWorkoutTypes.count, 2)
        XCTAssertTrue(settings.preferredWorkoutTypes.contains(.wod))
        XCTAssertTrue(settings.preferredWorkoutTypes.contains(.other))
        XCTAssertFalse(settings.enableHapticFeedback)
        XCTAssertTrue(settings.autoStartWorkout)
        XCTAssertEqual(settings.displayMetrics, displayMetrics)
    }

    func testWatchUserSettingsCodable() throws {
        // Given
        let originalSettings = WatchUserSettings(
            preferredWorkoutTypes: [.strength, .cardio],
            enableHapticFeedback: true,
            autoStartWorkout: false,
            displayMetrics: WatchDisplayMetrics()
        )

        // When
        let encoded = try JSONEncoder().encode(originalSettings)
        let decoded = try JSONDecoder().decode(WatchUserSettings.self, from: encoded)

        // Then
        XCTAssertEqual(decoded.preferredWorkoutTypes.count, originalSettings.preferredWorkoutTypes.count)
        XCTAssertEqual(decoded.enableHapticFeedback, originalSettings.enableHapticFeedback)
        XCTAssertEqual(decoded.autoStartWorkout, originalSettings.autoStartWorkout)
    }

    // MARK: - WatchDisplayMetrics Tests
    func testWatchDisplayMetricsInitialization() {
        // When
        let metrics = WatchDisplayMetrics()

        // Then
        XCTAssertTrue(metrics.showHeartRate)
        XCTAssertTrue(metrics.showCalories)
        XCTAssertTrue(metrics.showDuration)
        XCTAssertFalse(metrics.showSteps) // Default for strength training
    }

    func testWatchDisplayMetricsCodable() throws {
        // Given
        let originalMetrics = WatchDisplayMetrics(
            showHeartRate: false,
            showCalories: true,
            showDuration: true,
            showSteps: true
        )

        // When
        let encoded = try JSONEncoder().encode(originalMetrics)
        let decoded = try JSONDecoder().decode(WatchDisplayMetrics.self, from: encoded)

        // Then
        XCTAssertEqual(decoded.showHeartRate, originalMetrics.showHeartRate)
        XCTAssertEqual(decoded.showCalories, originalMetrics.showCalories)
        XCTAssertEqual(decoded.showDuration, originalMetrics.showDuration)
        XCTAssertEqual(decoded.showSteps, originalMetrics.showSteps)
    }

    // MARK: - WatchMessage Tests
    func testWatchMessageInitialization() {
        // When
        let message = WatchMessage(command: .startWorkout)

        // Then
        XCTAssertEqual(message.command, .startWorkout)
        XCTAssertTrue(abs(message.timestamp.timeIntervalSinceNow) < 1.0)
    }

    func testWatchMessageCodable() throws {
        // Given
        let originalMessage = WatchMessage(command: .stopWorkout)

        // When
        let encoded = try JSONEncoder().encode(originalMessage)
        let decoded = try JSONDecoder().decode(WatchMessage.self, from: encoded)

        // Then
        XCTAssertEqual(decoded.command, originalMessage.command)
    }

    // MARK: - WatchMessageCommand Tests
    func testWatchMessageCommandAllCases() {
        let allCases = WatchMessageCommand.allCases
        XCTAssertTrue(allCases.contains(.startWorkout))
        XCTAssertTrue(allCases.contains(.stopWorkout))
        XCTAssertTrue(allCases.contains(.pauseWorkout))
        XCTAssertTrue(allCases.contains(.resumeWorkout))
        XCTAssertTrue(allCases.contains(.requestHealthData))
        XCTAssertTrue(allCases.contains(.syncSettings))
    }

    // MARK: - WatchCommunicationResult Tests
    func testWatchCommunicationResultSuccess() {
        // When
        let result = WatchCommunicationResult(isSuccess: true, errorMessage: nil)

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertNil(result.errorMessage)
    }

    func testWatchCommunicationResultFailure() {
        // When
        let result = WatchCommunicationResult(isSuccess: false, errorMessage: "Test error")

        // Then
        XCTAssertFalse(result.isSuccess)
        XCTAssertEqual(result.errorMessage, "Test error")
    }

    // MARK: - WatchCommunicationError Tests
    func testWatchCommunicationErrorDescriptions() {
        let notConnected = WatchCommunicationError.notConnected
        let sendFailed = WatchCommunicationError.sendFailed("Send error")
        let receiveFailed = WatchCommunicationError.receiveFailed("Receive error")
        let invalidData = WatchCommunicationError.invalidData

        XCTAssertEqual(notConnected.errorDescription, "Watch is not connected")
        XCTAssertEqual(sendFailed.errorDescription, "Failed to send data: Send error")
        XCTAssertEqual(receiveFailed.errorDescription, "Failed to receive data: Receive error")
        XCTAssertEqual(invalidData.errorDescription, "Invalid data received")
    }

    // MARK: - WatchStorageInfo Tests
    func testWatchStorageInfoFormatters() {
        // Given
        let lastSync = Date().addingTimeInterval(-3600) // 1 hour ago
        let storageInfo = WatchStorageInfo(
            workoutCount: 25,
            storageSize: 1024000, // ~1MB
            lastSync: lastSync
        )

        // Then
        XCTAssertEqual(storageInfo.workoutCount, 25)
        XCTAssertEqual(storageInfo.storageSize, 1024000)
        XCTAssertEqual(storageInfo.lastSync, lastSync)

        // Test formatted values
        XCTAssertTrue(storageInfo.formattedStorageSize.contains("MB") || storageInfo.formattedStorageSize.contains("KB"))
        XCTAssertFalse(storageInfo.formattedLastSync.isEmpty)
    }
}