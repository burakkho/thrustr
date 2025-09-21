import Foundation
import SwiftUI

/**
 * Workout display service for Cardio Live Tracking metrics presentation.
 *
 * Handles the business logic for determining which metrics to display based on
 * workout type (indoor vs outdoor) and provides standardized metric configurations.
 * Separates display logic from UI rendering for better maintainability.
 */
struct CardioWorkoutDisplayService: Sendable {

    // MARK: - Metric Icons

    private static let icons: [String: String] = [
        "speed": "speedometer",
        "distance": "location.fill",
        "calories": "flame.fill",
        "pace": "gauge.medium",
        "heartRate": "heart.fill",
        "effort": "bolt.fill",
        "zone": "target"
    ]

    // MARK: - Display Logic

    /**
     * Determines if outdoor metrics should be shown.
     *
     * - Parameter isOutdoor: Whether the workout is outdoor
     * - Returns: Boolean indicating outdoor metrics usage
     */
    static func shouldShowOutdoorMetrics(isOutdoor: Bool) -> Bool {
        return isOutdoor
    }

    /**
     * Gets metric icon for a specific metric type.
     *
     * - Parameter metricKey: Key for the metric type
     * - Returns: SF Symbol name for the metric
     */
    static func getIcon(for metricKey: String) -> String {
        return icons[metricKey] ?? "questionmark.circle"
    }

    /**
     * Gets standardized color for metric types.
     *
     * - Parameter metricKey: Key for the metric type
     * - Returns: Color for the metric display
     */
    static func getColor(for metricKey: String) -> Color {
        switch metricKey {
        case "speed", "pace", "effort":
            return .blue
        case "distance":
            return .green
        case "calories":
            return .orange
        case "heartRate":
            return .red
        case "zone":
            return .purple
        default:
            return .gray
        }
    }

    // MARK: - Metric Configuration

    /**
     * Gets outdoor workout metric configuration.
     *
     * - Returns: Array of metric keys for outdoor display
     */
    static func getOutdoorMetricKeys() -> [String] {
        return ["speed", "distance", "calories", "pace"]
    }

    /**
     * Gets indoor workout metric configuration.
     *
     * - Returns: Array of metric keys for indoor display
     */
    static func getIndoorMetricKeys() -> [String] {
        return ["calories", "heartRate", "effort", "zone"]
    }

    /**
     * Gets essential metrics for screen lock display.
     *
     * - Parameter isOutdoor: Whether workout is outdoor
     * - Returns: Array of essential metric keys
     */
    static func getScreenLockMetricKeys(isOutdoor: Bool) -> [String] {
        if isOutdoor {
            return ["distance", "calories"]
        } else {
            return ["calories", "heartRate"]
        }
    }

    // MARK: - Formatting Utilities

    /**
     * Validates if metric should be displayed based on data availability.
     *
     * - Parameters:
     *   - metricKey: Metric to validate
     *   - value: Current metric value
     * - Returns: Boolean indicating if metric should be shown
     */
    static func shouldDisplayMetric(key metricKey: String, value: String) -> Bool {
        // Don't show metrics with empty or invalid values
        return !value.isEmpty && value != "--" && value != "0"
    }

    /**
     * Gets metric update identifier for SwiftUI tracking.
     *
     * - Parameters:
     *   - metricKey: Metric identifier
     *   - value: Current value for tracking changes
     * - Returns: Unique identifier for SwiftUI .id() modifier
     */
    static func getMetricId(key metricKey: String, value: String) -> String {
        return "\(metricKey)-\(value.hashValue)"
    }

    // MARK: - Performance Optimization

    /**
     * Determines if metric requires frequent updates.
     *
     * - Parameter metricKey: Metric to evaluate
     * - Returns: Boolean indicating high-frequency update need
     */
    static func isHighFrequencyMetric(_ metricKey: String) -> Bool {
        // These metrics change rapidly during workout
        return ["speed", "pace", "heartRate"].contains(metricKey)
    }

    /**
     * Gets update interval for metric type.
     *
     * - Parameter metricKey: Metric to evaluate
     * - Returns: Recommended update interval in seconds
     */
    static func getUpdateInterval(for metricKey: String) -> TimeInterval {
        if isHighFrequencyMetric(metricKey) {
            return 0.5 // 500ms for high-frequency metrics
        } else {
            return 1.0 // 1s for standard metrics
        }
    }
}

// MARK: - Supporting Types

/**
 * Metric display configuration for consistent presentation.
 */
struct MetricDisplayConfig {
    let key: String
    let icon: String
    let color: Color
    let isHighFrequency: Bool
    let updateInterval: TimeInterval

    init(key: String) {
        self.key = key
        self.icon = CardioWorkoutDisplayService.getIcon(for: key)
        self.color = CardioWorkoutDisplayService.getColor(for: key)
        self.isHighFrequency = CardioWorkoutDisplayService.isHighFrequencyMetric(key)
        self.updateInterval = CardioWorkoutDisplayService.getUpdateInterval(for: key)
    }
}