import Foundation
import SwiftUI
import SwiftData

@MainActor
@Observable
class StrengthProgressionSectionViewModel {

    // MARK: - Properties
    var exerciseMaxes: [(name: String, currentMax: Double, trend: TrendDirection, improvement: Double)] = []
    var strongestLiftValue: String = "--"
    var strongestLiftName: String = "--"
    var totalVolumeValue: String = "--"

    // MARK: - Dependencies
    private let trainingAnalytics = TrainingAnalyticsService()

    // MARK: - Initialization
    init() {}

    // MARK: - Public Methods

    func updateStrengthProgression(liftResults: [LiftExerciseResult], unitSettings: UnitSettings) {
        exerciseMaxes = TrainingAnalyticsService.calculateExerciseMaxes(from: liftResults)
        strongestLiftValue = calculateStrongestLiftValue(unitSettings: unitSettings)
        strongestLiftName = calculateStrongestLiftName()
        totalVolumeValue = calculateTotalVolumeValue(liftResults: liftResults, unitSettings: unitSettings)
    }

    // MARK: - Business Logic

    private func calculateStrongestLiftValue(unitSettings: UnitSettings) -> String {
        guard let strongest = exerciseMaxes.max(by: { $0.currentMax < $1.currentMax }) else {
            return "--"
        }
        return UnitsFormatter.formatWeight(kg: strongest.currentMax, system: unitSettings.unitSystem)
    }

    private func calculateStrongestLiftName() -> String {
        return exerciseMaxes.max(by: { $0.currentMax < $1.currentMax })?.name ?? "--"
    }

    private func calculateTotalVolumeValue(liftResults: [LiftExerciseResult], unitSettings: UnitSettings) -> String {
        let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        let recentResults = liftResults.filter { $0.performedAt >= oneMonthAgo }
        let totalVolume = recentResults.compactMap { $0.maxWeight }.reduce(0, +)

        if totalVolume == 0 { return "--" }
        return UnitsFormatter.formatWeight(kg: totalVolume, system: unitSettings.unitSystem)
    }

    // MARK: - Helper Methods

    func getExerciseIcon(_ exerciseName: String) -> String {
        let lowercaseName = exerciseName.lowercased()
        if lowercaseName.contains("squat") { return "figure.strengthtraining.traditional" }
        if lowercaseName.contains("bench") { return "figure.wrestling" }
        if lowercaseName.contains("deadlift") { return "figure.strengthtraining.functional" }
        if lowercaseName.contains("press") { return "figure.strengthtraining.functional" }
        if lowercaseName.contains("curl") { return "figure.strengthtraining.traditional" }
        if lowercaseName.contains("row") { return "figure.rowing" }
        return "dumbbell.fill"
    }

    func formatTrendValue(_ improvement: Double, trend: TrendDirection, unitSettings: UnitSettings) -> String {
        if improvement == 0 {
            return "--"
        }

        let prefix = trend == .increasing ? "+" : (trend == .decreasing ? "-" : "")
        return "\(prefix)\(UnitsFormatter.formatWeight(kg: improvement, system: unitSettings.unitSystem))"
    }

    func calculateMonthlyProgress(for exerciseName: String, liftResults: [LiftExerciseResult], unitSettings: UnitSettings) -> String {
        let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        let twoMonthsAgo = Calendar.current.date(byAdding: .month, value: -2, to: Date()) ?? Date()

        let exerciseResults = liftResults.filter {
            $0.exercise?.exerciseName == exerciseName
        }

        let recentMax = exerciseResults
            .filter { $0.performedAt >= oneMonthAgo }
            .compactMap { $0.maxWeight }
            .max() ?? 0

        let previousMax = exerciseResults
            .filter { $0.performedAt >= twoMonthsAgo && $0.performedAt < oneMonthAgo }
            .compactMap { $0.maxWeight }
            .max() ?? 0

        let improvement = recentMax - previousMax
        if improvement <= 0 { return "--" }

        return "+\(UnitsFormatter.formatWeight(kg: improvement, system: unitSettings.unitSystem))"
    }

    func calculateProgressPercentage(_ improvement: Double) -> Double? {
        // Convert improvement to a 0-1 scale for progress bar
        if improvement <= 0 { return nil }
        return min(1.0, improvement / 10.0) // Assume 10kg improvement = 100%
    }

    func getTrendColor(_ trend: TrendDirection) -> Color {
        switch trend {
        case .increasing: return .green
        case .decreasing: return .red
        case .stable: return .blue
        }
    }
}