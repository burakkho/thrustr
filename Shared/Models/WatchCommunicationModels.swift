import Foundation

// MARK: - Watch Communication Protocol Models

// MARK: - Watch Message
struct WatchMessage: Codable, Sendable {
    let id: UUID
    let command: WatchCommand
    let timestamp: Date
    let data: [String: AnyCodable]?

    init(command: WatchCommand, data: [String: AnyCodable]? = nil) {
        self.id = UUID()
        self.command = command
        self.timestamp = Date()
        self.data = data
    }
}

// MARK: - Watch Commands
enum WatchCommand: String, Codable, CaseIterable, Sendable {
    // Workout Commands
    case startWorkout = "startWorkout"
    case stopWorkout = "stopWorkout"
    case pauseWorkout = "pauseWorkout"
    case resumeWorkout = "resumeWorkout"

    // Data Sync Commands
    case requestHealthData = "requestHealthData"
    case syncWorkoutSession = "syncWorkoutSession"
    case syncUserSettings = "syncUserSettings"

    // Health Updates
    case healthUpdate = "healthUpdate"
    case workoutStatusUpdate = "workoutStatusUpdate"

    // System Commands
    case ping = "ping"
    case pong = "pong"
    case error = "error"
}

// MARK: - Watch Health Data
struct WatchHealthData: Codable, Sendable {
    let heartRate: Int?
    let steps: Int?
    let calories: Int?
    let timestamp: Date

    init(heartRate: Int? = nil, steps: Int? = nil, calories: Int? = nil) {
        self.heartRate = heartRate
        self.steps = steps
        self.calories = calories
        self.timestamp = Date()
    }
}

// MARK: - Watch User Settings
struct WatchUserSettings: Codable, Sendable {
    let preferredWorkoutTypes: [WatchWorkoutType]
    let enableHapticFeedback: Bool
    let autoStartWorkout: Bool
    let displayMetrics: WatchDisplayMetrics

    init(
        preferredWorkoutTypes: [WatchWorkoutType] = [.strength, .cardio],
        enableHapticFeedback: Bool = true,
        autoStartWorkout: Bool = false,
        displayMetrics: WatchDisplayMetrics = WatchDisplayMetrics()
    ) {
        self.preferredWorkoutTypes = preferredWorkoutTypes
        self.enableHapticFeedback = enableHapticFeedback
        self.autoStartWorkout = autoStartWorkout
        self.displayMetrics = displayMetrics
    }
}

// MARK: - Watch Display Metrics
struct WatchDisplayMetrics: Codable, Sendable {
    let showHeartRate: Bool
    let showCalories: Bool
    let showTimer: Bool
    let showSteps: Bool

    init(
        showHeartRate: Bool = true,
        showCalories: Bool = true,
        showTimer: Bool = true,
        showSteps: Bool = false
    ) {
        self.showHeartRate = showHeartRate
        self.showCalories = showCalories
        self.showTimer = showTimer
        self.showSteps = showSteps
    }
}

// MARK: - Communication Result
enum WatchCommunicationResult: Codable, Sendable {
    case success
    case error(String)
    case notReachable
    case timeout

    var isSuccess: Bool {
        if case .success = self {
            return true
        }
        return false
    }

    var errorMessage: String? {
        if case .error(let message) = self {
            return message
        }
        return nil
    }
}

// MARK: - AnyCodable Helper
struct AnyCodable: Codable, Sendable {
    let value: Any

    init<T>(_ value: T?) {
        self.value = value ?? ()
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue.map { $0.value }
        } else if let dictValue = try? container.decode([String: AnyCodable].self) {
            value = dictValue.mapValues { $0.value }
        } else {
            value = ()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let boolValue as Bool:
            try container.encode(boolValue)
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case let arrayValue as [Any]:
            let codableArray = arrayValue.map { AnyCodable($0) }
            try container.encode(codableArray)
        case let dictValue as [String: Any]:
            let codableDict = dictValue.mapValues { AnyCodable($0) }
            try container.encode(codableDict)
        default:
            try container.encodeNil()
        }
    }
}