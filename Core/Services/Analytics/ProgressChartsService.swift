import SwiftUI
import SwiftData
import Foundation

/**
 * Service for progress charts business logic and data processing.
 *
 * Handles all data filtering, chart data preparation, statistics calculation,
 * and insights generation for progress tracking functionality.
 *
 * Follows clean architecture principles with static methods and Result types.
 */
struct ProgressChartsService: Sendable {

    // MARK: - Date Calculations

    /**
     * Calculates cutoff date for given time range.
     */
    static func calculateCutoffDate(for timeRange: TimeRange) -> Date {
        return timeRange.cutoffDate
    }

    // MARK: - Data Filtering

    /**
     * Filters weight entries based on cutoff date.
     */
    static func filterWeightEntries(
        _ entries: [WeightEntry],
        cutoffDate: Date
    ) -> [WeightEntry] {
        return entries.filter { $0.date >= cutoffDate }
            .sorted { $0.date > $1.date }
    }

    /**
     * Filters lift sessions based on cutoff date and completion status.
     */
    static func filterLiftSessions(
        _ sessions: [LiftSession],
        cutoffDate: Date
    ) -> [LiftSession] {
        return sessions.filter { $0.isCompleted && $0.startDate >= cutoffDate }
            .sorted { $0.startDate > $1.startDate }
    }

    /**
     * Filters body measurements based on cutoff date.
     */
    static func filterBodyMeasurements(
        _ measurements: [BodyMeasurement],
        cutoffDate: Date
    ) -> [BodyMeasurement] {
        return measurements.filter { $0.date >= cutoffDate }
            .sorted { $0.date > $1.date }
    }

    /**
     * Filters cardio sessions based on cutoff date and completion status.
     */
    static func filterCardioSessions(
        _ sessions: [CardioSession],
        cutoffDate: Date
    ) -> [CardioSession] {
        return sessions.filter { $0.isCompleted && $0.startDate >= cutoffDate }
            .sorted { $0.startDate > $1.startDate }
    }

    // MARK: - Chart Data Preparation

    /**
     * Prepares weight chart data from weight entries.
     */
    static func prepareWeightChartData(from entries: [WeightEntry]) -> [WeightChartData] {
        return entries.map { entry in
            WeightChartData(date: entry.date, weight: entry.weight, trend: .stable)
        }.sorted { $0.date < $1.date }
    }

    /**
     * Prepares weekly volume chart data from lift sessions.
     */
    static func prepareVolumeChartData(from sessions: [LiftSession]) -> [WeeklyVolumeData] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: sessions) { session in
            calendar.dateInterval(of: .weekOfYear, for: session.startDate)?.start ?? session.startDate
        }

        return grouped.map { (week, sessionsInWeek) in
            let totalVolume = sessionsInWeek.reduce(0.0) { total, session in
                total + session.totalVolume
            }
            return WeeklyVolumeData(week: week, volume: totalVolume, workoutCount: sessionsInWeek.count, averageVolume: sessionsInWeek.count > 0 ? totalVolume / Double(sessionsInWeek.count) : 0.0)
        }.sorted { $0.week < $1.week }
    }

    /**
     * Prepares workout frequency chart data from lift sessions.
     */
    static func prepareFrequencyChartData(from sessions: [LiftSession]) -> [FrequencyData] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: sessions) { session in
            calendar.dateInterval(of: .weekOfYear, for: session.startDate)?.start ?? session.startDate
        }

        return grouped.map { (week, sessionsInWeek) in
            FrequencyData(period: week, frequency: sessionsInWeek.count, target: 3, completionRate: Double(sessionsInWeek.count) / 3.0)
        }.sorted { $0.period < $1.period }
    }

    /**
     * Prepares measurement chart data from body measurements.
     */
    static func prepareMeasurementChartData(from measurements: [BodyMeasurement]) -> [MeasurementChartData] {
        return measurements.map { measurement in
            MeasurementChartData(
                date: measurement.date,
                measurement: measurement.value,
                measurementType: measurement.type,
                change: 0.0
            )
        }.sorted { $0.date < $1.date }
    }

    /**
     * Prepares strength chart data from lift sessions.
     */
    static func prepareStrengthChartData(from sessions: [LiftSession]) -> [StrengthProgressData] {
        return sessions.compactMap { session in
            // Get the strongest exercise result from the session
            guard let results = session.exerciseResults,
                  let strongestResult = results.max(by: { $0.estimatedOneRM < $1.estimatedOneRM }) else {
                return nil
            }

            let bestSet = strongestResult.sets.filter { $0.isCompleted && $0.weight != nil }
                .max { ($0.weight ?? 0) < ($1.weight ?? 0) }

            return StrengthProgressData(
                date: session.startDate,
                exercise: strongestResult.exercise?.exerciseName ?? "Unknown",
                weight: bestSet?.weight ?? 0,
                reps: bestSet?.reps ?? 0,
                oneRM: strongestResult.estimatedOneRM,
                isPersonalRecord: strongestResult.isPersonalRecord
            )
        }.sorted { $0.date < $1.date }
    }

    /**
     * Prepares cardio chart data from cardio sessions.
     */
    static func prepareCardioChartData(from sessions: [CardioSession]) -> [CardioProgressData] {
        return sessions.map { session in
            CardioProgressData(
                date: session.startDate,
                duration: TimeInterval(session.totalDuration),
                distance: session.totalDistance,
                calories: session.totalCaloriesBurned ?? 0,
                heartRate: session.averageHeartRate.map { Double($0) },
                type: session.workoutName
            )
        }.sorted { $0.date < $1.date }
    }

    // MARK: - Statistics Calculations

    /**
     * Calculates weight statistics from weight entries.
     */
    static func calculateWeightStatistics(from entries: [WeightEntry]) -> WeightStatistics {
        guard !entries.isEmpty else {
            return WeightStatistics(
                weightChange: 0,
                averageWeight: 0,
                entryCount: 0,
                latestWeight: 0
            )
        }

        let sortedEntries = entries.sorted { $0.date > $1.date }
        let latestWeight = sortedEntries.first?.weight ?? 0
        let earliestWeight = sortedEntries.last?.weight ?? 0
        let weightChange = latestWeight - earliestWeight

        let averageWeight = entries.map { $0.weight }.reduce(0, +) / Double(entries.count)

        return WeightStatistics(
            weightChange: weightChange,
            averageWeight: averageWeight,
            entryCount: entries.count,
            latestWeight: latestWeight
        )
    }

    /**
     * Calculates workout statistics from lift sessions.
     */
    static func calculateWorkoutStatistics(
        from sessions: [LiftSession],
        timeRange: TimeRange
    ) -> WorkoutStatistics {
        let totalWorkouts = sessions.count
        let totalVolume = sessions.reduce(0) { $0 + $1.totalVolume }

        let weeks = timeRange.weekCount
        let averageWorkoutsPerWeek = weeks > 0 ? Double(totalWorkouts) / Double(weeks) : 0
        let averageVolume = totalWorkouts > 0 ? totalVolume / Double(totalWorkouts) : 0

        return WorkoutStatistics(
            totalWorkouts: totalWorkouts,
            averageWorkoutsPerWeek: averageWorkoutsPerWeek,
            totalVolume: totalVolume,
            averageVolume: averageVolume
        )
    }

    /**
     * Calculates measurement statistics from body measurements.
     */
    static func calculateMeasurementStatistics(from measurements: [BodyMeasurement]) -> MeasurementStatistics {
        // For now, return placeholder values
        // This can be enhanced based on specific measurement types
        return MeasurementStatistics(
            change: ProfileKeys.Analytics.calculating.localized,
            average: ProfileKeys.Analytics.calculating.localized
        )
    }

    /**
     * Calculates strength statistics from lift sessions.
     */
    static func calculateStrengthStatistics(
        from sessions: [LiftSession],
        timeRange: TimeRange
    ) -> StrengthStatistics {
        let totalWorkouts = sessions.count
        let allResults = sessions.compactMap { $0.exerciseResults }.flatMap { $0 }

        let totalVolume = allResults.reduce(0.0) { total, result in
            total + result.totalVolume
        }

        let averageOneRM = allResults.isEmpty ? 0.0 :
            allResults.map { $0.estimatedOneRM }.reduce(0, +) / Double(allResults.count)

        let topExercise = Dictionary(grouping: allResults, by: { $0.exercise?.exerciseName ?? "Unknown" })
            .max { $0.value.count < $1.value.count }?.key ?? "No exercises"

        return StrengthStatistics(
            totalWorkouts: totalWorkouts,
            averageOneRM: averageOneRM,
            totalVolume: totalVolume,
            topExercise: topExercise
        )
    }

    /**
     * Calculates cardio statistics from cardio sessions.
     */
    static func calculateCardioStatistics(
        from sessions: [CardioSession],
        timeRange: TimeRange
    ) -> CardioStatistics {
        let totalSessions = sessions.count
        let totalDistance = sessions.reduce(0.0) { $0 + $1.totalDistance }
        let totalDuration = sessions.reduce(0.0) { $0 + Double($1.totalDuration) }

        let heartRates = sessions.compactMap { $0.averageHeartRate.map { Double($0) } }
        let averageHeartRate = heartRates.isEmpty ? nil :
            heartRates.reduce(0, +) / Double(heartRates.count)

        return CardioStatistics(
            totalSessions: totalSessions,
            totalDistance: totalDistance,
            totalDuration: totalDuration,
            averageHeartRate: averageHeartRate
        )
    }

    // MARK: - Insights Generation

    /**
     * Generates weight insights based on weight trend analysis.
     */
    static func generateWeightInsights(from entries: [WeightEntry]) -> WeightInsights {
        guard entries.count >= 2 else {
            return WeightInsights(
                trend: ProfileKeys.Analytics.insufficientData.localized,
                trendDirection: .stable
            )
        }

        let sortedEntries = entries.sorted { $0.date > $1.date }
        let latest = sortedEntries.first?.weight ?? 0
        let previous = sortedEntries.dropFirst().first?.weight ?? 0

        let trend: String
        let direction: ProgressTrendDirection

        if latest > previous {
            trend = ProfileKeys.Analytics.trendingUpward.localized
            direction = .upward
        } else if latest < previous {
            trend = ProfileKeys.Analytics.trendingDownward.localized
            direction = .downward
        } else {
            trend = ProfileKeys.Analytics.stableTrend.localized
            direction = .stable
        }

        return WeightInsights(trend: trend, trendDirection: direction)
    }

    /**
     * Generates workout insights based on consistency analysis.
     */
    static func generateWorkoutInsights(
        from sessions: [LiftSession],
        timeRange: TimeRange
    ) -> WorkoutInsights {
        let weeks = timeRange.weekCount
        let averagePerWeek = weeks > 0 ? Double(sessions.count) / Double(weeks) : 0

        let consistency: String
        let level: ConsistencyLevel

        if averagePerWeek >= 4 {
            consistency = ProfileKeys.Analytics.excellentConsistency.localized
            level = .excellent
        } else if averagePerWeek >= 3 {
            consistency = ProfileKeys.Analytics.goodConsistency.localized
            level = .good
        } else if averagePerWeek >= 2 {
            consistency = ProfileKeys.Analytics.averageConsistency.localized
            level = .average
        } else {
            consistency = ProfileKeys.Analytics.lowConsistency.localized
            level = .low
        }

        return WorkoutInsights(consistency: consistency, consistencyLevel: level)
    }

    // MARK: - Chart Data Utilities

    /**
     * Finds nearest data point to a given date for chart interaction.
     */
    static func findNearestWeightDataPoint(
        in chartData: [WeightChartData],
        to date: Date
    ) -> Date? {
        return chartData.min(by: {
            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
        })?.date
    }

    /**
     * Filters measurements by type for body measurement charts.
     */
    static func filterMeasurementsByType(
        _ measurements: [BodyMeasurement],
        type: MeasurementType
    ) -> [BodyMeasurement] {
        return measurements.filter { $0.typeEnum == type }
            .sorted { $0.date < $1.date }
    }

    // MARK: - Loading State Utilities

    /**
     * Provides standard loading delay for smooth UX transitions.
     */
    static func getStandardLoadingDelay() -> TimeInterval {
        return 0.3 // 300ms
    }

    /**
     * Provides initial loading delay for app startup.
     */
    static func getInitialLoadingDelay() -> TimeInterval {
        return 0.5 // 500ms
    }
}

// MARK: - Chart Data Models

// MARK: - Statistics Data Models

/**
 * Strength training statistics.
 */
struct StrengthStatistics: Sendable {
    let totalWorkouts: Int
    let averageOneRM: Double
    let totalVolume: Double
    let topExercise: String
}

/**
 * Cardio training statistics.
 */
struct CardioStatistics: Sendable {
    let totalSessions: Int
    let totalDistance: Double
    let totalDuration: TimeInterval
    let averageHeartRate: Double?
}

// MARK: - Enums


