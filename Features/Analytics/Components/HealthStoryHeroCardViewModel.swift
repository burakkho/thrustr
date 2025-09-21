import Foundation
import SwiftUI

@MainActor
@Observable
class HealthStoryHeroCardViewModel {

    // MARK: - Properties
    var celebrationType: CelebrationType = .none
    var recoveryScore: Int = 0
    var weeklyPatternScore: Int = 0
    var dayOfWeekScore: Int = 0

    // Health Data Properties
    var todaySteps: Double = 0
    var todayActiveCalories: Double = 0
    var currentHeartRate: Double?

    // MARK: - Dependencies
    private let healthKitDashboard = HealthKitDashboardService.shared
    private let healthKitAnalytics = HealthKitAnalyticsService.shared

    // MARK: - Initialization
    init() {}

    // MARK: - Public Methods

    func updateHealthStory(user: User?) {
        // Load health data
        todaySteps = healthKitDashboard.todaySteps
        todayActiveCalories = healthKitDashboard.todayActiveCalories
        currentHeartRate = healthKitDashboard.todaySteps > 0 ? 70 : nil // Placeholder logic

        // Calculate metrics
        celebrationType = calculateOverallCelebration(user: user)
        recoveryScore = calculateRecoveryScore()
        weeklyPatternScore = calculateWeeklyPatternScore()
        dayOfWeekScore = calculateDayOfWeekScore()
    }

    // MARK: - Business Logic

    private func calculateOverallCelebration(user: User?) -> CelebrationType {
        let stepsCelebration = calculateStepsCelebration()
        let caloriesCelebration = calculateCaloriesCelebration(user: user)

        // Return the highest celebration level
        let celebrations = [stepsCelebration, caloriesCelebration]
        if celebrations.contains(.fire) { return .fire }
        if celebrations.contains(.celebration) { return .celebration }
        if celebrations.contains(.progress) { return .progress }
        return .none
    }

    private func calculateStepsCelebration() -> CelebrationType {
        let steps = healthKitDashboard.todaySteps
        if steps >= 15000 { return .fire }
        if steps >= 10000 { return .celebration }
        if steps >= 5000 { return .progress }
        return .none
    }

    private func calculateCaloriesCelebration(user: User?) -> CelebrationType {
        guard let user = user else { return .none }
        let calories = healthKitDashboard.todayActiveCalories
        let goal = user.dailyCalorieGoal

        if calories >= goal * 1.2 { return .fire }
        if calories >= goal { return .celebration }
        if calories >= goal * 0.7 { return .progress }
        return .none
    }

    private func calculateRecoveryScore() -> Int {
        // Mock recovery calculation - would use actual health data
        let sleep = healthKitAnalytics.lastNightSleep
        let hrv = 45.0 // Mock HRV data
        let restingHR = 65.0 // Mock resting heart rate

        let sleepScore = min(sleep / 8.0, 1.0) * 40
        let hrvScore = min(hrv / 50.0, 1.0) * 30
        let hrScore = max(0, (80 - restingHR) / 15.0) * 30

        return Int(sleepScore + hrvScore + hrScore)
    }

    private func calculateWeeklyPatternScore() -> Int {
        // Mock weekly pattern analysis
        let consistencyDays = 5 // Days active this week
        let targetDays = 7

        return Int((Double(consistencyDays) / Double(targetDays)) * 100)
    }

    private func calculateDayOfWeekScore() -> Int {
        // Mock day-of-week performance
        let calendar = Calendar.current
        let dayOfWeek = calendar.component(.weekday, from: Date())

        // Weekend vs weekday pattern scoring
        if [1, 7].contains(dayOfWeek) { // Weekend
            return Int.random(in: 60...85)
        } else { // Weekday
            return Int.random(in: 70...95)
        }
    }
}

// MARK: - Supporting Types
// Using existing CelebrationType from Shared/Models/CelebrationType.swift