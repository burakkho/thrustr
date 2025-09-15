import Foundation
import SwiftData

/**
 * Body measurement tracking service with comprehensive measurement management.
 *
 * This utility struct provides body measurement calculation logic extracted from views
 * to maintain clean separation of concerns. Handles measurement persistence, data
 * filtering, progress calculations, and activity logging for fitness tracking.
 *
 * Supported operations:
 * - Measurement data persistence and validation
 * - Progress calculation and trend analysis
 * - Data filtering for time-based analysis
 * - Activity logging integration for dashboard updates
 */
struct BodyMeasurementService: Sendable {

    // MARK: - Measurement Operations

    /**
     * Saves a new body measurement with comprehensive validation and logging.
     *
     * Validates measurement data, persists to database, and logs activity for
     * dashboard updates. Includes error handling and data consistency checks.
     *
     * - Parameters:
     *   - measurementType: Type of measurement being recorded
     *   - value: Measurement value in centimeters
     *   - date: Date of measurement
     *   - notes: Optional notes about measurement conditions
     *   - user: Current user for activity logging
     *   - modelContext: SwiftData context for persistence
     * - Returns: Result indicating success or failure with specific error
     */
    static func saveMeasurement(
        type: MeasurementType,
        value: Double,
        date: Date,
        notes: String?,
        user: User?,
        modelContext: ModelContext
    ) -> Result<Void, MeasurementError> {

        // Input validation
        guard value > 0 else {
            return .failure(.invalidValue("Measurement value must be greater than zero"))
        }

        guard value < 500 else { // Reasonable upper limit in cm
            return .failure(.invalidValue("Measurement value seems too large"))
        }

        // Create measurement instance
        let measurement = BodyMeasurement(
            type: type.rawValue,
            value: value,
            date: date,
            notes: notes?.isEmpty == false ? notes : nil
        )

        // Insert into context
        modelContext.insert(measurement)

        do {
            // Save to database
            try modelContext.save()

            // Note: Activity logging handled at UI layer if needed

            return .success(())

        } catch {
            return .failure(.saveFailed(error.localizedDescription))
        }
    }

    /**
     * Filters measurements for recent analysis periods.
     *
     * - Parameters:
     *   - measurements: All available measurements
     *   - period: Time period for filtering (default: 6 months)
     * - Returns: Measurements within specified time period
     */
    static func filterRecentMeasurements(
        _ measurements: [BodyMeasurement],
        period: Calendar.Component = .month,
        value: Int = -6
    ) -> [BodyMeasurement] {

        let cutoffDate = Calendar.current.date(byAdding: period, value: value, to: Date()) ?? Date()
        return measurements.filter { $0.date >= cutoffDate }
    }

    /**
     * Filters weight entries for recent analysis periods.
     *
     * - Parameters:
     *   - weightEntries: All available weight entries
     *   - period: Time period for filtering (default: 6 months)
     * - Returns: Weight entries within specified time period
     */
    static func filterRecentMeasurements(
        _ weightEntries: [WeightEntry],
        period: Calendar.Component = .month,
        value: Int = -6
    ) -> [WeightEntry] {

        let cutoffDate = Calendar.current.date(byAdding: period, value: value, to: Date()) ?? Date()
        return weightEntries.filter { $0.date >= cutoffDate }
    }

    /**
     * Calculates measurement progress statistics for dashboard display.
     *
     * - Parameters:
     *   - measurements: Recent measurements for analysis
     *   - weightEntries: Recent weight entries for comprehensive stats
     * - Returns: Progress statistics structure
     */
    static func calculateProgressStats(
        measurements: [BodyMeasurement],
        weightEntries: [WeightEntry]
    ) -> MeasurementProgressStats {

        let totalMeasurements = measurements.count
        let totalWeightEntries = weightEntries.count

        // Latest measurement date
        let latestMeasurement = measurements.max(by: { $0.date < $1.date })
        let latestMeasurementDate = latestMeasurement?.date

        // Active measurement types
        let activeMeasurementTypes = Set(measurements.map { $0.type }).count

        // Calculate trends if enough data points
        let hasTrends = measurements.count >= 3

        return MeasurementProgressStats(
            totalMeasurements: totalMeasurements,
            totalWeightEntries: totalWeightEntries,
            latestMeasurementDate: latestMeasurementDate,
            activeMeasurementTypes: activeMeasurementTypes,
            hasTrendData: hasTrends
        )
    }

    /**
     * Gets the latest measurement for a specific type.
     *
     * - Parameters:
     *   - measurements: All measurements to search
     *   - type: Specific measurement type to find
     * - Returns: Most recent measurement of specified type
     */
    static func getLatestMeasurement(
        from measurements: [BodyMeasurement],
        for type: MeasurementType
    ) -> BodyMeasurement? {

        return measurements
            .filter { $0.typeEnum == type }
            .sorted { $0.date > $1.date }
            .first
    }

    /**
     * Calculates measurement change over time for progress tracking.
     *
     * - Parameters:
     *   - measurements: Measurements of specific type, sorted by date
     * - Returns: Change data including trend direction and magnitude
     */
    static func calculateMeasurementChange(
        _ measurements: [BodyMeasurement]
    ) -> MeasurementChange? {

        guard measurements.count >= 2 else { return nil }

        let sortedMeasurements = measurements.sorted { $0.date < $1.date }
        guard let first = sortedMeasurements.first,
              let last = sortedMeasurements.last else { return nil }

        let change = last.value - first.value
        let changePercentage = (change / first.value) * 100

        return MeasurementChange(
            startValue: first.value,
            endValue: last.value,
            change: change,
            changePercentage: changePercentage,
            startDate: first.date,
            endDate: last.date
        )
    }

    // MARK: - Private Helper Methods

    // Note: Activity logging is handled at the UI layer to maintain
    // clean separation of concerns and avoid MainActor dependencies
}

// MARK: - Supporting Types

/**
 * Measurement operation error types.
 */
enum MeasurementError: LocalizedError, Sendable {
    case invalidValue(String)
    case saveFailed(String)
    case contextUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidValue(let message):
            return "Invalid measurement value: \(message)"
        case .saveFailed(let message):
            return "Failed to save measurement: \(message)"
        case .contextUnavailable:
            return "Database context is not available"
        }
    }
}

/**
 * Progress statistics for measurement tracking.
 */
struct MeasurementProgressStats: Sendable {
    let totalMeasurements: Int
    let totalWeightEntries: Int
    let latestMeasurementDate: Date?
    let activeMeasurementTypes: Int
    let hasTrendData: Bool

    var formattedLatestDate: String {
        guard let date = latestMeasurementDate else {
            return "analytics.no_data".localized
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

/**
 * Measurement change analysis for progress tracking.
 */
struct MeasurementChange: Sendable {
    let startValue: Double
    let endValue: Double
    let change: Double
    let changePercentage: Double
    let startDate: Date
    let endDate: Date

    var isImprovement: Bool {
        // For body measurements, decrease is generally considered improvement
        // This could be made more sophisticated based on measurement type and user goals
        return change < 0
    }

    var trend: MeasurementTrend {
        if abs(changePercentage) < 1.0 { // Less than 1% change
            return .stable
        } else if change > 0 {
            return .increasing
        } else {
            return .decreasing
        }
    }
}

/**
 * Measurement trend classification.
 */
enum MeasurementTrend: Sendable {
    case increasing
    case decreasing
    case stable

    var icon: String {
        switch self {
        case .increasing:
            return "arrow.up.circle.fill"
        case .decreasing:
            return "arrow.down.circle.fill"
        case .stable:
            return "minus.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .increasing:
            return "red" // Usually not desired for body measurements
        case .decreasing:
            return "green" // Usually desired for body measurements
        case .stable:
            return "blue"
        }
    }
}