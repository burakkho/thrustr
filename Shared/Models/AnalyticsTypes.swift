import SwiftUI
import Foundation

// MARK: - Time Range Types

/**
 * Unified time range enumeration for all analytics views.
 * Single source of truth following Apple's Clean Architecture guidelines.
 */
public enum TimeRange: String, CaseIterable, Sendable {
    case week1 = "1W"
    case month1 = "1M"
    case month3 = "3M"
    case month6 = "6M"
    case year1 = "1Y"
    case allTime = "All"

    // Legacy aliases for compatibility
    public static let week = TimeRange.week1
    public static let month = TimeRange.month1
    public static let threeMonths = TimeRange.month3
    public static let sixMonths = TimeRange.month6
    public static let oneYear = TimeRange.year1

    public var displayName: String {
        switch self {
        case .week1:
            return "analytics.last_week".localized
        case .month1:
            return "analytics.last_month".localized
        case .month3:
            return "analytics.last_3_months".localized
        case .month6:
            return "analytics.last_6_months".localized
        case .year1:
            return "analytics.last_year".localized
        case .allTime:
            return "analytics.all_time".localized
        }
    }

    public var months: Int {
        switch self {
        case .week1:
            return 0
        case .month1:
            return 1
        case .month3:
            return 3
        case .month6:
            return 6
        case .year1:
            return 12
        case .allTime:
            return 24
        }
    }

    public var days: Int {
        switch self {
        case .week1:
            return 7
        case .month1:
            return 30
        case .month3:
            return 90
        case .month6:
            return 180
        case .year1:
            return 365
        case .allTime:
            return 730
        }
    }

    public var cutoffDate: Date {
        let calendar = Calendar.current
        switch self {
        case .week1:
            return calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        case .month1:
            return calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        case .month3:
            return calendar.date(byAdding: .month, value: -3, to: Date()) ?? Date()
        case .month6:
            return calendar.date(byAdding: .month, value: -6, to: Date()) ?? Date()
        case .year1:
            return calendar.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        case .allTime:
            return calendar.date(byAdding: .year, value: -10, to: Date()) ?? Date()
        }
    }

    public var weekCount: Int {
        switch self {
        case .week1:
            return 1
        case .month1:
            return 4
        case .month3:
            return 12
        case .month6:
            return 24
        case .year1:
            return 52
        case .allTime:
            return 104
        }
    }
}

// MARK: - Chart Type Definitions

/**
 * Chart type enumeration for analytics displays.
 */
public enum ChartType: String, CaseIterable, Sendable {
    case weight = "weight"
    case workoutVolume = "volume"
    case workoutFrequency = "frequency"
    case bodyMeasurements = "measurements"
    case strength = "strength"
    case cardio = "cardio"

    public var displayName: String {
        switch self {
        case .weight:
            return "analytics.weight_progress".localized
        case .workoutVolume:
            return "analytics.workout_volume".localized
        case .workoutFrequency:
            return "analytics.workout_frequency".localized
        case .bodyMeasurements:
            return "analytics.body_measurements".localized
        case .strength:
            return "analytics.strength_progress".localized
        case .cardio:
            return "analytics.cardio_progress".localized
        }
    }

    public var systemImage: String {
        switch self {
        case .weight:
            return "scalemass"
        case .workoutVolume:
            return "chart.bar.xaxis"
        case .workoutFrequency:
            return "calendar"
        case .bodyMeasurements:
            return "ruler"
        case .strength:
            return "dumbbell"
        case .cardio:
            return "heart"
        }
    }

    public var icon: String {
        return systemImage
    }

    public var color: Color {
        switch self {
        case .weight:
            return .blue
        case .workoutVolume:
            return .purple
        case .workoutFrequency:
            return .orange
        case .bodyMeasurements:
            return .green
        case .strength:
            return .red
        case .cardio:
            return .pink
        }
    }
}

// MARK: - Chart Data Models

/**
 * Weight chart data point.
 */
public struct WeightChartData: Identifiable, Sendable {
    public let id = UUID()
    public let date: Date
    public let weight: Double
    public let trend: ChartTrendDirection

    public init(date: Date, weight: Double, trend: ChartTrendDirection = .stable) {
        self.date = date
        self.weight = weight
        self.trend = trend
    }
}

/**
 * Weekly volume data for workout analytics.
 */
public struct WeeklyVolumeData: Identifiable, Sendable {
    public let id = UUID()
    public let week: Date
    public let volume: Double
    public let workoutCount: Int
    public let averageVolume: Double

    public init(week: Date, volume: Double, workoutCount: Int, averageVolume: Double) {
        self.week = week
        self.volume = volume
        self.workoutCount = workoutCount
        self.averageVolume = averageVolume
    }
}

/**
 * Workout frequency data.
 */
public struct FrequencyData: Identifiable, Sendable {
    public let id = UUID()
    public let period: Date
    public let frequency: Int
    public let target: Int
    public let completionRate: Double

    public init(period: Date, frequency: Int, target: Int, completionRate: Double) {
        self.period = period
        self.frequency = frequency
        self.target = target
        self.completionRate = completionRate
    }
}


/**
 * Strength progress data point.
 */
public struct StrengthProgressData: Identifiable, Sendable {
    public let id = UUID()
    public let date: Date
    public let exercise: String
    public let weight: Double
    public let reps: Int
    public let oneRM: Double
    public let isPersonalRecord: Bool

    public init(date: Date, exercise: String, weight: Double, reps: Int, oneRM: Double, isPersonalRecord: Bool = false) {
        self.date = date
        self.exercise = exercise
        self.weight = weight
        self.reps = reps
        self.oneRM = oneRM
        self.isPersonalRecord = isPersonalRecord
    }
}

/**
 * Cardio progress data point.
 */
public struct CardioProgressData: Identifiable, Sendable {
    public let id = UUID()
    public let date: Date
    public let duration: TimeInterval
    public let distance: Double
    public let calories: Int
    public let heartRate: Double?
    public let type: String

    public init(date: Date, duration: TimeInterval, distance: Double, calories: Int, heartRate: Double? = nil, type: String) {
        self.date = date
        self.duration = duration
        self.distance = distance
        self.calories = calories
        self.heartRate = heartRate
        self.type = type
    }
}

/**
 * Body measurement chart data (using MeasurementType from BodyTrackingModels).
 */
public struct MeasurementChartData: Identifiable, Sendable {
    public let id = UUID()
    public let date: Date
    public let measurement: Double
    public let measurementType: String // Using string instead of enum to avoid import
    public let change: Double

    public init(date: Date, measurement: Double, measurementType: String, change: Double = 0) {
        self.date = date
        self.measurement = measurement
        self.measurementType = measurementType
        self.change = change
    }
}

// MARK: - Supporting Enums


/**
 * Trend direction for analytics charts.
 */
public enum ChartTrendDirection: String, Sendable {
    case upward = "upward"
    case downward = "downward"
    case stable = "stable"

    public var color: Color {
        switch self {
        case .upward:
            return .green
        case .downward:
            return .red
        case .stable:
            return .orange
        }
    }

    public var systemImage: String {
        switch self {
        case .upward:
            return "arrow.up.right"
        case .downward:
            return "arrow.down.right"
        case .stable:
            return "arrow.right"
        }
    }
}

// MARK: - Progress Data Models

/**
 * Progress data point for strength analytics.
 */
public struct ProgressDataPoint: Identifiable, Sendable {
    public let id = UUID()
    public let date: Date
    public let weight: Double
    public let exercise: String

    public init(date: Date, weight: Double, exercise: String) {
        self.date = date
        self.weight = weight
        self.exercise = exercise
    }
}

/**
 * Exercise comparison data.
 */
public struct ExerciseComparison: Sendable {
    public let exercise: String
    public let currentMax: Double
    public let improvement: Double

    public init(exercise: String, currentMax: Double, improvement: Double) {
        self.exercise = exercise
        self.currentMax = currentMax
        self.improvement = improvement
    }
}

