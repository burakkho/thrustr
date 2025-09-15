import Foundation
import SwiftData

/**
 * Achievement computation service with comprehensive fitness tracking capabilities.
 *
 * This utility struct provides achievement calculation logic extracted from views
 * to maintain clean separation of concerns. Computes achievements based on user
 * progress across training, nutrition, and health metrics.
 *
 * Supported computations:
 * - Recent achievement tracking based on user activity
 * - Progress percentage calculations for ongoing achievements
 * - Achievement filtering and prioritization logic
 * - Multi-modal fitness achievement detection (strength, cardio, nutrition)
 */
struct AchievementService: Sendable {

    // MARK: - Achievement Computation

    /**
     * Computes recent achievements based on user activity across all fitness modalities.
     *
     * Analyzes user's training sessions, nutrition entries, weight tracking, and health data
     * to identify completed and in-progress achievements. Prioritizes recent activity and
     * meaningful milestones for user motivation.
     *
     * - Parameters:
     *   - user: Current user profile with fitness goals and metrics
     *   - todaySteps: Today's step count from HealthKit
     *   - todayActiveCalories: Today's active calories from HealthKit
     *   - liftSessions: Strength training session history
     *   - nutritionEntries: Food logging and nutrition tracking data
     *   - weightEntries: Body weight tracking history
     * - Returns: Array of achievements sorted by relevance and completion status
     */
    static func computeRecentAchievements(
        user: User?,
        todaySteps: Double,
        todayActiveCalories: Double,
        liftSessions: [LiftSession],
        nutritionEntries: [NutritionEntry],
        weightEntries: [WeightEntry]
    ) -> [Achievement] {

        guard let user = user else { return [] }

        var achievements: [Achievement] = []

        // MARK: Strength Training Achievements
        achievements.append(contentsOf: computeStrengthAchievements(
            user: user,
            liftSessions: liftSessions
        ))

        // MARK: Nutrition Achievements
        achievements.append(contentsOf: computeNutritionAchievements(
            user: user,
            nutritionEntries: nutritionEntries
        ))

        // MARK: Weight Management Achievements
        achievements.append(contentsOf: computeWeightAchievements(
            user: user,
            weightEntries: weightEntries
        ))

        // MARK: Health & Activity Achievements
        achievements.append(contentsOf: computeHealthAchievements(
            user: user,
            todaySteps: todaySteps,
            todayActiveCalories: todayActiveCalories
        ))

        // Sort by completion status and progress
        return achievements.sorted { achievement1, achievement2 in
            // Completed achievements first
            if achievement1.isCompleted != achievement2.isCompleted {
                return achievement1.isCompleted
            }
            // Then by progress percentage (higher progress first)
            return achievement1.progressPercentage > achievement2.progressPercentage
        }
    }

    // MARK: - Private Achievement Computations

    /**
     * Computes strength training related achievements.
     */
    private static func computeStrengthAchievements(
        user: User,
        liftSessions: [LiftSession]
    ) -> [Achievement] {

        var achievements: [Achievement] = []
        let recentSessions = liftSessions.filter { session in
            Calendar.current.isDate(session.startDate, equalTo: Date(), toGranularity: .month)
        }

        // First Workout Achievement
        if !liftSessions.isEmpty {
            var firstWorkout = Achievement(
                title: "First Workout",
                description: "Complete your first strength training session",
                icon: "figure.strengthtraining.traditional",
                category: .workout,
                targetValue: 1.0
            )
            firstWorkout.currentProgress = 1.0
            achievements.append(firstWorkout)
        }

        // Monthly Training Consistency
        let monthlyTarget: Double = 12 // 3 times per week
        var monthlyConsistency = Achievement(
            title: "Monthly Warrior",
            description: "Complete 12 workouts this month",
            icon: "calendar.badge.checkmark",
            category: .streak,
            targetValue: monthlyTarget
        )
        monthlyConsistency.currentProgress = Double(recentSessions.count)
        achievements.append(monthlyConsistency)

        // Personal Records Achievement
        if user.hasCompleteOneRMData {
            var strengthMilestone = Achievement(
                title: "Strength Milestone",
                description: "Achieve intermediate strength level",
                icon: "dumbbell.fill",
                category: .workout,
                targetValue: 1.0
            )
            strengthMilestone.currentProgress = 1.0
            achievements.append(strengthMilestone)
        }

        return achievements
    }

    /**
     * Computes nutrition related achievements.
     */
    private static func computeNutritionAchievements(
        user: User,
        nutritionEntries: [NutritionEntry]
    ) -> [Achievement] {

        var achievements: [Achievement] = []
        let recentEntries = nutritionEntries.filter { entry in
            Calendar.current.isDate(entry.date, equalTo: Date(), toGranularity: .weekOfYear)
        }

        // Weekly Nutrition Tracking
        let weeklyTarget: Double = 7
        var weeklyNutrition = Achievement(
            title: "Nutrition Tracker",
            description: "Log meals for 7 consecutive days",
            icon: "leaf.fill",
            category: .nutrition,
            targetValue: weeklyTarget
        )
        weeklyNutrition.currentProgress = Double(recentEntries.count)
        achievements.append(weeklyNutrition)

        return achievements
    }

    /**
     * Computes weight management achievements.
     */
    private static func computeWeightAchievements(
        user: User,
        weightEntries: [WeightEntry]
    ) -> [Achievement] {

        var achievements: [Achievement] = []

        if !weightEntries.isEmpty {
            let sortedEntries = weightEntries.sorted { $0.date < $1.date }

            // Weight Tracking Consistency
            var weightTracking = Achievement(
                title: "Scale Master",
                description: "Track your weight consistently",
                icon: "scalemass.fill",
                category: .weight,
                targetValue: 5.0
            )
            weightTracking.currentProgress = Double(weightEntries.count)
            achievements.append(weightTracking)

            // Weight Goal Progress (if user has weight change goals)
            if let firstEntry = sortedEntries.first,
               let latestEntry = sortedEntries.last,
               sortedEntries.count >= 2 {

                let weightChange = latestEntry.weight - firstEntry.weight
                let hasProgress = abs(weightChange) > 1.0 // At least 1kg change

                var bodyTransformation = Achievement(
                    title: "Body Transformation",
                    description: "Make meaningful progress toward your weight goals",
                    icon: "figure.walk",
                    category: .weight,
                    targetValue: 1.0
                )
                bodyTransformation.currentProgress = hasProgress ? 1.0 : 0.5
                achievements.append(bodyTransformation)
            }
        }

        return achievements
    }

    /**
     * Computes health and activity achievements.
     *
     * Note: HealthKit values must be passed as parameters due to MainActor isolation.
     */
    private static func computeHealthAchievements(
        user: User,
        todaySteps: Double,
        todayActiveCalories: Double
    ) -> [Achievement] {

        var achievements: [Achievement] = []

        // Daily Steps Achievement
        let dailyStepsTarget: Double = 10000
        var stepsAchievement = Achievement(
            title: "Step Counter",
            description: "Walk 10,000 steps in a day",
            icon: "figure.walk",
            category: .weight,
            targetValue: dailyStepsTarget
        )
        stepsAchievement.currentProgress = todaySteps
        achievements.append(stepsAchievement)

        // Active Calories Achievement
        let caloriesTarget: Double = 600
        var caloriesAchievement = Achievement(
            title: "Calorie Burner",
            description: "Burn 600 active calories in a day",
            icon: "flame.fill",
            category: .weight,
            targetValue: caloriesTarget
        )
        caloriesAchievement.currentProgress = todayActiveCalories
        achievements.append(caloriesAchievement)

        return achievements
    }
}

// Note: Achievement model is defined in AchievementsView.swift
// This service uses the existing Achievement struct from the UI layer