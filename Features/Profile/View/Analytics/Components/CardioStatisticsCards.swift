import SwiftUI

/**
 * Statistics cards specifically for cardio training analytics.
 *
 * Displays key cardio metrics including total sessions, distance,
 * duration, calories burned, and average heart rate.
 */
struct CardioStatisticsCards: View {
    let cardioSessions: [CardioSession]
    let timeRange: TimeRange
    @Environment(UnitSettings.self) var unitSettings

    private var totalSessions: Int {
        cardioSessions.count
    }

    private var totalDistance: Double {
        cardioSessions.reduce(0.0) { $0 + $1.totalDistance }
    }

    private var totalDuration: TimeInterval {
        cardioSessions.reduce(0.0) { $0 + Double($1.totalDuration) }
    }

    private var totalCalories: Int {
        cardioSessions.compactMap { $0.totalCaloriesBurned }.reduce(0, +)
    }

    private var averageHeartRate: Double? {
        let heartRates = cardioSessions.compactMap { $0.averageHeartRate.map { Double($0) } }
        guard !heartRates.isEmpty else { return nil }
        return heartRates.reduce(0, +) / Double(heartRates.count)
    }

    private var averageDistance: Double {
        totalSessions > 0 ? totalDistance / Double(totalSessions) : 0
    }

    var body: some View {
        StatCard(
            title: ProfileKeys.Analytics.totalSessions.localized,
            value: "\(totalSessions)",
            icon: "figure.run",
            color: .pink
        )

        StatCard(
            title: ProfileKeys.Analytics.totalDistance.localized,
            value: formatDistance(totalDistance),
            icon: "location.fill",
            color: .blue
        )

        StatCard(
            title: ProfileKeys.Analytics.totalDuration.localized,
            value: formatDuration(totalDuration),
            icon: "clock.fill",
            color: .green
        )

        StatCard(
            title: ProfileKeys.Analytics.totalCalories.localized,
            value: "\(totalCalories)",
            icon: "flame.fill",
            color: .orange
        )

        if let avgHR = averageHeartRate {
            StatCard(
                title: ProfileKeys.Analytics.averageHeartRate.localized,
                value: "\(Int(avgHR)) BPM",
                icon: "heart.fill",
                color: .red
            )
        }

        StatCard(
            title: ProfileKeys.Analytics.averageDistance.localized,
            value: formatDistance(averageDistance),
            icon: "chart.line.uptrend.xyaxis",
            color: .purple
        )
    }

    private func formatDistance(_ km: Double) -> String {
        switch unitSettings.unitSystem {
        case .metric:
            return String(format: "%.1f km", km)
        case .imperial:
            let miles = km * 0.621371
            return String(format: "%.1f mi", miles)
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = Int(seconds.truncatingRemainder(dividingBy: 3600)) / 60

        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else {
            return String(format: "%dm", minutes)
        }
    }
}