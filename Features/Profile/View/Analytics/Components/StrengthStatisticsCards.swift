import SwiftUI

/**
 * Statistics cards specifically for strength training analytics.
 *
 * Displays key strength metrics including total workouts, average 1RM,
 * total volume, and top exercise performance.
 */
struct StrengthStatisticsCards: View {
    let liftSessions: [LiftSession]
    let timeRange: TimeRange
    @Environment(UnitSettings.self) var unitSettings

    private var totalWorkouts: Int {
        liftSessions.count
    }

    private var allResults: [LiftExerciseResult] {
        liftSessions.compactMap { $0.exerciseResults }.flatMap { $0 }
    }

    private var averageOneRM: Double {
        guard !allResults.isEmpty else { return 0.0 }
        return allResults.map { $0.estimatedOneRM }.reduce(0, +) / Double(allResults.count)
    }

    private var totalVolume: Double {
        allResults.reduce(into: 0.0) { total, result in
            total += result.totalVolume
        }
    }

    private var topExercise: String {
        let exerciseGroups = Dictionary(grouping: allResults, by: { $0.exercise?.exerciseName ?? "Unknown" })
        return exerciseGroups.max { $0.value.count < $1.value.count }?.key ?? "No exercises"
    }

    private var personalRecords: Int {
        allResults.filter { $0.isPersonalRecord }.count
    }

    var body: some View {
        StatCard(
            title: ProfileKeys.Analytics.totalWorkouts.localized,
            value: "\(totalWorkouts)",
            icon: "figure.strengthtraining.traditional",
            color: .red
        )

        StatCard(
            title: ProfileKeys.Analytics.averageOneRM.localized,
            value: UnitsFormatter.formatWeight(kg: averageOneRM, system: unitSettings.unitSystem),
            icon: "trophy.fill",
            color: .yellow
        )

        StatCard(
            title: ProfileKeys.Analytics.totalVolume.localized,
            value: UnitsFormatter.formatWeight(kg: totalVolume, system: unitSettings.unitSystem),
            icon: "chart.bar.fill",
            color: .blue
        )

        StatCard(
            title: ProfileKeys.Analytics.topExercise.localized,
            value: topExercise,
            icon: "star.fill",
            color: .purple
        )

        if personalRecords > 0 {
            StatCard(
                title: ProfileKeys.Analytics.personalRecords.localized,
                value: "\(personalRecords)",
                icon: "medal.fill",
                color: .orange
            )
        }
    }
}