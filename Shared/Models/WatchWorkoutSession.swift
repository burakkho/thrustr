import Foundation

// MARK: - Watch Workout Session (Shared Domain Model)
struct WatchWorkoutSession: Codable, Sendable, Identifiable {
    let id: UUID
    let type: WatchWorkoutType
    let startTime: Date
    var endTime: Date?
    var duration: TimeInterval
    var isActive: Bool

    // Health Metrics
    var heartRateReadings: [HeartRateReading]
    var averageHeartRate: Int
    var maxHeartRate: Int
    var calories: Int
    var steps: Int?

    // Training Specific
    var exerciseCount: Int?
    var notes: String?

    init(
        id: UUID = UUID(),
        type: WatchWorkoutType,
        startTime: Date = Date(),
        isActive: Bool = true
    ) {
        self.id = id
        self.type = type
        self.startTime = startTime
        self.isActive = isActive
        self.duration = 0
        self.heartRateReadings = []
        self.averageHeartRate = 0
        self.maxHeartRate = 0
        self.calories = 0
        self.exerciseCount = nil
        self.notes = nil
    }

    // MARK: - Computed Properties
    var isCompleted: Bool {
        !isActive && endTime != nil
    }

    var formattedDuration: String {
        TimeFormatter.format(duration)
    }

    mutating func complete() {
        isActive = false
        endTime = Date()
        if let startTime = endTime {
            duration = startTime.timeIntervalSince(self.startTime)
        }
    }

    mutating func addHeartRateReading(_ reading: HeartRateReading) {
        heartRateReadings.append(reading)

        // Update averages
        let readings = heartRateReadings.map { $0.value }
        averageHeartRate = Int(readings.reduce(0, +) / readings.count)
        maxHeartRate = readings.max() ?? 0
    }
}

// MARK: - Heart Rate Reading
struct HeartRateReading: Codable, Sendable {
    let value: Int
    let timestamp: Date

    init(value: Int, timestamp: Date = Date()) {
        self.value = value
        self.timestamp = timestamp
    }
}

// MARK: - Watch Workout Type
enum WatchWorkoutType: String, CaseIterable, Codable, Sendable {
    case strength = "strength"
    case cardio = "cardio"
    case wod = "wod"
    case other = "other"

    var displayName: String {
        switch self {
        case .strength:
            return "Strength Training"
        case .cardio:
            return "Cardio"
        case .wod:
            return "WOD"
        case .other:
            return "Other"
        }
    }

    var systemIcon: String {
        switch self {
        case .strength:
            return "dumbbell.fill"
        case .cardio:
            return "heart.fill"
        case .wod:
            return "timer"
        case .other:
            return "figure.run"
        }
    }

    var accentColor: String {
        switch self {
        case .strength:
            return "blue"
        case .cardio:
            return "red"
        case .wod:
            return "orange"
        case .other:
            return "green"
        }
    }
}

// MARK: - Time Formatter Utility
struct TimeFormatter {
    static func format(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    static func formatDetailed(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) % 3600 / 60
        let seconds = Int(timeInterval) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}