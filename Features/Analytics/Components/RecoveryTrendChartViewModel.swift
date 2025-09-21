import Foundation
import SwiftUI

@MainActor
@Observable
class RecoveryTrendChartViewModel {

    // MARK: - Properties
    var recoveryData: [RecoveryDataPoint] = []
    var isLoading = false
    var averageRecovery: Double = 0
    var trendDirection: TrendDirection = .stable

    // MARK: - Dependencies
    private let healthKitAnalytics = HealthKitAnalyticsService.shared

    // MARK: - Initialization
    init() {}

    // MARK: - Public Methods

    func loadRecoveryTrend(daysBack: Int = 7) async {
        isLoading = true
        defer { isLoading = false }

        recoveryData = generateRecoveryData(daysBack: daysBack)
        averageRecovery = calculateAverageRecovery()
        trendDirection = calculateTrendDirection()
    }

    // MARK: - Business Logic

    private func generateRecoveryData(daysBack: Int) -> [RecoveryDataPoint] {
        var data: [RecoveryDataPoint] = []
        let calendar = Calendar.current

        for daysBack in 0..<daysBack {
            let date = calendar.date(byAdding: .day, value: -daysBack, to: Date()) ?? Date()
            let recovery = calculateRealRecoveryForDay(daysBack: daysBack)

            data.append(RecoveryDataPoint(
                date: date,
                recoveryScore: recovery,
                sleepHours: Double.random(in: 6...9),
                hrv: Double.random(in: 30...60),
                restingHR: Double.random(in: 55...75)
            ))
        }

        return data.reversed() // Oldest to newest
    }

    private func calculateRealRecoveryForDay(daysBack: Int) -> Double {
        // Mock recovery calculation based on various factors
        let sleepQuality = healthKitAnalytics.sleepEfficiency / 100.0
        let baseRecovery = 0.7 + (sleepQuality * 0.3)

        // Add some variation based on day
        let variation = sin(Double(daysBack) * 0.5) * 0.15
        let recoveryScore = max(0.3, min(1.0, baseRecovery + variation))

        return recoveryScore * 100
    }

    private func calculateAverageRecovery() -> Double {
        guard !recoveryData.isEmpty else { return 0 }

        let total = recoveryData.reduce(0) { $0 + $1.recoveryScore }
        return total / Double(recoveryData.count)
    }

    private func calculateTrendDirection() -> TrendDirection {
        guard recoveryData.count >= 3 else { return .stable }

        let recent = Array(recoveryData.suffix(3))
        let older = Array(recoveryData.prefix(3))

        let recentAvg = recent.reduce(0) { $0 + $1.recoveryScore } / Double(recent.count)
        let olderAvg = older.reduce(0) { $0 + $1.recoveryScore } / Double(older.count)

        let difference = recentAvg - olderAvg

        if difference > 5 { return .increasing }
        if difference < -5 { return .decreasing }
        return .stable
    }

    // MARK: - Helper Methods

    func getRecoveryColor(score: Double) -> Color {
        switch score {
        case 80...100:
            return .green
        case 60...79:
            return .orange
        case 40...59:
            return .yellow
        default:
            return .red
        }
    }

    func getTrendMessage() -> String {
        switch trendDirection {
        case .increasing:
            return "📈 Recovery improving this week!"
        case .decreasing:
            return "📉 Focus on better rest and recovery"
        case .stable:
            return "➡️ Recovery maintaining steady levels"
        }
    }

    func getAverageRecoveryDescription() -> String {
        switch averageRecovery {
        case 80...100:
            return "Excellent recovery levels"
        case 60...79:
            return "Good recovery, room to improve"
        case 40...59:
            return "Moderate recovery levels"
        default:
            return "Focus on recovery improvements"
        }
    }
}

// MARK: - Supporting Types

struct RecoveryDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let recoveryScore: Double
    let sleepHours: Double
    let hrv: Double
    let restingHR: Double
}

// Using existing TrendDirection from Core/Models/TrendDirection.swift