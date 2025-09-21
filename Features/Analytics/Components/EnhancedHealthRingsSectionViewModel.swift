import Foundation
import SwiftUI

@MainActor
@Observable
class EnhancedHealthRingsSectionViewModel {

    // MARK: - Properties
    var stepsProgress: Double = 0
    var caloriesProgress: Double = 0
    var activeMinutesProgress: Double = 0
    var recoveryScore: Int = 0

    var stepsGoal: Double = 10000
    var caloriesGoal: Double = 500
    var activeMinutesGoal: Double = 30

    // MARK: - Dependencies
    private let healthKitDashboard = HealthKitDashboardService.shared
    private let healthKitAnalytics = HealthKitAnalyticsService.shared

    // MARK: - Initialization
    init() {}

    // MARK: - Public Methods

    func updateHealthRings(user: User?) {
        updateGoalsFromUser(user: user)
        calculateProgress()
        recoveryScore = calculateRecoveryScore()
    }

    // MARK: - Business Logic

    private func updateGoalsFromUser(user: User?) {
        guard let user = user else { return }

        stepsGoal = 10000 // Default or from user preferences
        caloriesGoal = user.dailyCalorieGoal > 0 ? user.dailyCalorieGoal : 500
        activeMinutesGoal = 30 // Default active minutes goal
    }

    private func calculateProgress() {
        let todaySteps = healthKitDashboard.todaySteps
        let todayCalories = healthKitDashboard.todayActiveCalories
        let todayActiveMinutes = healthKitDashboard.todayExerciseMinutes

        stepsProgress = min(1.0, todaySteps / stepsGoal)
        caloriesProgress = min(1.0, todayCalories / caloriesGoal)
        activeMinutesProgress = min(1.0, todayActiveMinutes / activeMinutesGoal)
    }

    private func calculateRecoveryScore() -> Int {
        // Advanced recovery calculation
        let sleep = healthKitAnalytics.lastNightSleep
        let sleepEfficiency = healthKitAnalytics.sleepEfficiency
        let hrv = 45.0 // Mock HRV data - would come from HealthKit

        // Sleep component (40% of score)
        let sleepScore = min(sleep / 8.0, 1.0) * 40

        // Sleep efficiency component (35% of score)
        let efficiencyScore = (sleepEfficiency / 100.0) * 35

        // HRV component (25% of score)
        let hrvScore = min(hrv / 50.0, 1.0) * 25

        return Int(sleepScore + efficiencyScore + hrvScore)
    }

    // MARK: - Helper Methods

    func getRingColor(for ringType: HealthRingType) -> Color {
        switch ringType {
        case .steps:
            return .blue
        case .calories:
            return .red
        case .activeMinutes:
            return .green
        }
    }

    func getProgressText(for ringType: HealthRingType) -> String {
        switch ringType {
        case .steps:
            return "\(Int(healthKitDashboard.todaySteps))/\(Int(stepsGoal))"
        case .calories:
            return "\(Int(healthKitDashboard.todayActiveCalories))/\(Int(caloriesGoal)) cal"
        case .activeMinutes:
            return "\(Int(healthKitDashboard.todayExerciseMinutes))/\(Int(activeMinutesGoal)) min"
        }
    }

    func getProgressValue(for ringType: HealthRingType) -> Double {
        switch ringType {
        case .steps:
            return stepsProgress
        case .calories:
            return caloriesProgress
        case .activeMinutes:
            return activeMinutesProgress
        }
    }

    func getGoalAchievedCount() -> Int {
        var achieved = 0
        if stepsProgress >= 1.0 { achieved += 1 }
        if caloriesProgress >= 1.0 { achieved += 1 }
        if activeMinutesProgress >= 1.0 { achieved += 1 }
        return achieved
    }

    func getRecoveryScoreColor() -> Color {
        switch recoveryScore {
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

    func getRecoveryMessage() -> String {
        switch recoveryScore {
        case 80...100:
            return "Excellent recovery! 🌟"
        case 60...79:
            return "Good recovery levels 💪"
        case 40...59:
            return "Moderate recovery 😴"
        default:
            return "Focus on rest 🛌"
        }
    }
}

// MARK: - Supporting Types

enum HealthRingType {
    case steps
    case calories
    case activeMinutes
}